# shellcheck shell=bash
# Common setup sourced by all Zwift scripts.
# Source at the top of each script before any other declarations:
#
#   # shellcheck source=./lib.sh
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

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

# Optional CONTAINER_TOOL prefix in output: "[podman|*]" vs "[*]"
msgbox() {
    local type="${1:?}"
    local msg="${2:?}"
    local _prefix="${CONTAINER_TOOL:+${CONTAINER_TOOL}|}"
    case ${type} in
        info)    echo -e "${COLOR_BLUE}[${_prefix}*] ${msg}${RESET_STYLE}" ;;
        ok)      echo -e "${COLOR_GREEN}[${_prefix}✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[${_prefix}!] ${msg}${RESET_STYLE}" ;;
        error)   echo -e "${COLOR_RED}[${_prefix}✗] ${msg}${RESET_STYLE}" >&2 ;;
        *)       echo -e "${COLOR_WHITE}[${_prefix}*] ${msg}${RESET_STYLE}" ;;
    esac
}
