#!/usr/bin/env bash
# Launch Zwift against the custom Wine image built by build-ble-wine.sh.
#
# Uses the zwift.sh from this source tree, not the possibly older installed
# wrapper in ~/.local/bin: that one predates the system D-Bus socket mount and
# without it the winebth driver cannot reach BlueZ at all.
#
# IMAGE/VERSION are forced here instead of inherited, so a leftover
# "VERSION=trace" in the shell cannot silently select an old image.
#
# Override with:
#   BLE_IMAGE=localhost/zwift-custom-wine
#   BLE_VERSION=ble-test
#   BLE_RIDER=$USER
#   BLE_TRACE=1        # focused BLE WINEDEBUG channels (no +seh/+loaddll)
#   BLE_LOG_DIR=~/zwift-logs
#
# Every run tees its output to a persistent log named
#   zwift-ble-<wine-commit>-<start-timestamp>.log
# under ${BLE_LOG_DIR:-${XDG_STATE_HOME:-~/.local/state}/zwift-ble}.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

ble_image="${BLE_IMAGE:-localhost/zwift-custom-wine}"
ble_version="${BLE_VERSION:-ble-test}"
ble_rider="${BLE_RIDER:-${USER:-custom-wine-test}}"

export IMAGE="${ble_image}"
export VERSION="${ble_version}"
export DONT_PULL=1
export DONT_CHECK=1
export ZWIFT_RIDER="${ble_rider}"
export ZWIFT_FG="${ZWIFT_FG:-1}"

# Focused tracing only. +loaddll/+seh produce far more output than the BLE
# channels and can stall the container's stdout pipe.
if [[ ${BLE_TRACE:-0} == 1 ]]; then
    export CONTAINER_EXTRA_ARGS="${CONTAINER_EXTRA_ARGS:-} --env WINEDEBUG=+timestamp,+pid,+tid,+bluetooth,+winebth,+combase,+vccorlib"
fi

# Wine does not bond devices on connect. Pair a trainer/controller once in the
# host OS (GNOME Settings or bluetoothctl) before launching; BlueZ then reuses
# that bond for every Wine connection. Do this for anything whose vendor
# characteristics need an encrypted link.

container_tool="${CONTAINER_TOOL:-podman}"
if ! image_info="$("${container_tool}" image inspect "${IMAGE}:${VERSION}" \
    --format '[ble] image {{.Id}} created {{.Created}}' 2> /dev/null)"; then
    echo "[ble] image ${IMAGE}:${VERSION} not found; run build-ble-wine.sh first" >&2
    exit 1
fi

# The image carries the Wine revision it was built from (see
# Dockerfile.custom-wine). Fall back to "unknown" for images built before that
# label existed.
wine_commit="$("${container_tool}" image inspect "${IMAGE}:${VERSION}" \
    --format '{{ index .Config.Labels "org.zwift.wine.commit" }}' 2> /dev/null || true)"
if [[ -z ${wine_commit} || ${wine_commit} == "<no value>" ]]; then
    wine_commit="unknown"
fi
readonly wine_commit

# Every run gets its own persistent log whose name records which Wine revision
# was tested and when: zwift-ble-<wine-commit>-<start-timestamp>.log
started_at="$(date '+%Y%m%dT%H%M%S%z')"
readonly started_at
ble_log_dir="${BLE_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/zwift-ble}"
readonly ble_log_dir
mkdir -p "${ble_log_dir}"
readonly ble_log_file="${ble_log_dir}/zwift-ble-${wine_commit}-${started_at}.log"

# Mirror everything this script and zwift.sh print into the log. Process
# substitution (rather than a pipe) keeps the final exec below intact, so
# zwift.sh still replaces this shell and its exit status passes through. The
# status of tee itself is not interesting, hence the "|| true".
exec > >(tee -a "${ble_log_file}" || true) 2>&1

if [[ ! -x "${script_dir}/zwift.sh" ]]; then
    echo "[ble] ${script_dir}/zwift.sh not found or not executable" >&2
    exit 1
fi

echo "[ble] logging to ${ble_log_file}"
echo "${image_info}"
echo "[ble] launching ${IMAGE}:${VERSION} wine-commit=${wine_commit} rider=${ZWIFT_RIDER} trace=${BLE_TRACE:-0} at ${started_at}"
cd "${script_dir}"
exec "${script_dir}/zwift.sh" "$@"
