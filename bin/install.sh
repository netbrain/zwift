#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

print_usage() {
    echo "Install or uninstall netbrain/zwift"
    echo "Invoking this script with sudo will perform a system wide install"
    echo "Invoking this script without sudo will perform a user local install"
    echo ""
    echo "Usage:"
    echo "    ${0} [ -v | --script-version COMMIT_HASH ]"
    echo "    ${0//?/ } [ -y | --auto-confirm ]"
    echo "    ${0//?/ } [ -u | --uninstall ] "
    echo "    ${0//?/ } [ -h | --help ]"
    echo ""
    echo "Options:"
    echo "    --script-version COMMIT_HASH    Install a specific netbrain/zwift version instead of master"
    echo "    --auto-confirm                  Automatically confirm installation"
    echo "    --uninstall                     Uninstall netbrain/zwift"
    echo "    --help                          Print usage"
    exit 2
}

script_args=("${@}")
script_version="master"
auto_confirm=0
uninstall=0
if ! options="$(getopt -n install -o "v:yuh" -l "script-version:,auto-confirm,uninstall,help" -- "${@}")"; then
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
        -u | --uninstall)
            uninstall=1
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

readonly VERBOSITY="${VERBOSITY:-1}"
readonly SYSTEM_BIN_DIR="/usr/local/bin"
readonly SYSTEM_SHARE_DIR="/usr/local/share"
readonly USER_BIN_DIR="${XDG_BIN_HOME:-${HOME}/.local/bin}"
readonly USER_SHARE_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}"
readonly ZWIFT_SCRIPT="https://raw.githubusercontent.com/netbrain/zwift/${script_version}/src/zwift.sh"
readonly ZWIFT_LOGO="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.svg"
readonly ZWIFT_DESKTOP_ENTRY="https://raw.githubusercontent.com/netbrain/zwift/master/bin/Zwift.desktop"

if [[ -t 1 ]]; then
    readonly INTERACTIVE_TERMINAL=1
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly STYLE_BOLD="\033[1m"
    readonly STYLE_UNDERLINE="\033[4m"
    readonly RESET_STYLE="\033[0m"
else
    readonly INTERACTIVE_TERMINAL=0
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
    local type="${1:?}" # Type: info, ok, warning, error, question, debug
    local msg="${2:?}"  # Message: the message to display

    local timestamp=""
    [[ ${VERBOSITY} -ge 2 ]] && printf -v timestamp '%(%T)T|' -1

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        question)
            [[ ${auto_confirm} -eq 1 ]] && return 0
            echo -ne "${COLOR_YELLOW}[${timestamp}?] ${STYLE_BOLD}${STYLE_UNDERLINE}${msg} [y/N]:${RESET_STYLE} "
            local ans
            read -rn 1 ans
            echo
            case "${ans}" in
                [yY] | [yY][eE][sS]) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

invoked_as_root() {
    [[ ${EUID} -eq 0 ]]
}

uninstall_netbrain_zwift() {
    remove_file() {
        local file="${1:?}"

        msgbox info "  Removing ${file}"

        if ! rm -f -- "${file}"; then
            msgbox warning "  Failed to remove ${file}"
        fi
    }

    remove_user_install() {
        if [[ -f "${USER_BIN_DIR}/zwift" ]]; then
            if msgbox question "Found user install of netbrain/zwift, remove it?"; then
                msgbox ok "Removing user install"
                remove_file "${USER_BIN_DIR}/zwift"
                remove_file "${USER_SHARE_DIR}/icons/hicolor/scalable/apps/zwift.svg"
                remove_file "${USER_SHARE_DIR}/applications/Zwift.desktop"
            else
                msgbox ok "Keeping netbrain/zwift user install 👌"
            fi
        else
            msgbox info "No user install of netbrain/zwift found"
        fi
    }

    remove_system_install() {
        if [[ -f "${SYSTEM_BIN_DIR}/zwift" ]]; then
            if invoked_as_root; then
                if msgbox question "Found system install of netbrain/zwift, remove it?"; then
                    msgbox ok "Removing system install"
                    remove_file "${SYSTEM_BIN_DIR}/zwift"
                    remove_file "${SYSTEM_SHARE_DIR}/icons/hicolor/scalable/apps/zwift.svg"
                    remove_file "${SYSTEM_SHARE_DIR}/applications/Zwift.desktop"
                else
                    msgbox ok "Keeping netbrain/zwift system install 👌"
                fi
            else
                msgbox warning "Found system install of netbrain/zwift, but removing it requires root"
                msgbox warning "  To uninstall run 'sudo ${0} ${script_args[*]}'"
            fi
        else
            msgbox info "No system install of netbrain/zwift found"
        fi
    }

    msgbox info "Preparing to uninstall netbrain/zwift"
    msgbox info "The zwift container image, volume, and configuration will not be removed"
    remove_user_install
    remove_system_install
    msgbox ok "Uninstall complete!"
}

install_netbrain_zwift() {
    exit_failure() {
        msgbox error "Zwift install failed! 😭"
        exit 1
    }

    determine_install_location() {
        if invoked_as_root; then
            root_bin="${SYSTEM_BIN_DIR}"
            root_share="${SYSTEM_SHARE_DIR}"
        else
            root_bin="${USER_BIN_DIR}"
            root_share="${USER_SHARE_DIR}"
        fi

        msgbox info "Installing Zwift to:"
        msgbox info "  binaries → ${root_bin}"
        msgbox info "  data     → ${root_share}"
    }

    ask_user_confirmation() {
        if msgbox question "Are you sure you want to install Zwift?"; then
            msgbox ok "Proceeding with netbrain/zwift installation"
        else
            msgbox info "Aborted netbrain/zwift installation"
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

        msgbox info "Downloading netbrain/zwift"

        download_asset "${root_bin}/zwift" "${ZWIFT_SCRIPT}"
        download_asset "${root_share}/icons/hicolor/scalable/apps/zwift.svg" "${ZWIFT_LOGO}"
        download_asset "${root_share}/applications/Zwift.desktop" "${ZWIFT_DESKTOP_ENTRY}"

        if ! chmod 755 "${root_bin}/zwift"; then
            msgbox error "Failed to set permissions for ${root_bin}/zwift, aborting"
            exit_failure
        fi

        msgbox ok "Download complete"
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

    msgbox info "Preparing to install netbrain/zwift"
    determine_install_location
    ask_user_confirmation
    create_directories
    download_zwift
    check_in_path
    msgbox ok "Install complete! 🥳"
}

echo -e "${COLOR_YELLOW}[!] ${STYLE_BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${COLOR_YELLOW}[!] ${STYLE_UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

if [[ ${INTERACTIVE_TERMINAL} -eq 0 ]] && [[ ${auto_confirm} -eq 0 ]]; then
    msgbox warning "Detected non-interactive environment, enabling auto-confirm"
    auto_confirm=1
fi

if [[ ${uninstall} -eq 1 ]]; then
    uninstall_netbrain_zwift
else
    install_netbrain_zwift
fi
