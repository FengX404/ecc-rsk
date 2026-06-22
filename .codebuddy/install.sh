#!/bin/bash
#
# ECC-RSK CodeBuddy Installer
#

set -euo pipefail
shopt -s nullglob

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

find_repo_root() {
    local dir="$(dirname "$SCRIPT_DIR")"
    if [ -f "$dir/VERSION" ] && [ -d "$dir/commands" ] && [ -d "$dir/agents" ]; then
        echo "$dir"
        return 0
    fi
    echo ""
    return 1
}

REPO_ROOT="$(find_repo_root)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Cannot locate the ECC-RSK repository root."
    exit 1
fi

CODEBUDDY_DIR=".codebuddy"

ensure_manifest_entry() {
    local manifest="$1"
    local entry="$2"
    touch "$manifest"
    if ! grep -Fqx "$entry" "$manifest"; then
        echo "$entry" >> "$manifest"
    fi
}

manifest_has_entry() {
    local manifest="$1"
    local entry="$2"
    [ -f "$manifest" ] && grep -Fqx "$entry" "$manifest"
}

copy_managed_file() {
    local source_path="$1"
    local target_path="$2"
    local manifest="$3"
    local manifest_entry="$4"
    local make_executable="${5:-0}"

    local already_managed=0
    if manifest_has_entry "$manifest" "$manifest_entry"; then
        already_managed=1
    fi

    if [ -f "$target_path" ]; then
        if [ "$already_managed" -eq 1 ]; then
            ensure_manifest_entry "$manifest" "$manifest_entry"
        fi
        return 1
    fi

    cp "$source_path" "$target_path"
    if [ "$make_executable" -eq 1 ]; then
        chmod +x "$target_path"
    fi
    ensure_manifest_entry "$manifest" "$manifest_entry"
    return 0
}

do_install() {
    local target_dir="$PWD"

    if [ "$#" -ge 1 ]; then
        if [ "$1" = "~" ] || [ "$1" = "$HOME" ]; then
            target_dir="$HOME"
        fi
    fi

    local current_dir_name="$(basename "$target_dir")"
    local codebuddy_full_path

    if [ "$current_dir_name" = ".codebuddy" ]; then
        codebuddy_full_path="$target_dir"
    else
        codebuddy_full_path="$target_dir/$CODEBUDDY_DIR"
    fi

    echo "ECC-RSK CodeBuddy Installer"
    echo "============================"
    echo ""
    echo "Source:  $REPO_ROOT"
    echo "Target:  $codebuddy_full_path/"
    echo ""

    SUBDIRS="commands agents skills rules"

    for dir in $SUBDIRS; do
        mkdir -p "$codebuddy_full_path/$dir"
    done

    MANIFEST="$codebuddy_full_path/.ecc-manifest"
    touch "$MANIFEST"

    commands=0
    agents=0
    skills=0
    rules=0
    other=0

    # Copy commands
    if [ -d "$REPO_ROOT/commands" ]; then
        for f in "$REPO_ROOT/commands"/*.md; do
            [ -f "$f" ] || continue
            local_name=$(basename "$f")
            target_path="$codebuddy_full_path/commands/$local_name"
            if copy_managed_file "$f" "$target_path" "$MANIFEST" "commands/$local_name"; then
                commands=$((commands + 1))
            fi
        done
    fi

    # Copy agents
    if [ -d "$REPO_ROOT/agents" ]; then
        for f in "$REPO_ROOT/agents"/*.md; do
            [ -f "$f" ] || continue
            local_name=$(basename "$f")
            target_path="$codebuddy_full_path/agents/$local_name"
            if copy_managed_file "$f" "$target_path" "$MANIFEST" "agents/$local_name"; then
                agents=$((agents + 1))
            fi
        done
    fi

    # Copy skills
    if [ -d "$REPO_ROOT/skills" ]; then
        for d in "$REPO_ROOT/skills"/*/; do
            [ -d "$d" ] || continue
            d="${d%/}"
            skill_name="$(basename "$d")"
            target_skill_dir="$codebuddy_full_path/skills/$skill_name"
            skill_copied=0

            while IFS= read -r source_file; do
                relative_path="${source_file#$d}"
                target_path="$target_skill_dir/$relative_path"
                mkdir -p "$(dirname "$target_path")"
                if copy_managed_file "$source_file" "$target_path" "$MANIFEST" "skills/$skill_name$relative_path"; then
                    skill_copied=1
                fi
            done < <(find "$d" -type f | sort)

            if [ "$skill_copied" -eq 1 ]; then
                skills=$((skills + 1))
            fi
        done
    fi

    # Copy rules
    if [ -d "$REPO_ROOT/rules" ]; then
        while IFS= read -r rule_file; do
            relative_path="${rule_file#$REPO_ROOT/rules/}"
            target_path="$codebuddy_full_path/rules/$relative_path"
            mkdir -p "$(dirname "$target_path")"
            if copy_managed_file "$rule_file" "$target_path" "$MANIFEST" "rules/$relative_path"; then
                rules=$((rules + 1))
            fi
        done < <(find "$REPO_ROOT/rules" -type f | sort)
    fi

    # Copy README files
    for readme_file in "$SCRIPT_DIR/README.md" "$SCRIPT_DIR/README.zh-CN.md"; do
        if [ -f "$readme_file" ]; then
            local_name=$(basename "$readme_file")
            target_path="$codebuddy_full_path/$local_name"
            copy_managed_file "$readme_file" "$target_path" "$MANIFEST" "$local_name" || true
        fi
    done

    ensure_manifest_entry "$MANIFEST" ".ecc-manifest"

    echo "Installation complete!"
    echo ""
    echo "Components installed:"
    echo "  Commands:  $commands"
    echo "  Agents:    $agents"
    echo "  Skills:    $skills"
    echo "  Rules:     $rules"
    echo ""
    echo "Directory:   $(basename "$codebuddy_full_path")"
}

do_install "$@"