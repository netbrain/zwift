#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

print_usage() {
    echo "Usage: install [ -v | --script-version COMMIT_HASH ]"
    echo "               [ -y | --auto-confirm ]"
    echo "               [ -h | --help ]"
    exit 2
}

script_version="master"
auto_confirm=0
if ! options="$(getopt -n install -o "v:yh" -l "script-version:,auto-confirm,help" -- "${@}")"; then
    print_usage
fi
eval set -- "${options}"
while :; do
    case "${1}" in
        -v | --script-version)
            script_version="${2}"
            shift 2
            ;;
        -y | --auto-confirm)
            auto_confirm=1
            shift
            ;;
        -h | --help)
            print_usage
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: ${1} - this should not happen." >&2
            print_usage
            ;;
    esac
done

readonly ZWIFT_SCRIPT="https://raw.githubusercontent.com/netbrain/zwift/${script_version}/src/zwift.sh"
readonly ZWIFT_LOGO="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.svg"
readonly ZWIFT_DESKTOP_ENTRY="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.desktop"

if [[ -t 1 ]]; then
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly STYLE_BOLD="\033[1m"
    readonly STYLE_UNDERLINE="\033[4m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLOR_WHITE=""
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_BLUE=""
    readonly COLOR_YELLOW=""
    readonly STYLE_BOLD=""
    readonly STYLE_UNDERLINE=""
    readonly RESET_STYLE=""
fi

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error, question
    local msg="${2:?}"  # Message: the message to display

    case ${type} in
        info) echo -e "${COLOR_BLUE}[*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[✗] ${msg}${RESET_STYLE}" >&2 ;;
        question)
            [[ ${auto_confirm} -eq 1 ]] && return 0
            echo -ne "${COLOR_YELLOW}[?] ${STYLE_BOLD}${STYLE_UNDERLINE}${msg} [y/N]:${RESET_STYLE} "
            local ans
            read -rn 1 ans
            echo
            case "${ans}" in
                [yY] | [yY][eE][sS]) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *) echo -e "${COLOR_WHITE}[*] ${msg}${RESET_STYLE}" ;;
    esac
}

exit_failure() {
    msgbox error "Zwift install failed! 😭"
    exit 1
}

determine_install_location() {
    if [[ ${EUID} -eq 0 ]]; then
        root_bin="/usr/local/bin"
        root_share="/usr/local/share"
    else
        # user install
        root_bin="${XDG_BIN_HOME:-${HOME}/.local/bin}"
        root_share="${XDG_DATA_HOME:-${HOME}/.local/share}"
    fi

    msgbox info "Installing Zwift to:"
    msgbox info "  binaries → ${root_bin}"
    msgbox info "  data     → ${root_share}"
}

ask_user_confirmation() {
    if msgbox question "Are you sure you want to install Zwift?"; then
        msgbox ok "Proceeding with Zwift installation"
    else
        msgbox info "Aborted Zwift installation"
        msgbox warning "Zwift not installed! 😥"
        exit 2
    fi
}

create_directories() {
    create_directory() {
        local directory="${1:?}"

        msgbox info "  Creating directory ${directory}"

        if ! mkdir -p "${directory}"; then
            msgbox error "Could not create ${directory}, aborting"
            exit_failure
        fi
    }

    msgbox info "Creating directories"

    create_directory "${root_bin}"
    create_directory "${root_share}/icons/hicolor/scalable/apps"
    create_directory "${root_share}/applications"

    msgbox ok "Directories created"
}

download_zwift() {
    download_asset() {
        local destination="${1:?}"
        local url="${2:?}"

        msgbox info "  Downloading ${url}"

        if ! curl -fsSLo "${destination}" "${url}"; then
            msgbox error "Downloading ${url} failed, aborting"
            exit_failure
        fi
    }

    msgbox info "Downloading Zwift"

    download_asset "${root_bin}/zwift" "${ZWIFT_SCRIPT}"
    download_asset "${root_share}/icons/hicolor/scalable/apps/zwift.svg" "${ZWIFT_LOGO}"
    download_asset "${root_share}/applications/Zwift.desktop" "${ZWIFT_DESKTOP_ENTRY}"

    if ! chmod 755 "${root_bin}/zwift"; then
        msgbox error "Failed to set permissions for ${root_bin}/zwift, aborting"
        exit_failure
    fi

    msgbox ok "Zwift download complete"
}

check_in_path() {
    msgbox info "Checking if 'zwift' is in PATH"

    if case ":${PATH}:" in *":${root_bin}:"*) true ;; *) false ;; esac then
        msgbox info "  ${root_bin} is in your PATH"
        msgbox ok "Zwift can be launched using the 'zwift' command"
    else
        msgbox warning "${root_bin} is not in your PATH"
        msgbox warning "You may need to add it to your PATH for the 'zwift' command to work"
    fi
}

echo -e "${COLOR_YELLOW}[!] ${STYLE_BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${COLOR_YELLOW}[!] ${STYLE_UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

msgbox info "Preparing to install Zwift"

determine_install_location
ask_user_confirmation
create_directories
download_zwift
check_in_path

msgbox ok "Zwift install complete! 🥳"
