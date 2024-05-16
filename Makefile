DESTDIR=/
PREFIX?=/usr/local
DATADIR?=${PREFIX}/share

.PHONY: all install uninstall

all:
	@echo "Call \"make install\" to install this program."
	@echo "Call \"make uninstall\" to remove this program."

install:
	mkdir -p ${DESTDIR}${PREFIX}/bin
	install -m 755 zwift.sh ${DESTDIR}${PREFIX}/bin/zwift
	mkdir -p ${DESTDIR}${DATADIR}/icons/hicolor/scalable/apps
	install -Dm 644 assets/hicolor/scalable/apps/Zwift\ Logogram.svg ${DESTDIR}${DATADIR}/icons/hicolor/scalable/apps/zwift.svg
	mkdir -p ${DESTDIR}${DATADIR}/applications
	install -Dm 644 assets/Zwift.desktop ${DESTDIR}${DATADIR}/applications/Zwift.desktop
uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/zwift
	rm -f ${DATADIR}/icons/hicolor/scalable/apps/zwift.svg
	rm -f ${DATADIR}${DATADIR}/applications/Zwift.desktop
