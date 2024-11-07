#!/usr/bin/env bash

if [ ! $(id -u) = 0 ]; then
    echo "Please run as root"
    exit 1
fi
echo "This will install zwift.sh into /usr/local/bin"
read -p "Press enter to continue"

mkdir -p /usr/local/bin
curl -s -o /usr/local/bin/zwift https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh
chmod u=rwx,go=rx /usr/local/bin/zwift

mkdir -p /usr/local/share/icons/hicolor/scalable/apps
curl -s -o /usr/local/share/icons/hicolor/scalable/apps/zwift.svg https://raw.githubusercontent.com/netbrain/zwift/master/assets/hicolor/scalable/apps/Zwift%20Logogram.svg

mkdir -p /usr/local/share/applications
curl -s -o /usr/local/share/applications/Zwift.desktop https://raw.githubusercontent.com/netbrain/zwift/master/assets/Zwift.desktop


if [ "$(echo $PATH | grep /usr/local/bin)" = "" ]; then
    echo "WARNING: Could not find /usr/local/bin on the \$PATH, you might need to add it."
fi
