---
name: ecc-rsk-routes
description: ECC-RSK Skills 路由规则 — 定义文件类型/路径、用户意图关键词、开发阶段到 skill 的映射，以及多 skill 编排链。
metadata:
  origin: ECC-RSK
  type: routing-rules
---

# ECC-RSK Skills 路由规则

本文件定义 ECC-RSK 的**薄路由规则**：根据文件类型/路径、用户意图关键词、开发阶段，将请求路由到一个或多个 skills。
入口文件为 [SKILL.md](SKILL.md)，本文件是路由规则层。

---

## 路由优先级

1. **显式调用** — 用户直接点名 skill（如"使用 supabase-patterns"）→ 直接激活
2. **文件类型/路径路由** — 根据当前操作的文件路径匹配（下表 1）
3. **意图关键词路由** — 根据用户请求中的关键词匹配（下表 2）
4. **开发阶段路由** — 根据当前开发阶段匹配编排链（下表 3）
5. **回退** — 未命中任何规则 → 使用通用 agents（planner / code-reviewer）

多 skill 命中时，按"编排链"章节顺序执行；无编排链定义时，并行激活。

---

## 1. 文件类型/路径路由

根据用户当前操作或打开的文件路径，自动激活对应 skill。

### 1.1 Next.js App Router 路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `app/**/page.tsx` | `nextjs-app-router` | 页面组件（RSC 边界、Metadata） |
| `app/**/layout.tsx` | `nextjs-app-router` | 布局组件（嵌套布局、Streaming） |
| `app/**/loading.tsx` | `nextjs-app-router` | 加载 UI（Suspense、Streaming） |
| `app/**/error.tsx` | `nextjs-app-router` | 错误边界 |
| `app/**/route.ts` | `nextjs-app-router` | Route Handlers |
| `app/**/middleware.ts` | `nextjs-app-router`、`fullstack-auth` | 中间件（会话刷新、认证） |
| `app/**/opengraph-image.tsx` | `nextjs-app-router`、`seo` | OG 图像、Metadata |
| `app/**/sitemap.ts` | `nextjs-app-router`、`seo` | 站点地图 |
| `app/**/robots.ts` | `nextjs-app-router`、`seo` | robots.txt |

### 1.2 Server Actions 路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `app/**/actions.ts` | `nextjs-app-router`、`type-safe-stack` | Server Actions（输入校验、类型安全） |
| `lib/actions/**/*.ts` | `nextjs-app-router`、`type-safe-stack` | 集中管理的 Server Actions |
| `**/actions/*.ts` | `nextjs-app-router`、`type-safe-stack` | Server Actions 目录 |

### 1.3 Supabase 路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `lib/supabase/client.ts` | `supabase-patterns`、`fullstack-auth` | 浏览器端 Supabase 客户端 |
| `lib/supabase/server.ts` | `supabase-patterns`、`fullstack-auth` | 服务端 Supabase 客户端 |
| `lib/supabase/middleware.ts` | `supabase-patterns`、`fullstack-auth` | Supabase 中间件（会话刷新） |
| `supabase/migrations/*.sql` | `supabase-patterns` | 数据库迁移 |
| `supabase/functions/**/*.ts` | `supabase-patterns` | Edge Functions |
| `**/rls.sql` | `supabase-patterns` | RLS 策略 |
| `types/supabase.ts` | `type-safe-stack` | Supabase 生成类型 |

### 1.4 表单路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `app/**/*-form.tsx` | `form-patterns` | 表单组件 |
| `app/**/register/page.tsx` | `form-patterns`、`fullstack-auth` | 注册页（认证 + 表单） |
| `app/**/login/page.tsx` | `form-patterns`、`fullstack-auth` | 登录页（认证 + 表单） |
| `components/**/*-form.tsx` | `form-patterns` | 表单组件 |
| `**/schemas/*.ts` | `form-patterns`、`type-safe-stack` | Zod schema（表单校验 + 类型安全） |

### 1.5 Realtime 路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `**/realtime/**/*.ts` | `realtime-sync` | Realtime 订阅逻辑 |
| `**/useRealtime*.ts` | `realtime-sync` | Realtime hooks |
| `**/use*.tsx`（含 subscribe） | `realtime-sync` | Realtime 订阅 hooks |

### 1.6 部署路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `vercel.json` | `vercel-deployment` | Vercel 配置 |
| `.env.example` | `vercel-deployment` | 环境变量示例 |
| `.github/workflows/*.yml` | `vercel-deployment` | CI/CD 配置 |
| `next.config.{js,mjs,ts}` | `nextjs-app-router`、`vercel-deployment` | Next.js 配置 |

### 1.7 通用工程路由

| 文件路径模式 | 激活 Skill | 说明 |
|---|---|---|
| `**/api/**/*.ts` | `api-design` | REST API 设计 |
| `**/*.test.{ts,tsx}` | `benchmark`（性能测试时） | 性能基线 |
| `.github/**/*.yml` | `github-ops` | GitHub 运营 |
| `README.md` | `code-tour`（需讲解时） | 项目讲解 |

---

## 2. 意图关键词路由

根据用户请求中的关键词，自动激活对应 skill。

### 2.1 Supabase 意图

| 关键词 | 激活 Skill |
|---|---|
| RLS、行级安全、row level security | `supabase-patterns` |
| Auth、认证、登录、注册、OAuth、PKCE | `fullstack-auth` |
| Realtime、实时、订阅、broadcast、presence | `realtime-sync` |
| Storage、上传、文件、bucket | `supabase-patterns` |
| Edge Function、边缘函数 | `supabase-patterns` |
| 迁移、migration、schema | `supabase-patterns` |
| 多租户、tenant、RBAC、角色 | `fullstack-auth` |

### 2.2 Next.js 意图

| 关键词 | 激活 Skill |
|---|---|
| RSC、Server Component、Client Component、'use client'、'use server' | `nextjs-app-router` |
| Server Action、useActionState、useFormStatus | `nextjs-app-router`、`form-patterns` |
| Route Handler、API Route | `nextjs-app-router`、`api-design` |
| Middleware、中间件 | `nextjs-app-router`、`fullstack-auth` |
| 缓存、cache、revalidate、ISR、SSG、SSR | `nextjs-app-router` |
| Streaming、Suspense、loading | `nextjs-app-router` |
| Metadata、SEO、og:image、sitemap、robots | `nextjs-app-router`、`seo` |

### 2.3 表单意图

| 关键词 | 激活 Skill |
|---|---|
| 表单、form、React Hook Form、useForm | `form-patterns` |
| Zod、schema、校验、validation | `form-patterns`、`type-safe-stack` |
| 多步表单、向导、wizard、multi-step | `form-patterns` |
| 文件上传、upload、dropzone | `form-patterns` |
| 可访问性、a11y、aria、label | `form-patterns` |

### 2.4 类型安全意图

| 关键词 | 激活 Skill |
|---|---|
| 类型安全、type-safe、end-to-end types | `type-safe-stack` |
| gen types、类型生成、supabase types | `type-safe-stack` |
| TypeScript strict、严格模式 | `type-safe-stack` |

### 2.5 部署意图

| 关键词 | 激活 Skill |
|---|---|
| 部署、deploy、Vercel | `vercel-deployment` |
| 环境变量、env vars、NEXT_PUBLIC | `vercel-deployment` |
| 运行时、runtime、Edge Runtime、Node Runtime | `vercel-deployment` |
| 性能监控、Analytics、Speed Insights | `vercel-deployment`、`benchmark` |
| 多账号、账号冲突、Vercel 账号 | `vercel-deployment` |
| vercel link、token 认证、非浏览器登录 | `vercel-deployment` |
| commit author、commit email、deployment blocked | `vercel-deployment` |
| GitHub Actions 部署、绕过 Git 集成 | `vercel-deployment` |

### 2.6 通用工程意图

| 关键词 | 激活 Skill |
|---|---|
| API 设计、REST、endpoint、状态码、分页 | `api-design` |
| 蓝图、blueprint、多会话、多 PR | `blueprint` |
| 视觉测试、browser QA、UI 验证 | `browser-qa` |
| 决策、tradeoff、go/no-go、议会 | `council` |
| 事实门、investigate before edit | `gateguard` |
| 代码审计、asset audit、第三方库检测 | `repo-scan` |
| SEO、搜索可见性、Core Web Vitals、结构化数据 | `seo` |
| UI 演示、demo 视频、walkthrough | `ui-demo` |
| GitHub 运营、issue 分诊、PR 管理、CI/CD | `github-ops` |
| 性能基线、回归检测、benchmark | `benchmark` |
| 配置清理、config GC、.claude 清理 | `config-gc` |
| ECC 裁剪、install plan、DAILY vs LIBRARY | `agent-sort` |
| 代码讲解、CodeTour、onboarding tour | `code-tour` |

---

## 3. 开发阶段路由

根据当前开发阶段，激活对应的 skill 编排链。

### 3.1 项目初始化阶段

| 场景 | 激活 Skill 编排链 |
|---|---|
| 新项目脚手架 | `agent-sort` → `blueprint` → `nextjs-app-router` |
| 棕地项目接入 | `repo-scan` → `agent-sort` → `blueprint` |
| 架构决策 | `council` → `blueprint` |

### 3.2 功能开发阶段

| 场景 | 激活 Skill 编排链 |
|---|---|
| 数据模型设计 | `supabase-patterns` → `type-safe-stack` |
| 认证流程实现 | `fullstack-auth` → `nextjs-app-router` → `form-patterns` |
| CRUD 页面开发 | `nextjs-app-router` → `form-patterns` → `type-safe-stack` |
| Realtime 功能 | `realtime-sync` → `nextjs-app-router` → `type-safe-stack` |
| API 开发 | `api-design` → `nextjs-app-router` → `type-safe-stack` |

### 3.3 测试阶段

| 场景 | 激活 Skill 编排链 |
|---|---|
| 单元/组件测试 | `type-safe-stack`（类型检查） |
| E2E 测试 | `browser-qa` |
| 性能测试 | `benchmark` |

### 3.4 部署阶段

| 场景 | 激活 Skill 编排链 |
|---|---|
| 部署配置 | `vercel-deployment` → `nextjs-app-router` |
| 环境变量管理 | `vercel-deployment` |
| 性能监控 | `vercel-deployment` → `benchmark` |
| SEO 优化 | `seo` → `nextjs-app-router` |

### 3.5 维护阶段

| 场景 | 激活 Skill 编排链 |
|---|---|
| 数据库迁移 | `supabase-patterns` → `type-safe-stack` |
| 配置清理 | `config-gc` |
| 代码讲解/onboarding | `code-tour` |
| GitHub 运营 | `github-ops` |

---

## 4. 编排链规则

当多个 skill 被激活时，按以下规则编排：

### 4.1 顺序执行（有依赖）

格式：`A → B → C`（A 的输出是 B 的输入）

示例：
- `supabase-patterns → type-safe-stack`：先设计 RLS 策略，再生成类型
- `fullstack-auth → nextjs-app-router → form-patterns`：先设计认证流程，再实现页面路由，最后实现表单

### 4.2 并行执行（无依赖）

格式：`A + B + C`（同时激活，互不依赖）

示例：
- `nextjs-app-router + form-patterns`：同时参考 Next.js 模式和表单模式
- `seo + nextjs-app-router`：同时参考 SEO 和 Next.js Metadata

### 4.3 混合编排

格式：`A → (B + C) → D`

示例：
- `fullstack-auth → (nextjs-app-router + form-patterns) → type-safe-stack`
  - 先设计认证流程
  - 再并行参考 Next.js 路由和表单模式
  - 最后确保端到端类型安全

---

## 5. 回退策略

当未命中任何路由规则时：

1. **代码修改类请求** → 回退到 `planner` agent + `code-reviewer` agent
2. **架构设计类请求** → 回退到 `architect` agent + `council` skill
3. **测试类请求** → 回退到 `tdd-guide` agent + `e2e-runner` agent
4. **完全无法匹配** → 询问用户是否需要激活特定 skill，或列出所有 skills 供选择

---

## 6. 路由规则维护

### 添加新规则

1. 在对应表格中添加一行
2. 如需新增编排链，在"开发阶段路由"或"编排链规则"中添加
3. 更新 [SKILL.md](SKILL.md) 的索引表（如新增 skill）

### 规则冲突处理

当多条规则同时命中时：
1. 文件类型/路径规则优先于意图关键词规则
2. 具体关键词优先于泛化关键词（如"RLS"优先于"Supabase"）
3. 开发阶段编排链优先于单 skill 激活

---

## 相关文件

- [SKILL.md](SKILL.md) — Skills 索引入口
- [AGENTS.md](AGENTS.md) — Agent 索引与编排规则
- [CLAUDE.md](CLAUDE.md) — Claude Code 使用指南
