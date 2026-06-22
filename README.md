# ECC-RSK — ECC-React-Stack-Kit

> **ECC-RSK** 是从 [Everything Claude Code (ECC)](https://github.com/affaan-m/ECC) 扩展而来的全栈开发专项插件包，聚焦 **React + Next.js + Vercel + Supabase** 技术栈，为 AI 编程助手（Claude Code、Cursor、Codex、Gemini 等）提供面向现代全栈 Web 开发的 agents、skills、commands、rules、hooks 与项目模板。

| | |
|---|---|
| **全名** | ECC-React-Stack-Kit (ECC-RSK) |
| **定位** | ECC 的全栈 Web 开发子集 + Supabase/Next.js/Vercel 专项扩展 |
| **技术栈** | React · Next.js (App Router) · Vercel · Supabase · TypeScript · Tailwind CSS · shadcn/ui · TanStack Query · Zustand · React Hook Form · Zod · Vitest · Playwright |
| **与 ECC 的关系** | Git Submodule + Symlink 架构，复用 ECC 核心内容，独立维护专项扩展 |
| **License** | MIT |

---

## 快速开始

### 安装

**macOS / Linux**：
```bash
git clone --recurse-submodules https://github.com/<your-org>/ecc-rsk.git
cd ecc-rsk
./install.sh
```

**Windows**：
```powershell
git clone --recurse-submodules https://github.com/<your-org>/ecc-rsk.git
cd ecc-rsk
# 推荐：复制模式（无需特殊权限，ZIP 下载也可用）
.\install.ps1 -UseCopy

# 或使用 symlink 模式（需要 Developer Mode 或管理员权限）
.\install.ps1
```

> **Windows 用户注意**：推荐使用 `-UseCopy` 模式。Symlink 模式在 Windows 上需要 Developer Mode 或管理员权限，且 GitHub ZIP 下载、部分 IDE 索引可能异常。`-UseCopy` 模式将文件复制到本地，无上述限制，缺点是 ECC 更新后需要手动重新运行 `.\install.ps1 -UseCopy` 同步。

### 同步 ECC 更新

ECC submodule 更新后，运行同步脚本刷新 symlinks：

```bash
# macOS / Linux
./sync-ecc.sh

# 或手动两步
git submodule update --remote ecc
./install.sh --symlinks-only
```

```powershell
# Windows（复制模式重新同步）
git submodule update --remote ecc
.\install.ps1 -UseCopy
```

### 使用

ECC-RSK 可用于以下 AI 编程助手：

**核心维护**（官方跟进，功能完整）：

- **Claude Code** — 将 `ecc-rsk/` 复制到项目根目录，或配置 `CLAUDE.md` 引用
- **Cursor** — 配置 `.cursor/rules/` 和 `.cursor/hooks.json`
- **Codex** — 配置 `.codex/AGENTS.md` 和 `.codex/config.toml`
- **Gemini** — 配置 `.gemini/GEMINI.md`
- **Trae** — 配置 `.trae/`（运行 `.trae/install.sh`）
- **Zed** — 配置 `.zed/settings.json`

**社区维护**（可用，但不保证及时跟进 ECC 更新）：

- **opencode** — 配置 `.opencode/`
- **Qoder** — 配置 `.qoder/`
- **CodeBuddy** — 配置 `.codebuddy/`
- **Kiro** — 配置 `.kiro/`（仅 ECC 提供，RSK 未扩展）

> **维护等级说明**：核心维护的 IDE 适配会随 ECC-RSK 版本同步更新；社区维护的 IDE 适配由社区贡献，可能滞后于主版本。如遇问题，欢迎 PR。

---

## 与 ECC 的关系

ECC-RSK 采用 **Git Submodule + Symlink** 架构：

- `ecc/` 目录是 ECC 仓库的 Git submodule
- 复用的 agents/skills/commands/rules 通过 symlink 指向 `ecc/` 目录
- 新增内容本地独立维护

**优势**：
- `git submodule update --remote` 即可同步 ECC 最新内容
- 清晰区分复用 vs 新增内容
- 低维护成本，只维护新增部分

---

## 内容概览

### 从 ECC 复用（通过 Symlink）

| 类别 | 数量 | 说明 |
|---|---|---|
| Agents | 17 | planner、architect、react-reviewer、tdd-guide、e2e-runner 等 |
| Skills | 14 | api-design、blueprint、browser-qa、council、gateguard 等 |
| Commands | ~40 | plan、code-review、build-fix、react-build、learn、prp-* 等 |
| Rules | 5 套 | common、react、typescript、web、nuxt |

### ECC-RSK 新增（本地维护）

| 类别 | 数量 | 说明 |
|---|---|---|
| Agents | 5 | typescript-reviewer、supabase-reviewer、nextjs-reviewer、vercel-deployer、fullstack-architect |
| Skills | 7 | supabase-patterns、nextjs-app-router、vercel-deployment、fullstack-auth、realtime-sync、type-safe-stack、form-patterns |
| Commands | 6 | supabase-review、supabase-migrate、nextjs-review、vercel-deploy、fullstack-init、typecheck-e2e |
| Rules | 3 套 | nextjs、supabase、vercel |

---

## 技术栈约定

ECC-RSK 所有内容基于以下技术栈约定编写：

| 层 | 技术 |
|---|---|
| 框架 | Next.js 15 (App Router) |
| UI | React 19 + Tailwind CSS + shadcn/ui |
| 状态 | TanStack Query + Zustand |
| 表单 | React Hook Form + Zod |
| 后端 | Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions) |
| 测试 | Vitest + Playwright |
| 类型 | TypeScript strict + Zod + Supabase gen types |

详见 [docs/ECC-RSK-PROPOSAL.md](docs/ECC-RSK-PROPOSAL.md) 第 2 章。

---

## 项目模板

`templates/nextjs-supabase/` 提供全栈项目脚手架：

- Next.js 15 App Router
- Supabase Auth (PKCE) + Middleware 会话刷新
- Tailwind CSS + shadcn/ui
- TanStack Query + Zustand
- React Hook Form + Zod
- Vitest + Playwright
- GitHub Actions CI
- Vercel 部署配置

使用 `/fullstack-init` 命令生成新项目。

---

## 文档

- [docs/ECC-RSK-PROPOSAL.md](docs/ECC-RSK-PROPOSAL.md) — 完整组合方案（筛选清单、新增内容职责、技术栈、模板、路线图）
- [docs/TECH-STACK.md](docs/TECH-STACK.md) — 技术栈约定详解（待编写）
- [docs/MIGRATION-FROM-ECC.md](docs/MIGRATION-FROM-ECC.md) — 从 ECC 迁移指南（待编写）

---

## 贡献

详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## License

MIT — 与 ECC 上游保持一致。

---

## 致谢

ECC-RSK 基于以下项目构建：

- [Everything Claude Code (ECC)](https://github.com/affaan-m/ECC) — 跨语言、跨 harness 的通用 AI 编程操作系统
- [Claude Code](https://claude.ai/code) — Anthropic 的 AI 编程助手
- [TRAE](https://www.trae.com.cn) — 字节跳动的 AI 编程 IDE
- [Next.js](https://nextjs.org) — React 全栈框架
- [Supabase](https://supabase.com) — 开源 Firebase 替代方案
- [Vercel](https://vercel.com) — Next.js 原生部署平台

---

## 关注作者

| 博客 | 小红书 | X | 公众号 |
|:---:|:---:|:---:|:---:|
| [![博客](./assets/blog-qr.png)](https://fengx404.com/blog/) | [![小红书](./assets/xiaohongshu-qr.png)](https://www.xiaohongshu.com/user/profile/5fa9ed6d000000000100a8be) | [![X](./assets/x-qr.png)](https://x.com/FengX404) | ![公众号](./assets/wechat-qr.jpg) |
| [fengx404.com/blog](https://fengx404.com/blog/) | [FengX](https://www.xiaohongshu.com/user/profile/5fa9ed6d000000000100a8be) | [@FengX404](https://x.com/FengX404) | FengX |