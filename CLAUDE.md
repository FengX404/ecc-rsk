# ECC-RSK — Claude Code 指南

本文件为 Claude Code 提供 ECC-RSK 的使用指南。

---

## 项目概述

ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase 技术栈。

**架构**：Git Submodule + Symlink
- `ecc/` 目录是 ECC submodule
- 复用内容通过 symlink 指向 `ecc/`
- 新增内容本地维护

---

## 技术栈约定

ECC-RSK 所有内容基于以下技术栈：

| 层 | 技术 | 版本 |
|---|---|---|
| 框架 | Next.js (App Router) | ≥ 15 |
| UI | React | ≥ 19 |
| 样式 | Tailwind CSS + shadcn/ui | latest |
| 状态 | TanStack Query + Zustand | latest |
| 表单 | React Hook Form + Zod | latest |
| 后端 | Supabase | latest |
| 测试 | Vitest + Playwright | latest |
| 类型 | TypeScript strict | ≥ 5.4 |
| 部署 | Vercel | latest |

> **部署层扩展点**：当前仅支持 Vercel。未来扩展为 `deployment/{vercel,railway,cloudflare}` 时，现有 `vercel-deployer` / `rules/vercel/` / `commands/vercel-deploy` 将迁移至该结构。

---

## 核心原则

继承 ECC 核心原则，并补充全栈特定约定：

1. **Agent-First** — 委托给 specialized agents
2. **Test-Driven** — 测试优先，覆盖率 ≥ 80%
3. **Security-First** — RLS 必备、Server Action 输入校验、环境变量安全
4. **Type-Safe** — 端到端类型安全（PostgreSQL → Zod → Server Action → React）
5. **Immutability** — 永不突变现有对象

---

## 可用 Agents

### 复用 ECC（17 个）

- `planner`、`architect`、`code-architect`、`code-explorer`、`code-reviewer`
- `react-reviewer`、`tdd-guide`、`e2e-runner`、`refactor-cleaner`、`doc-updater`
- `spec-miner`、`a11y-architect`、`seo-specialist`、`code-simplifier`
- `comment-analyzer`、`docs-lookup`、`pr-test-analyzer`

### ECC-RSK 新增（8 个）

- `typescript-reviewer` — TypeScript 专项审查
- `supabase-reviewer` — Supabase 专项审查
- `nextjs-reviewer` — Next.js App Router 专项审查
- `vercel-deployer` — Vercel 部署配置
- `fullstack-architect` — 全栈架构设计
- `ux-reviewer` — 体验专项审查（交互完整性、视觉一致性、微交互）
- `feature-reviewer` — 功能完整性审查（需求覆盖、竞品对标、A/B 实验）
- `observability-reviewer` — 可观测性审查（错误监控、日志链路、告警）

---

## 可用 Commands

### 复用 ECC（34 个）

- `/plan`、`/code-review`、`/build-fix`、`/test-coverage`、`/refactor-clean`
- `/react-build`、`/react-review`、`/react-test`
- `/learn`、`/pr`、`/review-pr`
- `/prp-*` 系列、`/epic-*` 系列、`/multi-*` 系列

### ECC-RSK 新增（6 个）

- `/supabase-review` — Supabase 代码审查
- `/supabase-migrate` — 数据库迁移工作流
- `/nextjs-review` — Next.js App Router 审查
- `/vercel-deploy` — Vercel 部署
- `/fullstack-init` — 全栈项目脚手架
- `/typecheck-e2e` — 端到端类型安全检查

---

## 可用 Skills

### 薄路由机制

ECC-RSK 提供**薄路由机制**，AI 助手据此自动激活对应 skill：

- [SKILL.md](SKILL.md) — Skills 索引入口（21 个 skills）
- [SKILL-ROUTES.md](SKILL-ROUTES.md) — 路由规则（文件类型/意图/阶段 → skill 映射）

**路由流程**：用户请求 → 查阅 SKILL-ROUTES.md → 激活对应 `skills/<name>/SKILL.md`

### 复用 ECC（14 个）

- `api-design`、`blueprint`、`browser-qa`、`council`、`gateguard`
- `repo-scan`、`seo`、`taste`、`ui-demo`、`github-ops`
- `benchmark`、`config-gc`、`agent-sort`、`code-tour`

### ECC-RSK 新增（8 个）

- `supabase-patterns` — RLS、Auth、Realtime、Storage、Edge Functions
- `nextjs-app-router` — RSC 边界、Server Actions、缓存、Metadata
- `vercel-deployment` — 部署模式、环境变量、运行时选择
- `fullstack-auth` — PKCE、会话管理、RBAC、多租户
- `realtime-sync` — Realtime 订阅、乐观更新、冲突解决
- `type-safe-stack` — 端到端类型安全流
- `form-patterns` — React Hook Form + Zod + Server Actions
- `multi-angle-review` — 多角度审查系统（功能/质量/体验/工程四维迭代）

---

## 可用 Rules

### 复用 ECC（5 套）

- `rules/common/` — 通用 agents/hooks/patterns/security/testing
- `rules/react/` — React 编码风格/hooks/模式/安全/测试
- `rules/typescript/` — TypeScript hooks
- `rules/web/` — Web 编码风格/hooks/模式/性能/安全/测试
- `rules/nuxt/` — Nuxt 规则（可选）

### ECC-RSK 新增（3 套）

- `rules/nextjs/` — App Router 模式/安全/测试/性能
- `rules/supabase/` — RLS/Auth/Realtime/Storage/Edge Functions
- `rules/vercel/` — 部署配置/环境变量/性能

---

## Rule vs Skill 边界

ECC-RSK 中 Rule 与 Skill 有明确职责划分，避免内容重复：

| 层 | 职责 | 内容形式 | 触发方式 |
|---|---|---|---|
| **Rule** | 约束 / 禁止 / 必须做 | 清单式条目（"必须做" / "禁止做"） | 始终生效（always-applied） |
| **Skill** | 工作流 / 案例 / 步骤 | 完整代码示例、决策矩阵、流程 | 按需激活（when-to-activate） |

### 划分原则

- **Rule 回答**："做这件事时，什么是必须做的？什么是禁止做的？"
- **Skill 回答**："如何完成这件事？给我看代码示例和决策流程。"

### 示例

| 主题 | Rule 内容 | Skill 内容 |
|---|---|---|
| Server Actions | "必须用 Zod 校验输入"、"禁止返回 Date 对象" | 完整的 Server Action 实现代码、`useActionState` 集成示例 |
| RLS | "所有表必须启用 RLS"、"禁止用动态 SQL" | RLS 策略模板代码（行级所有权、多租户、公开读私有写） |
| 环境变量 | "`NEXT_PUBLIC_*` 仅用于公开信息"、"禁止硬编码密钥" | `vercel env add` 工作流、分层配置示例 |

### 引用约定

- Rule 文件开头注明："代码示例与工作流见 [skills/xxx/SKILL.md]"
- Skill 文件开头注明："约束规则见 [rules/xxx/patterns.md]"

---

## 安全约定

### Supabase 安全（CRITICAL）

- **所有表必须启用 RLS**
- **Server Action 必须校验输入**（Zod schema）
- **Server Action 必须校验授权**
- **Service Role Key 永不暴露给 Client**
- **Edge Functions 必须校验 JWT**

### Next.js 安全（CRITICAL）

- **`NEXT_PUBLIC_*` 仅用于公开信息**
- **Client Component 不导入 `"server-only"` 模块**
- **Server Action 不返回非可序列化值**

---

## 测试约定

- 单元测试：Vitest（工具函数、hooks）
- 组件测试：Vitest + Testing Library
- E2E 测试：Playwright（关键用户流程）
- 覆盖率：≥ 80%

---

## 项目模板

`templates/nextjs-supabase/` 提供脚手架：

- Next.js 15 App Router
- Supabase Auth (PKCE) + Middleware
- Tailwind CSS + shadcn/ui
- TanStack Query + Zustand
- Vitest + Playwright
- GitHub Actions CI
- Vercel 部署配置

使用 `/fullstack-init` 生成新项目。

---

## 与 ECC 同步

```bash
# 更新 ECC submodule
git submodule update --remote ecc

# 检查变更
cd ecc && git log --oneline HEAD@{1}..HEAD && cd ..

# 如有新增文件，重新运行安装脚本
./install.sh

# 提交
git add ecc && git commit -m "sync: update ECC submodule"
```

---

## 文档

- [SKILL.md](SKILL.md) — Skills 索引入口
- [SKILL-ROUTES.md](SKILL-ROUTES.md) — Skills 路由规则
- [docs/ECC-RSK-PROPOSAL.md](docs/ECC-RSK-PROPOSAL.md) — 完整组合方案
- [AGENTS.md](AGENTS.md) — Agent 索引与编排规则