# ECC-RSK Commands Quick Reference

> ECC-RSK 可用命令索引。继承 ECC 50+ 命令 + RSK 专项 6 命令。按场景查找，不要全记。

---

## 核心工作流

| Command | 用途 |
|---|---|
| `/plan` | 规划实现方案，等待确认后再动代码 |
| `/feature-dev` | 功能开发流程（plan → tdd → review） |
| `/code-review` | 通用代码质量审查 |
| `/build-fix` | 检测并修复构建错误 |
| `/quality-gate` | 质量门检查 |
| `/project-init` | 项目初始化 |

---

## RSK 专项（6 个）

| Command | 用途 | 触发场景 |
|---|---|---|
| `/fullstack-init` | 初始化 Next.js + Supabase 项目 | 新项目脚手架 |
| `/nextjs-review` | Next.js App Router 审查（RSC/Server Actions/缓存） | `.tsx`/`app/` 文件修改 |
| `/supabase-review` | Supabase 审查（RLS/Auth/Edge Functions） | Supabase 相关代码修改 |
| `/supabase-migrate` | 数据库迁移工作流 | schema 变更 |
| `/typecheck-e2e` | 端到端类型安全检查（Postgres → Zod → React） | 类型同步验证 |
| `/vercel-deploy` | Vercel 部署配置与执行 | 部署前检查、部署执行 |

---

## 代码审查

| Command | 用途 |
|---|---|
| `/code-review` | 通用代码审查 |
| `/react-review` | React/JSX 专项审查 |
| `/review-pr` | PR 审查流程 |
| `/security-scan` | 安全扫描 |
| `/test-coverage` | 测试覆盖率检查 |

---

## 测试

| Command | 用途 |
|---|---|
| `/react-test` | React 组件测试（Vitest + Testing Library） |
| `/test-coverage` | 覆盖率报告与缺口分析 |
| `/refactor-clean` | 死代码清理与重构 |

---

## React 开发

| Command | 用途 |
|---|---|
| `/react-build` | React 组件构建与修复 |
| `/react-review` | React 专项审查 |
| `/react-test` | React 测试 |

---

## 会话与上下文

| Command | 用途 |
|---|---|
| `/checkpoint` | 创建检查点 |
| `/save-session` | 保存会话 |
| `/sessions` | 会话列表 |
| `/aside` | 旁路任务 |
| `/learn` | 从会话提取模式 |

---

## Skills 与文档

| Command | 用途 |
|---|---|
| `/skill-create` | 创建新 skill |
| `/skill-health` | skill 健康检查 |
| `/update-docs` | 更新文档 |
| `/prune` | 清理无用内容 |

---

## PR 与协作

| Command | 用途 |
|---|---|
| `/pr` | 创建 PR |
| `/review-pr` | 审查 PR |
| `/plan-prd` | 规划 PRD |
| `/model-route` | 模型路由 |
| `/cost-report` | 成本报告 |

---

## PRP / Epic / Multi 系列

| Command | 用途 |
|---|---|
| `/prp-plan` `/prp-implement` `/prp-pr` | PRP 工作流 |
| `/epic-claim` `/epic-review` `/epic-validate` | Epic 管理 |
| `/multi-plan` `/multi-execute` | 多任务编排 |

> 详细用法见 ECC 文档。RSK 场景下 `/multi-backend` `/multi-frontend` 不适用（技术栈固定）。

---

## 不适用命令（RSK 技术栈外）

以下命令面向非 React/Next.js 技术栈，**不应在 RSK 项目中使用**：

| 命令 | 技术栈 | RSK 替代 |
|---|---|---|
| `/go-build` `/go-review` `/go-test` | Go | `/build-fix` `/code-review` |
| `/rust-build` `/rust-review` `/rust-test` | Rust | `/build-fix` `/code-review` |
| `/kotlin-build` `/kotlin-review` `/kotlin-test` | Kotlin | `/build-fix` `/code-review` |
| `/cpp-build` `/cpp-review` `/cpp-test` | C++ | `/build-fix` `/code-review` |
| `/flutter-build` `/flutter-test` | Flutter | — |
| `/python-review` | Python | `/code-review` |
| `/vue-review` | Vue | `/react-review` |
| `/gradle-build` | Gradle | — |
| `/multi-backend` | 多后端 | — |
| `/multi-frontend` | 多前端 | — |

---

## 命令选择决策树

```
要做什么？
├── 新项目 → /fullstack-init
├── 规划功能 → /plan
├── 写代码 → /feature-dev
├── 审查代码
│   ├── 通用 → /code-review
│   ├── React/JSX → /react-review
│   ├── Next.js App Router → /nextjs-review
│   ├── Supabase/RLS → /supabase-review
│   └── PR → /review-pr
├── 测试
│   ├── 组件 → /react-test
│   └── 覆盖率 → /test-coverage
├── 构建失败 → /build-fix
├── 类型问题 → /typecheck-e2e
├── 数据库变更 → /supabase-migrate
├── 部署 → /vercel-deploy
└── 其他 → 查阅 ECC 文档
```

---

## 相关文档

- [AGENTS.md](AGENTS.md) — Agent 索引与编排规则
- [CLAUDE.md](CLAUDE.md) — Claude Code 指南
- [ecc/COMMANDS-QUICK-REF.md](ecc/COMMANDS-QUICK-REF.md) — ECC 完整命令索引（59 个）
