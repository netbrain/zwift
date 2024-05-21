#!/usr/bin/env bash

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

install_zwift() {
    echo "This will install zwift.sh into /usr/local/bin"
    read -p "Press enter to continue"

    mkdir -p /usr/local/bin
    curl -s -o /usr/local/bin/zwift https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh
    chmod +x /usr/local/bin/zwift

    mkdir -p /usr/local/share/icons/hicolor/scalable/apps
    curl -s -o /usr/local/share/icons/hicolor/scalable/apps/Zwift\ Logogram.svg https://raw.githubusercontent.com/netbrain/zwift/master/assets/hicolor/scalable/apps/Zwift%20Logogram.svg

    mkdir -p /usr/local/share/applications
    curl -s -o /usr/local/share/applications/Zwift.desktop https://raw.githubusercontent.com/netbrain/zwift/master/assets/Zwift.desktop

    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        echo "WARNING: Could not find /usr/local/bin on the \$PATH, you might need to add it."
    fi
}

uninstall_zwift() {
    echo "This will remove zwift.sh and associated files"
    read -p "Press enter to continue"

    rm -f /usr/local/bin/zwift
    rm -f /usr/local/share/icons/hicolor/scalable/apps/Zwift\ Logogram.svg
    rm -f /usr/local/share/applications/Zwift.desktop

    echo "Zwift has been uninstalled."
}

if [ "$1" == "uninstall" ]; then
    uninstall_zwift
else
    install_zwift
fi
