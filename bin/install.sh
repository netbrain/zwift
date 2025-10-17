#!/bin/bash

if [[ $EUID -eq 0 ]]; then
  ROOT_BIN=/usr/local/bin
  ROOT_SHARE=/usr/local/share
else
  # user install
  ROOT_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
  ROOT_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
fi

echo "Installing zwift to:"
echo "  binaries → $ROOT_BIN"
echo "  data     → $ROOT_SHARE"

read -r -p "Press ENTER to continue or Ctrl-C to abort…"

# create dirs
mkdir -p "$ROOT_BIN"
mkdir -p "$ROOT_SHARE/icons/hicolor/scalable/apps"
mkdir -p "$ROOT_SHARE/applications"

# download
curl -fsSL \
  -o "$ROOT_BIN/zwift" \
  https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh
chmod 755 "$ROOT_BIN/zwift"

curl -fsSL \
  -o "$ROOT_SHARE/icons/hicolor/scalable/apps/zwift.svg" \
  https://raw.githubusercontent.com/netbrain/zwift/master/assets/hicolor/scalable/apps/Zwift%20Logogram.svg

curl -fsSL \
  -o "$ROOT_SHARE/applications/Zwift.desktop" \
  https://raw.githubusercontent.com/netbrain/zwift/master/assets/Zwift.desktop


# warn if bin dir not in PATH
if ! case ":$PATH:" in
      *":$ROOT_BIN:"*) true  ;;
      *)               false ;;
    esac; then
  cat <<WARN
Warning: $ROOT_BIN is not in your PATH.
You may need to add it to your PATH for the zwift command to work
WARN
fi

echo "Done!"
