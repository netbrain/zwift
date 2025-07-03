#!/usr/bin/env bash

if [[ $EUID -eq 0 ]]; then
  root_bin=/usr/local/bin
  root_share=/usr/local/share
else
  # user install
  root_bin="${XDG_BIN_HOME:-$HOME/.local/bin}"
  root_share="${XDG_DATA_HOME:-$HOME/.local/share}"
fi

echo "Installing zwift to:"
echo "  binaries → ${root_bin}"
echo "  data     → ${root_share}"

read -p "Press ENTER to continue or Ctrl-C to abort…"

# create dirs
mkdir -p "${root_bin}"
mkdir -p "${root_share}/icons/hicolor/scalable/apps"
mkdir -p "${root_share}/applications"

# download
curl -fsSL \
  -o "${root_bin}/zwift" \
  https://raw.githubusercontent.com/netbrain/zwift/master/zwift.sh
chmod 755 "$root_bin/zwift"

curl -fsSL \
  -o "${root_share}/icons/hicolor/scalable/apps/zwift.svg" \
  https://raw.githubusercontent.com/netbrain/zwift/master/assets/hicolor/scalable/apps/Zwift%20Logogram.svg

curl -fsSL \
  -o "${root_share}/applications/Zwift.desktop" \
  https://raw.githubusercontent.com/netbrain/zwift/master/assets/Zwift.desktop


# warn if bin dir not in PATH
if ! case ":$PATH:" in
      *":$root_bin:"*) true  ;;
      *)               false ;;
    esac; then
  cat <<WARN
Warning: $root_bin is not in your PATH.
You may need to add it to your PATH for the zwift command to work
WARN
fi

echo "Done!"
