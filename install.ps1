# ECC-RSK Installation Script for Windows
# Requires PowerShell 5.1+ or PowerShell Core 7+

param(
  [switch]$UseJunction,
  [switch]$UseCopy
)

$ErrorActionPreference = "Stop"

Write-Host "=== ECC-RSK Installation ===" -ForegroundColor Cyan

# 检查 submodule 是否已初始化
if (-not (Test-Path "ecc")) {
  Write-Host "Initializing ECC submodule..." -ForegroundColor Yellow
  git submodule init
  git submodule update
}

# 创建目录结构
# 注意：scripts\lib 不在此处创建，因为后续会作为 symlink/junction 整体创建
$directories = @(
  "agents", "skills", "commands", "rules", "hooks", "contexts", "schemas",
  "scripts", "mcp-configs", "templates\nextjs-supabase", "docs",
  ".claude\rules", ".cursor\rules", ".github\workflows",
  "rules\nextjs", "rules\supabase", "rules\vercel",
  "skills\supabase-patterns", "skills\nextjs-app-router", "skills\vercel-deployment",
  "skills\fullstack-auth", "skills\realtime-sync", "skills\type-safe-stack", "skills\form-patterns"
)

foreach ($dir in $directories) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

Write-Host "Creating symlinks..." -ForegroundColor Yellow

# 选择 symlink 方式
if ($UseCopy) {
  # 全部使用复制（最安全，但需要手动同步）
  Write-Host "Using copy mode (manual sync required)..." -ForegroundColor Yellow

  # 复制 agents
  $agents = @("planner", "architect", "code-architect", "code-explorer", "code-reviewer",
              "code-simplifier", "comment-analyzer", "doc-updater", "docs-lookup", "e2e-runner",
              "pr-test-analyzer", "refactor-cleaner", "spec-miner", "tdd-guide",
              "a11y-architect", "seo-specialist", "react-reviewer")
  foreach ($agent in $agents) {
    Copy-Item -Path "ecc\agents\$agent.md" -Destination "agents\$agent.md" -Force
  }

  # 复制 skills 目录
  $skills = @("api-design", "blueprint", "browser-qa", "code-tour", "council",
              "gateguard", "repo-scan", "seo", "taste", "ui-demo",
              "github-ops", "benchmark", "config-gc", "agent-sort")
  foreach ($skill in $skills) {
    Copy-Item -Path "ecc\skills\$skill" -Destination "skills\$skill" -Force -Recurse
  }

  # 复制 commands
  $commands = @("plan", "plan-prd", "feature-dev", "code-review", "build-fix",
                "test-coverage", "refactor-clean", "update-docs", "security-scan", "quality-gate",
                "project-init", "pr", "review-pr", "react-build", "react-review", "react-test",
                "checkpoint", "save-session", "resume-session", "sessions", "aside",
                "learn", "learn-eval", "evolve", "skill-create", "skill-health",
                "prp-commit", "prp-implement", "prp-plan", "prp-pr", "prp-prd",
                "epic-claim", "epic-decompose", "epic-publish", "epic-review", "epic-sync",
                "epic-unblock", "epic-validate", "multi-plan", "multi-execute", "multi-frontend",
                "multi-backend", "multi-workflow", "auto-update", "prune", "promote",
                "model-route", "cost-report", "harness-audit", "hookify", "hookify-list",
                "hookify-help", "setup-pm", "projects")
  foreach ($cmd in $commands) {
    Copy-Item -Path "ecc\commands\$cmd.md" -Destination "commands\$cmd.md" -Force
  }

  # 复制 rules 目录
  $rules = @("common", "react", "typescript", "web", "nuxt")
  foreach ($rule in $rules) {
    Copy-Item -Path "ecc\rules\$rule" -Destination "rules\$rule" -Force -Recurse
  }

  # 复制其他文件
  Copy-Item -Path "ecc\hooks\hooks.json" -Destination "hooks\hooks.json" -Force
  Copy-Item -Path "ecc\contexts\dev.md" -Destination "contexts\dev.md" -Force
  Copy-Item -Path "ecc\contexts\research.md" -Destination "contexts\research.md" -Force
  Copy-Item -Path "ecc\contexts\review.md" -Destination "contexts\review.md" -Force
  Copy-Item -Path "ecc\schemas\hooks.schema.json" -Destination "schemas\hooks.schema.json" -Force
  Copy-Item -Path "ecc\schemas\plugin.schema.json" -Destination "schemas\plugin.schema.json" -Force
  Copy-Item -Path "ecc\scripts\lib" -Destination "scripts\lib" -Force -Recurse
  Copy-Item -Path "ecc\mcp-configs\supabase.json" -Destination "mcp-configs\supabase.json" -Force
  Copy-Item -Path "ecc\mcp-configs\context7.json" -Destination "mcp-configs\context7.json" -Force
  Copy-Item -Path "ecc\mcp-configs\playwright.json" -Destination "mcp-configs\playwright.json" -Force
  Copy-Item -Path "ecc\LICENSE" -Destination "LICENSE" -Force

} else {
  # 默认：尝试 symlink（需要开发者模式或管理员权限）
  Write-Host "Attempting symlink (requires Developer Mode or Admin)..." -ForegroundColor Yellow
  Write-Host "If symlink fails, use -UseCopy flag: .\install.ps1 -UseCopy" -ForegroundColor Gray

  try {
    # 文件 symlink
    $agents = @("planner", "architect", "code-architect", "code-explorer", "code-reviewer",
                "code-simplifier", "comment-analyzer", "doc-updater", "docs-lookup", "e2e-runner",
                "pr-test-analyzer", "refactor-cleaner", "spec-miner", "tdd-guide",
                "a11y-architect", "seo-specialist", "react-reviewer")
    foreach ($agent in $agents) {
      New-Item -ItemType SymbolicLink -Path "agents\$agent.md" -Target "ecc\agents\$agent.md" -Force | Out-Null
    }

    # 目录 symlink
    $skills = @("api-design", "blueprint", "browser-qa", "code-tour", "council",
                "gateguard", "repo-scan", "seo", "taste", "ui-demo",
                "github-ops", "benchmark", "config-gc", "agent-sort")
    foreach ($skill in $skills) {
      New-Item -ItemType SymbolicLink -Path "skills\$skill" -Target "ecc\skills\$skill" -Force | Out-Null
    }

    # Commands symlink
    $commands = @("plan", "plan-prd", "feature-dev", "code-review", "build-fix",
                  "test-coverage", "refactor-clean", "update-docs", "security-scan", "quality-gate",
                  "project-init", "pr", "review-pr", "react-build", "react-review", "react-test",
                  "checkpoint", "save-session", "resume-session", "sessions", "aside",
                  "learn", "learn-eval", "evolve", "skill-create", "skill-health",
                  "prp-commit", "prp-implement", "prp-plan", "prp-pr", "prp-prd",
                  "epic-claim", "epic-decompose", "epic-publish", "epic-review", "epic-sync",
                  "epic-unblock", "epic-validate", "multi-plan", "multi-execute", "multi-frontend",
                  "multi-backend", "multi-workflow", "auto-update", "prune", "promote",
                  "model-route", "cost-report", "harness-audit", "hookify", "hookify-list",
                  "hookify-help", "setup-pm", "projects")
    foreach ($cmd in $commands) {
      New-Item -ItemType SymbolicLink -Path "commands\$cmd.md" -Target "ecc\commands\$cmd.md" -Force | Out-Null
    }

    # Rules symlink
    $rules = @("common", "react", "typescript", "web", "nuxt")
    foreach ($rule in $rules) {
      New-Item -ItemType SymbolicLink -Path "rules\$rule" -Target "ecc\rules\$rule" -Force | Out-Null
    }

    # 其他 symlink
    New-Item -ItemType SymbolicLink -Path "hooks\hooks.json" -Target "ecc\hooks\hooks.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "contexts\dev.md" -Target "ecc\contexts\dev.md" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "contexts\research.md" -Target "ecc\contexts\research.md" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "contexts\review.md" -Target "ecc\contexts\review.md" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "schemas\hooks.schema.json" -Target "ecc\schemas\hooks.schema.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "schemas\plugin.schema.json" -Target "ecc\schemas\plugin.schema.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "scripts\lib" -Target "ecc\scripts\lib" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "mcp-configs\supabase.json" -Target "ecc\mcp-configs\supabase.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "mcp-configs\context7.json" -Target "ecc\mcp-configs\context7.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "mcp-configs\playwright.json" -Target "ecc\mcp-configs\playwright.json" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "LICENSE" -Target "ecc\LICENSE" -Force | Out-Null

    Write-Host "✓ Symlinks created successfully." -ForegroundColor Green
  } catch {
    Write-Host "Symlink failed. Use -UseCopy flag." -ForegroundColor Red
    Write-Host "Example: .\install.ps1 -UseCopy" -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "Installation complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Write new agents/skills/commands/rules"
Write-Host "  2. Write README.md, AGENTS.md, CLAUDE.md"
Write-Host "  3. Write templates\nextjs-supabase\"
Write-Host "  4. Commit and push"