#!/usr/bin/env bash
set -uo pipefail

readonly DEBUG="${DEBUG:-0}"
if [[ ${DEBUG} -eq 1 ]]; then set -x; fi

readonly USER_CONFIG_DIR="${HOME}/.config/zwift"
readonly WINE_USER_HOME="/home/user/.wine/drive_c/users/user"
readonly ZWIFT_HOME="/home/user/.wine/drive_c/Program Files (x86)/Zwift"
readonly ZWIFT_DOCS="${WINE_USER_HOME}/AppData/Local/Zwift"
readonly ZWIFT_DOCS_OLD="${WINE_USER_HOME}/Documents/Zwift" # TODO remove when no longer needed (301)

if [[ -t 1 ]]; then
    readonly COLORED_OUTPUT_SUPPORTED="1"
    readonly COLOR_WHITE="\033[0;37m"
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_YELLOW="\033[0;33m"
    readonly STYLE_BOLD="\033[1m"
    readonly STYLE_UNDERLINE="\033[4m"
    readonly RESET_STYLE="\033[0m"
else
    readonly COLORED_OUTPUT_SUPPORTED="0"
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
    local type="${1:?}"    # Type: info, ok, warning, error, question
    local msg="${2:?}"     # Message: the message to display
    local timeout="${3:-}" # Optional timeout: if explicitly set to 0, wait for user input to continue

    case ${type} in
        info) echo -e "${COLOR_BLUE}[*] ${msg}${RESET_STYLE}" ;;
        ok) echo -e "${COLOR_GREEN}[✓] ${msg}${RESET_STYLE}" ;;
        warning) echo -e "${COLOR_YELLOW}[!] ${msg}${RESET_STYLE}" ;;
        error) echo -e "${COLOR_RED}[✗] ${msg}${RESET_STYLE}" >&2 ;;
        question)
            local ans
            if [[ -n ${timeout} ]] && [[ ${timeout} -gt "0" ]]; then
                echo -ne "${COLOR_YELLOW}[?] ${STYLE_BOLD}${STYLE_UNDERLINE}${msg} (Default no in ${timeout} seconds.) [y/N]:${RESET_STYLE} "
                read -rt "${timeout}" -n 1 ans
                echo
            else
                echo -ne "${COLOR_YELLOW}[?] ${STYLE_BOLD}${STYLE_UNDERLINE}${msg} [y/N]:${RESET_STYLE} "
                read -rn 1 ans
                echo
            fi
            case "${ans}" in
                [yY] | [yY][eE][sS]) return 0 ;;
                *) return 1 ;;
            esac
            ;;
        *) echo -e "${COLOR_WHITE}[*] ${msg}${RESET_STYLE}" ;;
    esac

    if [[ -n ${timeout} ]]; then
        if [[ ${timeout} -gt 0 ]]; then
            sleep "${timeout}"
        else
            echo -ne "${COLOR_YELLOW}[*] ${STYLE_BOLD}${STYLE_UNDERLINE}Press any key to continue...${RESET_STYLE}"
            read -rsn1
            echo
        fi
    fi
}

is_array() {
    local variable_name="${1:?}"
    local array_regex="^declare -a"
    [[ "$(declare -p "${variable_name}")" =~ ${array_regex} ]]
}

command_exists() {
    local cmd="${1:?}"
    local cmd_path
    cmd_path="$(command -v "${cmd}" 2> /dev/null)" && [[ -x ${cmd_path} ]]
}

echo -e "${COLOR_YELLOW}[!] ${STYLE_BOLD}Easily Zwift on linux!${RESET_STYLE}"
echo -e "${COLOR_YELLOW}[!] ${STYLE_UNDERLINE}https://github.com/netbrain/zwift${RESET_STYLE}"

msgbox info "Preparing to launch Zwift"

##################################################################
##### Load user configuration files and initialize variables #####

# Check for zwift configuration, sourced here
load_config_file() {
    local config_file="${1:?}"
    msgbox info "Looking for config file ${config_file}"
    if [[ -f ${config_file} ]]; then
        # shellcheck source=/dev/null
        if source "${config_file}"; then
            msgbox ok "Loaded ${config_file}"
        else
            msgbox error "Failed to load ${config_file}"
        fi
    fi
}
mkdir -p "${USER_CONFIG_DIR}"
load_config_file "${USER_CONFIG_DIR}/config"
load_config_file "${USER_CONFIG_DIR}/${USER}-config"

# Initialize system environment variables
readonly DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}"
readonly DISPLAY="${DISPLAY:-}"
readonly WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}"
readonly XAUTHORITY="${XAUTHORITY:-}"
readonly XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}"
readonly XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-}"

# Initialize user configuration environment variables
readonly IMAGE="${IMAGE:-docker.io/netbrain/zwift}"
readonly VERSION="${VERSION:-latest}"
readonly LATEST_SCRIPT_VERSION="master"
readonly SCRIPT_VERSION="${SCRIPT_VERSION:-${LATEST_SCRIPT_VERSION}}"
readonly DONT_CHECK="${DONT_CHECK:-0}"
readonly DONT_PULL="${DONT_PULL:-0}"
readonly DONT_CLEAN="${DONT_CLEAN:-0}"
readonly DRYRUN="${DRYRUN:-0}"
readonly INTERACTIVE="${INTERACTIVE:-0}"
readonly CONTAINER_EXTRA_ARGS="${CONTAINER_EXTRA_ARGS:-}"
readonly ZWIFT_USERNAME="${ZWIFT_USERNAME:-}"
readonly ZWIFT_PASSWORD="${ZWIFT_PASSWORD:-}"
readonly ZWIFT_WORKOUT_DIR="${ZWIFT_WORKOUT_DIR:-}"
readonly ZWIFT_ACTIVITY_DIR="${ZWIFT_ACTIVITY_DIR:-}"
readonly ZWIFT_LOG_DIR="${ZWIFT_LOG_DIR:-}"
readonly ZWIFT_SCREENSHOTS_DIR="${ZWIFT_SCREENSHOTS_DIR:-}"
readonly ZWIFT_OVERRIDE_GRAPHICS="${ZWIFT_OVERRIDE_GRAPHICS:-0}"
readonly ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION:-}"
readonly ZWIFT_FG="${ZWIFT_FG:-0}"
readonly ZWIFT_NO_GAMEMODE="${ZWIFT_NO_GAMEMODE:-0}"
readonly WINE_EXPERIMENTAL_WAYLAND="${WINE_EXPERIMENTAL_WAYLAND:-0}"
readonly NETWORKING="${NETWORKING:-bridge}"
readonly ZWIFT_UID="${ZWIFT_UID:-${UID}}"
readonly ZWIFT_GID="${ZWIFT_GID:-$(id -g)}"
readonly VGA_DEVICE_FLAG="${VGA_DEVICE_FLAG:-}"
readonly PRIVILEGED_CONTAINER="${PRIVILEGED_CONTAINER:-0}"

# Initialize CONTAINER_TOOL: Use podman if available
msgbox info "Looking for container tool"
CONTAINER_TOOL="${CONTAINER_TOOL:-}"
if [[ -z ${CONTAINER_TOOL} ]]; then
    if command_exists podman; then
        CONTAINER_TOOL="podman"
    else
        CONTAINER_TOOL="docker"
    fi
fi
readonly CONTAINER_TOOL
if command_exists "${CONTAINER_TOOL}"; then
    msgbox ok "Found container tool: ${CONTAINER_TOOL}"
else
    msgbox error "Container tool ${CONTAINER_TOOL} not found"
    msgbox error "  To install podman, see: https://podman.io/docs/installation"
    msgbox error "  To install docker, see: https://docs.docker.com/get-started/get-docker/"
    exit 1
fi

##################################################################
##### Update zwift.sh script and pull latest container image #####

# Check for updated zwift.sh by comparing checksums

check_script_up_to_date() {
    local remote_sum this_sum

    if ! remote_sum="$(curl -fsSL "https://raw.githubusercontent.com/netbrain/zwift/${SCRIPT_VERSION}/src/zwift.sh" | sha256sum | awk '{print $1}')"; then
        msgbox warning "Failed to check latest script version, assuming update is required"
        return 1
    fi

    this_sum="$(sha256sum "${0}" | awk '{print $1}')"

    [[ ${remote_sum} == "${this_sum}" ]]
}

upgrade_script() {
    local install_script

    msgbox info "Downloading latest install script"
    if ! install_script="$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"; then
        msgbox error "Failed to download install script"
        return 1
    fi

    msgbox info "Running install script"
    if ! pkexec env PATH="${PATH}" bash -c "${install_script}" -- --script-version="${SCRIPT_VERSION}"; then
        msgbox error "Install script failed"
        return 1
    fi
}

if [[ ${SCRIPT_VERSION} != "${LATEST_SCRIPT_VERSION}" ]]; then
    msgbox warning "Using zwift.sh version ${SCRIPT_VERSION} instead of latest"
fi
if [[ ${DONT_CHECK} -ne 1 ]]; then
    msgbox info "Checking for updated zwift.sh"
    if check_script_up_to_date; then
        msgbox ok "You are running the latest zwift.sh 👏"
    elif msgbox question "You are not running the latest zwift.sh 😭, download?" 5; then
        if upgrade_script; then
            msgbox ok "Switching to new zwift.sh script"
            exec "${0}" "${@}"
        else
            msgbox error "Failed to upgrade script, continuing with old zwift.sh! 😔"
        fi
    else
        msgbox warning "Continuing with old zwift.sh"
    fi
else
    msgbox warning "DONT_CHECK: Not checking for new zwift.sh"
    msgbox warning "  Zwift may fail to launch if you are not using the latest zwift.sh script"
    # shellcheck disable=SC2016 # using a command as literal string on the next line
    msgbox warning '  To update manually, run: sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/netbrain/zwift/master/bin/install.sh)"'
    msgbox warning "  To use a specific version of the script, it is recommended to set SCRIPT_VERSION=... instead"
fi

# Check for updated container image
if [[ "${IMAGE}:${VERSION}" != "docker.io/netbrain/zwift:latest" ]]; then
    msgbox warning "Using image ${IMAGE}:${VERSION} instead of docker.io/netbrain/zwift:latest"
fi
if [[ ${DONT_PULL} -ne 1 ]]; then
    msgbox info "Checking for updated container image"
    if ${CONTAINER_TOOL} pull "${IMAGE}:${VERSION}"; then
        msgbox ok "Container image is up to date"
    else
        msgbox error "Failed to update container image"
    fi
else
    msgbox warning "DONT_PULL: Not checking for new container image"
    msgbox warning "  Zwift may fail to launch if you are not using the latest container image"
    msgbox warning "  To update manually, run: ${CONTAINER_TOOL} pull ${IMAGE}:${VERSION}"
    msgbox warning "  To use a specific version of the image, it is recommended to set VERSION=... instead"
fi

# Clean previous container images (if any)
if [[ ${DONT_CLEAN} -ne 1 ]] && [[ ${DONT_PULL} -ne 1 ]]; then
    declare -a old_images
    old_images=()
    if images_output="$(${CONTAINER_TOOL} images --filter "reference=${IMAGE#docker.io/}" --filter "before=${IMAGE#docker.io/}:${VERSION}" --format '{{.ID}}')"; then
        [[ -n ${images_output} ]] && readarray -t old_images <<< "${images_output}"
    else
        msgbox warning "Failed to retrieve list of container images"
    fi
    if [[ ${#old_images[@]} -gt 0 ]]; then
        msgbox info "Cleaning up previous container images"
        if ${CONTAINER_TOOL} image rm "${old_images[@]}"; then
            msgbox ok "Previous container images have been deleted"
        else
            msgbox warning "Failed to clean up previous container images"
        fi
    fi
fi

###############################
##### Basic configuration #####

# Create temporary file for container environment variables, automatically removed upon exit
if container_env_file="$(mktemp -q /tmp/zwift-container.env.XXXXXXXXXX)"; then
    trap 'rm -f -- "${container_env_file}" && msgbox info "Removed temporary file ${container_env_file}"' EXIT
    msgbox info "Created temporary file for environment variables:"
    msgbox info "  ${container_env_file}"
    msgbox info "  This file will be removed automatically when the script exits"
else
    msgbox error "Failed to create temporary file for environment variables"
    exit 1
fi

# Create array for container environment variables
declare -a container_env_vars
container_env_vars=()

# Create array for container arguments
declare -a container_args
container_args=()

# Create array for entrypoint arguments
declare -a entrypoint_args
entrypoint_args=()

if [[ ${CONTAINER_TOOL} == "podman" ]]; then
    # Podman has to use container id 1000
    # Local user is mapped to the container id
    local_uid="${ZWIFT_UID}"
    container_uid=1000
    container_gid=1000
    container_args+=(--userns "keep-id:uid=${container_uid},gid=${container_gid}")
else
    # Docker will run as the id's provided.
    local_uid="${UID}"
    container_uid="${ZWIFT_UID}"
    container_gid="${ZWIFT_GID}"
fi

# Define base container environment variables
container_env_vars+=(
    DEBUG="${DEBUG}"
    DISPLAY="${DISPLAY}"
    ZWIFT_UID="${container_uid}"
    ZWIFT_GID="${container_gid}"
    PULSE_SERVER="/run/user/${container_uid}/pulse/native"
    CONTAINER_TOOL="${CONTAINER_TOOL}"
)

# Define base container parameters
container_args+=(
    --rm
    --network "${NETWORKING}"
    --name "zwift-${USER}"
    --hostname "${HOSTNAME}"
    --env-file "${container_env_file}"
    -v "zwift-${USER}:${ZWIFT_DOCS}"
    -v "zwift-${USER}:${ZWIFT_DOCS_OLD}" # TODO remove when no longer needed (301)
    -v "/run/user/${local_uid}/pulse:/run/user/${container_uid}/pulse"
)

###################################################
##### Forward arguments passed to this script #####

# Arguments before -- are forwarded to the container tool
# Arguments after -- are forwarded to the container entrypoint

dashes_found=0
for arg; do
    if [[ ${dashes_found} -eq 1 ]]; then
        entrypoint_args+=("${arg}")
    elif [[ ${arg} == "--" ]]; then
        dashes_found=1
    else
        container_args+=("${arg}")
    fi
done

##############################################
##### User defined environment variables #####

# If a workout directory is specified then map to that directory.
if [[ -n ${ZWIFT_WORKOUT_DIR} ]]; then
    container_args+=(-v "${ZWIFT_WORKOUT_DIR}:${ZWIFT_DOCS}/Workouts")
fi

# If an activity directory is specified then map to that directory.
if [[ -n ${ZWIFT_ACTIVITY_DIR} ]]; then
    container_args+=(-v "${ZWIFT_ACTIVITY_DIR}:${ZWIFT_DOCS}/Activities")
fi

# If a log directory is specified then map to that directory.
if [[ -n ${ZWIFT_LOG_DIR} ]]; then
    container_args+=(-v "${ZWIFT_LOG_DIR}:${ZWIFT_DOCS}/Logs")
fi

# If a screenshots directory is specified then map to that directory.
if [[ -n ${ZWIFT_SCREENSHOTS_DIR} ]]; then
    container_args+=(-v "${ZWIFT_SCREENSHOTS_DIR}:${WINE_USER_HOME}/Pictures/Zwift")
fi

# If overriding zwift graphics then map custom config to the graphics profiles.
if [[ ${ZWIFT_OVERRIDE_GRAPHICS} -eq 1 ]]; then
    zwift_graphics_config="${USER_CONFIG_DIR}/graphics.txt"

    # Check for $USER specific graphics config file.
    zwift_user_graphics_config="${USER_CONFIG_DIR}/${USER}-graphics.txt"
    if [[ -f ${zwift_user_graphics_config} ]]; then
        zwift_graphics_config="${zwift_user_graphics_config}"
    # Create graphics.txt file if it does not exist.
    elif [[ ! -f ${zwift_graphics_config} ]]; then
        echo -e "res 1920x1080(0x)\nsres 2048x2048\nset gSSAO=1\nset gFXAA=1\nset gSunRays=1\nset gHeadlight=1\nset gFoliagePercent=1.0\nset gSimpleReflections=0\nset gLODBias=0\nset gShowFPS=0" > "${zwift_graphics_config}"
        msgbox warning "Created ${zwift_graphics_config} with default values, edit this file to tweak the zwift graphics settings" 0
    fi

    # Override all zwift graphics profiles with the custom config file.
    msgbox ok "Overriding zwift graphics profiles with ${zwift_graphics_config}"
    container_args+=(
        -v "${zwift_graphics_config}:${ZWIFT_HOME}/data/configs/basic.txt"
        -v "${zwift_graphics_config}:${ZWIFT_HOME}/data/configs/medium.txt"
        -v "${zwift_graphics_config}:${ZWIFT_HOME}/data/configs/high.txt"
        -v "${zwift_graphics_config}:${ZWIFT_HOME}/data/configs/ultra.txt"
    )
fi

# If custom resolution is requested, pass environment variable to container
if [[ -n ${ZWIFT_OVERRIDE_RESOLUTION} ]]; then
    container_env_vars+=(ZWIFT_OVERRIDE_RESOLUTION="${ZWIFT_OVERRIDE_RESOLUTION}")
fi

# Pass environment variable to container if gamemode should be disabled
if [[ ${ZWIFT_NO_GAMEMODE} -eq 1 ]]; then
    container_env_vars+=(ZWIFT_NO_GAMEMODE="1")
fi

# Interactive mode and run in foreground/background
if [[ ${INTERACTIVE} -eq 1 ]]; then
    container_env_vars+=(COLORED_OUTPUT="${COLORED_OUTPUT_SUPPORTED}")
    container_args+=(-it --entrypoint bash)
elif [[ ${ZWIFT_FG} -eq 1 ]]; then
    container_env_vars+=(COLORED_OUTPUT="${COLORED_OUTPUT_SUPPORTED}")
    container_args+=(-it)
else
    container_env_vars+=(COLORED_OUTPUT="0")
    container_args+=(-d)
fi

# Setup container security flags
if [[ ${PRIVILEGED_CONTAINER} -eq 1 ]]; then
    container_args+=(--privileged --security-opt label=disable) # privileged container, less secure
else
    container_args+=(--security-opt label=type:container_runtime_t) # more secure
fi

# Append extra arguments provided by user
if is_array "CONTAINER_EXTRA_ARGS"; then
    container_args+=("${CONTAINER_EXTRA_ARGS[@]}")
elif [[ -n ${CONTAINER_EXTRA_ARGS} ]]; then
    msgbox warning "CONTAINER_EXTRA_ARGS is defined as a string, it is recommended to use an array"
    read -ra extra_args <<< "${CONTAINER_EXTRA_ARGS}" && container_args+=("${extra_args[@]}")
fi

#####################################
##### Authentication parameters #####

# Lookup zwift password and create secret to pass to the container
# Note: can't use the docker secret store since it requires swarm
if [[ -n ${ZWIFT_USERNAME} ]]; then
    msgbox info "Looking up Zwift password for ${ZWIFT_USERNAME}"
    password_secret_name="zwift-password-${ZWIFT_USERNAME}"
    plaintext_password="${ZWIFT_PASSWORD}"

    # ZWIFT_PASSWORD not set, check if secret already exists or if password is stored in secret-tool
    has_password_secret=0
    if [[ -z ${plaintext_password} ]]; then
        if [[ ${CONTAINER_TOOL} == "podman" ]] && ${CONTAINER_TOOL} secret exists "${password_secret_name}"; then
            msgbox ok "Password for ${ZWIFT_USERNAME} found in ${CONTAINER_TOOL} secret store"
            has_password_secret=1
        elif command_exists secret-tool; then
            msgbox info "Looking for password in secret-tool (application zwift username ${ZWIFT_USERNAME})"
            plaintext_password=$(secret-tool lookup application zwift username "${ZWIFT_USERNAME}")
        fi
    fi

    # ZWIFT_PASSWORD set or found in secret-tool, create/update secret
    has_plaintext_password=0
    if [[ -n ${plaintext_password} ]]; then
        msgbox ok "Password found for ${ZWIFT_USERNAME}"
        has_plaintext_password=1
        if [[ ${CONTAINER_TOOL} == "podman" ]] && printf '%s' "${plaintext_password}" | ${CONTAINER_TOOL} secret create --replace=true "${password_secret_name}" - > /dev/null; then
            msgbox ok "Stored password in ${CONTAINER_TOOL} secret store"
            has_password_secret=1
        else
            msgbox info "Could not create secret for password, using environment variable instead"
        fi
    fi

    # prefer passing secret, otherwise pass plaintext_password as plain text
    container_env_vars+=(ZWIFT_USERNAME="${ZWIFT_USERNAME}")
    if [[ ${has_password_secret} -eq 1 ]]; then
        container_args+=(--secret "${password_secret_name},type=env,target=ZWIFT_PASSWORD")
    elif [[ ${has_plaintext_password} -eq 1 ]]; then
        container_env_vars+=(ZWIFT_PASSWORD="${plaintext_password}")
    else
        msgbox info "No password found for ${ZWIFT_USERNAME}"
        msgbox info "  To avoid manually entering your Zwift password each time, you can either:"
        msgbox info "  1. Start Zwift using the command:"
        msgbox info '     ZWIFT_PASSWORD="hunter2" zwift'
        msgbox info "  2. Store your password securely in the secret store with the following command:"
        msgbox info "     secret-tool store --label \"Zwift password for ${ZWIFT_USERNAME}\" application zwift username ${ZWIFT_USERNAME}"
    fi
else
    msgbox warning "No Zwift credentials found..."
fi

###################################
##### Window manager settings #####

if [[ ${XDG_SESSION_TYPE} == "wayland" ]] || [[ -n ${WAYLAND_DISPLAY} ]]; then
    if [[ ${WINE_EXPERIMENTAL_WAYLAND} -eq 1 ]]; then
        window_manager="Wayland"
    else
        window_manager="XWayland"
    fi
elif [[ ${XDG_SESSION_TYPE} == "x11" ]] || [[ -n ${DISPLAY} ]]; then
    window_manager="XOrg"
else
    window_manager="Other"
fi

# Setup Flags for Window Managers
if [[ ${window_manager} == "Wayland" ]]; then
    if [[ ${ZWIFT_UID} -ne ${UID} ]]; then
        msgbox error "Wayland does not support ZWIFT_UID different to your id of ${UID}, may not start"
    fi

    container_env_vars+=(
        WINE_EXPERIMENTAL_WAYLAND=1
        XDG_RUNTIME_DIR="/run/user/${container_uid}"
        WAYLAND_DISPLAY="${WAYLAND_DISPLAY}"
    )

    if [[ -n ${XDG_RUNTIME_DIR} ]]; then
        container_args+=(-v "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}:${XDG_RUNTIME_DIR//${local_uid}/${container_uid}}/${WAYLAND_DISPLAY}")
    else
        msgbox error "XDG_RUNTIME_DIR not set, Zwift will likely launch with a black screen!"
    fi
elif [[ ${window_manager} == "XWayland" ]] || [[ ${window_manager} == "XOrg" ]]; then
    container_args+=(-v /tmp/.X11-unix:/tmp/.X11-unix)
    if [[ -n ${XAUTHORITY} ]]; then
        # If not XAuthority set then don't pass, hyprland is one that does not use it
        container_env_vars+=(XAUTHORITY="${XAUTHORITY//${local_uid}/${container_uid}}")
        container_args+=(-v "${XAUTHORITY}:${XAUTHORITY//${local_uid}/${container_uid}}")
    fi
fi

####################################
##### Hardware driver settings #####

if [[ -n ${DBUS_SESSION_BUS_ADDRESS} ]]; then
    [[ ${DBUS_SESSION_BUS_ADDRESS} =~ ^unix:path=([^,]+) ]]
    dbus_unix_socket=${BASH_REMATCH[1]}
    if [[ -n ${dbus_unix_socket} ]]; then
        container_env_vars+=(DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS//${local_uid}/${container_uid}}")
        container_args+=(-v "${dbus_unix_socket}:${dbus_unix_socket//${local_uid}/${container_uid}}")
    fi
fi

# Check for proprietary nvidia driver and set correct device to use (respects existing VGA_DEVICE_FLAG)
if is_array "VGA_DEVICE_FLAG"; then
    container_args+=("${VGA_DEVICE_FLAG[@]}")
elif [[ -n ${VGA_DEVICE_FLAG} ]]; then
    msgbox warning "VGA_DEVICE_FLAG is defined as a string, it is recommended to use an array"
    read -ra vga_device_flags <<< "${VGA_DEVICE_FLAG}" && container_args+=("${vga_device_flags[@]}")
elif [[ -f "/proc/driver/nvidia/version" ]]; then
    if [[ ${CONTAINER_TOOL} == "podman" ]]; then
        container_args+=(--device="nvidia.com/gpu=all")
    else
        container_args+=(--gpus="all")
    fi
else
    container_args+=(--device="/dev/dri:/dev/dri")
fi

###########################
##### Start container #####

declare -a container_command
container_command=("${CONTAINER_TOOL}" run "${container_args[@]}" "${IMAGE}:${VERSION}" "${entrypoint_args[@]}")

# DRYRUN: print the exact command that would be executed, then exit
if [[ ${DRYRUN} -eq 1 ]]; then
    msgbox ok "DRYRUN:"
    msgbox ok "environment variables (${container_env_file}):"
    for env_var in "${container_env_vars[@]}"; do
        env_var="${env_var//\\/\\\\}"                                  # escape backslashes
        env_var="${env_var//ZWIFT_PASSWORD=*/ZWIFT_PASSWORD=REDACTED}" # redact password
        msgbox ok "  ${env_var}"
    done
    msgbox ok "${CONTAINER_TOOL} command:"
    msgbox ok "  $(printf '%q ' "${container_command[@]}")"
    exit 0
fi

# Create a volume if not already exists, this is done now as
# if left to the run command the directory can get the wrong permissions
if [[ ${CONTAINER_TOOL} == "podman" ]] && ! ${CONTAINER_TOOL} volume ls | grep "zwift-${USER}" > /dev/null; then
    if ${CONTAINER_TOOL} volume create "zwift-${USER}"; then
        msgbox ok "Created volume zwift-${USER}"
    else
        msgbox error "Failed to create volume zwift-${USER}"
    fi
fi

# Only write environment variables to file when needed
msgbox info "Writing environment variables to temporary file"
printf '%s\n' "${container_env_vars[@]}" > "${container_env_file}"

# Determine whether xhost access should be provided
if { [[ ${window_manager} == "XOrg" ]] || [[ ${WINE_EXPERIMENTAL_WAYLAND} -ne 1 ]]; } && command_exists xhost; then
    require_xhost_access=1
else
    require_xhost_access=0
fi

if [[ ${INTERACTIVE} -eq 1 ]] || [[ ${ZWIFT_FG} -eq 1 ]]; then
    # In interactive mode we don't have a container ID to run xhost against later.
    # If using X11/XWayland, show instructions so users can enable X access manually.
    if [[ ${require_xhost_access} -eq 1 ]]; then
        msgbox info "Starting Zwift in foreground: xhost is not automatically enabled for this container."
        msgbox info "  If you need X11 apps inside the container to display, run this in another terminal:"
        msgbox info "    xhost +local:${HOSTNAME}"
        msgbox info "  After you're done, you can revoke access with:"
        msgbox info "    xhost -local:${HOSTNAME}"
    fi
    msgbox ok "Launching Zwift! 🚀"
    if "${container_command[@]}"; then
        msgbox ok "Zwift container closed, exiting 🫡"
    else
        msgbox error "Failed to start Zwift, check variables! 😢" 10
        exit 1
    fi
else
    if container_id=$("${container_command[@]}"); then
        msgbox ok "Launched Zwift! 🚀"
        if [[ -n ${container_id} ]] && [[ ${require_xhost_access} -eq 1 ]]; then
            if hostname="$(${CONTAINER_TOOL} inspect --format='{{ .Config.Hostname }}' "${container_id}")" && xhost "+local:${hostname}" > /dev/null; then
                msgbox ok "Allowed container access to X server"
            else
                msgbox error "Failed to allow container access to X server, may not start"
            fi
        fi
    else
        msgbox error "Failed to start Zwift, check variables! 😢" 10
        exit 1
    fi
fi
