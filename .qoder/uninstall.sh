#!/bin/bash
#
# ECC-RSK Qoder Uninstaller
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QODER_DIR=".qoder"

do_uninstall() {
    local target_dir="$SCRIPT_DIR"
    local qoder_full_path

    local current_dir_name="$(basename "$target_dir")"
    if [ "$current_dir_name" = ".qoder" ]; then
        qoder_full_path="$target_dir"
    else
        qoder_full_path="$target_dir/$QODER_DIR"
    fi

    local MANIFEST="$qoder_full_path/.ecc-manifest"

    if [ ! -f "$MANIFEST" ]; then
        echo "No manifest found. Cannot safely uninstall."
        echo "Would you like to remove the entire directory? [y/N]"
        read -r response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            rm -rf "$qoder_full_path"
            echo "Directory removed."
        else
            echo "Aborted."
        fi
        return 0
    fi

    echo "ECC-RSK Qoder Uninstaller"
    echo "========================="
    echo ""
    echo "Target: $qoder_full_path/"
    echo ""
    echo "Continue? [y/N]"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Aborted."
        return 0
    fi

    while IFS= read -r entry; do
        local file_path="$qoder_full_path/$entry"
        if [ -f "$file_path" ]; then
            rm "$file_path"
            echo "Removed: $entry"
        fi
    done < "$MANIFEST"

    find "$qoder_full_path" -type d -empty -delete 2>/dev/null || true
    rm "$MANIFEST"

    echo ""
    echo "Uninstall complete."
}

do_uninstall "$@"