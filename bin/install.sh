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
        if ! rm -- "${file}" > /dev/null 2>&1; then
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
    local root_bin
    local root_share

    determine_install_location() {
        if invoked_as_root; then
            root_bin="${SYSTEM_BIN_DIR}"
            root_share="${SYSTEM_SHARE_DIR}"
        else
            root_bin="${USER_BIN_DIR}"
            root_share="${USER_SHARE_DIR}"
        fi

        msgbox info "Installing netbrain/zwift to:"
        msgbox info "  binaries → ${root_bin}"
        msgbox info "  data     → ${root_share}"
    }

    create_directories() {
        create_directory() {
            local directory="${1:?}"

            msgbox info "  Creating directory ${directory}"
            if ! mkdir -p "${directory}"; then
                msgbox error "Could not create ${directory}"
                return 1
            fi
        }

        msgbox info "Creating directories"
        create_directory "${root_bin}" || return 1
        create_directory "${root_share}/icons/hicolor/scalable/apps" || return 1
        create_directory "${root_share}/applications" || return 1
        msgbox ok "Directories created"
    }

    download_zwift() {
        local assets_map temporary_files
        declare -A assets_map
        declare -a temporary_files=()

        cleanup() {
            trap - RETURN
            msgbox debug "Removing temporary files"
            rm -f -- "${temporary_files[@]}" > /dev/null 2>&1 || true
        }
        trap cleanup RETURN

        download_asset() {
            local url="${1:?}"
            local destination="${2:?}"
            local mode="${3:-}"
            local tmp_file=""

            msgbox info "  Downloading ${url}"
            tmp_file="$(mktemp -q "${destination}.part-XXXXXXXXXX")" || return 1
            temporary_files+=("${tmp_file}")
            curl -fsSLo "${tmp_file}" "${url}" || return 1
            if [[ -n ${mode} ]]; then chmod "${mode}" "${tmp_file}" || return 1; fi
            assets_map["${destination}"]="${tmp_file}"
        }

        msgbox info "Downloading netbrain/zwift"

        # During an update, the zwift.sh script is running while being replaced with the new version.
        # The safe way to do this is by downloading the updated file to a temporary location in the same
        # directory as the target directory, and replacing the original file by renaming the new file to
        # the original name. This rename operation is atomic (if it happens on the same filesystem, this
        # is why we use the same directory for the temporary file), and atomic renames don't invalidate
        # existing file descriptors. The already running script keeps reading from the old file and
        # continues to execute just fine. By following this procedure we can safely update files that are
        # in use.

        # step 1: download to temporary file
        download_asset "${ZWIFT_SCRIPT}" "${root_bin}/zwift" 755 || return 1
        download_asset "${ZWIFT_LOGO}" "${root_share}/icons/hicolor/scalable/apps/zwift.svg" || return 1
        download_asset "${ZWIFT_DESKTOP_ENTRY}" "${root_share}/applications/Zwift.desktop" || return 1

        # step 2: replace old file by renaming temporary file
        for asset in "${!assets_map[@]}"; do
            msgbox debug "  Installing temporary file ${assets_map["${asset}"]}"
            mv -f "${assets_map["${asset}"]}" "${asset}" || return 1
        done

        msgbox ok "Download complete"
    }

    check_in_path() {
        msgbox info "Checking if 'zwift' is in PATH"
        if [[ ":${PATH}:" == *":${root_bin}:"* ]]; then
            msgbox info "  ${root_bin} is in your PATH"
            msgbox ok "netbrain/zwift can be launched using the 'zwift' command"
        else
            msgbox warning "${root_bin} is not in your PATH"
            msgbox warning "You may need to add it to your PATH for the 'zwift' command to work"
        fi
    }

    msgbox info "Preparing to install netbrain/zwift"
    determine_install_location
    if msgbox question "Are you sure you want to install netbrain/zwift?"; then
        msgbox ok "Proceeding with netbrain/zwift installation"
        if create_directories && download_zwift && check_in_path; then
            msgbox ok "Install complete! 🥳"
        else
            msgbox error "netbrain/zwift install failed! 😭"
            exit 1
        fi
    else
        msgbox info "Aborted netbrain/zwift installation"
        msgbox warning "netbrain/zwift not installed! 😥"
        exit 2
    fi
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
