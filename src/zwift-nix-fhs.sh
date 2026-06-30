#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly COLORED_OUTPUT="${COLORED_OUTPUT:-0}"
if [[ -t 1 ]] || [[ ${COLORED_OUTPUT} -eq 1 ]]; then
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLOR_WHITE=""
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_BLUE=""
    readonly COLOR_YELLOW=""
    readonly RESET_STYLE=""
fi

readonly VERBOSITY="${VERBOSITY:-1}"

msgbox() {
    local type="${1:?}" # Type: info, ok, warning, error, debug
    local msg="${2:?}"  # Message: the message to display

    local timestamp=""
    [[ ${VERBOSITY} -ge 2 ]] && printf -v timestamp '%(%T)T|' -1

    case ${type} in
        info) [[ ${VERBOSITY} -ge 1 ]] && echo -e "${COLOR_BLUE}[${timestamp}*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[${timestamp}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${timestamp}!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[${timestamp}✗] ${msg}${RESET_STYLE}" >&2 ;;
        debug) [[ ${VERBOSITY} -ge 3 ]] && echo -e "${COLOR_WHITE}[${timestamp}◉] ${msg}${RESET_STYLE}" ;;
        *) echo "msgbox - unknown type ${type}" >&2 && exit 1 ;;
    esac
}

readonly USER_CONFIG_DIR="${HOME}/.config/zwift"

load_config_file() {
    local config_file="${1:?}"
    if [[ -f ${config_file} ]]; then
        set -a
        # shellcheck source=/dev/null
        source "${config_file}"
        set +a
    fi
}
mkdir -p "${USER_CONFIG_DIR}"
load_config_file "${USER_CONFIG_DIR}/config"
load_config_file "${USER_CONFIG_DIR}/${USER}-config"

show_help() {
    echo "Zwift for Linux (Native)"
    echo ""
    echo "Usage: zwift [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --install    Install Zwift (first-time setup)"
    echo "  --help       Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  WINEPREFIX                 Wine prefix directory (default: ~/.wine-zwift)"
    echo "  ZWIFT_USERNAME             Zwift account email"
    echo "  ZWIFT_PASSWORD             Zwift account password"
    echo "  ZWIFT_OVERRIDE_RESOLUTION  Override resolution (e.g., 1920x1080)"
    echo "  ZWIFT_NO_GAMEMODE          Set to 1 to disable GameMode"
    echo "  WINE_EXPERIMENTAL_WAYLAND  Set to 1 for Wayland support"
    echo "  DEBUG                      Set to 1 for debug output"
}

case "${1:-}" in
    --install)
        export CONTAINER_TOOL="nix-fhs"
        exec zwift-update --install
        ;;
    --help | -h)
        show_help
        exit 0
        ;;
    "")
        _wineprefix="${WINEPREFIX:-${HOME}/.wine-zwift}"
        _zwift_home="${_wineprefix}/drive_c/Program Files (x86)/Zwift"
        export CONTAINER_TOOL="nix-fhs"
        export ZWIFT_NO_GAMEMODE=1
        if [[ ! -d ${_zwift_home} ]]; then
            msgbox info "Zwift is not installed. Running installation first..."
            zwift-update --install || exit 1
        else
            zwift-update || exit 1
        fi
        exec zwift-run
        ;;
    *)
        echo "Unknown option: ${1}"
        show_help
        exit 1
        ;;
esac
