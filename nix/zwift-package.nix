{
  pkgs,
  zwift-fhs,
}:
let
  # Script to authenticate with Zwift OAuth
  zwift-auth-script = pkgs.writeShellScript "zwift-auth" ''
    set -euo pipefail

    readonly DEBUG="''${DEBUG:-0}"
    if [[ ''${DEBUG} -eq 1 ]]; then set -x; fi

    readonly ZWIFT_USERNAME="''${ZWIFT_USERNAME:?ZWIFT_USERNAME is required}"
    readonly ZWIFT_PASSWORD="''${ZWIFT_PASSWORD:?ZWIFT_PASSWORD is required}"

    readonly LAUNCHER_CLIENT_ID="Game_Launcher"
    readonly LAUNCHER_HOME="https://launcher.zwift.com/launcher"
    readonly ZWIFT_REALM_URL="https://secure.zwift.com/auth/realms/zwift"
    readonly COOKIE="$(mktemp)"
    trap 'rm -f "''${COOKIE}"' EXIT

    curl -sS "''${LAUNCHER_HOME}" --cookie-jar "''${COOKIE}"
    request_state="$(grep -oP "OAuth_Token_Request_State\s+\K.*$" "''${COOKIE}")"

    authenticate_url="$(curl -sSL --get --cookie "''${COOKIE}" --cookie-jar "''${COOKIE}" \
        --data-urlencode "response_type=code" \
        --data-urlencode "client_id=''${LAUNCHER_CLIENT_ID}" \
        --data-urlencode "redirect_uri=''${LAUNCHER_HOME}" \
        --data-urlencode "login=true" \
        --data-urlencode "scope=openid" \
        --data-urlencode "state=''${request_state}" \
        "''${ZWIFT_REALM_URL}/protocol/openid-connect/auth" \
        | grep -oP '<form id="form" class="zwift-form" action="\K(.+?)(?=" method="post">)' \
        | sed -e 's/\&amp;/\&/g')"

    access_code="$(curl -sS --cookie "''${COOKIE}" --cookie-jar "''${COOKIE}" \
        --data-urlencode "username=''${ZWIFT_USERNAME}" \
        --data-urlencode "password=''${ZWIFT_PASSWORD}" \
        --write-out "%{redirect_url}" \
        "''${authenticate_url}" \
        | grep -oP "code=\K.+$")"

    auth_token_json="$(curl -sS --cookie "''${COOKIE}" --cookie-jar "''${COOKIE}" \
        --data-urlencode "client_id=''${LAUNCHER_CLIENT_ID}" \
        --data-urlencode "redirect_uri=''${LAUNCHER_HOME}" \
        --data-urlencode "code=''${access_code}" \
        --data-urlencode "grant_type=authorization_code" \
        --data-urlencode "scope=openid" \
        "''${ZWIFT_REALM_URL}/protocol/openid-connect/token")"

    echo "''${auth_token_json}"
  '';

  # Script to install Zwift
  zwift-install-script = pkgs.writeShellScript "zwift-install" ''
    set -uo pipefail

    readonly DEBUG="''${DEBUG:-0}"
    if [[ ''${DEBUG} -eq 1 ]]; then set -x; fi

    # Color output
    if [[ -t 1 ]]; then
        readonly COLOR_RED="\033[0;31m"
        readonly COLOR_GREEN="\033[0;32m"
        readonly COLOR_BLUE="\033[0;34m"
        readonly COLOR_YELLOW="\033[0;33m"
        readonly RESET_STYLE="\033[0m"
    else
        readonly COLOR_RED=""
        readonly COLOR_GREEN=""
        readonly COLOR_BLUE=""
        readonly COLOR_YELLOW=""
        readonly RESET_STYLE=""
    fi

    msgbox() {
        local type="''${1:?}"
        local msg="''${2:?}"
        case ''${type} in
            info) echo -e "''${COLOR_BLUE}[*] ''${msg}''${RESET_STYLE}" ;;
            ok) echo -e "''${COLOR_GREEN}[OK] ''${msg}''${RESET_STYLE}" ;;
            warning) echo -e "''${COLOR_YELLOW}[!] ''${msg}''${RESET_STYLE}" ;;
            error) echo -e "''${COLOR_RED}[X] ''${msg}''${RESET_STYLE}" >&2 ;;
        esac
    }

    readonly WINEPREFIX="''${WINEPREFIX:-$HOME/.wine-zwift}"
    readonly ZWIFT_HOME="''${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"

    msgbox info "Installing Zwift to ''${WINEPREFIX}"

    # Set up Wine environment
    export WINEARCH=win64
    export WINEPREFIX
    export WINEDEBUG="''${WINEDEBUG:--all}"

    # Find the actual wine binary (not the wrapper script) for winetricks detection
    # NixOS wraps wine in a shell script, but winetricks needs the ELF binary for arch detection
    wine_wrapper="$(command -v wine)"
    if [[ -f "''${wine_wrapper}" ]] && head -1 "''${wine_wrapper}" | grep -q "^#!"; then
        # It's a wrapper script, find the actual binary
        wine_bindir="$(dirname "''${wine_wrapper}")"
        if [[ -f "''${wine_bindir}/.wine" ]]; then
            # The actual binary is .wine in the same directory
            export WINELOADER="''${wine_bindir}/.wine"
        fi
    fi

    # Clean up any existing broken prefix
    if [[ -d "''${WINEPREFIX}" ]] && [[ ! -f "''${WINEPREFIX}/system.reg" ]]; then
        msgbox warning "Removing incomplete Wine prefix..."
        rm -rf "''${WINEPREFIX}"
    fi

    # Initialize Wine prefix
    msgbox info "Initializing Wine prefix..."

    # Prevent Wine from trying to install mono/gecko (we'll use winetricks for .NET)
    # Use inline form (not export) so this only applies to wineboot, not later commands.
    # ZwiftLauncher.exe is an IL-only .NET binary that needs mscoree.dll — exporting this
    # override would prevent it from loading.
    WINEDLLOVERRIDES="mscoree,mshtml=" wineboot -u || {
        msgbox error "Failed to initialize Wine prefix"
        exit 1
    }

    # Wait for wineserver to finish
    msgbox info "Waiting for Wine to settle..."
    wineserver -w
    sleep 2

    # Verify Wine is working
    msgbox info "Verifying Wine installation..."
    if ! wine cmd.exe /c "echo Wine is working" > /dev/null 2>&1; then
        msgbox error "Wine is not responding correctly"
        exit 1
    fi
    wineserver -w
    msgbox ok "Wine prefix initialized"

    # Install prerequisites using winetricks (matching container approach)
    # dotnet48: required by Zwift
    # d3dcompiler_47: required for Vulkan shaders
    # Note: dotnet20 skipped - it's only to prevent a dialog with CloseLauncher.exe
    # and causes issues with winetricks on NixOS
    msgbox info "Installing prerequisites using winetricks..."
    export W_OPT_UNATTENDED=1
    export W_ARCH=win64

    winetricks -q dotnet48 d3dcompiler_47 || {
        msgbox error "Failed to install .NET prerequisites"
        exit 1
    }
    wineserver -w
    msgbox ok "Prerequisites installed"

    # Download and install WebView2
    # Note: WebView2 spawns MicrosoftEdgeUpdate background processes that keep wineserver alive.
    # We use timeout and kill those processes to prevent hanging.
    msgbox info "Downloading and installing WebView2..."
    webview_installer="$(mktemp --suffix=.exe)"

    wget -O "''${webview_installer}" https://go.microsoft.com/fwlink/p/?LinkId=2124703 || {
        msgbox error "Failed to download WebView2 installer"
        rm -f "''${webview_installer}"
        exit 1
    }

    # Run WebView2 installer with timeout (it spawns background processes)
    timeout 120 wine "''${webview_installer}" /silent /install || {
        msgbox warning "WebView2 installation timed out or returned non-zero, continuing anyway..."
    }

    # Kill Edge background processes that keep wineserver alive
    pkill -f MicrosoftEdgeUpdate 2>/dev/null || true
    pkill -f EdgeUpdate 2>/dev/null || true
    sleep 2

    # Force kill wineserver to clean up
    wineserver -k 2>/dev/null || true
    sleep 1

    rm -f "''${webview_installer}"
    msgbox ok "WebView2 installed"

    # Enable Wayland support in Wine registry
    msgbox info "Enabling Wayland support in Wine..."
    wine reg.exe add 'HKCU\Software\Wine\Drivers' /v Graphics /d x11,wayland /f || {
        msgbox warning "Failed to set Wayland registry entry"
    }
    wineserver -w

    # Download and install Zwift
    msgbox info "Downloading Zwift installer..."
    zwift_installer="$(mktemp --suffix=.exe)"

    wget -O "''${zwift_installer}" https://cdn.zwift.com/app/ZwiftSetup.exe || {
        msgbox error "Failed to download Zwift installer"
        rm -f "''${zwift_installer}"
        exit 1
    }

    msgbox info "Installing Zwift..."
    wine "''${zwift_installer}" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCANCEL || {
        msgbox error "Zwift installation failed"
        rm -f "''${zwift_installer}"
        exit 1
    }
    wineserver -w

    rm -f "''${zwift_installer}"
    msgbox ok "Zwift launcher installed"

    # Now run the launcher to download the actual game files
    msgbox info "Downloading Zwift game files (this may take a while)..."

    # Change to Zwift directory
    cd "''${ZWIFT_HOME}" || {
        msgbox error "Cannot access Zwift directory"
        exit 1
    }

    # Get latest version from CDN
    zwift_latest_version="$(wget --no-cache --quiet -O - http://cdn.zwift.com/gameassets/Zwift_Updates_Root/Zwift_ver_cur.xml \
        | grep -oP 'sversion="\K.*?(?=")' | cut -f 1 -d ' ')" || {
        msgbox error "Failed to get latest Zwift version"
        exit 1
    }
    msgbox info "Latest Zwift version: ''${zwift_latest_version}"

    # Start launcher in silent mode to download game files
    msgbox info "Starting ZwiftLauncher.exe from $(pwd)..."
    ls -la ZwiftLauncher.exe || msgbox warning "ZwiftLauncher.exe not found in current directory!"

    # Run directly in background with error-level wine debug output so we can diagnose crashes.
    # (The FHS profile sets WINEDEBUG=-all which silences everything; override it here.)
    launcher_log="$(mktemp --suffix=.zwift-launcher.log)"
    WINEDEBUG="+err" wine ZwiftLauncher.exe SilentLaunch > "''${launcher_log}" 2>&1 &
    wine_pid=$!
    sleep 5

    # Check if launcher started - try multiple process name patterns
    msgbox info "Checking for running processes..."
    pgrep -la -i zwift || true

    if ! pgrep -f ZwiftLauncher.exe > /dev/null 2>&1; then
        msgbox warning "Launcher process not detected after 5 seconds"
        if [[ -s "''${launcher_log}" ]]; then
            msgbox info "Wine error output (last 30 lines):"
            tail -30 "''${launcher_log}" >&2
        fi
        rm -f "''${launcher_log}"
        msgbox error "ZwiftLauncher.exe failed to start - check wine errors above"
        exit 1
    fi

    # Wait for download to complete by checking version file
    get_current_version() {
        local version_filename="Zwift_ver_cur.xml"
        if [[ -f "''${ZWIFT_HOME}/Zwift_ver_cur_filename.txt" ]]; then
            version_filename="$(tr '\0' '\n' < "''${ZWIFT_HOME}/Zwift_ver_cur_filename.txt")"
        fi
        grep -oP 'sversion="\K.*?(?=\s)' "''${ZWIFT_HOME}/''${version_filename}" 2>/dev/null | cut -f 1 -d ' ' || echo "0.0.0"
    }

    counter=1
    zwift_current_version="$(get_current_version)"
    while [[ "''${zwift_current_version}" != "''${zwift_latest_version}" ]] && pgrep -f ZwiftLauncher.exe > /dev/null 2>&1; do
        msgbox info "Downloading Zwift... (''${counter}) - current: ''${zwift_current_version}, target: ''${zwift_latest_version}"
        sleep 5
        zwift_current_version="$(get_current_version)"
        ((counter++))
    done
    rm -f "''${launcher_log}"

    # Check if download completed successfully
    if [[ "''${zwift_current_version}" != "''${zwift_latest_version}" ]]; then
        msgbox error "Launcher exited before download completed"
        exit 1
    fi

    msgbox ok "Zwift ''${zwift_latest_version} downloaded successfully!"

    # Wait a bit for things to settle
    sleep 5

    # Kill the launcher
    pkill -f ZwiftLauncher.exe 2>/dev/null || true
    wineserver -k 2>/dev/null || true
    sleep 2

    # Cleanup
    msgbox info "Cleaning up installation artifacts..."
    rm -f "''${ZWIFT_HOME}/ZwiftSetup.exe" 2>/dev/null || true
    rm -f "''${ZWIFT_HOME}/webview2-setup.exe" 2>/dev/null || true

    msgbox ok "Installation complete!"
    msgbox info "You can now run Zwift with: zwift"
  '';

  # Script to run Zwift
  zwift-run-script = pkgs.writeShellScript "zwift-run" ''
    set -uo pipefail

    readonly DEBUG="''${DEBUG:-0}"
    if [[ ''${DEBUG} -eq 1 ]]; then set -x; fi

    # Color output
    if [[ -t 1 ]]; then
        readonly COLOR_RED="\033[0;31m"
        readonly COLOR_GREEN="\033[0;32m"
        readonly COLOR_BLUE="\033[0;34m"
        readonly COLOR_YELLOW="\033[0;33m"
        readonly RESET_STYLE="\033[0m"
    else
        readonly COLOR_RED=""
        readonly COLOR_GREEN=""
        readonly COLOR_BLUE=""
        readonly COLOR_YELLOW=""
        readonly RESET_STYLE=""
    fi

    msgbox() {
        local type="''${1:?}"
        local msg="''${2:?}"
        case ''${type} in
            info) echo -e "''${COLOR_BLUE}[*] ''${msg}''${RESET_STYLE}" ;;
            ok) echo -e "''${COLOR_GREEN}[OK] ''${msg}''${RESET_STYLE}" ;;
            warning) echo -e "''${COLOR_YELLOW}[!] ''${msg}''${RESET_STYLE}" ;;
            error) echo -e "''${COLOR_RED}[X] ''${msg}''${RESET_STYLE}" >&2 ;;
        esac
    }

    readonly WINEPREFIX="''${WINEPREFIX:-$HOME/.wine-zwift}"
    readonly ZWIFT_HOME="''${WINEPREFIX}/drive_c/Program Files (x86)/Zwift"
    readonly WINE_USER_HOME="''${WINEPREFIX}/drive_c/users/''${USER}"
    readonly ZWIFT_DOCS="''${WINE_USER_HOME}/AppData/Local/Zwift"
    readonly ZWIFT_PREFS="''${ZWIFT_DOCS}/prefs.xml"

    readonly ZWIFT_USERNAME="''${ZWIFT_USERNAME:-}"
    readonly ZWIFT_PASSWORD="''${ZWIFT_PASSWORD:-}"
    readonly ZWIFT_OVERRIDE_RESOLUTION="''${ZWIFT_OVERRIDE_RESOLUTION:-}"
    readonly ZWIFT_NO_GAMEMODE="''${ZWIFT_NO_GAMEMODE:-0}"
    readonly WINE_EXPERIMENTAL_WAYLAND="''${WINE_EXPERIMENTAL_WAYLAND:-0}"

    export WINEPREFIX
    export WINEARCH=win64

    # Check if Zwift is installed
    if [[ ! -d "''${ZWIFT_HOME}" ]]; then
        msgbox error "Zwift is not installed. Run 'zwift --install' first."
        exit 1
    fi

    cd "''${ZWIFT_HOME}" || {
        msgbox error "Cannot access Zwift directory: ''${ZWIFT_HOME}"
        exit 1
    }

    # Apply resolution override if specified
    if [[ -n "''${ZWIFT_OVERRIDE_RESOLUTION}" ]]; then
        if [[ -f "''${ZWIFT_PREFS}" ]]; then
            msgbox info "Setting Zwift resolution to ''${ZWIFT_OVERRIDE_RESOLUTION}"
            updated_prefs="$(awk -v resolution="''${ZWIFT_OVERRIDE_RESOLUTION}" '{
                gsub(/<USER_RESOLUTION_PREF>.*<\/USER_RESOLUTION_PREF>/,
                     "<USER_RESOLUTION_PREF>" resolution "</USER_RESOLUTION_PREF>")
            } 1' "''${ZWIFT_PREFS}")"
            echo "''${updated_prefs}" > "''${ZWIFT_PREFS}"
        else
            msgbox warning "Preferences file does not exist yet. Resolution cannot be set."
        fi
    fi

    # Handle Wayland experimental mode
    if [[ "''${WINE_EXPERIMENTAL_WAYLAND}" -eq 1 ]]; then
        msgbox info "Using experimental Wayland mode"
        unset DISPLAY
    fi

    # Cleanup function
    cleanup_invoked=0
    cleanup() {
        if [[ ''${cleanup_invoked} -ne 1 ]]; then
            msgbox info "Cleaning up..."
            pkill ZwiftLauncher 2>/dev/null || true
            pkill ZwiftWindowsCra 2>/dev/null || true
            pkill -f MicrosoftEdgeUpdate 2>/dev/null || true
            cleanup_invoked=1
        fi
    }
    trap cleanup EXIT

    # Start Zwift Launcher
    msgbox info "Starting Zwift launcher..."

    if ! wine start ZwiftLauncher.exe SilentLaunch; then
        msgbox error "Failed to start Zwift launcher"
        exit 1
    fi

    # Get launcher PID
    sleep 2  # Give launcher time to start
    if ! launcher_pid_hex="$(winedbg --command "info proc" 2>/dev/null | grep -P "ZwiftLauncher.exe" | grep -oP "^\s*\K[0-9a-fA-F]+(?=\s)")"; then
        msgbox error "Unable to get launcher process ID. Did it crash?"
        exit 1
    fi

    launcher_pid="$((16#''${launcher_pid_hex}))"
    msgbox ok "Zwift launcher started (PID: ''${launcher_pid})"

    # Prepare wine command for ZwiftApp
    # runfromprocess-rs.exe is at /usr/bin/ in the FHS, Wine accesses it via Z: drive
    # ZwiftApp.exe needs full Windows path
    declare -a wine_cmd
    wine_cmd=(wine start /exec "Z:\\usr\\bin\\runfromprocess-rs.exe" "''${launcher_pid}" ZwiftApp.exe)

    # Authenticate if credentials provided
    if [[ -n "''${ZWIFT_USERNAME}" ]] && [[ -n "''${ZWIFT_PASSWORD}" ]]; then
        msgbox info "Authenticating with Zwift..."
        if token="$(zwift-auth 2>/dev/null)"; then
            wine_cmd+=(--token="''${token}")
            msgbox ok "Authentication successful"
        else
            msgbox warning "Authentication failed, manual login will be required"
        fi
    fi

    # Start ZwiftApp
    msgbox info "Starting ZwiftApp..."
    if ! "''${wine_cmd[@]}"; then
        msgbox error "Failed to start ZwiftApp"
        exit 1
    fi

    # Wait for Zwift to start
    for i in $(seq 3 -1 1); do
        msgbox info "Waiting for Zwift to start... (''${i})"
        sleep 1
    done

    if ! pgrep -f ZwiftApp.exe > /dev/null 2>&1; then
        msgbox error "ZwiftApp has not started!"
        exit 1
    fi

    msgbox ok "Zwift started successfully!"

    # Cleanup launcher processes
    cleanup

    # Run wineserver (optionally with gamemode)
    declare -a wineserver_cmd
    wineserver_cmd=(wineserver -w)

    if [[ "''${ZWIFT_NO_GAMEMODE}" -ne 1 ]] && command -v gamemoderun &>/dev/null; then
        msgbox info "Running with GameMode enabled"
        wineserver_cmd=(gamemoderun "''${wineserver_cmd[@]}")
    fi

    msgbox info "Waiting for Zwift to close..."
    "''${wineserver_cmd[@]}" || true

    msgbox ok "Zwift closed, exiting"
  '';

  # Main wrapper script
  zwift-wrapper = pkgs.writeShellScript "zwift-wrapper" ''
    set -uo pipefail

    readonly DEBUG="''${DEBUG:-0}"
    if [[ ''${DEBUG} -eq 1 ]]; then set -x; fi

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
        echo "  WINEPREFIX              Wine prefix directory (default: ~/.wine-zwift)"
        echo "  ZWIFT_USERNAME          Zwift account email"
        echo "  ZWIFT_PASSWORD          Zwift account password"
        echo "  ZWIFT_OVERRIDE_RESOLUTION  Override resolution (e.g., 1920x1080)"
        echo "  ZWIFT_NO_GAMEMODE       Set to 1 to disable GameMode"
        echo "  WINE_EXPERIMENTAL_WAYLAND  Set to 1 for Wayland support"
        echo "  DEBUG                   Set to 1 for debug output"
    }

    case "''${1:-}" in
        --install)
            exec ${zwift-install-script}
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        "")
            _wineprefix="''${WINEPREFIX:-$HOME/.wine-zwift}"
            _zwift_home="''${_wineprefix}/drive_c/Program Files (x86)/Zwift"
            if [[ ! -d "''${_zwift_home}" ]]; then
                msgbox info "Zwift is not installed. Running installation first..."
                ${zwift-install-script} || exit 1
            fi
            exec ${zwift-run-script}
            ;;
        *)
            echo "Unknown option: ''${1}"
            show_help
            exit 1
            ;;
    esac
  '';
in
pkgs.stdenv.mkDerivation {
  pname = "zwift-scripts";
  version = "0-unstable";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ${zwift-auth-script} $out/bin/zwift-auth
    cp ${zwift-install-script} $out/bin/zwift-install
    cp ${zwift-run-script} $out/bin/zwift-run
    cp ${zwift-wrapper} $out/bin/zwift-wrapper

    runHook postInstall
  '';
}
