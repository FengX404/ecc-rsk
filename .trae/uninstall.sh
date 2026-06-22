#!/bin/bash
#
# ECC-RSK Trae Uninstaller
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

get_trae_dir() {
    if [ "${TRAE_ENV:-}" = "cn" ]; then
        echo ".trae-cn"
    else
        echo ".trae"
    fi
}

do_uninstall() {
    local target_dir="$SCRIPT_DIR"
    local trae_dir="$(get_trae_dir)"
    local trae_full_path

    local current_dir_name="$(basename "$target_dir")"
    if [ "$current_dir_name" = ".trae" ] || [ "$current_dir_name" = ".trae-cn" ]; then
        trae_full_path="$target_dir"
    else
        trae_full_path="$target_dir/$trae_dir"
    fi

    local MANIFEST="$trae_full_path/.ecc-manifest"

    if [ ! -f "$MANIFEST" ]; then
        echo "No manifest found. Cannot safely uninstall."
        echo "Would you like to remove the entire directory? [y/N]"
        read -r response
        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            rm -rf "$trae_full_path"
            echo "Directory removed."
        else
            echo "Aborted."
        fi
        return 0
    fi

    echo "ECC-RSK Trae Uninstaller"
    echo "========================"
    echo ""
    echo "Target: $trae_full_path/"
    echo ""
    echo "This will remove all files tracked in the manifest."
    echo "Continue? [y/N]"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Aborted."
        return 0
    fi

    # Remove tracked files
    while IFS= read -r entry; do
        local file_path="$trae_full_path/$entry"
        if [ -f "$file_path" ]; then
            rm "$file_path"
            echo "Removed: $entry"
        fi
    done < "$MANIFEST"

    # Remove empty directories
    find "$trae_full_path" -type d -empty -delete 2>/dev/null || true

    # Remove manifest
    rm "$MANIFEST"

    echo ""
    echo "Uninstall complete."
}

do_uninstall "$@"