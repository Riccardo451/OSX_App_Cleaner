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

# Fallback case manipulation compatible with Bash 3.2 (macOS default)
APP_NAME_LOWER=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')
APP_NAME_NO_SPACE="${APP_NAME_LOWER// /}"

echo "Searching for application: $APP_NAME"

# ----------------------------
# Find app bundle (ROBUST)
# ----------------------------
APP_PATH=""

# 1. Spotlight (best source)
APP_PATH=$(mdfind "kMDItemKind == 'Application'" 2>/dev/null | grep -i "$APP_NAME" | head -n 1 || true)

# 2. Applications folders fallback
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find /Applications "$HOME/Applications" -type d -name "*.app" 2>/dev/null | grep -i -E "$APP_NAME|${APP_NAME// /}" | head -n 1 || true)
fi

BUNDLE_ID=""

if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
    # Calculate the size of the .app bundle specifically
    APP_SIZE=$(du -sh "$APP_PATH" 2>/dev/null | awk '{print $1}')
    
    echo "Found application:"
    echo "  $APP_PATH ($APP_SIZE)"

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
# FAST SCAN (Offloads filtering to `find`)
# ----------------------------
# Construct regex for find: (name|nospace|bundle_id)
FIND_REGEX=".*(${APP_NAME_LOWER}|${APP_NAME_NO_SPACE}"
if [ -n "$BUNDLE_ID" ]; then
    BUNDLE_ID_LOWER=$(echo "$BUNDLE_ID" | tr '[:upper:]' '[:lower:]')
    FIND_REGEX="${FIND_REGEX}|${BUNDLE_ID_LOWER}"
fi
FIND_REGEX="${FIND_REGEX}).*"

for location in "${SEARCH_LOCATIONS[@]}"; do
    [ -d "$location" ] || continue

    # -iregex performs case-insensitive regex matching on the entire path directly inside find.
    # This prevents Bash from looping over thousands of irrelevant files.
    while IFS= read -r -d '' item; do
        MATCHES+=("$item")
    done < <(find -E "$location" -maxdepth 3 -iregex "$FIND_REGEX" -print0 2>/dev/null)
done

# ----------------------------
# DEDUP (Optimized via Awk)
# ----------------------------
UNIQUE_MATCHES=()
if [ ${#MATCHES[@]} -gt 0 ]; then
    # Using awk to deduplicate is drastically faster than nested bash loops
    while IFS= read -r line; do
        UNIQUE_MATCHES+=("$line")
    done < <(printf '%s\n' "${MATCHES[@]}" | awk '!x[$0]++')
fi

# ----------------------------
# EXIT IF NOTHING
# ----------------------------
if [ ${#UNIQUE_MATCHES[@]} -eq 0 ]; then
    echo
    echo "No matching files found."
    exit 0
fi

# ----------------------------
# SUMMARY (Fixed for spaces)
# ----------------------------
echo
echo "========================================="
echo "Items found: ${#UNIQUE_MATCHES[@]}"
echo "========================================="
echo

TOTAL_KB=0

for item in "${UNIQUE_MATCHES[@]}"; do
    # Check if file still exists (to avoid du throwing errors)
    [ -e "$item" ] || continue

    # Safely get human-readable size and raw KB size without breaking on spaces
    human_size=$(du -sh "$item" 2>/dev/null | awk '{print $1}')
    size_kb=$(du -sk "$item" 2>/dev/null | awk '{print $1}')

    [ -z "$size_kb" ] && size_kb=0
    [ -z "$human_size" ] && human_size="0B"
    
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
