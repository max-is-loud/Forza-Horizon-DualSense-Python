#!/usr/bin/env bash
# FH DualSense - Linux/macOS launcher.
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO="HamzaYslmn/Forza-Horizon-DualSense-Python"
RELEASES="https://github.com/$REPO/releases/latest"
APP="$ROOT/app"
PYPROJECT="$APP/src/pyproject.toml"

trap 'c=$?; echo; [ $# -eq 0 ] && read -r -p "Press Enter to close..." _ || true; exit $c' EXIT

need() { command -v "$1" >/dev/null 2>&1; }
fetch() { if need curl; then curl -fsSL "$1"; elif need wget; then wget -qO- "$1"; fi; }

LATEST=$(fetch "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
    | grep -E '"tag_name"' | head -n1 | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')
SOURCE="tags"
[ -z "$LATEST" ] && { LATEST="main"; SOURCE="heads"; }

CURRENT=""
if [ -f "$PYPROJECT" ]; then
    v=$(grep -E '^version\s*=' "$PYPROJECT" | head -n1 | sed -E 's/version\s*=\s*"([^"]+)".*/\1/')
    [ -n "$v" ] && CURRENT="v$v"
fi

install_release() {
    local zip="$ROOT/fhds.zip" extract="$ROOT/_extract"
    echo "Downloading $LATEST..."
    if ! fetch "https://github.com/$REPO/archive/refs/$SOURCE/$LATEST.zip" > "$zip"; then
        echo "Download failed. Get the release manually from $RELEASES"
        rm -f "$zip"; [ -f "$APP/src/main.py" ] || exit 1; return
    fi
    rm -rf "$extract"; mkdir -p "$extract"
    if need unzip; then unzip -q "$zip" -d "$extract"
    else python3 -c "import zipfile,sys; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$zip" "$extract"
    fi
    mkdir -p "$APP"
    cp -Rf "$extract"/*/. "$APP"/
    rm -rf "$extract" "$zip"
}

if [ -z "$CURRENT" ] || [ "$SOURCE" = "heads" ]; then
    install_release
elif [ "$CURRENT" = "$LATEST" ]; then
    echo "Up to date ($CURRENT)."
else
    echo "Update available: $CURRENT -> $LATEST"
    read -r -p "Update now? [Y/n] " ans
    case "${ans:-Y}" in [Nn]*) ;; *) install_release ;; esac
fi

if ! need uv; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    need uv || { echo "uv not on PATH - restart shell."; exit 1; }
fi

RULE_DST="/etc/udev/rules.d/70-dualsense.rules"
if [ "$(uname -s)" = "Linux" ] && [ ! -f "$RULE_DST" ] && [ -f "$APP/packaging/linux/70-dualsense.rules" ]; then
    read -r -p "Install DualSense udev rule (sudo)? [Y/n] " ans
    case "${ans:-Y}" in [Nn]*) ;; *)
        sudo cp "$APP/packaging/linux/70-dualsense.rules" "$RULE_DST" \
            && sudo udevadm control --reload-rules && sudo udevadm trigger \
            && echo "Installed udev rule. Re-plug controller." ;;
    esac
fi

cd "$APP/src"
unset PYTHONHOME PYTHONPATH
export PYTHONNOUSERSITE=1
if [ "$#" -gt 0 ]; then "$@" & fi
uv run main.py
