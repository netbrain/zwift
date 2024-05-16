DESTDIR=/
PREFIX=/usr/
DATADIR?=${PREFIX}/share

.PHONY: all install uninstall zwift icons desktop

all:
	@echo "Call \"make install\" to install this program."
	@echo "Call \"make uninstall\" to remove this program."

install_zwift:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -m 755 zwift.sh ${DESTDIR}${PREFIX}/bin/zwift

uninstall_zwift:
	rm -f ${DESTDIR}${PREFIX}/bin/zwift

install_icons:
	mkdir -p ${DESTDIR}${DATADIR}/icons/hicolor/scalable/apps
	install -Dm 644 assets/hicolor/scalable/apps/Zwift Logogram.svg ${DESTDIR}${DATADIR}/icons/hicolor/scalable/apps/zwift.svg

uninstall_icons:
	rm -f ${DATADIR}/icons/hicolor/scalable/apps/zwift.svg

install_desktop:
	mkdir -p ${DESTDIR}${DATADIR}/applications
	install -Dm 644 assets/Zwift.desktop ${DESTDIR}${DATADIR}/applications/Zwift.desktop

uninstall_desktop:
	rm -f ${DATADIR}${DATADIR}/applications/Zwift.desktop

install: install_zwift install_icons install_desktop
uninstall: uninstall_zwift uninstall_icons uninstall_desktop
