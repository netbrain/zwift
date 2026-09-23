#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR
readonly WINE_REPO="${WINE_REPO:-https://github.com/purm/wine-with-ble.git}"
readonly WINE_REF="${WINE_REF:-PR-BT-BLE}"

if ! command -v git > /dev/null 2>&1; then
    echo "git not found, it is needed to fetch ${WINE_REPO}" >&2
    exit 1
fi

# Never block on a credential prompt: fail with git's own error instead.
export GIT_TERMINAL_PROMPT=0

if [[ -n ${CONTAINER_TOOL:-} ]]; then
    container_tool="${CONTAINER_TOOL}"
elif command -v podman > /dev/null 2>&1; then
    container_tool="podman"
else
    container_tool="docker"
fi
readonly container_tool

if ! command -v "${container_tool}" > /dev/null 2>&1; then
    echo "Container tool not found: ${container_tool}" >&2
    exit 1
fi

case ${container_tool} in
    podman)
        default_image="localhost/zwift-custom-wine:latest"
        ;;
    docker)
        default_image="zwift-custom-wine:latest"
        ;;
    *)
        echo "Unsupported container tool: ${container_tool}" >&2
        exit 1
        ;;
esac

readonly CUSTOM_WINE_IMAGE="${CUSTOM_WINE_IMAGE:-${default_image}}"
readonly BASE_IMAGE="${BASE_IMAGE:-docker.io/netbrain/zwift:latest}"

build_context="$(mktemp -d -t zwift-custom-wine.XXXXXXXX)"
readonly build_context
cleanup() {
    rm -rf -- "${build_context}"
}
trap cleanup EXIT

wine_source="${build_context}/wine"
readonly wine_source

# Fail fast when the repository is unreachable or empty, and when a branch or
# tag name is misspelled: the fallback below would otherwise clone the full
# Wine history before noticing. A commit id is not advertised by ls-remote, so
# it is only verified when it is fetched.
if ! git ls-remote --exit-code --heads --tags "${WINE_REPO}" > /dev/null 2>&1; then
    echo "No branches or tags found in ${WINE_REPO}" >&2
    echo "Check that the repository is reachable and that the Wine sources are pushed to it." >&2
    exit 1
fi
if [[ ! ${WINE_REF} =~ ^[0-9a-f]{7,40}$ ]] \
    && ! git ls-remote --exit-code "${WINE_REPO}" "refs/heads/${WINE_REF}" "refs/tags/${WINE_REF}" > /dev/null 2>&1; then
    echo "No branch or tag called '${WINE_REF}' in ${WINE_REPO}" >&2
    echo "Set WINE_REF to an advertised branch or tag, or to a commit id." >&2
    exit 1
fi

# Clone a single revision instead of the full history. A branch or tag is much
# cheaper, but --branch cannot resolve a commit id, so fall back to fetching the
# revision itself and, for servers that refuse that too, to a complete clone.
clone_wine() {
    if git clone --quiet --depth 1 --branch "${WINE_REF}" "${WINE_REPO}" "${wine_source}" 2> /dev/null; then
        return 0
    fi

    rm -rf -- "${wine_source}"
    if git clone --quiet --depth 1 "${WINE_REPO}" "${wine_source}" 2> /dev/null \
        && git -C "${wine_source}" fetch --quiet --depth 1 origin "${WINE_REF}" 2> /dev/null \
        && git -C "${wine_source}" checkout --quiet FETCH_HEAD 2> /dev/null; then
        return 0
    fi

    rm -rf -- "${wine_source}"
    echo "Fetching the full history of ${WINE_REPO} to resolve ${WINE_REF}"
    if ! git clone --quiet "${WINE_REPO}" "${wine_source}" 2> /dev/null \
        || ! git -C "${wine_source}" checkout --quiet "${WINE_REF}" 2> /dev/null; then
        echo "Could not check out '${WINE_REF}' from ${WINE_REPO}" >&2
        exit 1
    fi
}

echo "Cloning Wine ${WINE_REF} from ${WINE_REPO}"
clone_wine

if [[ ! -x "${wine_source}/configure" ]] || [[ ! -f "${wine_source}/VERSION" ]]; then
    echo "Not a Wine source tree: ${WINE_REPO} (${WINE_REF}) has no configure/VERSION" >&2
    exit 1
fi

wine_commit="$(git -C "${wine_source}" rev-parse --short HEAD)"
readonly wine_commit
wine_version="$(< "${wine_source}/VERSION")"
readonly wine_version

# Git's object database is not needed for compilation and would only bloat the
# build context sent to the container tool.
rm -rf -- "${wine_source}/.git"
cp "${SCRIPT_DIR}/Dockerfile.custom-wine" "${build_context}/Dockerfile"

echo "Building ${CUSTOM_WINE_IMAGE} from ${wine_version} (${WINE_REPO} at ${wine_commit})"
declare -a build_args
build_args=(
    --build-arg "BASE_IMAGE=${BASE_IMAGE}"
    --build-arg "WINE_REPO=${WINE_REPO}"
    --build-arg "WINE_REF=${WINE_REF}"
    --build-arg "WINE_COMMIT=${wine_commit}"
    --file "${build_context}/Dockerfile"
    --tag "${CUSTOM_WINE_IMAGE}"
)
if [[ ${container_tool} == "podman" ]]; then
    build_args+=(--layers)
fi
"${container_tool}" build "${build_args[@]}" "${build_context}"

echo
echo "Custom Wine image is ready: ${CUSTOM_WINE_IMAGE}"
echo "Verify it with:"
echo "  ${container_tool} run --rm --entrypoint /bin/bash ${CUSTOM_WINE_IMAGE} -c 'command -v wine; wine --version'"
echo
echo "Launch it from ${SCRIPT_DIR} with an isolated test profile:"
image_name="${CUSTOM_WINE_IMAGE%:*}"
image_version="${CUSTOM_WINE_IMAGE##*:}"
printf '  IMAGE=%q VERSION=%q DONT_PULL=1 DONT_CHECK=1 ZWIFT_RIDER=custom-wine-test ZWIFT_FG=1 ./zwift.sh\n' \
    "${image_name}" "${image_version}"
