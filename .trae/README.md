# ECC-RSK for Trae

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## Quick Start

### Option 1: Local Installation (Current Project Only)

```bash
# Install to current project
cd /path/to/your/project
TRAE_ENV=cn .trae/install.sh
```

This creates `.trae-cn/` in your project directory.

### Option 2: Global Installation (All Projects)

```bash
# Install globally to ~/.trae-cn/
cd /path/to/your/project
TRAE_ENV=cn .trae/install.sh ~
```

## What's Included

### Commands（~61）

Commands are on-demand workflows invocable via the `/` menu in Trae chat.

**复用 ECC（~55）**：
- `/plan`、`/code-review`、`/build-fix`、`/test-coverage`、`/refactor-clean`
- `/react-build`、`/react-review`、`/react-test`
- `/learn`、`/skill-create`、`/pr`、`/review-pr`
- `/tdd`、`/security`、`/e2e`、`/update-docs`

**ECC-RSK 新增（6）**：
- `/supabase-review` — Supabase 代码审查
- `/supabase-migrate` — 数据库迁移工作流
- `/nextjs-review` — Next.js App Router 审查
- `/vercel-deploy` — Vercel 部署
- `/fullstack-init` — 全栈项目脚手架
- `/typecheck-e2e` — 端到端类型安全检查

### Agents（22）

**复用 ECC（17）**：
- planner、architect、code-architect、code-explorer、code-reviewer
- react-reviewer、tdd-guide、e2e-runner、refactor-cleaner、doc-updater
- spec-miner、a11y-architect、seo-specialist、code-simplifier
- comment-analyzer、docs-lookup、pr-test-analyzer

**ECC-RSK 新增（5）**：
- typescript-reviewer — TypeScript 专项审查
- supabase-reviewer — Supabase 专项审查
- nextjs-reviewer — Next.js App Router 专项审查
- vercel-deployer — Vercel 部署配置
- fullstack-architect — 全栈架构设计

### Skills（21）

**复用 ECC（14）**：
- api-design、blueprint、browser-qa、council、gateguard
- repo-scan、seo、taste、ui-demo、github-ops
- benchmark、config-gc、agent-sort、code-tour

**ECC-RSK 新增（7）**：
- supabase-patterns — RLS、Auth、Realtime、Storage、Edge Functions
- nextjs-app-router — RSC 边界、Server Actions、缓存、Metadata
- vercel-deployment — 部署模式、环境变量、运行时选择
- fullstack-auth — PKCE、会话管理、RBAC、多租户
- realtime-sync — Realtime 订阅、乐观更新、冲突解决
- type-safe-stack — 端到端类型安全流
- form-patterns — React Hook Form + Zod + Server Actions

### Rules（8 套）

**复用 ECC（5 套）**：
- rules/common/ — 通用规则
- rules/react/ — React 规则
- rules/typescript/ — TypeScript 规则
- rules/web/ — Web 规则
- rules/nuxt/ — Nuxt 规则（可选）

**ECC-RSK 新增（3 套）**：
- rules/nextjs/ — App Router 模式/安全/测试/性能
- rules/supabase/ — RLS/Auth/Realtime/Storage/Edge Functions
- rules/vercel/ — 部署配置/环境变量/性能

## Security Checklist（CRITICAL）

Before any commit:

- **所有 Supabase 表启用 RLS**
- **Server Action 用 Zod 校验输入**
- **Server Action 校验授权**
- **Service Role Key 不暴露给 Client**
- **Edge Functions 校验 JWT**
- **`NEXT_PUBLIC_*` 仅用于公开信息**

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Next.js 15 (App Router) |
| UI | React 19 + Tailwind CSS + shadcn/ui |
| State | TanStack Query + Zustand |
| Form | React Hook Form + Zod |
| Backend | Supabase |
| Testing | Vitest + Playwright |
| Types | TypeScript strict |

## Recommended Workflow

1. **Start with planning**: Use `/plan` command to break down complex features
2. **Write tests first**: Invoke `/tdd` command before implementing
3. **Review your code**: Use `/code-review` after writing code
4. **Check security**: Use `/supabase-review` for Supabase code, `/nextjs-review` for Next.js code
5. **Fix build errors**: Use `/build-fix` if there are build errors

## Uninstall

```bash
# Uninstall from current directory
cd .trae-cn
./uninstall.sh

# Or uninstall from project root
TRAE_ENV=cn .trae/uninstall.sh
```