# ECC-RSK for CodeBuddy

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## Quick Start

### Option 1: Local Installation (Current Project Only)

```bash
# Install to current project
cd /path/to/your/project
.codebuddy/install.sh
```

### Option 2: Global Installation (All Projects)

```bash
# Install globally to ~/.codebuddy/
cd /path/to/your/project
.codebuddy/install.sh ~
```

## What's Included

### Commands（~61）

Commands are on-demand workflows invocable via the `/` menu in CodeBuddy chat.

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

**复用 ECC（17）**：planner、architect、code-reviewer、react-reviewer、tdd-guide 等

**ECC-RSK 新增（5）**：
- typescript-reviewer — TypeScript 专项审查
- supabase-reviewer — Supabase 专项审查
- nextjs-reviewer — Next.js App Router 专项审查
- vercel-deployer — Vercel 部署配置
- fullstack-architect — 全栈架构设计

### Skills（21）

**复用 ECC（14）**：api-design、blueprint、browser-qa 等

**ECC-RSK 新增（7）**：supabase-patterns、nextjs-app-router、vercel-deployment 等

### Rules（8 套）

**复用 ECC（5 套）**：common、react、typescript、web、nuxt

**ECC-RSK 新增（3 套）**：nextjs、supabase、vercel

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

1. **Start with planning**: Use `/plan` command
2. **Write tests first**: Invoke `/tdd` command
3. **Review your code**: Use `/code-review`
4. **Check security**: Use `/supabase-review` or `/nextjs-review`
5. **Fix build errors**: Use `/build-fix`

## Uninstall

```bash
cd .codebuddy
./uninstall.sh
```