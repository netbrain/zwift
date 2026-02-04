#!/usr/bin/env bash

if [ -t 1 ]; then
    WHITE="\033[0;37m"
    RED="\033[0;31m"
    GREEN="\033[0;32m"
    BLUE="\033[0;34m"
    YELLOW="\033[0;33m"
    BOLD="\033[1m"
    UNDERLINE="\033[4m"
    RESET_STYLE="\033[0m"
else
    WHITE=""
    RED=""
    GREEN=""
    BLUE=""
    YELLOW=""
    BOLD=""
    UNDERLINE=""
    RESET_STYLE=""
fi

# Message Box to simplify errors and questions.
msgbox() {
    TYPE="$1" # Type: info, ok, warning, error, question
    MSG="$2"  # Message: the message to display

    case $TYPE in
        info) echo -e "${BLUE}[*] $MSG${RESET_STYLE}" ;;
        ok) echo -e "${GREEN}[✓] $MSG${RESET_STYLE}" ;;
        warning) echo -e "${YELLOW}[!] $MSG${RESET_STYLE}" ;;
        error) echo -e "${RED}[✗] $MSG${RESET_STYLE}" >&2 ;;
        question)
            echo -ne "${YELLOW}[?] ${BOLD}${UNDERLINE}$MSG [y/N]:${RESET_STYLE} "
            read -rn 1 ans
            echo
            case "$ans" in
                [yY] | [yY][eE][sS]) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *) echo -e "${WHITE}[*] $MSG${RESET_STYLE}" ;;
    esac
}

exit_failure() {
    msgbox error "Zwift install failed! 😭"
    exit 1
}

determine_install_location() {
    if [[ $EUID -eq 0 ]]; then
        ROOT_BIN=/usr/local/bin
        ROOT_SHARE=/usr/local/share
    else
        # user install
        ROOT_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
        ROOT_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
    fi

    msgbox info "Installing Zwift to:"
    msgbox info "  binaries → $ROOT_BIN"
    msgbox info "  data     → $ROOT_SHARE"
}

ask_user_confirmation() {
    if msgbox question "Are you sure you want to install Zwift?"; then
        msgbox ok "Proceeding with Zwift installation"
    else
        msgbox info "Aborted Zwift installation"
        msgbox warning "Zwift not installed! 😥"
        exit 0
    fi
}

create_directories() {
    create_directory() {
        DIRECTORY="$1"

        msgbox info "  Creating directory $DIRECTORY"

        if ! mkdir -p "$DIRECTORY"; then
            msgbox error "Could not create $DIRECTORY, aborting"
            exit_failure
        fi
    }

    msgbox info "Creating directories"

    create_directory "$ROOT_BIN"
    create_directory "$ROOT_SHARE/icons/hicolor/scalable/apps"
    create_directory "$ROOT_SHARE/applications"

    msgbox ok "Directories created"
}

download_zwift() {
    download_asset() {
        DESTINATION="$1"
        URL="$2"

        msgbox info "  Downloading $URL"

        if ! curl -fsSLo "$DESTINATION" "$URL"; then
            msgbox error "Downloading $URL failed, aborting"
            exit_failure
        fi
    }

    msgbox info "Downloading Zwift"

    ZWIFT_SCRIPT="https://raw.githubusercontent.com/netbrain/zwift/master/src/zwift.sh"
    ZWIFT_LOGO="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.svg"
    ZWIFT_DESKTOP_ENTRY="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.desktop"

    download_asset "$ROOT_BIN/zwift" "$ZWIFT_SCRIPT"
    download_asset "$ROOT_SHARE/icons/hicolor/scalable/apps/zwift.svg" "$ZWIFT_LOGO"
    download_asset "$ROOT_SHARE/applications/Zwift.desktop" "$ZWIFT_DESKTOP_ENTRY"

    if ! chmod 755 "$ROOT_BIN/zwift"; then
        msgbox error "Failed to set permissions for $ROOT_BIN/zwift, aborting"
        exit_failure
    fi

    msgbox ok "Zwift download complete"
}

check_in_path() {
    msgbox info "Checking if 'zwift' is in PATH"

    if case ":$PATH:" in *":$ROOT_BIN:"*) true ;; *) false ;; esac then
        msgbox info "  $ROOT_BIN is in your PATH"
        msgbox ok "Zwift can be launched using the 'zwift' command"
    else
        msgbox warning "$ROOT_BIN is not in your PATH"
        msgbox warning "You may need to add it to your PATH for the 'zwift' command to work"
    fi
}

echo -e "${YELLOW}[!] ${BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${YELLOW}[!] ${UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

msgbox info "Preparing to install Zwift"

determine_install_location
ask_user_confirmation
create_directories
download_zwift
check_in_path

msgbox ok "Zwift install complete! 🥳"
