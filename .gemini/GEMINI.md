# ECC-RSK for Gemini CLI

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## Overview

ECC-RSK 提供 22 个 specialized agents、21 个 skills、~61 个 commands，聚焦全栈 Web 开发。

## Core Workflow

1. Plan before editing large features.
2. Prefer test-first changes for bug fixes and new functionality.
3. Review for security before shipping.
4. Keep changes self-contained, readable, and easy to revert.

## Coding Standards

- TypeScript strict mode
- Prefer immutable updates over in-place mutation
- Keep functions small and files focused
- Validate user input at boundaries (Zod schemas)
- Never hardcode secrets
- Fail loudly with clear error messages

## Security Checklist（CRITICAL）

Before any commit:

- **所有 Supabase 表启用 RLS**
- **Server Action 用 Zod 校验输入**
- **Server Action 校验授权**
- **Service Role Key 不暴露给 Client**
- **Edge Functions 校验 JWT**
- **`NEXT_PUBLIC_*` 仅用于公开信息**
- No hardcoded API keys, passwords, or tokens
- Parameterized queries for database writes
- Sanitized HTML output where applicable

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

## ECC-RSK Areas To Reuse

- `AGENTS.md` for repo-wide operating rules
- `CLAUDE.md` for Claude Code specific guidance
- `skills/` for deep workflow guidance
- `commands/` for slash-command patterns
- `rules/` for always-on coding rules
- `mcp-configs/` for shared connector baselines

## New ECC-RSK Components

### Agents（5 新增）

- `typescript-reviewer` — TypeScript 专项审查
- `supabase-reviewer` — Supabase 专项审查
- `nextjs-reviewer` — Next.js App Router 专项审查
- `vercel-deployer` — Vercel 部署配置
- `fullstack-architect` — 全栈架构设计

### Skills（7 新增）

- `supabase-patterns` — RLS、Auth、Realtime、Storage
- `nextjs-app-router` — RSC 边界、Server Actions、缓存
- `vercel-deployment` — 部署模式、环境变量
- `fullstack-auth` — PKCE、会话管理、RBAC
- `realtime-sync` — Realtime 订阅、乐观更新
- `type-safe-stack` — 端到端类型安全
- `form-patterns` — React Hook Form + Zod

### Commands（6 新增）

- `/supabase-review` — Supabase 代码审查
- `/supabase-migrate` — 数据库迁移工作流
- `/nextjs-review` — Next.js App Router 审查
- `/vercel-deploy` — Vercel 部署
- `/fullstack-init` — 全栈项目脚手架
- `/typecheck-e2e` — 端到端类型安全检查

## Recommended Workflow

1. **Start with planning**: Use `/plan` command to break down complex features
2. **Write tests first**: Invoke `/tdd` command before implementing
3. **Review your code**: Use `/code-review` after writing code
4. **Check security**: Use `/supabase-review` for Supabase code, `/nextjs-review` for Next.js code
5. **Fix build errors**: Use `/build-fix` if there are build errors