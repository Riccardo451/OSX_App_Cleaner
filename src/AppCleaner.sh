#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

DRY_RUN=false
APP_NAME=""
MATCHES=()

usage() {
    echo "Usage:"
    echo "  $0 -p \"Application Name\" [--dry-run]"
    exit 1
}

delete_item() {
    local target="$1"

    [ ! -e "$target" ] && return

    if $DRY_RUN; then
        echo "[DRY RUN] Would move to Trash: $target"
    else
        echo "Moving to Trash: $target"
        # Ensure the Trash directory exists before moving
        mkdir -p "$HOME/.Trash"
        mv "$target" "$HOME/.Trash/"
    fi
}

# ----------------------------
# Parse arguments
# ----------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)
            APP_NAME="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

[ -z "$APP_NAME" ] && usage

APP_NAME_LOWER=$(printf '%s' "$APP_NAME" | tr '[:upper:]' '[:lower:]')
# New: Strip all spaces for alternative matching
APP_NAME_NO_SPACE="${APP_NAME_LOWER// /}"

echo "Searching for application: $APP_NAME"

# ----------------------------
# Find app bundle (ROBUST)
# ----------------------------
APP_PATH=""

# 1. Spotlight (best source)
# Using a mapfile or reading directly avoids subshell assignment issues
APP_PATH=$(mdfind "kMDItemKind == 'Application'" 2>/dev/null | grep -i "$APP_NAME" | head -n 1 || true)

# 2. Applications folders fallback
if [ -z "$APP_PATH" ]; then
    # Enhanced to look for both "Mullvad Browser" and "MullvadBrowser"
    APP_PATH=$(find /Applications "$HOME/Applications" -type d -name "*.app" 2>/dev/null | grep -i -E "$APP_NAME|${APP_NAME// /}" | head -n 1 || true)
fi

BUNDLE_ID=""

if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
    echo "Found application:"
    echo "  $APP_PATH"

    BUNDLE_ID=$(
        /usr/libexec/PlistBuddy \
        -c "Print :CFBundleIdentifier" \
        "$APP_PATH/Contents/Info.plist" \
        2>/dev/null || true
    )

    MATCHES+=("$APP_PATH")
else
    echo "Application bundle not found (continuing anyway)."
fi

# ----------------------------
# Locations
# ----------------------------
SEARCH_LOCATIONS=(
    "$HOME/Library/Application Support"
    "$HOME/Library/Caches"
    "$HOME/Library/Preferences"
    "$HOME/Library/Logs"
    "$HOME/Library/Containers"
    "$HOME/Library/Saved Application State"
    "$HOME/Library/WebKit"
    "$HOME/Library/HTTPStorages"
    "$HOME/Library/Group Containers"

    "/Library/Application Support"
    "/Library/Caches"
    "/Library/Preferences"
    "/Library/Logs"
    "/Library/LaunchAgents"
    "/Library/LaunchDaemons"
    "/Library/PrivilegedHelperTools"
)

echo
echo "Scanning filesystem..."

# ----------------------------
# SAFE SCAN (macOS Bash 3.2 compatible)
# ----------------------------
for location in "${SEARCH_LOCATIONS[@]}"; do

    [ -d "$location" ] || continue

    while IFS= read -r -d '' item; do

            name=$(basename "$item")
            name_lower=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')

            # Check for original name OR space-stripped name
            if [[ "$name_lower" == *"$APP_NAME_LOWER"* ]] || [[ "$name_lower" == *"$APP_NAME_NO_SPACE"* ]]; then
                MATCHES+=("$item")
            fi

            if [ -n "$BUNDLE_ID" ]; then
                bundle_lower=$(printf '%s' "$BUNDLE_ID" | tr '[:upper:]' '[:lower:]')
                if [[ "$name_lower" == *"$bundle_lower"* ]]; then
                    MATCHES+=("$item")
                fi
            fi

        done < <(find "$location" -maxdepth 3 -print0 2>/dev/null)

done

# ----------------------------
# DEDUP
# ----------------------------
UNIQUE_MATCHES=()

for item in "${MATCHES[@]}"; do
    skip=false

    # Fix: Safely expand the array even if it's currently empty
    for existing in ${UNIQUE_MATCHES[@]+"${UNIQUE_MATCHES[@]}"}; do
        if [ "$existing" = "$item" ]; then
            skip=true
            break
        fi
    done

    $skip || UNIQUE_MATCHES+=("$item")
done

# ----------------------------
# EXIT IF NOTHING
# ----------------------------
if [ ${#UNIQUE_MATCHES[@]} -eq 0 ]; then
    echo
    echo "No matching files found."
    exit 0
fi

# ----------------------------
# SUMMARY
# ----------------------------
echo
echo "========================================="
echo "Items found: ${#UNIQUE_MATCHES[@]}"
echo "========================================="
echo

TOTAL_KB=0

for item in "${UNIQUE_MATCHES[@]}"; do
    # Check if file still exists (to avoid du throwing errors under set -e)
    [ -e "$item" ] || continue

    size_kb=$(du -sk "$item" 2>/dev/null | awk '{print $1}' || echo 0)
    human_size=$(du -sh "$item" 2>/dev/null | awk '{print $1}' || echo "0B")

    # Handle cases where size_kb is empty
    [ -z "$size_kb" ] && size_kb=0
    TOTAL_KB=$((TOTAL_KB + size_kb))

    printf "%-10s %s\n" "$human_size" "$item"
done

echo
echo "Approximate total size: $(awk -v kb="$TOTAL_KB" '
BEGIN {
    if (kb > 1048576)
        printf "%.2f GB\n", kb / 1048576
    else if (kb > 1024)
        printf "%.2f MB\n", kb / 1024
    else
        printf "%d KB\n", kb
}')"

# ----------------------------
# CONFIRMATION
# ----------------------------
echo
# -r ensures backslashes aren't mangled in input
read -r -p "Proceed with deletion? [y/N] " CONFIRM

case "$CONFIRM" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
esac

# ----------------------------
# DELETE
# ----------------------------
echo
echo "Deleting..."

for item in "${UNIQUE_MATCHES[@]}"; do
    delete_item "$item"
done

echo
echo "Finished."
