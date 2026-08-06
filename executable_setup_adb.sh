#!/bin/bash

# Point adb (and pontisd) at the corp ADB vendor keys, then restart the server.
# ADB_VENDOR_KEYS takes a directory; adb picks up every *.adb_key inside it.
# The keys themselves are cloned by the adb-keys/security chezmoi external.

set -e

KEYS_DIR="$HOME/adb-keys/security/adb"

if [ ! -d "$KEYS_DIR" ]; then
    echo "Error: $KEYS_DIR is missing, run 'chezmoi apply' to clone the keys repo." >&2
    exit 1
fi

export ADB_VENDOR_KEYS="$KEYS_DIR"
echo "=> ADB_VENDOR_KEYS=$ADB_VENDOR_KEYS"

# Linux only; macOS has no systemctl and no pontisd.
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR"
    systemctl --user restart pontisd
    echo "=> pontisd restarted"
fi

adb kill-server
adb devices
