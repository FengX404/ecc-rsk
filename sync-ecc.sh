#!/bin/bash
#
# sync-ecc.sh — 同步 ECC submodule 更新到 RSK
#
# 用途：更新 ECC submodule 后，重新创建 symlinks 以同步新增/变更文件
# 依赖：symlink-manifest.json（symlink 清单）、install.sh（创建 symlinks）
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== ECC-RSK Sync ==="
echo ""

# 1. 检查 ECC submodule 是否存在
if [ ! -d "ecc" ]; then
  echo "Error: ecc/ directory not found. Run 'git submodule init && git submodule update' first."
  exit 1
fi

# 2. 记录当前 commit
OLD_COMMIT=$(cd ecc && git rev-parse HEAD 2>/dev/null || echo "none")

# 3. 更新 submodule
echo "Updating ECC submodule..."
git submodule update --remote ecc

NEW_COMMIT=$(cd ecc && git rev-parse HEAD)

# 4. 无变更则退出
if [ "$OLD_COMMIT" = "$NEW_COMMIT" ]; then
  echo "No changes in ECC submodule."
  exit 0
fi

echo ""
echo "ECC updated: ${OLD_COMMIT:0:8} → ${NEW_COMMIT:0:8}"
echo ""
echo "Changes:"
(cd ecc && git log --oneline "${OLD_COMMIT}"..HEAD 2>/dev/null | head -20) || true

echo ""
echo "New/changed/deleted files:"
(cd ecc && git diff --name-status "$OLD_COMMIT" HEAD 2>/dev/null | head -50) || true

# 5. 检测 ECC 是否有新增文件需要加入 manifest
echo ""
echo "Checking for new ECC files not in manifest..."

python3 -c "
import json, os, sys

MANIFEST = 'symlink-manifest.json'

# Load existing manifest entries
with open(MANIFEST) as f:
    m = json.load(f)

existing_agents = set(m.get('agents', []))
existing_skills = set(m.get('skills', []))
existing_commands = set(m.get('commands', []))

# Scan ECC directories for new files
ecc_agents = set(f for f in os.listdir('ecc/agents') if f.endswith('.md'))
ecc_skills = set(d for d in os.listdir('ecc/skills') if os.path.isdir(os.path.join('ecc/skills', d)) and not d.startswith('.'))
ecc_commands = set(f for f in os.listdir('ecc/commands') if f.endswith('.md'))

new_agents = ecc_agents - existing_agents
new_skills = ecc_skills - existing_skills
new_commands = ecc_commands - existing_commands

if new_agents:
    print(f'  NEW agents in ECC (not in manifest): {sorted(new_agents)}')
if new_skills:
    print(f'  NEW skills in ECC (not in manifest): {sorted(new_skills)}')
if new_commands:
    print(f'  NEW commands in ECC (not in manifest): {sorted(new_commands)}')

if not new_agents and not new_skills and not new_commands:
    print('  No new ECC files detected.')
else:
    print('')
    print('  Review and add desired entries to symlink-manifest.json, then re-run ./install.sh')
" 2>/dev/null || echo "  (skipped — python3 not available)"

# 6. 重新创建 symlinks
echo ""
echo "Recreating symlinks..."
./install.sh --symlinks-only

echo ""
echo "=== Sync complete ==="
echo ""
echo "Next steps:"
echo "  1. Review changes: git status"
echo "  2. Run verification: ./install.sh --verify"
echo "  3. Commit: git add -A && git commit -m 'sync: update ECC submodule'"
