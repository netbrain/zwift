#!/usr/bin/env python3
"""ANT+ heart rate strap bridge for Zwift on Linux.

Reads heart rate from an ANT+ strap through a USB dongle and offers it on the
network as a Direct Connect (DIRCON) device, the same way a Wahoo KICKR does.
Zwift in the container finds it by itself (with NETWORKING="host"), with no
Companion app and no ANT+ support in Wine.

With --ble the heart rate is instead offered as a standard Bluetooth LE heart
rate sensor through the PC's Bluetooth adapter, which the Companion app can
then pass on to Zwift.

Usage:
  ant-hrm-bridge.py                 ANT+ in, Direct Connect out
  ant-hrm-bridge.py --belt-id 12345 only use the strap with this ANT ID
  ant-hrm-bridge.py --ble           ANT+ in, Bluetooth LE out
  ant-hrm-bridge.py --ant-only      only print the heart rate from the strap
  ant-hrm-bridge.py --sim           simulated heart rate out (no dongle/strap)
"""
import argparse
import logging
import math
import os
import select
import shutil
import signal
import socketserver
import struct
import subprocess
import sys
import threading
import time
import uuid

HR_SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb"
HR_MEASUREMENT_UUID = "00002a37-0000-1000-8000-00805f9b34fb"
BODY_SENSOR_LOCATION_UUID = "00002a38-0000-1000-8000-00805f9b34fb"
BODY_SENSOR_CHEST = 0x01

# Dynastream/Garmin, the vendor of ANTUSB2 and ANTUSB-m dongles.
ANT_VENDOR_ID = 0x0FCF
DONGLE_CHECK_INTERVAL = 2.0

# Stop sending when the strap has been silent this long (seconds).
STALE_AFTER = 5.0

DEFAULT_NAME = "ANT HRM Bridge"

log = logging.getLogger("ant-hrm-bridge")


class Pulse:
    """Latest heart rate, shared between the ANT thread and the output side."""

    def __init__(self):
        self._lock = threading.Lock()
        self._bpm = 0
        self._at = 0.0

    def set(self, bpm):
        with self._lock:
            self._bpm = bpm
            self._at = time.monotonic()

    def get(self):
        with self._lock:
            if time.monotonic() - self._at > STALE_AFTER:
                return None
            return self._bpm


def dongle_address():
    import usb.core

    device = usb.core.find(idVendor=ANT_VENDOR_ID)
    return None if device is None else (device.bus, device.address)


def watch_dongle(address, stop):
    """Exit if the dongle disappears, so systemd can restart the bridge.

    openant catches USB errors in its own thread and retries forever, so
    ant_loop never hears about them. Normal cleanup is skipped because libusb
    can crash when the device is gone.
    """
    while not stop.wait(DONGLE_CHECK_INTERVAL):
        if dongle_address() != address:
            log.error("Lost the ANT dongle, exiting so it can be restarted")
            logging.shutdown()
            os._exit(1)


def ant_loop(pulse, stop, belt_id):
    """Run the ANT node, and start it again if it fails."""
    from openant.devices import ANTPLUS_NETWORK_KEY
    from openant.devices.heart_rate import HeartRate, HeartRateData
    from openant.easy.node import Node

    last_error = None
    while not stop.is_set():
        node = None
        try:
            node = Node()
            threading.Thread(
                target=watch_dongle, args=(dongle_address(), stop), daemon=True
            ).start()
            node.set_network_key(0x00, ANTPLUS_NETWORK_KEY)
            # The ANT channel searches forever, so the strap is picked up
            # again whenever it comes back in range or wakes up.
            device = HeartRate(node, device_id=belt_id)
            last = [0.0]

            def on_found():
                log.info("Found heart rate strap with ANT ID %d", device.device_id)

            def on_device_data(page, page_name, data):
                if not isinstance(data, HeartRateData) or data.heart_rate <= 0:
                    return
                pulse.set(data.heart_rate)
                now = time.monotonic()
                if now - last[0] >= 5:
                    last[0] = now
                    log.info("Heart rate: %d bpm", data.heart_rate)

            device.on_found = on_found
            device.on_device_data = on_device_data
            if belt_id:
                log.info("Listening for ANT+ strap %d (wet it and put it on)", belt_id)
            else:
                log.info("Listening for any ANT+ strap (wet it and put it on)")
            last_error = None
            node.start()
        except Exception as err:  # openant raises many different types
            if stop.is_set():
                break
            # As a service this retries forever, so log each error only once.
            error = f"{type(err).__name__}: {err}"
            if error != last_error:
                log.error("ANT error: %s", error)
                if "Access denied" in error or "Errno 13" in error:
                    log.error("No access to the dongle. Is the udev rule installed?")
                elif type(err).__name__ == "DriverNotFound":
                    log.error("No ANT dongle found. Is it plugged in?")
            last_error = error
            stop.wait(5)
        finally:
            if node is not None:
                try:
                    node.stop()
                except Exception:
                    pass


def sim_loop(pulse, stop, belt_id=None):
    start = time.monotonic()
    while not stop.is_set():
        pulse.set(int(120 + 15 * math.sin((time.monotonic() - start) / 10)))
        stop.wait(1)


# Bluetooth LE output through BlueZ (--ble).

BLUEZ = "org.bluez"
OM_IFACE = "org.freedesktop.DBus.ObjectManager"
PROP_IFACE = "org.freedesktop.DBus.Properties"
ADAPTER_IFACE = "org.bluez.Adapter1"
GATT_MANAGER_IFACE = "org.bluez.GattManager1"
GATT_SERVICE_IFACE = "org.bluez.GattService1"
GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1"
AD_MANAGER_IFACE = "org.bluez.LEAdvertisingManager1"
AD_IFACE = "org.bluez.LEAdvertisement1"
ROOT_PATH = "/antplus/hrmbridge"
APPEARANCE_HR_BELT = 0x0341


def run_ble(pulse, stop, name):
    # Imported here so Direct Connect mode does not need dbus-python or PyGObject.
    import dbus
    import dbus.exceptions
    import dbus.mainloop.glib
    import dbus.service
    from gi.repository import GLib, GLibUnix

    class InvalidArgs(dbus.exceptions.DBusException):
        _dbus_error_name = "org.freedesktop.DBus.Error.InvalidArgs"

    class Characteristic(dbus.service.Object):
        def __init__(self, bus, service, index, uuid, flags):
            self.path = f"{service.path}/char{index}"
            self.service = service
            self.uuid = uuid
            self.flags = flags
            super().__init__(bus, self.path)

        def properties(self):
            return {
                GATT_CHRC_IFACE: {
                    "Service": dbus.ObjectPath(self.service.path),
                    "UUID": self.uuid,
                    "Flags": dbus.Array(self.flags, signature="s"),
                }
            }

        @dbus.service.method(PROP_IFACE, in_signature="s", out_signature="a{sv}")
        def GetAll(self, interface):
            if interface != GATT_CHRC_IFACE:
                raise InvalidArgs()
            return self.properties()[GATT_CHRC_IFACE]

        @dbus.service.signal(PROP_IFACE, signature="sa{sv}as")
        def PropertiesChanged(self, interface, changed, invalidated):
            pass

    class HeartRateMeasurement(Characteristic):
        def __init__(self, bus, service):
            super().__init__(bus, service, 0, HR_MEASUREMENT_UUID, ["notify"])
            self.notifying = False

        @dbus.service.method(GATT_CHRC_IFACE)
        def StartNotify(self):
            if not self.notifying:
                self.notifying = True
                log.info("Bluetooth client connected and receiving heart rate")

        @dbus.service.method(GATT_CHRC_IFACE)
        def StopNotify(self):
            if self.notifying:
                self.notifying = False
                log.info("Bluetooth client disconnected")

        def send(self, bpm):
            if not self.notifying:
                return
            # Flags 0x00: heart rate is a uint8 with no extra fields.
            value = dbus.Array(
                [dbus.Byte(0x00), dbus.Byte(min(bpm, 255))], signature="y"
            )
            self.PropertiesChanged(GATT_CHRC_IFACE, {"Value": value}, [])

    class BodySensorLocation(Characteristic):
        def __init__(self, bus, service):
            super().__init__(bus, service, 1, BODY_SENSOR_LOCATION_UUID, ["read"])

        @dbus.service.method(
            GATT_CHRC_IFACE, in_signature="a{sv}", out_signature="ay"
        )
        def ReadValue(self, options):
            return dbus.Array([dbus.Byte(BODY_SENSOR_CHEST)], signature="y")

    class HeartRateService(dbus.service.Object):
        def __init__(self, bus):
            self.path = ROOT_PATH + "/service0"
            super().__init__(bus, self.path)
            self.measurement = HeartRateMeasurement(bus, self)
            self.characteristics = [self.measurement, BodySensorLocation(bus, self)]

        def properties(self):
            return {
                GATT_SERVICE_IFACE: {
                    "UUID": HR_SERVICE_UUID,
                    "Primary": True,
                    "Characteristics": dbus.Array(
                        [dbus.ObjectPath(c.path) for c in self.characteristics],
                        signature="o",
                    ),
                }
            }

    class Application(dbus.service.Object):
        def __init__(self, bus):
            super().__init__(bus, ROOT_PATH)
            self.service = HeartRateService(bus)

        @dbus.service.method(OM_IFACE, out_signature="a{oa{sa{sv}}}")
        def GetManagedObjects(self):
            objects = {self.service.path: self.service.properties()}
            for chrc in self.service.characteristics:
                objects[chrc.path] = chrc.properties()
            return objects

    class Advertisement(dbus.service.Object):
        def __init__(self, bus):
            self.path = ROOT_PATH + "/advertisement0"
            super().__init__(bus, self.path)

        @dbus.service.method(PROP_IFACE, in_signature="s", out_signature="a{sv}")
        def GetAll(self, interface):
            if interface != AD_IFACE:
                raise InvalidArgs()
            return {
                "Type": "peripheral",
                "ServiceUUIDs": dbus.Array([HR_SERVICE_UUID], signature="s"),
                "LocalName": name,
                "Appearance": dbus.UInt16(APPEARANCE_HR_BELT),
            }

        @dbus.service.method(AD_IFACE)
        def Release(self):
            log.warning("BlueZ released the Bluetooth advertisement")

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    manager = dbus.Interface(bus.get_object(BLUEZ, "/"), OM_IFACE)
    adapter_path = None
    for path, interfaces in manager.GetManagedObjects().items():
        if GATT_MANAGER_IFACE in interfaces and AD_MANAGER_IFACE in interfaces:
            adapter_path = path
            break
    if adapter_path is None:
        log.error("Found no Bluetooth adapter that can act as an LE peripheral")
        return 1

    adapter = bus.get_object(BLUEZ, adapter_path)
    adapter_props = dbus.Interface(adapter, PROP_IFACE)
    adapter_props.Set(ADAPTER_IFACE, "Powered", dbus.Boolean(True))

    gatt_manager = dbus.Interface(adapter, GATT_MANAGER_IFACE)
    ad_manager = dbus.Interface(adapter, AD_MANAGER_IFACE)
    app = Application(bus)
    advertisement = Advertisement(bus)
    loop = GLib.MainLoop()
    failed = []

    def fail(what):
        def handler(err):
            log.error("%s failed: %s", what, err)
            failed.append(what)
            loop.quit()

        return handler

    gatt_manager.RegisterApplication(
        dbus.ObjectPath(ROOT_PATH), {},
        reply_handler=lambda: log.info("Heart rate GATT service registered"),
        error_handler=fail("GATT registration"),
    )
    ad_manager.RegisterAdvertisement(
        dbus.ObjectPath(advertisement.path), {},
        reply_handler=lambda: log.info("Advertising as '%s'", name),
        error_handler=fail("Bluetooth advertising"),
    )

    def tick():
        bpm = pulse.get()
        if bpm is not None:
            app.service.measurement.send(bpm)
        return True

    GLib.timeout_add_seconds(1, tick)
    for sig in (signal.SIGINT, signal.SIGTERM):
        GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, sig, loop.quit)
    loop.run()

    stop.set()
    try:
        ad_manager.UnregisterAdvertisement(dbus.ObjectPath(advertisement.path))
        gatt_manager.UnregisterApplication(dbus.ObjectPath(ROOT_PATH))
    except dbus.exceptions.DBusException:
        pass
    return 1 if failed else 0


# Direct Connect (DIRCON): BLE GATT over TCP, the protocol the KICKR uses.

DC_SERVICE_TYPE = "_wahoo-fitness-tnp._tcp"
DC_DEFAULT_PORT = 36867
DC_SERIAL = "ANTHRM01"
DC_HEADER = struct.Struct(">BBBBH")  # version, message, sequence, response, length
DC_VERSION = 1

DC_DISCOVER_SERVICES = 0x01
DC_DISCOVER_CHARACTERISTICS = 0x02
DC_READ_CHARACTERISTIC = 0x03
DC_WRITE_CHARACTERISTIC = 0x04
DC_ENABLE_NOTIFICATIONS = 0x05
DC_NOTIFICATION = 0x06
DC_UNKNOWN_07 = 0x07

DC_OK = 0x00
DC_UNKNOWN_MESSAGE = 0x01
DC_SERVICE_NOT_FOUND = 0x03
DC_CHARACTERISTIC_NOT_FOUND = 0x04
DC_NOT_SUPPORTED = 0x05

DC_PROP_READ = 0x01
DC_PROP_NOTIFY = 0x04

DC_UUID_LENGTH = 16
DC_HR_SERVICE = uuid.UUID(HR_SERVICE_UUID).bytes
DC_HR_MEASUREMENT = uuid.UUID(HR_MEASUREMENT_UUID).bytes
DC_BODY_SENSOR_LOCATION = uuid.UUID(BODY_SENSOR_LOCATION_UUID).bytes


def dircon_packet(message, sequence, response, payload=b""):
    header = DC_HEADER.pack(DC_VERSION, message, sequence, response, len(payload))
    return header + payload


def dircon_reply(message, sequence, payload):
    """Build the reply to a request from Zwift."""
    if message == DC_DISCOVER_SERVICES:
        return dircon_packet(message, sequence, DC_OK, DC_HR_SERVICE)
    if message == DC_DISCOVER_CHARACTERISTICS:
        if payload[:DC_UUID_LENGTH] != DC_HR_SERVICE:
            return dircon_packet(message, sequence, DC_SERVICE_NOT_FOUND)
        body = (
            DC_HR_SERVICE
            + DC_HR_MEASUREMENT + bytes([DC_PROP_NOTIFY])
            + DC_BODY_SENSOR_LOCATION + bytes([DC_PROP_READ])
        )
        return dircon_packet(message, sequence, DC_OK, body)

    char = payload[:DC_UUID_LENGTH]
    if message == DC_READ_CHARACTERISTIC:
        if char == DC_BODY_SENSOR_LOCATION:
            body = char + bytes([BODY_SENSOR_CHEST])
            return dircon_packet(message, sequence, DC_OK, body)
        if char == DC_HR_MEASUREMENT:
            return dircon_packet(message, sequence, DC_NOT_SUPPORTED)
        return dircon_packet(message, sequence, DC_CHARACTERISTIC_NOT_FOUND)
    if message == DC_WRITE_CHARACTERISTIC:
        return dircon_packet(message, sequence, DC_NOT_SUPPORTED)
    if message == DC_ENABLE_NOTIFICATIONS:
        if char != DC_HR_MEASUREMENT:
            return dircon_packet(message, sequence, DC_NOT_SUPPORTED)
        return dircon_packet(message, sequence, DC_OK, char)
    if message == DC_UNKNOWN_07:
        return dircon_packet(message, sequence, DC_OK)
    return dircon_packet(message, sequence, DC_UNKNOWN_MESSAGE)


class DirconHandler(socketserver.BaseRequestHandler):
    def handle(self):
        client = self.client_address[0]
        log.info("Direct Connect: %s connected", client)
        pending = b""
        notifying = False
        next_send = 0.0
        while not self.server.stop.is_set():
            readable, _, _ = select.select([self.request], [], [], 0.2)
            if readable:
                try:
                    data = self.request.recv(4096)
                except OSError:
                    break
                if not data:
                    break
                pending += data

            while len(pending) >= DC_HEADER.size:
                _, message, sequence, _, length = DC_HEADER.unpack_from(pending)
                end = DC_HEADER.size + length
                if len(pending) < end:
                    break
                payload = pending[DC_HEADER.size:end]
                pending = pending[end:]
                log.debug("Direct Connect: message 0x%02x, %d bytes", message, length)
                if message == DC_ENABLE_NOTIFICATIONS and (
                    payload[:DC_UUID_LENGTH] == DC_HR_MEASUREMENT
                ):
                    notifying = len(payload) <= DC_UUID_LENGTH or payload[-1] != 0
                    log.info("Direct Connect: heart rate notifications %s",
                             "on" if notifying else "off")
                self.request.sendall(dircon_reply(message, sequence, payload))

            now = time.monotonic()
            if notifying and now >= next_send:
                next_send = now + 1
                bpm = self.server.pulse.get()
                if bpm is not None:
                    value = DC_HR_MEASUREMENT + bytes([0x00, min(bpm, 255)])
                    try:
                        self.request.sendall(
                            dircon_packet(DC_NOTIFICATION, 0, DC_OK, value)
                        )
                    except OSError:
                        break
        log.info("Direct Connect: %s disconnected", client)


class DirconServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def __init__(self, pulse, stop, port):
        super().__init__(("0.0.0.0", port), DirconHandler)
        self.pulse = pulse
        self.stop = stop


def run_dircon(pulse, stop, name, port):
    if shutil.which("avahi-publish") is None:
        log.error("avahi-publish not found (install avahi-utils)")
        return 1

    server = DirconServer(pulse, stop, port)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    mac = uuid.getnode().to_bytes(6, "big").hex("-").upper()
    mdns = subprocess.Popen([
        "avahi-publish", "-s", name, DC_SERVICE_TYPE, str(port),
        "ble-service-uuids=0x180D",
        f"mac-address={mac}",
        f"serial-number={DC_SERIAL}",
    ], stdout=subprocess.DEVNULL)
    log.info("Advertising '%s' on port %d", name, port)

    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, lambda *_: stop.set())
    stop.wait()

    mdns.terminate()
    mdns.wait()
    server.shutdown()
    server.server_close()
    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Bridge an ANT+ heart rate strap to Zwift via Direct Connect"
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--ant-only", action="store_true",
                      help="only read and print the heart rate from the strap")
    mode.add_argument("--sim", action="store_true",
                      help="send a simulated heart rate (no dongle or strap)")
    parser.add_argument("--ble", action="store_true",
                        help="offer a Bluetooth LE sensor instead of Direct Connect")
    parser.add_argument("--belt-id", type=int, default=0, metavar="ID",
                        help="ANT ID of the strap; 0 (default) takes the first one found")
    parser.add_argument("--name", default=DEFAULT_NAME,
                        help=f"device name shown in Zwift (default: {DEFAULT_NAME})")
    parser.add_argument("--port", type=int, default=DC_DEFAULT_PORT,
                        help=f"Direct Connect TCP port (default: {DC_DEFAULT_PORT})")
    parser.add_argument("--verbose", action="store_true", help="log more detail")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(message)s",
        datefmt="%H:%M:%S",
    )
    logging.getLogger("openant").setLevel(logging.WARNING)
    # Logs thousands of lines when the dongle disappears, see watch_dongle.
    logging.getLogger("openant.base.ant").setLevel(logging.ERROR)

    pulse = Pulse()
    stop = threading.Event()

    if args.ant_only:
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        try:
            ant_loop(pulse, stop, args.belt_id)
        except KeyboardInterrupt:
            stop.set()
        return 0

    source = sim_loop if args.sim else ant_loop
    threading.Thread(
        target=source, args=(pulse, stop, args.belt_id), daemon=True
    ).start()
    if args.ble:
        code = run_ble(pulse, stop, args.name)
    else:
        code = run_dircon(pulse, stop, args.name, args.port)
    # A normal Python exit can segfault while the ANT thread is inside libusb.
    logging.shutdown()
    os._exit(code)


if __name__ == "__main__":
    sys.exit(main())
