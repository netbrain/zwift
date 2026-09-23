#!/usr/bin/env bash
# Build the custom Wine image that contains the winebth changes, tagged for the
# matching launch script.
#
# The sources come from the PR-BT-BLE branch of the wine-with-ble Git
# repository, so push whatever you want to test before running this.
#
# Override with:
#   WINE_REPO=https://github.com/purm/wine-with-ble.git
#   WINE_REF=PR-BT-BLE
#   CUSTOM_WINE_IMAGE=localhost/zwift-custom-wine:ble-test
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

export WINE_REPO="${WINE_REPO:-https://github.com/purm/wine-with-ble.git}"
export WINE_REF="${WINE_REF:-PR-BT-BLE}"
export CUSTOM_WINE_IMAGE="${CUSTOM_WINE_IMAGE:-localhost/zwift-custom-wine:ble-test}"

echo "[ble] building ${CUSTOM_WINE_IMAGE} from ${WINE_REPO} (${WINE_REF})"
exec "${script_dir}/build-custom-wine.sh"
