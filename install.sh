#!/usr/bin/env bash

if [ -t 1 ]; then
    YELLOW="\033[0;33m"
    RESET_STYLE="\033[0m"
else
    YELLOW=""
    RESET_STYLE=""
fi

echo -e "${YELLOW}[!] Install script was moved, redirecting to new location${RESET_STYLE}"

pkexec env PATH="$PATH" bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/install/install.sh)"
