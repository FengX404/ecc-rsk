# OpenCode ECC-RSK Plugin

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## Installation

### Option 1: npm Package

```bash
npm install ecc-rsk
```

Add to your `opencode.json`:

```json
{
  "plugin": ["ecc-rsk"]
}
```

### Option 2: Direct Use

Clone and run OpenCode in the repository:

```bash
git clone https://github.com/your-org/ecc-rsk
cd ecc-rsk
opencode
```

## Features

### Agents（16）

| Agent | Description |
|-------|-------------|
| build | Primary coding agent for full-stack development |
| planner | Implementation planning |
| architect | System design and scalability |
| code-reviewer | General code review |
| react-reviewer | React/JSX specialist |
| typescript-reviewer | TypeScript specialist |
| supabase-reviewer | Supabase specialist |
| nextjs-reviewer | Next.js App Router specialist |
| security-reviewer | Security analysis |
| tdd-guide | Test-driven development |
| build-error-resolver | Build error fixes |
| e2e-runner | E2E testing with Playwright |
| doc-updater | Documentation |
| refactor-cleaner | Dead code cleanup |
| database-reviewer | PostgreSQL/Supabase optimization |
| docs-lookup | Documentation lookup via Context7 |

### Commands（18）

| Command | Description |
|---------|-------------|
| `/plan` | Create implementation plan |
| `/tdd` | TDD workflow |
| `/code-review` | Review code changes |
| `/react-review` | React/JSX review |
| `/typescript-review` | TypeScript review |
| `/supabase-review` | Supabase review |
| `/nextjs-review` | Next.js App Router review |
| `/security` | Security review |
| `/build-fix` | Fix build errors |
| `/e2e` | E2E tests |
| `/refactor-clean` | Remove dead code |
| `/update-docs` | Update docs |
| `/test-coverage` | Coverage analysis |
| `/supabase-migrate` | Database migration |
| `/vercel-deploy` | Vercel deployment |
| `/fullstack-init` | Initialize full-stack project |
| `/typecheck-e2e` | End-to-end type safety |
| `/learn` | Extract patterns |

### Skills（15）

Loaded by default:
- supabase-patterns
- nextjs-app-router
- vercel-deployment
- fullstack-auth
- realtime-sync
- type-safe-stack
- form-patterns
- api-design
- tdd-workflow
- security-review
- e2e-testing
- verification-loop

## Security Checklist

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

## License

MIT