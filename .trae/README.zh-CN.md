# ECC-RSK for Trae（中文版）

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## 快速开始

### 方式 1：本地安装（仅当前项目）

```bash
# 安装到当前项目
cd /path/to/your/project
TRAE_ENV=cn .trae/install.sh
```

这会在项目目录创建 `.trae-cn/`。

### 方式 2：全局安装（所有项目）

```bash
# 全局安装到 ~/.trae-cn/
cd /path/to/your/project
TRAE_ENV=cn .trae/install.sh ~
```

## 包含内容

### Commands（~61）

通过 Trae 聊天中的 `/` 菜单调用。

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

## 安全检查清单（CRITICAL）

每次提交前检查：

- **所有 Supabase 表启用 RLS**
- **Server Action 用 Zod 校验输入**
- **Server Action 校验授权**
- **Service Role Key 不暴露给 Client**
- **Edge Functions 校验 JWT**
- **`NEXT_PUBLIC_*` 仅用于公开信息**

## 推荐工作流

1. **规划先行**：使用 `/plan` 拆解复杂功能
2. **测试优先**：使用 `/tdd` 在实现前编写测试
3. **代码审查**：使用 `/code-review` 检查代码质量
4. **安全检查**：使用 `/supabase-review` 检查 Supabase 代码，`/nextjs-review` 检查 Next.js 代码
5. **修复构建**：使用 `/build-fix` 修复构建错误

## 卸载

```bash
cd .trae-cn
./uninstall.sh
```