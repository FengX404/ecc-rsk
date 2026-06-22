#Requires -Version 5.1

<#
.SYNOPSIS
    ECC-RSK Installation Script for Windows
.DESCRIPTION
    Reads symlink-manifest.json to create symlinks (or copies) from ECC submodule.
.PARAMETER SymlinksOnly
    Only recreate symlinks, skip mkdir.
.PARAMETER Verify
    Verify all symlinks resolve correctly, then exit.
.PARAMETER UseCopy
    Copy files instead of creating symlinks (no admin/DevMode required).
    Run this again after ECC submodule updates to resync.
.EXAMPLE
    .\install.ps1
    .\install.ps1 -UseCopy
    .\install.ps1 -Verify
    .\install.ps1 -SymlinksOnly
#>

param(
    [switch]$SymlinksOnly,
    [switch]$Verify,
    [switch]$UseCopy,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Write-Usage {
    Write-Host "Usage: .\install.ps1 [-SymlinksOnly] [-Verify] [-UseCopy]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -SymlinksOnly   Only recreate symlinks, skip mkdir"
    Write-Host "  -Verify         Verify all symlinks resolve correctly"
    Write-Host "  -UseCopy        Copy files instead of symlinks (no admin required)"
    Write-Host "  -Help           Show this help"
    exit 0
}

if ($Help) { Write-Usage }

$Manifest = "symlink-manifest.json"

# Check manifest exists
if (-not (Test-Path $Manifest)) {
    Write-Host "Error: $Manifest not found in current directory." -ForegroundColor Red
    Write-Host "This script must be run from the ecc-rsk project root."
    exit 1
}

# Load manifest
$manifest = Get-Content $Manifest -Raw | ConvertFrom-Json

# Verify mode
if ($Verify) {
    Write-Host "=== ECC-RSK Symlink Verification ===" -ForegroundColor Cyan
    Write-Host ""

    # Find broken symlinks (junctions/symlinks pointing to non-existent targets)
    $dirs = @("agents", "skills", "commands", "rules", "hooks", "contexts", "schemas")
    $broken = @()
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -Force | Where-Object {
            $_.LinkType -and -not (Test-Path $_.Target -ErrorAction SilentlyContinue)
        } | ForEach-Object { $broken += $_.FullName }
    }

    if ($broken.Count -gt 0) {
        Write-Host "Broken symlinks:" -ForegroundColor Red
        $broken | ForEach-Object { Write-Host "  $_" }
        exit 1
    }

    # Count expected vs actual
    $expected  = @($manifest.agents).Count
    $expected += @($manifest.skills).Count
    $expected += @($manifest.commands).Count
    $expected += @($manifest.rules).Count
    $expected += @($manifest.misc_files).Count
    $expected += @($manifest.misc_dirs).Count

    $actual = 0
    foreach ($dir in ($dirs + @("scripts/lib"))) {
        if (Test-Path $dir) {
            $actual += @(Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.LinkType }).Count
        }
    }

    Write-Host "Manifest entries: $expected, actual links: $actual"
    Write-Host "All links resolve correctly." -ForegroundColor Green
    exit 0
}

Write-Host "=== ECC-RSK Installation ===" -ForegroundColor Cyan
Write-Host ""

# Check submodule
if (-not (Test-Path "ecc")) {
    Write-Host "Initializing ECC submodule..." -ForegroundColor Yellow
    git submodule init
    git submodule update
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to initialize ECC submodule." -ForegroundColor Red
        exit 1
    }
}

# Create directory structure
if (-not $SymlinksOnly) {
    Write-Host "Creating directory structure..."
    $dirsToCreate = @(
        "agents", "skills", "commands", "rules", "hooks", "contexts", "schemas",
        "scripts", "mcp-configs", "templates", "docs",
        ".claude/rules", ".cursor/rules", ".github/workflows",
        "rules/nextjs", "rules/supabase", "rules/vercel",
        "skills/supabase-patterns", "skills/nextjs-app-router",
        "skills/vercel-deployment", "skills/fullstack-auth",
        "skills/realtime-sync", "skills/type-safe-stack", "skills/form-patterns"
    )
    foreach ($dir in $dirsToCreate) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

Write-Host "Creating links from $Manifest..." -ForegroundColor Cyan
Write-Host ""

$created = 0
$failed  = 0

function New-Link {
    param(
        [string]$Category,   # agents, skills, commands, rules
        [string]$EccDir,     # ../ecc/agents, ../ecc/skills, etc.
        [string]$Name        # planner.md, api-design, etc.
    )

    $eccSource  = Join-Path "ecc" ($EccDir -replace '^\.\.\\?/?ecc\\?/?', '')
    $sourcePath = Join-Path $eccSource $Name
    $linkPath   = Join-Path $Category $Name

    if (Test-Path $sourcePath) {
        if ($UseCopy) {
            if (Test-Path $linkPath) { Remove-Item $linkPath -Force -Recurse }
            if ((Get-Item $sourcePath).PSIsContainer) {
                Copy-Item -Path $sourcePath -Destination $linkPath -Recurse -Force
            } else {
                Copy-Item -Path $sourcePath -Destination $linkPath -Force
            }
        } else {
            # Try symlink (requires DevMode or admin)
            try {
                if (Test-Path $linkPath) { Remove-Item $linkPath -Force -Recurse }
                if ((Get-Item $sourcePath).PSIsContainer) {
                    New-Item -ItemType Junction -Path $linkPath -Target (Resolve-Path $sourcePath) -Force | Out-Null
                } else {
                    New-Item -ItemType SymbolicLink -Path $linkPath -Target (Resolve-Path $sourcePath) -Force | Out-Null
                }
            } catch {
                Write-Host "  Symlink failed for $linkPath — falling back to copy." -ForegroundColor Yellow
                if (Test-Path $linkPath) { Remove-Item $linkPath -Force -Recurse -ErrorAction SilentlyContinue }
                if ((Get-Item $sourcePath).PSIsContainer) {
                    Copy-Item -Path $sourcePath -Destination $linkPath -Recurse -Force
                } else {
                    Copy-Item -Path $sourcePath -Destination $linkPath -Force
                }
            }
        }
        $script:created++
    } else {
        Write-Host "  WARNING: source not found: $sourcePath -> skipping $linkPath" -ForegroundColor Yellow
        $script:failed++
    }
}

# --- Agents ---
foreach ($agent in $manifest.agents) {
    New-Link -Category "agents" -EccDir "../ecc/agents" -Name $agent
}

# --- Skills (directories) ---
foreach ($skill in $manifest.skills) {
    New-Link -Category "skills" -EccDir "../ecc/skills" -Name $skill
}

# --- Commands ---
foreach ($cmd in $manifest.commands) {
    New-Link -Category "commands" -EccDir "../ecc/commands" -Name $cmd
}

# --- Rules (directories) ---
foreach ($rule in $manifest.rules) {
    New-Link -Category "rules" -EccDir "../ecc/rules" -Name $rule
}

# --- Misc files ---
foreach ($item in $manifest.misc_files) {
    $sourcePath = $item.target
    $linkPath   = $item.link

    if (Test-Path $sourcePath) {
        if ($UseCopy) {
            if (Test-Path $linkPath) { Remove-Item $linkPath -Force }
            Copy-Item -Path $sourcePath -Destination $linkPath -Force
        } else {
            try {
                if (Test-Path $linkPath) { Remove-Item $linkPath -Force }
                New-Item -ItemType SymbolicLink -Path $linkPath -Target (Resolve-Path $sourcePath) -Force | Out-Null
            } catch {
                Write-Host "  Symlink failed for $linkPath — falling back to copy." -ForegroundColor Yellow
                Copy-Item -Path $sourcePath -Destination $linkPath -Force
            }
        }
        $created++
    } else {
        Write-Host "  WARNING: source not found: $sourcePath -> skipping $linkPath" -ForegroundColor Yellow
        $failed++
    }
}

# --- Misc dirs ---
foreach ($item in $manifest.misc_dirs) {
    $sourcePath = $item.target
    $linkPath   = $item.link

    if (Test-Path $sourcePath) {
        if ($UseCopy) {
            if (Test-Path $linkPath) { Remove-Item $linkPath -Force -Recurse }
            Copy-Item -Path $sourcePath -Destination $linkPath -Recurse -Force
        } else {
            try {
                if (Test-Path $linkPath) { Remove-Item $linkPath -Force -Recurse }
                New-Item -ItemType Junction -Path $linkPath -Target (Resolve-Path $sourcePath) -Force | Out-Null
            } catch {
                Write-Host "  Symlink failed for $linkPath — falling back to copy." -ForegroundColor Yellow
                Copy-Item -Path $sourcePath -Destination $linkPath -Recurse -Force
            }
        }
        $created++
    } else {
        Write-Host "  WARNING: source not found: $sourcePath -> skipping $linkPath" -ForegroundColor Yellow
        $failed++
    }
}

Write-Host ""
$modeLabel = if ($UseCopy) { "copies" } else { "symlinks" }
Write-Host "Links ($modeLabel): $created created, $failed skipped (source not found)" -ForegroundColor $(if ($failed -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($failed -gt 0) {
    Write-Host "WARNING: $failed link(s) were skipped because ECC source files were not found." -ForegroundColor Yellow
    Write-Host "This may happen if ECC submodule is not fully initialized."
    Write-Host "Run: git submodule update --init --recursive"
    Write-Host ""
}

Write-Host "✓ Installation complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Verify: .\install.ps1 -Verify"
if ($UseCopy) {
    Write-Host "  2. After ECC updates: git submodule update --remote ecc; .\install.ps1 -UseCopy"
} else {
    Write-Host "  2. Commit any new links: git add agents/ skills/ commands/ rules/"
}
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