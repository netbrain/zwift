#!/usr/bin/env bash
set -uo pipefail

# shellcheck source=./lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

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
        exec zwift-install
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    "")
        _wineprefix="${WINEPREFIX:-$HOME/.wine-zwift}"
        _zwift_home="${_wineprefix}/drive_c/Program Files (x86)/Zwift"
        if [[ ! -d "${_zwift_home}" ]]; then
            msgbox info "Zwift is not installed. Running installation first..."
            zwift-install || exit 1
        fi
        exec zwift-run
        ;;
    *)
        echo "Unknown option: ${1}"
        show_help
        exit 1
        ;;
esac
