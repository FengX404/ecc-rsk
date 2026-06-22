#!/bin/bash
set -e

# ECC-RSK Installation Script
# Reads symlink-manifest.json to create all symlinks from ECC submodule.
#
# Usage:
#   ./install.sh              # Full install: mkdir + symlinks
#   ./install.sh --symlinks-only  # Only recreate symlinks (skip mkdir)
#   ./install.sh --verify     # Verify all symlinks resolve correctly

SYMLINKS_ONLY=false
VERIFY_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --symlinks-only)
      SYMLINKS_ONLY=true
      ;;
    --verify)
      VERIFY_ONLY=true
      ;;
    -h|--help)
      echo "Usage: ./install.sh [--symlinks-only] [--verify]"
      echo ""
      echo "Options:"
      echo "  --symlinks-only   Only recreate symlinks, skip mkdir"
      echo "  --verify          Verify all symlinks resolve correctly"
      echo "  -h, --help        Show help"
      exit 0
      ;;
  esac
done

MANIFEST="symlink-manifest.json"

# Check manifest exists
if [ ! -f "$MANIFEST" ]; then
  echo "Error: $MANIFEST not found in current directory."
  echo "This script must be run from the ecc-rsk project root."
  exit 1
fi

# Verify mode: check all symlinks then exit
if [ "$VERIFY_ONLY" = true ]; then
  echo "=== ECC-RSK Symlink Verification ==="
  echo ""

  broken=$(find . -type l -xtype l -not -path "./ecc/*" -print 2>/dev/null || true)
  if [ -n "$broken" ]; then
    echo "Broken symlinks:"
    echo "$broken"
    exit 1
  fi

  # Count expected vs actual
  expected=$(python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
count = len(m.get('agents',[])) + len(m.get('skills',[])) + len(m.get('commands',[]))
count += len(m.get('rules',[])) + len(m.get('misc_files',[])) + len(m.get('misc_dirs',[]))
print(count)
" 2>/dev/null)

  actual=$(find agents skills commands rules hooks contexts schemas scripts/lib mcp-configs -type l 2>/dev/null | wc -l | tr -d ' ')
  expected=${expected:-0}
  echo "Manifest entries: $expected, actual symlinks: $actual"
  echo "All symlinks resolve correctly."
  exit 0
fi

echo "=== ECC-RSK Installation ==="
echo ""

# Check submodule
if [ ! -d "ecc" ]; then
  echo "Initializing ECC submodule..."
  git submodule init
  git submodule update
fi

# Create directory structure
if [ "$SYMLINKS_ONLY" = false ]; then
  echo "Creating directory structure..."
  mkdir -p agents skills commands rules hooks contexts schemas scripts mcp-configs templates docs .claude/rules .cursor/rules .github/workflows
  mkdir -p rules/nextjs rules/supabase rules/vercel
  mkdir -p skills/supabase-patterns skills/nextjs-app-router skills/vercel-deployment skills/fullstack-auth skills/realtime-sync skills/type-safe-stack skills/form-patterns
fi

echo "Creating symlinks from $MANIFEST..."
echo ""

CREATED=0
FAILED=0

# Helper: create symlink for a file within a category directory
create_symlink() {
  local category="$1"   # agents, skills, commands, rules
  local ecc_dir="$2"    # ../ecc/agents, ../ecc/skills, etc.
  local name="$3"       # planner.md, api-design, etc.

  local target="${ecc_dir}/${name}"
  local link="${category}/${name}"

  if [ -e "$target" ]; then
    ln -sf "$target" "$link"
    ((CREATED++)) || true
  else
    echo "  WARNING: source not found: $target → skipping $link"
    ((FAILED++)) || true
  fi
}

# --- Agents ---
for agent in $(python3 -c "import json; print(' '.join(json.load(open('$MANIFEST'))['agents']))" 2>/dev/null); do
  create_symlink "agents" "../ecc/agents" "$agent"
done

# --- Skills (directories) ---
for skill in $(python3 -c "import json; print(' '.join(json.load(open('$MANIFEST'))['skills']))" 2>/dev/null); do
  create_symlink "skills" "../ecc/skills" "$skill"
done

# --- Commands ---
for cmd in $(python3 -c "import json; print(' '.join(json.load(open('$MANIFEST'))['commands']))" 2>/dev/null); do
  create_symlink "commands" "../ecc/commands" "$cmd"
done

# --- Rules (directories) ---
for rule in $(python3 -c "import json; print(' '.join(json.load(open('$MANIFEST'))['rules']))" 2>/dev/null); do
  create_symlink "rules" "../ecc/rules" "$rule"
done

# --- Misc files ---
python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
for item in m.get('misc_files', []):
    print(item['target'], item['link'])
" 2>/dev/null | while read target link; do
  if [ -e "$target" ]; then
    ln -sf "$target" "$link"
    ((CREATED++)) || true
  else
    echo "  WARNING: source not found: $target → skipping $link"
    ((FAILED++)) || true
  fi
done

# --- Misc dirs ---
python3 -c "
import json
with open('$MANIFEST') as f:
    m = json.load(f)
for item in m.get('misc_dirs', []):
    print(item['target'], item['link'])
" 2>/dev/null | while read target link; do
  if [ -d "$target" ]; then
    ln -sfn "$target" "$link"
    ((CREATED++)) || true
  else
    echo "  WARNING: source not found: $target → skipping $link"
    ((FAILED++)) || true
  fi
done

echo ""
echo "Symlinks: $CREATED created, $FAILED skipped (source not found)"
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo "WARNING: $FAILED symlink(s) were skipped because ECC source files were not found."
  echo "This may happen if ECC submodule is not fully initialized."
  echo "Run: git submodule update --init --recursive"
  echo ""
fi

echo "✓ Installation complete."
echo ""
echo "Next steps:"
echo "  1. Verify: ./install.sh --verify"
echo "  2. Commit any new symlinks: git add agents/ skills/ commands/ rules/"
