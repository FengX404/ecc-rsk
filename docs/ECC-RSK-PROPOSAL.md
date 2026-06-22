# ECC-RSK — ECC-React-Stack-Kit

> **ECC-RSK** 是从 [Everything Claude Code (ECC)](../README.md) 扩展而来的全栈开发专项插件包，聚焦 **React + Next.js + Vercel + Supabase** 技术栈，为 AI 编程助手（Claude Code、Cursor、Codex、Gemini 等）提供面向现代全栈 Web 开发的 agents、skills、commands、rules、hooks 与项目模板。

| | |
|---|---|
| **全名** | ECC-React-Stack-Kit (ECC-RSK) |
| **定位** | ECC 的全栈 Web 开发子集 + Supabase/Next.js/Vercel 专项扩展 |
| **技术栈** | React · Next.js (App Router) · Vercel · Supabase · TypeScript · Tailwind CSS · shadcn/ui · TanStack Query · Zustand · React Hook Form · Zod · Vitest · Playwright |
| **与 ECC 的关系** | 子集复用 + 专项扩展；可独立使用，也可作为 ECC 的补充包 |
| **License** | MIT |

---

## 目录

- [1. 项目定位](#1-项目定位)
- [2. 技术栈约定](#2-技术栈约定)
- [3. 从 ECC 筛选的子集](#3-从-ecc-筛选的子集)
  - [3.1 Agents（17 个）](#31-agents17-个)
  - [3.2 Skills（14 个）](#32-skills14-个)
  - [3.3 Commands（约 40 个）](#33-commands约-40-个)
  - [3.4 Rules（5 套）](#34-rules5-套)
  - [3.5 其他复用项](#35-其他复用项)
- [4. 新增内容（专项扩展）](#4-新增内容专项扩展)
  - [4.1 新 Agents（5 个）](#41-new-agents5-个)
  - [4.2 新 Skills（7 个）](#42-new-skills7-个)
  - [4.3 新 Commands（6 个）](#43-new-commands6-个)
  - [4.4 新 Rules（3 套）](#44-new-rules3-套)
- [5. 项目结构](#5-项目结构)
- [6. 项目模板（脚手架）](#6-项目模板脚手架)
- [7. 实施路线图](#7-实施路线图)
- [8. 与 ECC 的同步策略](#8-与-ecc-的同步策略)
- [9. 排除清单](#9-排除清单)

---

## 1. 项目定位

ECC 是一个跨语言、跨 harness 的通用 AI 编程操作系统，覆盖 12+ 语言生态。ECC-RSK 在此基础上做**减法与加法**：

- **减法**：剥离所有非 Web 全栈的语言生态（C/C++、Go、Rust、Java、Kotlin、Swift、Flutter、PHP、Python、Django、FastAPI、C#、F#、Ruby、Perl、Vue、Angular、ArkTS、Dart）。
- **加法**：补充 Supabase、Next.js App Router、Vercel 部署的专项 agents/skills/commands/rules，覆盖 RLS 安全、RSC 边界、Server Actions、Edge Functions、端到端类型安全等 ECC 未深入的领域。

**适用场景**：使用 AI 编程助手开发 React + Next.js + Supabase 全栈应用的个人开发者与团队。

---

## 2. 技术栈约定

ECC-RSK 的所有 agents/skills/commands/rules 基于以下技术栈约定编写。项目模板也按此约定生成。

### 2.1 核心技术栈

| 层 | 技术 | 版本建议 | 选型理由 |
|---|---|---|---|
| 语言 | TypeScript (strict) | ≥ 5.4 | 端到端类型安全基础 |
| 框架 | Next.js (App Router) | ≥ 15 | RSC、Server Actions、Streaming、Metadata |
| 运行时 | Node.js / Vercel Edge | ≥ 20 (Node) | 双运行时支持 |
| UI 库 | React | ≥ 19 | `useActionState`、`useFormStatus`、ref as prop |
| 样式 | Tailwind CSS | ≥ 3.4 | 原子化 CSS，与 shadcn/ui 配合 |
| 组件库 | shadcn/ui | latest | 可定制、无运行时依赖、类型安全 |
| 后端 | Supabase | latest | PostgreSQL + Auth + Realtime + Storage + Edge Functions |
| 数据库 | PostgreSQL (via Supabase) | ≥ 15 | RLS、类型生成 |

### 2.2 状态与数据

| 层 | 技术 | 用途 |
|---|---|---|
| 服务器状态 | TanStack Query (React Query) | 数据缓存、mutations、乐观更新、轮询 |
| 客户端状态 | Zustand | 高频 UI 状态、跨组件共享 |
| 表单状态 | React Hook Form | 高性能表单、非受控优先 |
| 表单校验 | Zod | schema 校验、类型推导 |
| URL 状态 | Next.js `searchParams` + `nuqs` | 可分享、可书签的状态 |

**状态位置决策树**（继承 ECC `rules/react/patterns.md` 并扩展）：

1. 单组件使用 → `useState`
2. 父子共享 → lift to nearest ancestor
3. 跨分支低频读取 → React Context（theme、auth、locale）
4. 高频更新跨树 → Zustand
5. 服务器数据 → TanStack Query（**不**放入应用状态）
6. URL 可分享状态 → `nuqs` / `searchParams`

### 2.3 认证与安全

| 层 | 技术 | 约定 |
|---|---|---|
| 认证 | Supabase Auth (PKCE flow) | httpOnly cookie、SSR 友好 |
| 会话管理 | Next.js Middleware + Supabase SSR | 每路由刷新会话 |
| 授权 | PostgreSQL RLS + Server Action 校验 | 数据库层 + 应用层双重校验 |
| 密钥管理 | Vercel Environment Variables + Supabase Vault | 永不硬编码、永不暴露给 Client |

### 2.4 测试

| 类型 | 工具 | 覆盖目标 |
|---|---|---|
| 单元测试 | Vitest | 工具函数、hooks、纯逻辑 |
| 组件测试 | Vitest + Testing Library | 组件交互、渲染、可访问性 |
| E2E 测试 | Playwright | 关键用户流程 |
| 视觉回归 | Playwright snapshots（可选） | UI 回归 |
| 类型测试 | `expect-type` / `tsc --noEmit` | 类型契约 |

**覆盖率目标**：≥ 80%（继承 ECC 约定）。

### 2.5 部署与运维

| 层 | 技术 |
|---|---|
| 前端部署 | Vercel（Next.js 原生集成） |
| 后端部署 | Supabase（托管 PostgreSQL + Auth + Edge Functions） |
| CI/CD | GitHub Actions |
| 监控 | Vercel Analytics + Speed Insights |
| 错误追踪 | Sentry |
| 类型生成 | `supabase gen types`（CI 中自动运行） |

### 2.6 可选扩展

| 能力 | 技术 | 何时引入 |
|---|---|---|
| 国际化 | next-intl | 多语言需求 |
| PWA | next-pwa | 离线访问需求 |
| 支付 | Stripe + Supabase Edge Functions | 商业化需求 |
| 邮件 | Resend / Supabase Edge Functions | 事务邮件 |
| 搜索 | Supabase Full-Text Search / Algolia | 全文搜索需求 |
| 分析 | PostHog / Vercel Analytics | 产品分析 |

---

## 3. 从 ECC 筛选的子集

以下内容从 ECC 仓库直接复用，保持文件内容与格式不变。

### 3.1 Agents（17 个）

| Agent | 文件 | 职责 | 保留理由 |
|---|---|---|---|
| `planner` | `agents/planner.md` | 复杂功能实现规划 | 全栈开发核心工作流 |
| `architect` | `agents/architect.md` | 系统设计与可扩展性 | 架构决策 |
| `code-architect` | `agents/code-architect.md` | 代码架构设计 | 模块设计 |
| `code-explorer` | `agents/code-explorer.md` | 代码库探索 | 理解现有代码 |
| `code-reviewer` | `agents/code-reviewer.md` | 通用代码质量审查 | 代码质量保障 |
| `react-reviewer` | `agents/react-reviewer.md` | React/JSX 专项审查 | **全栈核心** |
| `tdd-guide` | `agents/tdd-guide.md` | 测试驱动开发 | 新功能、Bug 修复 |
| `e2e-runner` | `agents/e2e-runner.md` | Playwright E2E 测试 | 关键流程验证 |
| `refactor-cleaner` | `agents/refactor-cleaner.md` | 死代码清理、重构 | 代码维护 |
| `doc-updater` | `agents/doc-updater.md` | 文档与 codemap 更新 | 文档同步 |
| `spec-miner` | `agents/spec-miner.md` | 棕地项目规范挖掘 | 现有项目接入 |
| `a11y-architect` | `agents/a11y-architect.md` | 无障碍设计 | Web 必备 |
| `seo-specialist` | `agents/seo-specialist.md` | SEO 优化 | Next.js 必备 |
| `code-simplifier` | `agents/code-simplifier.md` | 代码简化 | 降低复杂度 |
| `comment-analyzer` | `agents/comment-analyzer.md` | 注释质量分析 | 文档质量 |
| `docs-lookup` | `agents/docs-lookup.md` | 文档查询（Context7） | API 文档查询 |
| `pr-test-analyzer` | `agents/pr-test-analyzer.md` | PR 测试覆盖分析 | PR 质量保障 |

### 3.2 Skills（14 个）

| Skill | 目录 | 用途 |
|---|---|---|
| `api-design` | `skills/api-design/` | REST API 设计模式（资源命名、状态码、分页、错误格式、版本化、限流） |
| `blueprint` | `skills/blueprint/` | 多 PR 工程蓝图生成（多 session、多 agent 协作） |
| `browser-qa` | `skills/browser-qa/` | 浏览器 QA 工作流 |
| `code-tour` | `skills/code-tour/` | 代码导览生成 |
| `council` | `skills/council/` | 多 agent 评审会议 |
| `gateguard` | `skills/gateguard/` | 质量门禁 |
| `repo-scan` | `skills/repo-scan/` | 仓库扫描与分析 |
| `seo` | `skills/seo/` | SEO 工作流 |
| `taste` | `skills/taste/` | 设计品味与 UI 质量 |
| `ui-demo` | `skills/ui-demo/` | UI 演示生成 |
| `github-ops` | `skills/github-ops/` | GitHub 操作（PR、Issue、Release） |
| `benchmark` | `skills/benchmark/` | 性能基准测试 |
| `config-gc` | `skills/config-gc/` | 配置垃圾回收 |
| `agent-sort` | `skills/agent-sort/` | Agent 治理与排序 |

### 3.3 Commands（约 40 个）

#### 全栈开发核心（13 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/plan` | `commands/plan.md` | 实现规划 |
| `/plan-prd` | `commands/plan-prd.md` | PRD 驱动规划 |
| `/feature-dev` | `commands/feature-dev.md` | 功能开发工作流 |
| `/code-review` | `commands/code-review.md` | 代码质量审查 |
| `/build-fix` | `commands/build-fix.md` | 构建错误修复 |
| `/test-coverage` | `commands/test-coverage.md` | 测试覆盖率 |
| `/refactor-clean` | `commands/refactor-clean.md` | 重构清理 |
| `/update-docs` | `commands/update-docs.md` | 文档更新 |
| `/security-scan` | `commands/security-scan.md` | 安全扫描 |
| `/quality-gate` | `commands/quality-gate.md` | 质量门禁 |
| `/project-init` | `commands/project-init.md` | 项目初始化 |
| `/pr` | `commands/pr.md` | PR 创建 |
| `/review-pr` | `commands/review-pr.md` | PR 审查 |

#### React 专项（3 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/react-build` | `commands/react-build.md` | React 构建修复 |
| `/react-review` | `commands/react-review.md` | React 代码审查 |
| `/react-test` | `commands/react-test.md` | React 测试 |

#### 会话与记忆（5 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/checkpoint` | `commands/checkpoint.md` | 检查点保存 |
| `/save-session` | `commands/save-session.md` | 会话保存 |
| `/resume-session` | `commands/resume-session.md` | 会话恢复 |
| `/sessions` | `commands/sessions.md` | 会话列表 |
| `/aside` | `commands/aside.md` | 旁路任务 |

#### 学习与演进（5 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/learn` | `commands/learn.md` | 会话模式提取 |
| `/learn-eval` | `commands/learn-eval.md` | 学习评估 |
| `/evolve` | `commands/evolve.md` | 能力演进 |
| `/skill-create` | `commands/skill-create.md` | Skill 生成 |
| `/skill-health` | `commands/skill-health.md` | Skill 健康检查 |

#### PR 与史诗（13 个）

| 命令组 | 文件 | 用途 |
|---|---|---|
| `/prp-*` 系列（5 个） | `commands/prp-*.md` | PRP 工作流（commit/implement/plan/pr/prd） |
| `/epic-*` 系列（8 个） | `commands/epic-*.md` | Epic 工作流（claim/decompose/publish/review/sync/unblock/validate） |

#### 多 Agent 协作（5 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/multi-plan` | `commands/multi-plan.md` | 多 agent 规划 |
| `/multi-execute` | `commands/multi-execute.md` | 多 agent 执行 |
| `/multi-frontend` | `commands/multi-frontend.md` | 前端多 agent |
| `/multi-backend` | `commands/multi-backend.md` | 后端多 agent（重定义为 Supabase 后端） |
| `/multi-workflow` | `commands/multi-workflow.md` | 多 agent 工作流 |

#### 运维与治理（约 10 个）

| 命令 | 文件 | 用途 |
|---|---|---|
| `/auto-update` | `commands/auto-update.md` | 自动更新 |
| `/prune` | `commands/prune.md` | 清理 |
| `/promote` | `commands/promote.md` | 提升 |
| `/model-route` | `commands/model-route.md` | 模型路由 |
| `/cost-report` | `commands/cost-report.md` | 成本报告 |
| `/harness-audit` | `commands/harness-audit.md` | Harness 审计 |
| `/hookify` | `commands/hookify.md` | Hook 生成 |
| `/hookify-list` | `commands/hookify-list.md` | Hook 列表 |
| `/hookify-help` | `commands/hookify-help.md` | Hook 帮助 |
| `/setup-pm` | `commands/setup-pm.md` | 包管理器设置 |
| `/projects` | `commands/projects.md` | 项目管理 |

### 3.4 Rules（5 套）

| 规则集 | 目录 | 内容 |
|---|---|---|
| `common/` | `rules/common/` | 通用 agents、hooks、patterns、security、testing |
| `react/` | `rules/react/` | React coding-style、hooks、patterns、security、testing |
| `typescript/` | `rules/typescript/` | TypeScript hooks |
| `web/` | `rules/web/` | Web coding-style、hooks、patterns、performance、security、testing |
| `nuxt/` | `rules/nuxt/` | Nuxt 规则（可选，若需 Nuxt 支持） |

### 3.5 其他复用项

| 项 | 来源 | 用途 |
|---|---|---|
| `hooks/hooks.json` | ECC | 通用自动化 hooks |
| `contexts/dev.md` | ECC | 开发上下文 |
| `contexts/research.md` | ECC | 研究上下文 |
| `contexts/review.md` | ECC | 审查上下文 |
| `schemas/hooks.schema.json` | ECC | Hook JSON schema |
| `schemas/plugin.schema.json` | ECC | Plugin JSON schema |
| `scripts/lib/utils.js` | ECC | 通用工具函数 |
| `scripts/lib/path-safety.js` | ECC | 路径安全 |
| `scripts/lib/shell-split.js` | ECC | Shell 命令拆分 |
| `scripts/lib/hook-flags.js` | ECC | Hook 标志 |
| `scripts/lib/inspection.js` | ECC | 代码检查 |
| `scripts/lib/mcp-config.js` | ECC | MCP 配置 |
| `mcp-configs/` | ECC 精选 | Supabase、Context7、Playwright 等 MCP 配置 |

---

## 4. 新增内容（专项扩展）

以下内容为 ECC-RSK 新增，补充 Supabase / Next.js App Router / Vercel 部署的专项能力。

### 4.1 新 Agents（5 个）

#### `agents/supabase-reviewer.md`

**职责**：Supabase 专项代码审查。

**审查优先级**：

| 级别 | 审查项 |
|---|---|
| CRITICAL | RLS 策略缺失或过于宽松（`USING (true)`）、SQL 注入（字符串拼接）、Edge Functions 未校验 JWT、Service Role Key 泄露到 Client、Storage 桶未设为 Private |
| CRITICAL | Auth 策略：未启用 PKCE、会话存储在 localStorage、未刷新会话 |
| HIGH | 索引缺失（外键、常用查询条件）、N+1 查询、未使用 `select()` 投影、`count()` 性能问题 |
| HIGH | Realtime 订阅未清理、订阅频道泄漏、未限流 |
| HIGH | Edge Functions：未处理 OPTIONS/CORS、未限流、同步阻塞、未使用 Deno.serve |
| MEDIUM | 迁移文件命名不规范、未使用事务、种子数据混入迁移 |
| MEDIUM | Storage：未限制文件类型/大小、未生成缩略图、未使用签名 URL |

**诊断命令**：
```bash
supabase db lint
supabase functions deploy --dry-run
psql -c "EXPLAIN ANALYZE ..."
```

**与 `database-reviewer` 的边界**：`database-reviewer` 负责通用 PostgreSQL；`supabase-reviewer` 负责 Supabase 特有能力（RLS、Auth、Realtime、Storage、Edge Functions）。

---

#### `agents/nextjs-reviewer.md`

**职责**：Next.js App Router 专项审查。

**审查优先级**：

| 级别 | 审查项 |
|---|---|
| CRITICAL | Server Action 未校验输入（无 Zod schema）、Server Action 未校验授权、`"use server"` 函数返回非可序列化值 |
| CRITICAL | Client Component 导入 `"server-only"` 模块、Service Role Key 通过 `NEXT_PUBLIC_*` 暴露 |
| HIGH | RSC 边界：不必要的 `"use client"`、Client Component 中调用服务端 SDK、Server Component 传递非可序列化 props 给 Client |
| HIGH | 缓存策略：`fetch` 未设置 `cache`/`revalidate`、`unstable_cache` key 不稳定、`revalidatePath`/`revalidateTag` 缺失 |
| HIGH | Metadata：`metadata` 在 Client Component 中、`generateMetadata` 中执行重计算、未使用 `templateString` 优化 |
| HIGH | Middleware：未排除静态资源、未处理 matcher、在 Middleware 中执行重计算 |
| MEDIUM | `loading.tsx`/`error.tsx` 缺失、Suspense 边界过粗、未使用 Streaming |
| MEDIUM | `next/image` 未使用、未设置 `priority`/`sizes`、`next/font` 未使用 |
| MEDIUM | Route Handler 未校验方法、未设置 CORS、未处理 OPTIONS |

**诊断命令**：
```bash
next build
next lint
npx @next/bundle-analyzer
```

**与 `react-reviewer` 的边界**：`react-reviewer` 负责 React 核心（hooks、JSX、可访问性）；`nextjs-reviewer` 负责 Next.js 框架特性（RSC、Server Actions、缓存、Middleware、Metadata）。

---

#### `agents/vercel-deployer.md`

**职责**：Vercel 部署配置与优化。

**审查与执行项**：

| 类别 | 项 |
|---|---|
| 部署配置 | `vercel.json` 配置审查、`regions` 选择、`functions` 内存/超时配置 |
| 环境变量 | 环境变量分层（Production/Preview/Development）、密钥轮换、`NEXT_PUBLIC_*` 审查 |
| 运行时 | Edge vs Node.js 运行时选择、`export const runtime = 'edge'` 审查、冷启动优化 |
| 渲染模式 | ISR/SSG/SSR 决策、`revalidate` 配置、`generateStaticParams` 使用 |
| 性能 | Bundle 分析、`next build` 输出解读、LCP/FCP/INP 优化、图片优化 |
| 监控 | Vercel Analytics 启用、Speed Insights、Web Vitals 上报、Sentry 集成 |
| 部署流 | Preview Deployment 审查、Promote to Production、Rollback 策略 |
| 域名 | 自定义域名、重定向规则、Headers 配置 |

**诊断命令**：
```bash
vercel inspect <deployment-url>
vercel logs <deployment-url>
npx @next/bundle-analyzer
```

---

#### `agents/fullstack-architect.md`

**职责**：React + Next.js + Supabase 整体架构设计。

**设计职责**：

| 领域 | 职责 |
|---|---|
| 数据流架构 | Server Component fetch → Client Component mutation → Server Action → revalidatePath → Realtime 订阅 |
| 认证流 | Supabase Auth PKCE → httpOnly cookie → Middleware 刷新 → Server Component 读取 → Client Component via SSR |
| 授权架构 | RLS 策略设计（行级、列级）+ Server Action 授权校验 + UI 条件渲染 |
| 类型安全流 | PostgreSQL schema → `supabase gen types` → Zod schema → Server Action 输入 → React props |
| 目录结构 | `app/` 路由组织、`lib/` 业务逻辑、`components/` UI、`supabase/` 迁移与函数 |
| 缓存架构 | `fetch` cache → `unstable_cache` → TanStack Query cache → Realtime invalidation |
| 实时架构 | Realtime 订阅 → 乐观更新 → 冲突解决 → 回滚 |
| 多租户 | schema 隔离 vs RLS 隔离决策、租户解析中间件 |

**输出**：架构决策记录（ADR）、数据流图、目录结构建议。

---

#### `agents/typescript-reviewer.md`

**职责**：TypeScript 专项审查（ECC 中被 `react-reviewer` 引用但未创建，ECC-RSK 补齐）。

**审查优先级**：

| 级别 | 审查项 |
|---|---|
| CRITICAL | `any` 滥用、`as` 断言绕过类型、`@ts-ignore`/`@ts-expect-error` 无理由 |
| CRITICAL | 严格模式未启用（`strict: false`）、`noUncheckedIndexedAccess` 未启用 |
| HIGH | Promise/async 正确性：floating promise、未处理的 rejection、`async` 函数无 `await` |
| HIGH | `null`/`undefined` 安全：可选链缺失、空值合并缺失、`non-null assertion` 滥用 |
| HIGH | Node.js 安全：`innerHTML`、`eval`、同步 fs、env 未校验 |
| MEDIUM | 泛型约束缺失、`unknown` 未收窄、`enum` vs union type |
| MEDIUM | 类型导入：`import type` 缺失、`verbatimModuleSyntax` 未启用 |

**诊断命令**：
```bash
tsc --noEmit
npx ts-prune
npx knip
```

### 4.2 新 Skills（7 个）

#### `skills/supabase-patterns/SKILL.md`

**内容大纲**：

1. **RLS 策略模板**
   - 行级所有权：`USING (auth.uid() = user_id)`
   - 多租户隔离：`USING (auth.uid() = ANY (tenant_members.user_ids)`
   - 公开读 / 私有写
   - 列级安全（Column-level Security）

2. **Auth 集成**
   - PKCE 流程（Next.js App Router）
   - Middleware 会话刷新
   - Server Component 读取会话
   - Client Component 订阅会话变化
   - OAuth Provider 配置（Google、GitHub、Apple）
   - Magic Link / OTP

3. **Realtime 订阅**
   - Postgres Changes（INSERT/UPDATE/DELETE）
   - Broadcast（客户端事件）
   - Presence（在线状态）
   - React 集成：订阅 → 清理 → 乐观更新

4. **Storage 上传**
   - 直传（Signed URL）
   - 服务端代传
   - 文件类型/大小限制
   - 缩略图生成
   - 私有文件访问（Signed URL）

5. **Edge Functions**
   - Deno 运行时约定
   - JWT 校验
   - CORS 处理
   - 限流
   - 与数据库交互（`supabase-js` service role）

6. **类型生成**
   - `supabase gen types --typescript`
   - CI 自动生成
   - 与 Zod schema 对齐

7. **迁移工作流**
   - `supabase migration new`
   - 命名约定（`YYYYMMDDHHMMSS_name.sql`）
   - 事务包裹
   - 回滚策略
   - 种子数据分离

---

#### `skills/nextjs-app-router/SKILL.md`

**内容大纲**：

1. **RSC / Client Component 边界**
   - 默认 Server Component
   - `"use client"` 最小化原则
   - 通过 `children` 传递 Server Component
   - `import "server-only"` 标记

2. **Server Actions**
   - `"use server"` 函数定义
   - 输入校验（Zod）
   - 授权校验
   - `revalidatePath` / `revalidateTag`
   - 错误处理与 `useActionState`
   - 渐进式增强（无 JS 也能工作）

3. **Route Handlers**
   - `app/api/*/route.ts`
   - 方法校验
   - CORS
   - 流式响应

4. **Middleware**
   - 会话刷新（Supabase）
   - 路由保护
   - matcher 配置
   - 避免重计算

5. **缓存策略**
   - `fetch` cache 选项
   - `unstable_cache`
   - `revalidate` / `revalidateTag` / `revalidatePath`
   - ISR vs SSR vs SSG 决策

6. **Streaming 与 Suspense**
   - `loading.tsx`
   - 嵌套 Suspense 边界
   - 渐进式渲染
   - Error Boundary 配对

7. **Metadata 与 SEO**
   - `metadata` 静态导出
   - `generateMetadata` 动态生成
   - `sitemap.ts` / `robots.ts`
   - Open Graph / Twitter Card
   - JSON-LD 结构化数据

8. **Parallel & Intercepting Routes**
   - 模态框（Intercepting）
   - 条件路由（Parallel）

9. **性能优化**
   - `next/image`
   - `next/font`
   - `next/script`
   - Bundle 分析
   - 动态导入

---

#### `skills/vercel-deployment/SKILL.md`

**内容大纲**：

1. **部署模式**
   - Preview Deployment
   - Production Deployment
   - Promote to Production
   - Rollback

2. **环境变量管理**
   - 分层：Production / Preview / Development
   - `NEXT_PUBLIC_*` 前缀约定
   - Vercel + Supabase 环境变量同步
   - 密钥轮换

3. **运行时选择**
   - Edge Runtime：低延迟、冷启动快、API 受限
   - Node.js Runtime：完整 API、冷启动慢
   - 决策矩阵

4. **渲染模式决策**
   - SSG：静态内容
   - SSR：个性化内容
   - ISR：周期性更新
   - Streaming：渐进式渲染

5. **`vercel.json` 配置**
   - `regions`
   - `functions`（内存、超时）
   - `redirects` / `rewrites` / `headers`
   - `cleanUrls`

6. **性能监控**
   - Vercel Analytics
   - Speed Insights
   - Web Vitals（LCP、FID、CLS、INP）
   - Sentry 集成

7. **域名与网络**
   - 自定义域名
   - DNS 配置
   - HTTPS 自动续期
   - 防火墙规则

8. **CI/CD 集成**
   - GitHub → Vercel 自动部署
   - 分支 → Preview Environment
   - 主分支 → Production
   - 环境变量按分支注入

---

#### `skills/fullstack-auth/SKILL.md`

**内容大纲**：

1. **认证流程（PKCE）**
   - Supabase Auth PKCE 配置
   - Next.js App Router 集成
   - `@supabase/ssr` 包使用
   - httpOnly cookie 设置

2. **会话管理**
   - Middleware 刷新会话
   - Server Component 读取会话
   - Client Component 订阅会话
   - 会话过期处理

3. **授权架构**
   - RLS 策略（数据库层）
   - Server Action 授权校验（应用层）
   - UI 条件渲染（展示层）
   - 三层防御

4. **OAuth 集成**
   - Google / GitHub / Apple
   - Provider 配置
   - 回调处理
   - 账号关联

5. **RBAC（基于角色的访问控制）**
   - 角色表设计
   - RLS 策略中的角色检查
   - Server Action 中的角色检查
   - UI 中的角色条件渲染

6. **多租户认证**
   - 租户解析（域名 / 子路径 / claim）
   - 租户隔离 RLS
   - 租户切换

7. **安全加固**
   - 密码策略
   - 2FA / TOTP
   - 会话撤销
   - 异常登录检测

8. **常见攻击防护**
   - CSRF（SameSite cookie）
   - XSS（CSP、httpOnly）
   - 会话固定
   - 暴力破解（限流）

---

#### `skills/realtime-sync/SKILL.md`

**内容大纲**：

1. **Realtime 订阅模式**
   - Postgres Changes 订阅
   - Broadcast（客户端事件）
   - Presence（在线状态）
   - 频道管理

2. **React 集成**
   - `useEffect` 订阅 + 清理
   - 自定义 hook：`useRealtime`
   - TanStack Query 与 Realtime 配合
   - 订阅去重

3. **乐观更新**
   - 立即更新 UI
   - 等待服务器确认
   - 冲突检测
   - 回滚策略

4. **冲突解决**
   - Last-Write-Wins
   - 版本号 / 时间戳
   - CRDT（简介）
   - 业务层合并

5. **性能优化**
   - 订阅粒度（列过滤、行过滤）
   - 节流 / 去抖
   - 批量更新
   - 连接复用

6. **离线支持**
   - 离线队列
   - 重连重放
   - 本地持久化（IndexedDB）

7. **典型场景**
   - 协同编辑
   - 实时评论
   - 通知系统
   - 在线状态
   - 实时仪表盘

---

#### `skills/type-safe-stack/SKILL.md`

**内容大纲**：

1. **端到端类型安全流**
   ```
   PostgreSQL schema
     → supabase gen types (Database type)
       → Zod schema (runtime validation)
         → Server Action input
           → React component props
   ```

2. **Supabase 类型生成**
   - `supabase gen types --typescript`
   - `types/supabase.ts` 生成与提交
   - CI 自动重新生成
   - 类型版本与迁移同步

3. **Zod schema 设计**
   - 从 Database 类型推导 Zod schema
   - `z.infer` 反向推导 TypeScript 类型
   - 输入 vs 输出类型分离
   - 嵌套对象、数组、枚举

4. **Server Action 类型安全**
   - 输入：Zod schema `safeParse`
   - 输出：可序列化类型
   - 错误类型：`ActionState<T>`
   - `useActionState` 集成

5. **TanStack Query 类型安全**
   - `queryKey` 类型化
   - `queryFn` 返回类型
   - `mutationFn` 输入/输出
   - 乐观更新类型

6. **React 组件 props 类型**
   - Server Component props（可序列化）
   - Client Component props
   - children 类型
   - 事件处理器类型

7. **类型测试**
   - `expect-type`
   - `tsc --noEmit`
   - 类型覆盖率

8. **常见陷阱**
   - `any` 渗透路径
   - `as` 断言风险
   - 可选 vs 可空
   - 联合类型收窄

---

#### `skills/form-patterns/SKILL.md`

**内容大纲**：

1. **React Hook Form + Zod**
   - `useForm` + `zodResolver`
   - 受控 vs 非受控
   - `Controller` 使用时机
   - 表单模式：登录、注册、编辑、向导

2. **Server Actions 表单**
   - `useActionState` + `useFormStatus`
   - 渐进式增强（无 JS 可用）
   - `formData` 解析
   - 字段级错误

3. **复杂表单**
   - 多步向导
   - 动态字段数组（`useFieldArray`）
   - 跨字段校验
   - 条件字段

4. **表单 UX**
   - 实时校验 vs 提交时校验
   - 错误展示位置
   - 加载状态
   - 成功/失败反馈
   - 自动保存

5. **可访问性**
   - `<label>` 关联
   - `aria-invalid` / `aria-describedby`
   - 错误公告（`aria-live`）
   - 键盘导航

6. **文件上传**
   - 单文件 / 多文件
   - 拖拽上传
   - 进度条
   - Supabase Storage 集成

7. **与 TanStack Query 配合**
   - 提交后 invalidate query
   - 乐观更新
   - 冲突处理

### 4.3 新 Commands（6 个）

#### `commands/supabase-review.md`

```
---
description: Supabase 专项代码审查（RLS、SQL 注入、Auth、Edge Functions、Realtime、Storage）。调用 supabase-reviewer agent。
---
```

**工作流**：
1. 检测 `supabase/` 目录与 `@supabase/ssr` / `@supabase/supabase-js` 依赖
2. 扫描 `.sql` 迁移文件（RLS 策略、索引）
3. 扫描 Edge Functions（`supabase/functions/`）
4. 扫描 Server Actions / Route Handlers 中的 Supabase 调用
5. 调用 `supabase-reviewer` agent 输出审查报告
6. 按严重级别分组（CRITICAL / HIGH / MEDIUM）

#### `commands/supabase-migrate.md`

```
---
description: Supabase 数据库迁移工作流（生成、应用、回滚、种子数据、类型重新生成）。
---
```

**工作流**：
1. `supabase migration new <name>`
2. 编写 SQL（事务包裹、RLS 策略、索引）
3. `supabase db lint`
4. `supabase migration up`（本地）
5. `supabase gen types --typescript > types/supabase.ts`
6. 运行测试验证
7. 提交迁移文件 + 类型文件

#### `commands/nextjs-review.md`

```
---
description: Next.js App Router 专项审查（RSC 边界、Server Actions、缓存、Middleware、Metadata）。调用 nextjs-reviewer agent。
---
```

**工作流**：
1. 检测 Next.js 版本与 App Router 使用
2. `next build` + `next lint`
3. 扫描 `"use client"` / `"use server"` 边界
4. 扫描 Server Actions 输入校验与授权
5. 扫描 `fetch` cache 配置
6. 扫描 Middleware matcher
7. 调用 `nextjs-reviewer` agent 输出报告

#### `commands/vercel-deploy.md`

```
---
description: Vercel 部署前检查与部署执行（环境变量、运行时、构建、Preview/Production）。
---
```

**工作流**：
1. 部署前检查：`vercel.json`、环境变量、`next build` 通过
2. 运行时审查：Edge vs Node 选择
3. Bundle 分析：`@next/bundle-analyzer`
4. Preview 部署：`vercel`
5. 审查 Preview URL
6. Promote to Production：`vercel --prod`
7. 部署后验证：Analytics、Web Vitals、Sentry

#### `commands/fullstack-init.md`

```
---
description: 全栈项目脚手架（Next.js + Supabase + Tailwind + shadcn/ui + TanStack Query + Zustand + React Hook Form + Zod + Vitest + Playwright）。
---
```

**工作流**：
1. `create-next-app@latest`（TypeScript、App Router、Tailwind、ESLint）
2. 初始化 shadcn/ui
3. 安装依赖：`@supabase/ssr` `@supabase/supabase-js` `@tanstack/react-query` `zustand` `react-hook-form` `@hookform/resolvers` `zod`
4. 安装测试依赖：`vitest` `@testing-library/react` `@playwright/test`
5. 配置 Supabase：`supabase init`、环境变量、`utils/supabase/server.ts` / `client.ts` / `middleware.ts`
6. 配置 TanStack Query：`QueryClientProvider`
7. 配置目录结构（见 [§6](#6-项目模板脚手架)）
8. 生成 `types/supabase.ts`
9. 配置 ESLint / Prettier / TypeScript strict
10. 配置 GitHub Actions CI
11. 配置 Vercel 项目

#### `commands/typecheck-e2e.md`

```
---
description: 端到端类型安全检查（PostgreSQL → Supabase 类型 → Zod schema → Server Action → React props）。
---
```

**工作流**：
1. 重新生成 Supabase 类型：`supabase gen types`
2. 检查 Zod schema 与 Database 类型对齐
3. 检查 Server Action 输入/输出类型
4. 检查 TanStack Query 类型
5. 检查 React 组件 props 类型
6. `tsc --noEmit` 全量检查
7. 报告类型断点（`any`、`as`、`@ts-ignore`）

### 4.4 新 Rules（3 套）

#### `rules/nextjs/`

| 文件 | 内容 |
|---|---|
| `patterns.md` | RSC 边界、Server Actions、Route Handlers、Middleware、Parallel/Intercepting Routes、Streaming、Metadata |
| `hooks.md` | Next.js 专用 hook 配置（`usePathname`、`useRouter`、`useSearchParams`、`useReportWebVitals`） |
| `security.md` | Server Action 输入校验、授权校验、`NEXT_PUBLIC_*` 审查、Middleware 安全、`headers()` / `cookies()` 安全 |
| `testing.md` | App Router 测试策略、Server Component 测试、Client Component 测试、Server Action 测试、Middleware 测试 |
| `performance.md` | `next/image`、`next/font`、`next/script`、Bundle 优化、缓存策略、Streaming |

#### `rules/supabase/`

| 文件 | 内容 |
|---|---|
| `patterns.md` | RLS 策略模板、Auth 集成、Realtime 订阅、Storage 上传、Edge Functions、类型生成、迁移工作流 |
| `hooks.md` | Supabase 专用 hook 配置（`useSupabase`、`useRealtime`、`useStorage`） |
| `security.md` | **RLS 必备**（所有表）、SQL 注入防护（参数化查询）、Service Role Key 隔离、Auth PKCE、Storage 桶权限、Edge Functions JWT 校验 |
| `testing.md` | RLS 策略测试、Auth 流测试、Realtime 测试、Storage 测试、Edge Functions 测试（Deno test） |

#### `rules/vercel/`

| 文件 | 内容 |
|---|---|
| `patterns.md` | 部署模式、环境变量分层、运行时选择、渲染模式决策、`vercel.json` 配置 |
| `hooks.md` | Vercel 专用 hook 配置（部署后通知、Preview 部署触发） |
| `security.md` | 环境变量安全、密钥轮换、Preview 环境隔离、防火墙规则 |
| `performance.md` | Edge Runtime 性能、Bundle 预算、Web Vitals 目标（LCP < 2.5s、INP < 200ms、CLS < 0.1）、Analytics 配置 |

---

## 5. 项目结构（Submodule + Symlink 架构）

ECC-RSK 采用 **Git Submodule + Symbolic Link** 架构，将 ECC 作为子模块引入，复用内容通过 symlink 指向 ECC，新增内容本地独立维护。

### 5.1 架构优势

| 优势 | 说明 |
|---|---|
| **上游同步** | `git submodule update --remote` 即可同步 ECC 最新内容，无需手动复制 |
| **清晰边界** | symlink 指向 ECC（复用），本地文件为新增，一目了然 |
| **维护成本低** | 只维护新增内容，复用部分由 ECC 上游维护 |
| **Git 历史清晰** | submodule 有独立的 commit 历史，便于追溯 |
| **贡献回流** | 新增内容 PR 到 ECC 时，submodule 机制不影响 |

### 5.2 目录结构

```
ecc-rsk/                          # ECC-RSK 仓库根目录
│
├── ecc/                          # Git submodule → ECC 仓库（完整内容）
│   └── (ECC 完整目录结构)
│
├── agents/                       # symlink（复用）+ 本地新增
│   ├── planner.md                # symlink → ../ecc/agents/planner.md
│   ├── architect.md              # symlink → ../ecc/agents/architect.md
│   ├── code-architect.md         # symlink → ../ecc/agents/code-architect.md
│   ├── code-explorer.md          # symlink → ../ecc/agents/code-explorer.md
│   ├── code-reviewer.md          # symlink → ../ecc/agents/code-reviewer.md
│   ├── code-simplifier.md        # symlink → ../ecc/agents/code-simplifier.md
│   ├── comment-analyzer.md       # symlink → ../ecc/agents/comment-analyzer.md
│   ├── doc-updater.md            # symlink → ../ecc/agents/doc-updater.md
│   ├── docs-lookup.md            # symlink → ../ecc/agents/docs-lookup.md
│   ├── e2e-runner.md             # symlink → ../ecc/agents/e2e-runner.md
│   ├── pr-test-analyzer.md       # symlink → ../ecc/agents/pr-test-analyzer.md
│   ├── refactor-cleaner.md       # symlink → ../ecc/agents/refactor-cleaner.md
│   ├── spec-miner.md             # symlink → ../ecc/agents/spec-miner.md
│   ├── tdd-guide.md              # symlink → ../ecc/agents/tdd-guide.md
│   ├── a11y-architect.md         # symlink → ../ecc/agents/a11y-architect.md
│   ├── seo-specialist.md         # symlink → ../ecc/agents/seo-specialist.md
│   ├── react-reviewer.md         # symlink → ../ecc/agents/react-reviewer.md
│   ├── typescript-reviewer.md    # [本地新增] 补齐 ECC 缺失
│   ├── supabase-reviewer.md      # [本地新增]
│   ├── nextjs-reviewer.md        # [本地新增]
│   ├── vercel-deployer.md        # [本地新增]
│   └── fullstack-architect.md    # [本地新增]
│
├── skills/                       # symlink（复用）+ 本地新增
│   ├── api-design                # symlink → ../ecc/skills/api-design
│   ├── blueprint                 # symlink → ../ecc/skills/blueprint
│   ├── browser-qa                # symlink → ../ecc/skills/browser-qa
│   ├── code-tour                 # symlink → ../ecc/skills/code-tour
│   ├── council                   # symlink → ../ecc/skills/council
│   ├── gateguard                 # symlink → ../ecc/skills/gateguard
│   ├── repo-scan                 # symlink → ../ecc/skills/repo-scan
│   ├── seo                       # symlink → ../ecc/skills/seo
│   ├── taste                     # symlink → ../ecc/skills/taste
│   ├── ui-demo                   # symlink → ../ecc/skills/ui-demo
│   ├── github-ops                # symlink → ../ecc/skills/github-ops
│   ├── benchmark                 # symlink → ../ecc/skills/benchmark
│   ├── config-gc                 # symlink → ../ecc/skills/config-gc
│   ├── agent-sort                # symlink → ../ecc/skills/agent-sort
│   ├── supabase-patterns         # [本地新增]
│   ├── nextjs-app-router         # [本地新增]
│   ├── vercel-deployment         # [本地新增]
│   ├── fullstack-auth            # [本地新增]
│   ├── realtime-sync             # [本地新增]
│   ├── type-safe-stack           # [本地新增]
│   └── form-patterns             # [本地新增]
│
├── commands/                     # symlink（复用）+ 本地新增
│   ├── plan.md                   # symlink → ../ecc/commands/plan.md
│   ├── plan-prd.md               # symlink → ../ecc/commands/plan-prd.md
│   ├── feature-dev.md            # symlink → ../ecc/commands/feature-dev.md
│   ├── code-review.md            # symlink → ../ecc/commands/code-review.md
│   ├── build-fix.md              # symlink → ../ecc/commands/build-fix.md
│   ├── test-coverage.md          # symlink → ../ecc/commands/test-coverage.md
│   ├── refactor-clean.md         # symlink → ../ecc/commands/refactor-clean.md
│   ├── update-docs.md            # symlink → ../ecc/commands/update-docs.md
│   ├── security-scan.md          # symlink → ../ecc/commands/security-scan.md
│   ├── quality-gate.md           # symlink → ../ecc/commands/quality-gate.md
│   ├── project-init.md           # symlink → ../ecc/commands/project-init.md
│   ├── pr.md                     # symlink → ../ecc/commands/pr.md
│   ├── review-pr.md              # symlink → ../ecc/commands/review-pr.md
│   ├── react-build.md            # symlink → ../ecc/commands/react-build.md
│   ├── react-review.md           # symlink → ../ecc/commands/react-review.md
│   ├── react-test.md             # symlink → ../ecc/commands/react-test.md
│   ├── checkpoint.md             # symlink → ../ecc/commands/checkpoint.md
│   ├── save-session.md           # symlink → ../ecc/commands/save-session.md
│   ├── resume-session.md         # symlink → ../ecc/commands/resume-session.md
│   ├── sessions.md               # symlink → ../ecc/commands/sessions.md
│   ├── aside.md                  # symlink → ../ecc/commands/aside.md
│   ├── learn.md                  # symlink → ../ecc/commands/learn.md
│   ├── learn-eval.md             # symlink → ../ecc/commands/learn-eval.md
│   ├── evolve.md                 # symlink → ../ecc/commands/evolve.md
│   ├── skill-create.md           # symlink → ../ecc/commands/skill-create.md
│   ├── skill-health.md           # symlink → ../ecc/commands/skill-health.md
│   ├── prp-commit.md             # symlink → ../ecc/commands/prp-commit.md
│   ├── prp-implement.md          # symlink → ../ecc/commands/prp-implement.md
│   ├── prp-plan.md               # symlink → ../ecc/commands/prp-plan.md
│   ├── prp-pr.md                 # symlink → ../ecc/commands/prp-pr.md
│   ├── prp-prd.md                # symlink → ../ecc/commands/prp-prd.md
│   ├── epic-claim.md             # symlink → ../ecc/commands/epic-claim.md
│   ├── epic-decompose.md         # symlink → ../ecc/commands/epic-decompose.md
│   ├── epic-publish.md           # symlink → ../ecc/commands/epic-publish.md
│   ├── epic-review.md            # symlink → ../ecc/commands/epic-review.md
│   ├── epic-sync.md              # symlink → ../ecc/commands/epic-sync.md
│   ├── epic-unblock.md           # symlink → ../ecc/commands/epic-unblock.md
│   ├── epic-validate.md          # symlink → ../ecc/commands/epic-validate.md
│   ├── multi-plan.md             # symlink → ../ecc/commands/multi-plan.md
│   ├── multi-execute.md          # symlink → ../ecc/commands/multi-execute.md
│   ├── multi-frontend.md         # symlink → ../ecc/commands/multi-frontend.md
│   ├── multi-backend.md          # symlink → ../ecc/commands/multi-backend.md
│   ├── multi-workflow.md         # symlink → ../ecc/commands/multi-workflow.md
│   ├── auto-update.md            # symlink → ../ecc/commands/auto-update.md
│   ├── prune.md                  # symlink → ../ecc/commands/prune.md
│   ├── promote.md                # symlink → ../ecc/commands/promote.md
│   ├── model-route.md            # symlink → ../ecc/commands/model-route.md
│   ├── cost-report.md            # symlink → ../ecc/commands/cost-report.md
│   ├── harness-audit.md          # symlink → ../ecc/commands/harness-audit.md
│   ├── hookify.md                # symlink → ../ecc/commands/hookify.md
│   ├── hookify-list.md           # symlink → ../ecc/commands/hookify-list.md
│   ├── hookify-help.md           # symlink → ../ecc/commands/hookify-help.md
│   ├── setup-pm.md               # symlink → ../ecc/commands/setup-pm.md
│   ├── projects.md               # symlink → ../ecc/commands/projects.md
│   ├── supabase-review.md        # [本地新增]
│   ├── supabase-migrate.md       # [本地新增]
│   ├── nextjs-review.md          # [本地新增]
│   ├── vercel-deploy.md          # [本地新增]
│   ├── fullstack-init.md         # [本地新增]
│   └── typecheck-e2e.md          # [本地新增]
│
├── rules/                        # symlink（复用）+ 本地新增
│   ├── common                    # symlink → ../ecc/rules/common
│   ├── react                     # symlink → ../ecc/rules/react
│   ├── typescript                # symlink → ../ecc/rules/typescript
│   ├── web                       # symlink → ../ecc/rules/web
│   ├── nuxt                      # symlink → ../ecc/rules/nuxt（可选）
│   ├── nextjs                    # [本地新增]
│   ├── supabase                  # [本地新增]
│   └── vercel                    # [本地新增]
│
├── hooks/
│   └── hooks.json                # symlink → ../ecc/hooks/hooks.json
│
├── contexts/                     # symlink → ../ecc/contexts
│   ├── dev.md                    # symlink
│   ├── research.md               # symlink
│   └── review.md                 # symlink
│
├── schemas/                      # symlink → ../ecc/schemas
│   ├── hooks.schema.json         # symlink
│   └── plugin.schema.json        # symlink
│
├── scripts/
│   └── lib                       # symlink → ../ecc/scripts/lib
│       ├── utils.js              # symlink
│       ├── path-safety.js        # symlink
│       ├── shell-split.js        # symlink
│       ├── hook-flags.js         # symlink
│       ├── inspection.js         # symlink
│       └── mcp-config.js         # symlink
│
├── mcp-configs/                  # symlink（精选）
│   ├── supabase.json             # symlink → ../ecc/mcp-configs/supabase.json
│   ├── context7.json             # symlink → ../ecc/mcp-configs/context7.json
│   ├── playwright.json           # symlink → ../ecc/mcp-configs/playwright.json
│   └── ...                       # symlink（其他精选）
│
├── templates/                    # [本地新增] 项目脚手架模板
│   └── nextjs-supabase/          # 默认全栈模板
│       ├── README.md             # 模板说明
│       └── ...                   # 见 §6
│
├── docs/                         # [本地新增]
│   ├── ECC-RSK-PROPOSAL.md       # 本文档
│   ├── TECH-STACK.md             # 技术栈约定详解
│   └── MIGRATION-FROM-ECC.md     # 从 ECC 迁移指南
│
├── .claude/                      # [本地新增]（harness 配置不能 symlink）
│   └── rules/
│       └── node.md               # 本地（继承 ECC，裁剪）
│
├── .cursor/                      # [本地新增]（harness 配置）
│   ├── hooks.json
│   └── rules/
│
├── .github/                      # [本地新增]
│   ├── workflows/
│   │   ├── ci.yml                # lint + typecheck + test
│   │   └── sync-ecc.yml          # 同步 ECC submodule
│   └── CODEOWNERS
│
├── AGENTS.md                     # [本地新增]（基于 ECC裁剪）
├── CLAUDE.md                     # [本地新增]（基于 ECC裁剪）
├── CONTRIBUTING.md               # [本地新增]
├── README.md                     # [本地新增]
├── README.zh-CN.md               # [本地新增]
├── LICENSE                       # symlink → ecc/LICENSE
├── VERSION                       # [本地新增]
├── .gitmodules                   # Git submodule 配置
├── install.sh                    # [本地新增] macOS/Linux 安装脚本
└── install.ps1                   # [本地新增] Windows 安装脚本
```

### 5.3 Symlink vs 本地文件的决策

| 内容 | symlink | 本地文件 | 理由 |
|---|---|---|---|
| agents/skills/commands/rules（复用） | ✓ | | 保持上游同步 |
| harness 配置（`.claude/`、`.cursor/`等） | | ✓ | 需要裁剪 + 本地修改，harness 会修改这些文件 |
| 新增内容 | | ✓ | 本地独立维护 |
| LICENSE | ✓ | | 保持上游一致 |

### 5.4 Git Submodule 配置

`.gitmodules`:
```
[submodule "ecc"]
	path = ecc
	url = https://github.com/affaan-m/ECC.git
	branch = main
```

---

## 6. 项目模板（脚手架）

`templates/nextjs-supabase/` 是 `/fullstack-init` 命令生成的默认项目结构。**模板仅提供脚手架文件，不含完整示例业务逻辑。**

### 6.1 模板目录结构

```
templates/nextjs-supabase/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── register/
│   │   │   └── page.tsx
│   │   └── callback/
│   │       └── route.ts        # OAuth 回调
│   ├── (protected)/
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   └── layout.tsx          # 受保护路由布局
│   ├── api/
│   │   └── */route.ts          # Route Handlers
│   ├── layout.tsx              # 根布局（含 QueryClientProvider）
│   ├── page.tsx                # 首页
│   ├── loading.tsx
│   ├── error.tsx
│   ├── not-found.tsx
│   ├── globals.css
│   ├── sitemap.ts
│   └── robots.ts
│
├── components/
│   ├── ui/                     # shadcn/ui 组件
│   ├── providers/
│   │   ├── query-provider.tsx  # TanStack Query Provider
│   │   └── theme-provider.tsx
│   └── shared/                 # 共享组件
│
├── lib/
│   ├── supabase/
│   │   ├── client.ts           # 浏览器端 client
│   │   ├── server.ts           # 服务端 client
│   │   ├── middleware.ts       # 会话刷新 middleware
│   │   └── admin.ts            # Service Role client（仅服务端）
│   ├── utils.ts                # 通用工具
│   ├── validations/            # Zod schema
│   │   └── *.ts
│   └── actions/                # Server Actions
│       └── *.ts
│
├── hooks/
│   ├── use-realtime.ts         # Realtime 订阅 hook
│   ├── use-user.ts             # 当前用户 hook
│   └── ...
│
├── stores/
│   └── *.ts                    # Zustand stores
│
├── types/
│   ├── supabase.ts             # [自动生成] supabase gen types
│   └── index.ts                # 公共类型
│
├── supabase/
│   ├── migrations/             # SQL 迁移文件
│   ├── functions/              # Edge Functions
│   ├── seed.sql                # 种子数据
│   └── config.toml             # Supabase 配置
│
├── tests/
│   ├── unit/                   # Vitest 单元测试
│   ├── component/              # Testing Library 组件测试
│   └── e2e/                    # Playwright E2E 测试
│
├── public/
│   └── ...
│
├── .github/
│   └── workflows/
│       ├── ci.yml              # lint + typecheck + test
│       └── deploy.yml          # Vercel 部署
│
├── .env.example                # 环境变量示例
├── middleware.ts               # Next.js Middleware（会话刷新）
├── next.config.mjs
├── tailwind.config.ts
├── tsconfig.json               # strict + noUncheckedIndexedAccess
├── vitest.config.ts
├── playwright.config.ts
├── components.json             # shadcn/ui 配置
├── package.json
├── README.md                   # 模板使用说明
└── .gitignore
```

### 6.2 模板关键配置约定

#### `tsconfig.json`

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "paths": {
      "@/*": ["./*"]
    }
  }
}
```

#### `.env.example`

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # 仅服务端，永不暴露

# Vercel
VERCEL_URL=your-vercel-url

# Sentry（可选）
SENTRY_DSN=your-sentry-dsn
```

#### `package.json` scripts

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest",
    "test:run": "vitest run",
    "test:e2e": "playwright test",
    "test:coverage": "vitest run --coverage",
    "db:gen-types": "supabase gen types --typescript > types/supabase.ts",
    "db:migrate": "supabase migration up",
    "db:new": "supabase migration new",
    "db:lint": "supabase db lint",
    "db:seed": "supabase db reset --seed"
  }
}
```

### 6.3 模板不包含的内容

- 业务逻辑代码（页面内容、API 逻辑、数据库 schema）
- 完整示例应用（如博客、Todo、Dashboard）
- 部署后的域名配置
- Supabase 项目创建（需用户手动创建并填入环境变量）

模板定位为**起点**，而非可运行的示例。

---

## 7. 实施路线图（Submodule + Symlink）

### Phase 1：仓库初始化与 Submodule 配置

**目标**：建立 Git 仓库，引入 ECC 作为 submodule。

| 任务 | 命令 / 产出 |
|---|---|
| 创建 ecc-rsk 目录 | `mkdir ~/develop/contributing/ecc-rsk && cd ~/develop/contributing/ecc-rsk` |
| 初始化 Git 仓库 | `git init` |
| 添加 ECC 作为 submodule | `git submodule add -b main https://github.com/affaan-m/ECC.git ecc` |
| 创建 .gitmodules | 自动生成 |
| 初始化 submodule | `git submodule init && git submodule update` |

### Phase 2：目录结构创建

**目标**：创建本地目录结构，为 symlink 和新增内容做准备。

| 任务 | 命令 |
|---|---|
| 创建顶层目录 | `mkdir -p agents skills commands rules hooks contexts schemas scripts/lib mcp-configs templates/nextjs-supabase docs .claude/rules .cursor/rules .github/workflows` |
| 创建新增内容目录 | `mkdir -p rules/nextjs rules/supabase rules/vercel skills/supabase-patterns skills/nextjs-app-router skills/vercel-deployment skills/fullstack-auth skills/realtime-sync skills/type-safe-stack skills/form-patterns` |

### Phase 3：创建 Symlink（复用 ECC 内容）

**目标**：通过 symlink 指向 ECC 子模块中的复用内容。

**macOS / Linux**（使用 `install.sh`）：
```bash
# Agents symlink
ln -sf ../ecc/agents/planner.md agents/planner.md
ln -sf ../ecc/agents/architect.md agents/architect.md
# ...（共 17 个）

# Skills symlink（目录）
ln -sf ../ecc/skills/api-design skills/api-design
ln -sf ../ecc/skills/blueprint skills/blueprint
# ...（共 14 个）

# Commands symlink
ln -sf ../ecc/commands/plan.md commands/plan.md
ln -sf ../ecc/commands/plan-prd.md commands/plan-prd.md
# ...（共 ~40 个）

# Rules symlink（目录）
ln -sf ../ecc/rules/common rules/common
ln -sf ../ecc/rules/react rules/react
# ...（共 5 套）

# 其他 symlink
ln -sf ../ecc/hooks/hooks.json hooks/hooks.json
ln -sf ../ecc/contexts/dev.md contexts/dev.md
ln -sf ../ecc/contexts/research.md contexts/research.md
ln -sf ../ecc/contexts/review.md contexts/review.md
ln -sf ../ecc/schemas/hooks.schema.json schemas/hooks.schema.json
ln -sf ../ecc/schemas/plugin.schema.json schemas/plugin.schema.json
ln -sf ../ecc/scripts/lib scripts/lib
ln -sf ../ecc/mcp-configs/supabase.json mcp-configs/supabase.json
ln -sf ../ecc/mcp-configs/context7.json mcp-configs/context7.json
ln -sf ../ecc/mcp-configs/playwright.json mcp-configs/playwright.json
ln -sf ../ecc/LICENSE LICENSE
```

**Windows**（使用 `install.ps1`）：
```powershell
# Windows junction（无需管理员权限）
cmd /c mklink /J agents\planner.md ..\..\ecc\agents\planner.md
# 或使用复制 fallback（如果 junction 不支持文件）
Copy-Item -Path ..\ecc\agents\planner.md -Destination agents\planner.md -Force
# ...（其他文件同理）
```

### Phase 4：编写安装脚本

**目标**：提供跨平台安装脚本，自动化 symlink 创建。

| 任务 | 产出 |
|---|---|
| 编写 `install.sh` | macOS/Linux 安装脚本（见 §7.4.1） |
| 编写 `install.ps1` | Windows 安装脚本（见 §7.4.2） |

#### 7.4.1 `install.sh`（macOS/Linux）

```bash
#!/bin/bash
set -e

echo "=== ECC-RSK Installation ==="

# 检查 submodule 是否已初始化
if [ ! -d "ecc" ]; then
  echo "Initializing ECC submodule..."
  git submodule init
  git submodule update
fi

# 创建目录结构
mkdir -p agents skills commands rules hooks contexts schemas scripts/lib mcp-configs templates docs .claude/rules .cursor/rules .github/workflows

# Agents symlink（17 个）
ln -sf ../ecc/agents/planner.md agents/planner.md
ln -sf ../ecc/agents/architect.md agents/architect.md
ln -sf ../ecc/agents/code-architect.md agents/code-architect.md
ln -sf ../ecc/agents/code-explorer.md agents/code-explorer.md
ln -sf ../ecc/agents/code-reviewer.md agents/code-reviewer.md
ln -sf ../ecc/agents/code-simplifier.md agents/code-simplifier.md
ln -sf ../ecc/agents/comment-analyzer.md agents/comment-analyzer.md
ln -sf ../ecc/agents/doc-updater.md agents/doc-updater.md
ln -sf ../ecc/agents/docs-lookup.md agents/docs-lookup.md
ln -sf ../ecc/agents/e2e-runner.md agents/e2e-runner.md
ln -sf ../ecc/agents/pr-test-analyzer.md agents/pr-test-analyzer.md
ln -sf ../ecc/agents/refactor-cleaner.md agents/refactor-cleaner.md
ln -sf ../ecc/agents/spec-miner.md agents/spec-miner.md
ln -sf ../ecc/agents/tdd-guide.md agents/tdd-guide.md
ln -sf ../ecc/agents/a11y-architect.md agents/a11y-architect.md
ln -sf ../ecc/agents/seo-specialist.md agents/seo-specialist.md
ln -sf ../ecc/agents/react-reviewer.md agents/react-reviewer.md

# Skills symlink（14 个目录）
ln -sf ../ecc/skills/api-design skills/api-design
ln -sf ../ecc/skills/blueprint skills/blueprint
ln -sf ../ecc/skills/browser-qa skills/browser-qa
ln -sf ../ecc/skills/code-tour skills/code-tour
ln -sf ../ecc/skills/council skills/council
ln -sf ../ecc/skills/gateguard skills/gateguard
ln -sf ../ecc/skills/repo-scan skills/repo-scan
ln -sf ../ecc/skills/seo skills/seo
ln -sf ../ecc/skills/taste skills/taste
ln -sf ../ecc/skills/ui-demo skills/ui-demo
ln -sf ../ecc/skills/github-ops skills/github-ops
ln -sf ../ecc/skills/benchmark skills/benchmark
ln -sf ../ecc/skills/config-gc skills/config-gc
ln -sf ../ecc/skills/agent-sort skills/agent-sort

# Commands symlink（~40 个）
ln -sf ../ecc/commands/plan.md commands/plan.md
ln -sf ../ecc/commands/plan-prd.md commands/plan-prd.md
ln -sf ../ecc/commands/feature-dev.md commands/feature-dev.md
ln -sf ../ecc/commands/code-review.md commands/code-review.md
ln -sf ../ecc/commands/build-fix.md commands/build-fix.md
ln -sf ../ecc/commands/test-coverage.md commands/test-coverage.md
ln -sf ../ecc/commands/refactor-clean.md commands/refactor-clean.md
ln -sf ../ecc/commands/update-docs.md commands/update-docs.md
ln -sf ../ecc/commands/security-scan.md commands/security-scan.md
ln -sf ../ecc/commands/quality-gate.md commands/quality-gate.md
ln -sf ../ecc/commands/project-init.md commands/project-init.md
ln -sf ../ecc/commands/pr.md commands/pr.md
ln -sf ../ecc/commands/review-pr.md commands/review-pr.md
ln -sf ../ecc/commands/react-build.md commands/react-build.md
ln -sf ../ecc/commands/react-review.md commands/react-review.md
ln -sf ../ecc/commands/react-test.md commands/react-test.md
ln -sf ../ecc/commands/checkpoint.md commands/checkpoint.md
ln -sf ../ecc/commands/save-session.md commands/save-session.md
ln -sf ../ecc/commands/resume-session.md commands/resume-session.md
ln -sf ../ecc/commands/sessions.md commands/sessions.md
ln -sf ../ecc/commands/aside.md commands/aside.md
ln -sf ../ecc/commands/learn.md commands/learn.md
ln -sf ../ecc/commands/learn-eval.md commands/learn-eval.md
ln -sf ../ecc/commands/evolve.md commands/evolve.md
ln -sf ../ecc/commands/skill-create.md commands/skill-create.md
ln -sf ../ecc/commands/skill-health.md commands/skill-health.md
ln -sf ../ecc/commands/prp-commit.md commands/prp-commit.md
ln -sf ../ecc/commands/prp-implement.md commands/prp-implement.md
ln -sf ../ecc/commands/prp-plan.md commands/prp-plan.md
ln -sf ../ecc/commands/prp-pr.md commands/prp-pr.md
ln -sf ../ecc/commands/prp-prd.md commands/prp-prd.md
ln -sf ../ecc/commands/epic-claim.md commands/epic-claim.md
ln -sf ../ecc/commands/epic-decompose.md commands/epic-decompose.md
ln -sf ../ecc/commands/epic-publish.md commands/epic-publish.md
ln -sf ../ecc/commands/epic-review.md commands/epic-review.md
ln -sf ../ecc/commands/epic-sync.md commands/epic-sync.md
ln -sf ../ecc/commands/epic-unblock.md commands/epic-unblock.md
ln -sf ../ecc/commands/epic-validate.md commands/epic-validate.md
ln -sf ../ecc/commands/multi-plan.md commands/multi-plan.md
ln -sf ../ecc/commands/multi-execute.md commands/multi-execute.md
ln -sf ../ecc/commands/multi-frontend.md commands/multi-frontend.md
ln -sf ../ecc/commands/multi-backend.md commands/multi-backend.md
ln -sf ../ecc/commands/multi-workflow.md commands/multi-workflow.md
ln -sf ../ecc/commands/auto-update.md commands/auto-update.md
ln -sf ../ecc/commands/prune.md commands/prune.md
ln -sf ../ecc/commands/promote.md commands/promote.md
ln -sf ../ecc/commands/model-route.md commands/model-route.md
ln -sf ../ecc/commands/cost-report.md commands/cost-report.md
ln -sf ../ecc/commands/harness-audit.md commands/harness-audit.md
ln -sf ../ecc/commands/hookify.md commands/hookify.md
ln -sf ../ecc/commands/hookify-list.md commands/hookify-list.md
ln -sf ../ecc/commands/hookify-help.md commands/hookify-help.md
ln -sf ../ecc/commands/setup-pm.md commands/setup-pm.md
ln -sf ../ecc/commands/projects.md commands/projects.md

# Rules symlink（5 套目录）
ln -sf ../ecc/rules/common rules/common
ln -sf ../ecc/rules/react rules/react
ln -sf ../ecc/rules/typescript rules/typescript
ln -sf ../ecc/rules/web rules/web
ln -sf ../ecc/rules/nuxt rules/nuxt

# 其他 symlink
ln -sf ../ecc/hooks/hooks.json hooks/hooks.json
ln -sf ../ecc/contexts/dev.md contexts/dev.md
ln -sf ../ecc/contexts/research.md contexts/research.md
ln -sf ../ecc/contexts/review.md contexts/review.md
ln -sf ../ecc/schemas/hooks.schema.json schemas/hooks.schema.json
ln -sf ../ecc/schemas/plugin.schema.json schemas/plugin.schema.json
ln -sf ../ecc/scripts/lib scripts/lib
ln -sf ../ecc/mcp-configs/supabase.json mcp-configs/supabase.json
ln -sf ../ecc/mcp-configs/context7.json mcp-configs/context7.json
ln -sf ../ecc/mcp-configs/playwright.json mcp-configs/playwright.json
ln -sf ../ecc/LICENSE LICENSE

echo "✓ Symlinks created successfully."
echo "Next steps:"
echo "  1. Write new agents/skills/commands/rules"
echo "  2. Write README.md, AGENTS.md, CLAUDE.md"
echo "  3. Write templates/nextjs-supabase/"
echo "  4. Commit and push"
```

#### 7.4.2 `install.ps1`（Windows）

```powershell
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
$directories = @(
  "agents", "skills", "commands", "rules", "hooks", "contexts", "schemas",
  "scripts\lib", "mcp-configs", "templates\nextjs-supabase", "docs",
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

# 选择 symlink 方式
if ($UseJunction) {
  # Windows junction（无需管理员权限，但仅支持目录）
  Write-Host "Using Windows junction for directories..." -ForegroundColor Yellow

  # 目录 symlink（使用 junction）
  $dirSymlinks = @(
    @{Target = "..\..\ecc\skills\api-design"; Link = "skills\api-design"},
    @{Target = "..\..\ecc\skills\blueprint"; Link = "skills\blueprint"},
    # ...（其他目录同理）
  )

  foreach ($item in $dirSymlinks) {
    if (Test-Path $item.Link) { Remove-Item $item.Link -Force -Recurse }
    cmd /c mklink /J "$($item.Link)" "$($item.Target)"
  }

  # 文件使用复制 fallback
  Write-Host "Copying files (junction does not support files)..." -ForegroundColor Yellow
  $fileCopies = @(
    @{Source = "..\ecc\agents\planner.md"; Dest = "agents\planner.md"},
    @{Source = "..\ecc\agents\architect.md"; Dest = "agents\architect.md"},
    # ...（其他文件同理）
  )

  foreach ($item in $fileCopies) {
    Copy-Item -Path $item.Source -Destination $item.Dest -Force
  }

} elseif ($UseCopy) {
  # 全部使用复制（最安全，但需要手动同步）
  Write-Host "Using copy mode (manual sync required)..." -ForegroundColor Yellow

  # 复制 agents
  Copy-Item -Path "..\ecc\agents\planner.md" -Destination "agents\planner.md" -Force
  Copy-Item -Path "..\ecc\agents\architect.md" -Destination "agents\architect.md" -Force
  # ...（其他文件同理）

  # 复制 skills 目录
  Copy-Item -Path "..\ecc\skills\api-design" -Destination "skills\api-design" -Force -Recurse
  Copy-Item -Path "..\ecc\skills\blueprint" -Destination "skills\blueprint" -Force -Recurse
  # ...（其他目录同理）

} else {
  # 默认：尝试 symlink（需要开发者模式或管理员权限）
  Write-Host "Attempting symlink (requires Developer Mode or Admin)..." -ForegroundColor Yellow

  try {
    # 文件 symlink
    New-Item -ItemType SymbolicLink -Path "agents\planner.md" -Target "..\ecc\agents\planner.md" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "agents\architect.md" -Target "..\ecc\agents\architect.md" -Force | Out-Null
    # ...（其他文件同理）

    # 目录 symlink
    New-Item -ItemType SymbolicLink -Path "skills\api-design" -Target "..\ecc\skills\api-design" -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path "skills\blueprint" -Target "..\ecc\skills\blueprint" -Force | Out-Null
    # ...（其他目录同理）

    Write-Host "✓ Symlinks created successfully." -ForegroundColor Green
  } catch {
    Write-Host "Symlink failed. Use -UseJunction or -UseCopy flag." -ForegroundColor Red
    Write-Host "Example: .\install.ps1 -UseCopy" -ForegroundColor Yellow
    exit 1
  }
}

Write-Host "Installation complete." -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "  1. Write new agents/skills/commands/rules"
Write-Host "  2. Write README.md, AGENTS.md, CLAUDE.md"
Write-Host "  3. Write templates\nextjs-supabase\"
Write-Host "  4. Commit and push"
```

### Phase 5：编写新增内容

**目标**：编写 ECC-RSK 专项扩展内容。

| 任务 | 产出 |
|---|---|
| 编写 5 个新 agents | `agents/typescript-reviewer.md`、`supabase-reviewer.md`、`nextjs-reviewer.md`、`vercel-deployer.md`、`fullstack-architect.md` |
| 编写 7 个新 skills | `skills/supabase-patterns/SKILL.md`、`nextjs-app-router/SKILL.md`、... |
| 编写 6 个新 commands | `commands/supabase-review.md`、`supabase-migrate.md`、... |
| 编写 3 套新 rules | `rules/nextjs/patterns.md`、`supabase/patterns.md`、... |

### Phase 6：编写核心文档

**目标**：编写 README、AGENTS.md、CLAUDE.md 等核心文档。

| 任务 | 产出 |
|---|---|
| 编写 README.md | 项目说明、与 ECC 关系、安装指南、使用指南 |
| 编写 README.zh-CN.md | 中文版 README |
| 编写 AGENTS.md | Agent 索引与编排规则（基于 ECC裁剪） |
| 编写 CLAUDE.md | Claude Code 指南（基于 ECC裁剪） |
| 编写 CONTRIBUTING.md | 贡献指南 |
| 编写 VERSION | 版本号（如 `2.0.0-rsk.1`） |

### Phase 7：项目模板

**目标**：创建 `templates/nextjs-supabase/` 脚手架。

| 任务 | 产出 |
|---|---|
| 创建模板目录结构 | 见 §6.1 |
| 编写关键配置文件 | `tsconfig.json`、`next.config.mjs`、`tailwind.config.ts`、`.env.example`、`package.json` |
| 编写 Supabase 集成文件 | `lib/supabase/*.ts`、`middleware.ts` |
| 编写 Provider 文件 | `components/providers/*.tsx` |
| 编写模板 README | `templates/nextjs-supabase/README.md` |

### Phase 8：Harness 配置与 CI

**目标**：配置 harness 和 CI/CD。

| 任务 | 产出 |
|---|---|
| 配置 `.claude/rules/node.md` | 本地裁剪版（继承 ECC） |
| 配置 `.cursor/hooks.json` | Cursor hooks 配置 |
| 配置 `.cursor/rules/` | Cursor rules（裁剪版） |
| 配置 `.github/workflows/ci.yml` | lint + typecheck + test |
| 配置 `.github/workflows/sync-ecc.yml` | 定期同步 ECC submodule |
| 配置 `.github/CODEOWNERS` | 代码所有权 |

### Phase 9：跨 harness 适配（可选）

**目标**：支持 Claude Code 之外的 harness。

| 任务 | 产出 |
|---|---|
| Cursor 适配 | `.cursor/hooks.json`、`.cursor/rules/`（已完成） |
| Codex 适配 | `.codex/AGENTS.md`、`.codex/config.toml` |
| Gemini 适配 | `.gemini/GEMINI.md` |
| Zed 适配 | `.zed/settings.json` |
| OpenCode 适配 | `.opencode/commands/`、`.opencode/plugins/` |

---

## 8. 与 ECC 的同步策略（Submodule 机制）

ECC-RSK 通过 Git Submodule 机制与 ECC 保持同步，无需手动复制代码。

### 8.1 同步机制

| 操作 | 命令 | 说明 |
|---|---|---|
| 初始化 submodule | `git submodule init && git submodule update` | 首次克隆仓库后执行 |
| 更新 ECC 到最新 | `git submodule update --remote ecc` | 拉取 ECC 最新 main 分支 |
| 锁定 ECC 到特定版本 | `git submodule update --remote ecc -- <commit-hash>` | 锁定到特定 commit |
| 检查 submodule 状态 | `git submodule status` | 查看 ECC 当前版本 |
| 更新 symlink（如有新增） | `./install.sh` 或 `./install.ps1` | ECC 新增文件后重新运行安装脚本 |

### 8.2 同步流程

**定期同步 ECC 上游**：
```bash
# 1. 更新 ECC submodule
cd ecc-rsk
git submodule update --remote ecc

# 2. 检查 ECC 变更
cd ecc
git log --oneline HEAD@{1}..HEAD
cd ..

# 3. 检查是否有新增复用文件（需创建新 symlink）
# 对比 ECC 新增文件与 ECC-RSK symlink 清单

# 4. 如有新增，重新运行安装脚本
./install.sh

# 5. 提交 submodule 更新
git add ecc
git commit -m "sync: update ECC submodule to <version>"
git push
```

**自动化同步（GitHub Actions）**：
```yaml
# .github/workflows/sync-ecc.yml
name: Sync ECC Submodule

on:
  schedule:
    - cron: '0 0 * * 0'  # 每周日 00:00 UTC
  workflow_dispatch:      # 手动触发

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - name: Update ECC submodule
        run: |
          git submodule update --remote ecc
          cd ecc
          ECC_VERSION=$(git describe --tags --always)
          cd ..
          echo "ECC_VERSION=$ECC_VERSION" >> $GITHUB_ENV

      - name: Check for changes
        run: |
          if git diff --quiet ecc; then
            echo "No changes in ECC submodule"
            exit 0
          fi

      - name: Create PR
        uses: peter-evans/create-pull-request@v5
        with:
          title: "sync: update ECC submodule to ${{ env.ECC_VERSION }}"
          body: "Automated sync of ECC submodule."
          branch: "sync/ecc-${{ env.ECC_VERSION }}"
          commit-message: "sync: update ECC submodule to ${{ env.ECC_VERSION }}"
```

### 8.3 版本约定

- ECC-RSK 版本号：`<ECC-version>-rsk.<rsk-version>`（如 `2.0.0-rsk.1`）
- 每个 ECC-RSK 版本绑定一个 ECC submodule commit
- `VERSION` 文件记录当前 ECC-RSK 版本
- `.gitmodules` 中 ECC submodule 指向特定 commit（不自动跟随 main）

**锁定 ECC 版本**：
```bash
# 锁定 ECC 到特定 commit
cd ecc
git checkout <commit-hash>
cd ..
git add ecc
git commit -m "lock: ECC submodule to <commit-hash>"
```

### 8.4 Symlink 维护

**ECC 新增文件处理**：
- ECC 上游新增 agent/skill/command/rule 时，需评估是否纳入 ECC-RSK
- 如纳入，在 `install.sh` / `install.ps1` 中添加新 symlink
- 运行安装脚本创建 symlink
- 提交安装脚本更新

**ECC 删除文件处理**：
- ECC 上游删除文件时，symlink 会自动失效（指向不存在文件）
- 检查 symlink 状态：`find . -type l -xtype l`（查找失效 symlink）
- 删除失效 symlink：`find . -type l -xtype l -delete`
- 提交删除

### 8.5 贡献回流

ECC-RSK 中的优秀扩展（如 `supabase-reviewer`、`nextjs-reviewer`）可通过 PR 回流到 ECC 上游：

**回流流程**：
1. 在 ECC-RSK 中编写新增内容（本地文件，非 symlink）
2. 测试验证
3. 将新增内容复制到 ECC 仓库（或直接在 ECC 中编写）
4. 向 ECC 提交 PR
5. PR 合并后，ECC-RSK 中该文件改为 symlink 指向 ECC

**回流后处理**：
```bash
# ECC PR 合并后，ECC-RSK 更新
git submodule update --remote ecc

# 将本地新增文件改为 symlink
rm agents/supabase-reviewer.md  # 删除本地文件
ln -sf ../ecc/agents/supabase-reviewer.md agents/supabase-reviewer.md  # 创建 symlink

# 更新安装脚本（移除本地创建逻辑，改为 symlink）
git add agents/supabase-reviewer.md install.sh
git commit -m "refactor: symlink supabase-reviewer after ECC merge"
```

### 8.6 冲突处理

**ECC 修改了复用文件**：
- symlink 自动指向 ECC 最新版本，无需手动处理
- 如 ECC 修改与 ECC-RSK 技术栈假设冲突，需评估是否继续复用
- 如冲突严重，可改为本地文件（删除 symlink，复制内容到本地）

**ECC-RSK 需要定制复用文件**：
- 删除 symlink
- 复制 ECC 文件到本地
- 本地修改
- 提交本地版本
- 标注为"本地定制版，不跟随上游"

### 8.7 Harness 配置同步

`.claude/`、`.cursor/` 等 harness 配置目录**不能 symlink**，需本地维护：

**同步策略**：
- 定期检查 ECC 上游 harness 配置变更
- 手动合并变更到 ECC-RSK 本地配置
- 保留 ECC-RSK 特有配置（如裁剪非全栈内容）
- 删除 ECC-RSK 不需要的配置（如非 Web 语言规则）

**同步脚本示例**：
```bash
# 检查 ECC .claude/rules 变更
diff -r ecc/.claude/rules .claude/rules

# 手动合并变更
# ...
```

---

## 9. 排除清单

以下 ECC 内容**不纳入** ECC-RSK：

### 9.1 排除的 Agents

| Agent | 排除理由 |
|---|---|
| `cpp-reviewer` | 非 Web 语言 |
| `csharp-reviewer` | 非 Web 语言 |
| `django-reviewer` | 非 React 全栈 |
| `fastapi-reviewer` | 非 React 全栈 |
| `flutter-reviewer` | 非 Web |
| `fsharp-reviewer` | 非 Web 语言 |
| `go-reviewer` | 非 Web 语言 |
| `java-reviewer` | 非 Web 语言 |
| `kotlin-reviewer` | 非 Web 语言 |
| `php-reviewer` | 非 Web 语言 |
| `python-reviewer` | 非 Web 语言 |
| `rust-reviewer` | 非 Web 语言 |
| `swift-reviewer` | 非 Web 语言 |
| `vue-reviewer` | 聚焦 React，排除 Vue |
| `mle-reviewer` | ML 专用，非全栈 Web |
| `gan-evaluator` / `gan-generator` / `gan-planner` | GAN 专用 |
| `marketing-agent` | 非开发 |
| `loop-operator` | 自主循环，非全栈核心 |
| `chief-of-staff` | 非全栈核心 |
| `agent-evaluator` | Agent 评估，非全栈核心 |

### 9.2 排除的 Skills

| Skill | 排除理由 |
|---|---|
| `django-tdd` | 非 React 全栈 |
| `ecc-guide` | ECC 专用 |
| `email-ops` | 非全栈核心 |
| `crosspost` | 非全栈核心 |
| `exa-search` | 非全栈核心 |
| `motion-ui` | 非全栈核心 |
| `uncloud` | 非全栈核心 |
| `videodb` | 非全栈核心 |
| `x-api` | 非全栈核心 |
| `ck` | 非全栈核心 |
| `ui-to-vue` | 聚焦 React，排除 Vue |
| `agentic-os` | Agent 操作系统，非全栈核心 |
| `agent-eval` | Agent 评估，非全栈核心 |

### 9.3 排除的 Commands

| 命令组 | 排除理由 |
|---|---|
| `cpp-build` / `cpp-review` / `cpp-test` | 非 Web 语言 |
| `go-build` / `go-review` / `go-test` | 非 Web 语言 |
| `kotlin-build` / `kotlin-review` / `kotlin-test` / `gradle-build` | 非 Web 语言 |
| `rust-build` / `rust-review` / `rust-test` | 非 Web 语言 |
| `flutter-build` / `flutter-review` / `flutter-test` | 非 Web |
| `fastapi-review` | 非 React 全栈 |
| `python-review` | 非 Web 语言 |
| `vue-review` | 聚焦 React，排除 Vue |
| `jira` | 非全栈核心 |
| `pm2` | Vercel 部署，不需要 PM2 |
| `santa-loop` / `loop-start` / `loop-status` | 自主循环，非全栈核心 |
| `gan-build` / `gan-design` | GAN 专用 |
| `ecc-guide` | ECC 专用 |
| `multi-backend` | 重定义为 Supabase 后端（见 §3.3） |

### 9.4 排除的 Rules

| 规则集 | 排除理由 |
|---|---|
| `cpp/` | 非 Web 语言 |
| `csharp/` | 非 Web 语言 |
| `dart/` | 非 Web 语言 |
| `fsharp/` | 非 Web 语言 |
| `golang/` | 非 Web 语言 |
| `java/` | 非 Web 语言 |
| `kotlin/` | 非 Web 语言 |
| `perl/` | 非 Web 语言 |
| `php/` | 非 Web 语言 |
| `python/` | 非 Web 语言 |
| `ruby/` | 非 Web 语言 |
| `rust/` | 非 Web 语言 |
| `swift/` | 非 Web 语言 |
| `vue/` | 聚焦 React，排除 Vue |
| `angular/` | 聚焦 React，排除 Angular |
| `arkts/` | 非 Web 语言 |

### 9.5 排除的其他

| 项 | 排除理由 |
|---|---|
| `ecc2/` (Rust TUI) | ECC 专用工具 |
| `src/llm/` (Python LLM CLI) | 非全栈核心 |
| `ecc_dashboard.py` | ECC 专用 |
| `the-longform-guide.md` / `the-shortform-guide.md` / `the-security-guide.md` | ECC 专用指南 |
| `WORKING-CONTEXT.md` / `SOUL.md` | ECC 专用 |
| `docs/` 多语言翻译 | ECC-RSK 自建文档体系 |
| `.kiro/` / `.codex/` / `.qwen/` / `.codebuddy/` / `.trae/` / `.opencode/` | Phase 5 跨 harness 适配时按需引入 |

---

## 附录：统计摘要

| 类别 | 复用 | 新增 | 合计 |
|---|---|---|---|
| Agents | 17 | 5 | 22 |
| Skills | 14 | 7 | 21 |
| Commands | ~40 | 6 | ~46 |
| Rules | 5 套 | 3 套 | 8 套 |
| **总计** | **~76** | **~21** | **~97** |

---

*本方案文档为 ECC-RSK 项目的完整组合方案，实施时按 Phase 1 → Phase 5 顺序推进。*
