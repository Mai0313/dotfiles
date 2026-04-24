#!/bin/bash

# Only run on work machines (Cloudtop / Roam). Matches the is_work detection
# in .chezmoi.toml.tmpl so behavior stays consistent with the old template.
fqdn=$(hostname -f 2>/dev/null || hostname)
case "$fqdn" in
  *.c.googlers.com|*.roam.internal) ;;
  *) echo "Not a work machine, skipping ADB setup."; exit 0 ;;
esac

# Exit on error
set -e

# Define variables
BASE_DIR="$HOME/adb-keys"
SECURITY_DIR="$BASE_DIR/security"
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

echo "=> 2. Finding and setting ADB_VENDOR_KEYS..."

# Fix paste compatibility across platforms
KEY_PATHS=$(find "$SECURITY_DIR/adb" -name '*.adb_key' 2>/dev/null | paste -sd ":" - || true)

if [ -z "$KEY_PATHS" ]; then
    echo "Warning: No .adb_key files found in $SECURITY_DIR/adb!"
else
    # Export for the current script environment
    export ADB_VENDOR_KEYS="$KEY_PATHS"
    echo "=> ADB_VENDOR_KEYS set successfully"
fi

# Only run Pontis/systemd logic on Linux (not macOS)
if [ "$IS_MAC" = false ]; then
    echo "=> 3. Detected Linux, configuring systemd/pontisd..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user set-environment ADB_VENDOR_KEYS="$KEY_PATHS"
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
