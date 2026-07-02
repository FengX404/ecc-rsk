# ECC-RSK Agents

ECC-RSK 提供 22 个 specialized agents，其中 17 个复用 ECC（通过 symlink），5 个为 ECC-RSK 专项新增。

---

## 从 ECC 复用的 Agents（17 个）

| Agent | 职责 | 触发时机 |
|---|---|---|
| `planner` | 复杂功能实现规划 | 用户请求规划、复杂任务 |
| `architect` | 系统设计与可扩展性 | 架构决策、技术选型 |
| `code-architect` | 代码架构设计 | 模块设计、代码组织 |
| `code-explorer` | 代码库探索 | 理解现有代码、查找实现 |
| `code-reviewer` | 通用代码质量审查 | 代码修改后 |
| `react-reviewer` | React/JSX 专项审查 | `.tsx`/`.jsx` 文件修改 |
| `tdd-guide` | 测试驱动开发 | 新功能、Bug 修复 |
| `e2e-runner` | Playwright E2E 测试 | 关键用户流程测试 |
| `refactor-cleaner` | 死代码清理、重构 | 代码维护 |
| `doc-updater` | 文档与 codemap 更新 | 文档同步 |
| `spec-miner` | 棕地项目规范挖掘 | 现有项目接入 |
| `a11y-architect` | 无障碍设计 | UI 组件开发 |
| `seo-specialist` | SEO 优化 | Next.js 页面开发 |
| `code-simplifier` | 代码简化 | 降低复杂度 |
| `comment-analyzer` | 注释质量分析 | 文档质量检查 |
| `docs-lookup` | 文档查询（Context7） | API 文档查询 |
| `pr-test-analyzer` | PR 测试覆盖分析 | PR 质量保障 |

---

## ECC-RSK 新增的 Agents（8 个）

| Agent | 职责 | 触发时机 |
|---|---|---|
| `typescript-reviewer` | TypeScript 专项审查（`any` 滥用、async 正确性、严格模式） | `.ts` 文件修改、类型安全检查 |
| `supabase-reviewer` | Supabase 专项审查（RLS、SQL 注入、Auth、Edge Functions） | Supabase 相关代码修改 |
| `nextjs-reviewer` | Next.js App Router 专项审查（RSC 边界、Server Actions、缓存） | Next.js 相关代码修改 |
| `vercel-deployer` | Vercel 部署配置与优化（环境变量、运行时、性能） | 部署前检查、部署执行 |
| `fullstack-architect` | React+Next.js+Supabase 整体架构设计（数据流、认证流、类型安全） | 新项目架构设计、重大重构 |
| `ux-reviewer` | 体验专项审查（交互完整性、视觉一致性、微交互、信息架构） | UI 组件修改、页面开发、体验迭代 |
| `feature-reviewer` | 功能完整性审查（需求覆盖度、竞品对标、A/B 实验设计、边界场景） | 新功能开发、功能增强、PR 审查 |
| `observability-reviewer` | 可观测性审查（错误监控、性能追踪、日志链路、告警机制） | 上线前检查、可观测性建设 |

---

## Agent 编排规则

### 审查链（PR Review）

对于涉及 `.tsx`/`.jsx` 文件的 PR，应并行调用以下 agents：

1. `react-reviewer` — React 专项审查
2. `typescript-reviewer` — TypeScript 专项审查
3. `code-reviewer` — 通用代码质量审查

对于涉及 Supabase 的 PR，应调用：

1. `supabase-reviewer` — Supabase 专项审查
2. `database-reviewer`（来自 ECC，如需通用 PostgreSQL 审查）

对于涉及 Next.js App Router 的 PR，应调用：

1. `nextjs-reviewer` — Next.js 专项审查
2. `react-reviewer` — React 专项审查（如有 JSX）

### 开发链（Feature Development）

1. `planner` — 规划实现方案
2. `tdd-guide` — 编写测试
3. `code-architect` — 设计代码架构
4. `fullstack-architect` — 设计整体架构（如涉及认证/数据流）
5. `e2e-runner` — 运行 E2E 测试

### 部署链（Deployment）

1. `vercel-deployer` — 部署前检查与执行
2. `nextjs-reviewer` — Next.js 配置审查
3. `supabase-reviewer` — Supabase 配置审查（如涉及 Edge Functions）

---

## 冲突解决规则

当多个 reviewer agent 给出冲突建议时，按以下优先级裁决：

| 冲突类型 | 优先 Agent | 理由 |
|---|---|---|
| 类型安全冲突（`any` 滥用、类型断言） | `typescript-reviewer` | 类型安全是 RSK 核心原则 |
| RSC 边界冲突（Server/Client Component 划分） | `nextjs-reviewer` | App Router 边界规则专项 |
| RLS / Auth / 密钥安全冲突 | `supabase-reviewer` | 安全问题一票否决 |
| 缓存策略冲突（`revalidate` / `cache` 选项） | `nextjs-reviewer` | Next.js 缓存语义专项 |
| 部署配置冲突（runtime / env / vercel.json） | `vercel-deployer` | 部署目标专项 |
| 通用代码风格冲突（命名、结构） | `code-reviewer` | 通用质量兜底 |

**裁决原则**：
1. 安全问题 > 类型安全 > 框架专项 > 通用风格
2. 专项 reviewer 的建议优先于通用 `code-reviewer`
3. 冲突无法通过优先级裁决时，由 `fullstack-architect` 仲裁

---

## 不适用的 ECC 命令

ECC 中有部分命令面向非 RSK 技术栈（Go、Rust、Kotlin、C++、Flutter、Python、Vue 等），这些命令**未引入 ECC-RSK**，不会出现在 `commands/` 目录中。

ECC 的以下 ECC 内部系统命令也已排除（未 symlink）：

- `multi-backend` `multi-frontend` — 多后端/多前端编排（RSK 后端固定 Supabase、前端固定 Next.js）
- `hookify` `hookify-help` `hookify-list` — ECC hooks 管理系统
- `sessions` `save-session` `resume-session` — ECC 会话持久化
- `project-init` `projects` `promote` `prune` `evolve` — ECC instincts 系统
- `skill-create` `skill-health` — ECC Skill Creator App
- `harness-audit` `quality-gate` `model-route` `cost-report` `setup-pm` — ECC 内部工具

如遇上述场景，RSK 推荐替代：

| 场景 | 不适用命令 | RSK 推荐命令 |
|---|---|---|
| 代码审查 | `/python-review` `/go-review` | `/code-review` `/nextjs-review` `/supabase-review` |
| 构建修复 | `/go-build` `/rust-build` | `/build-fix` `/react-build` |
| 测试 | `/go-test` `/rust-test` | `/react-test` `/test-coverage` |

---

## Agent 调用方式

### 通过 Command 调用

- `/code-review` → 调用 `code-reviewer`
- `/react-review` → 调用 `react-reviewer`
- `/supabase-review` → 调用 `supabase-reviewer`
- `/nextjs-review` → 调用 `nextjs-reviewer`
- `/multi-review` → 调用 `multi-angle-review` skill（编排多 Agent 并行审查）
- `/plan` → 调用 `planner`

### 直接调用（Claude Code）

在 Claude Code 中，可直接请求 agent：

```
请使用 supabase-reviewer agent审查我的 RLS 策略。
```

---

## Agent 文件位置

- 复用 agents：`agents/*.md`（symlink → `../ecc/agents/*.md`）
- 新增 agents：`agents/typescript-reviewer.md`、`supabase-reviewer.md` 等（本地文件）

---

## Skills 薄路由

ECC-RSK 提供 21 个 skills（14 个复用 ECC + 7 个新增），通过薄路由机制自动激活：

- [SKILL.md](SKILL.md) — Skills 索引入口
- [SKILL-ROUTES.md](SKILL-ROUTES.md) — 路由规则（文件类型/意图/阶段 → skill 映射）

**路由流程**：用户请求 → 查阅 SKILL-ROUTES.md → 激活对应 `skills/<name>/SKILL.md`