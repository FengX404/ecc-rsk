#!/bin/bash
#
# ECC-RSK CodeBuddy Uninstaller
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEBUDDY_DIR=".codebuddy"

do_uninstall() {
    local target_dir="$SCRIPT_DIR"
    local codebuddy_full_path

    local current_dir_name="$(basename "$target_dir")"
    if [ "$current_dir_name" = ".codebuddy" ]; then
        codebuddy_full_path="$target_dir"
    else
        codebuddy_full_path="$target_dir/$CODEBUDDY_DIR"
    fi

    local MANIFEST="$codebuddy_full_path/.ecc-manifest"

    if [ ! -f "$MANIFEST" ]; then
        echo "No manifest found. Cannot safely uninstall."
        echo "Would you like to remove the entire directory? [y/N]"
        read -r response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            rm -rf "$codebuddy_full_path"
            echo "Directory removed."
        else
            echo "Aborted."
        fi
        return 0
    fi

    echo "ECC-RSK CodeBuddy Uninstaller"
    echo "=============================="
    echo ""
    echo "Target: $codebuddy_full_path/"
    echo ""
    echo "Continue? [y/N]"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Aborted."
        return 0
    fi

    while IFS= read -r entry; do
        local file_path="$codebuddy_full_path/$entry"
        if [ -f "$file_path" ]; then
            rm "$file_path"
            echo "Removed: $entry"
        fi
    done < "$MANIFEST"

    find "$codebuddy_full_path" -type d -empty -delete 2>/dev/null || true
    rm "$MANIFEST"

    echo ""
    echo "Uninstall complete."
}

do_uninstall "$@"