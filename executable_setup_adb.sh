#!/bin/bash

# Exit on error
set -e

# Define variables
BASE_DIR="$HOME/adb-keys"
SECURITY_DIR="$BASE_DIR/security"
KEYS_DIR="$SECURITY_DIR/adb"
REPO_URL="sso://googleplex-android/platform/vendor/google/security"

# Detect macOS
IS_MAC=$([[ "$OSTYPE" == "darwin"* ]] && echo true || echo false)

echo "=> 1. Cloning security repository..."
mkdir -p "$BASE_DIR"

if [ ! -d "$SECURITY_DIR" ]; then
    git clone "$REPO_URL" "$SECURITY_DIR"
else
    echo "=> Repository already exists, running git pull to update..."
    git -C "$SECURITY_DIR" pull
fi

echo "=> 2. Setting ADB_VENDOR_KEYS to keys directory..."

if [ ! -d "$KEYS_DIR" ]; then
    echo "Warning: $KEYS_DIR does not exist!"
    exit 1
fi

export ADB_VENDOR_KEYS="$KEYS_DIR"
echo "=> ADB_VENDOR_KEYS=$ADB_VENDOR_KEYS"

# Only run Pontis/systemd logic on Linux (not macOS)
if [ "$IS_MAC" = false ]; then
    echo "=> 3. Detected Linux, configuring systemd/pontisd..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR"
        systemctl --user daemon-reload
        systemctl --user restart pontisd
        echo "=> pontisd restarted successfully"
    else
        echo "=> systemctl not found, skipping service restart"
    fi
else
    echo "=> 3. Detected macOS, skipping Pontis service setup (env var only)."
fi

echo "---"
echo "Done!"
echo "Run 'source ~/.zshrc' (or restart your terminal) to apply the changes."
