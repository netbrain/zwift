#!/usr/bin/env bash

if [ ! $(id -u) = 0 ]; then
    echo "Please run as root"
    exit 1
fi
echo "This will install zwift.sh into /usr/local/bin"
read -p "Press enter to continue"

mkdir -p /usr/local/bin
curl -s -o /usr/local/bin/zwift https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh
chmod +x /usr/local/bin/zwift

if [ "$(echo $PATH | grep /usr/local/bin)" = "" ]; then
    echo "WARNING: Could not find /usr/local/bin on the \$PATH, you might need to add it."
fi
