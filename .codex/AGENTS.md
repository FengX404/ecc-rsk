# ECC-RSK for Codex CLI

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## Model Recommendations

| Task Type | Recommended Model |
|-----------|------------------|
| Routine coding, tests, formatting | GPT 5.5 |
| Complex features, architecture | GPT 5.5 |
| Debugging, refactoring | GPT 5.5 |
| Security review | GPT 5.5 |

## Skills Discovery

Skills are auto-loaded from `.agents/skills/`. ECC-RSK 提供以下 skills：

### 复用 ECC（14 个）

- api-design — REST API 设计模式
- blueprint — 项目蓝图生成
- browser-qa — 浏览器 QA 测试
- council — 多角色评审
- gateguard — 安全门禁检查
- repo-scan — 仓库扫描分析
- seo — SEO 优化
- taste — 设计品味检查
- ui-demo — UI 演示生成
- github-ops — GitHub 操作
- benchmark — 性能基准测试
- config-gc — 配置清理
- agent-sort — Agent 分类
- code-tour — 代码导览

### ECC-RSK 新增（7 个）

- supabase-patterns — RLS、Auth、Realtime、Storage、Edge Functions
- nextjs-app-router — RSC 边界、Server Actions、缓存、Metadata
- vercel-deployment — 部署模式、环境变量、运行时选择
- fullstack-auth — PKCE、会话管理、RBAC、多租户
- realtime-sync — Realtime 订阅、乐观更新、冲突解决
- type-safe-stack — 端到端类型安全流
- form-patterns — React Hook Form + Zod + Server Actions

## MCP Servers

ECC-RSK 使用以下 MCP servers（继承 ECC）：

- GitHub — `@modelcontextprotocol/server-github`
- Context7 — `@upstash/context7-mcp`
- Playwright — `@playwright/mcp`
- Memory — `@modelcontextprotocol/server-memory`
- Supabase — `supabase-mcp-server`（可选）

## Key Differences from ECC

| Feature | ECC | ECC-RSK |
|---------|-----|---------|
| Agents | 36 | 22（17 复用 + 5 新增） |
| Skills | 142 | 21（14 复用 + 7 新增） |
| Commands | 68 | ~61（~55 复用 + 6 新增） |
| Rules | 5 套 | 8 套（5 复用 + 3 新增） |
| Tech Stack | 全栈 + 多语言 | React + Next.js + Supabase + Vercel |

## Security Without Hooks

Since Codex lacks hooks, security enforcement is instruction-based:

1. **所有 Supabase 表必须启用 RLS**
2. **Server Action 必须用 Zod 校验输入**
3. **Server Action 必须校验授权**
4. **Service Role Key 永不暴露给 Client**
5. **Edge Functions 必须校验 JWT**
6. **`NEXT_PUBLIC_*` 仅用于公开信息**

## Multi-Agent Support

Codex multi-agent roles for ECC-RSK:

```toml
[agents.explorer]
description = "Read-only codebase explorer for gathering evidence before changes are proposed."
config_file = "agents/explorer.toml"

[agents.reviewer]
description = "PR reviewer focused on correctness, security, and missing tests."
config_file = "agents/reviewer.toml"

[agents.typescript_reviewer]
description = "TypeScript specialist reviewing for `any` abuse, async correctness, and strict mode compliance."
config_file = "agents/typescript-reviewer.toml"

[agents.supabase_reviewer]
description = "Supabase specialist reviewing RLS, SQL injection, Auth, and Edge Functions."
config_file = "agents/supabase-reviewer.toml"

[agents.nextjs_reviewer]
description = "Next.js App Router specialist reviewing RSC boundaries, Server Actions, and caching."
config_file = "agents/nextjs-reviewer.toml"
```