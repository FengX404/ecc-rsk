# ECC-RSK — ECC-React-Stack-Kit

> **ECC-RSK** 是从 [Everything Claude Code (ECC)](https://github.com/affaan-m/ECC) 扩展而来的全栈开发专项插件包，聚焦 **React + Next.js + Vercel + Supabase** 技术栈。

| | |
|---|---|
| **全名** | ECC-React-Stack-Kit (ECC-RSK) |
| **定位** | ECC 的全栈 Web 开发子集 + Supabase/Next.js/Vercel 专项扩展 |
| **技术栈** | React · Next.js (App Router) · Vercel · Supabase · TypeScript · Tailwind CSS · shadcn/ui · TanStack Query · Zustand · React Hook Form · Zod · Vitest · Playwright |
| **与 ECC 的关系** | Git Submodule + Symlink 架构 |
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
.\install.ps1 -UseCopy
```

---

## 与 ECC 的关系

ECC-RSK 采用 **Git Submodule + Symlink** 架构：

- `ecc/` 目录是 ECC 仓库的 Git submodule
- 复用的 agents/skills/commands/rules 通过 symlink 指向 `ecc/` 目录
- 新增内容本地独立维护

**同步 ECC 上游**：
```bash
git submodule update --remote ecc
./install.sh  # 如有新增文件
git add ecc
git commit -m "sync: update ECC submodule"
```

---

## 内容概览

### 从 ECC 复用

- **Agents**：planner、architect、react-reviewer、tdd-guide、e2e-runner 等（17 个）
- **Skills**：api-design、blueprint、browser-qa、council、gateguard 等（14 个）
- **Commands**：plan、code-review、build-fix、react-build、learn 等（~40 个）
- **Rules**：common、react、typescript、web、nuxt（5 套）

### ECC-RSK 新增

- **Agents**：typescript-reviewer、supabase-reviewer、nextjs-reviewer、vercel-deployer、fullstack-architect（5 个）
- **Skills**：supabase-patterns、nextjs-app-router、vercel-deployment、fullstack-auth、realtime-sync、type-safe-stack、form-patterns（7 个）
- **Commands**：supabase-review、supabase-migrate、nextjs-review、vercel-deploy、fullstack-init、typecheck-e2e（6 个）
- **Rules**：nextjs、supabase、vercel（3 套）

---

## 技术栈约定

| 层 | 技术 |
|---|---|
| 框架 | Next.js 15 (App Router) |
| UI | React 19 + Tailwind CSS + shadcn/ui |
| 状态 | TanStack Query + Zustand |
| 表单 | React Hook Form + Zod |
| 后端 | Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions) |
| 测试 | Vitest + Playwright |

---

## 文档

- [docs/ECC-RSK-PROPOSAL.md](docs/ECC-RSK-PROPOSAL.md) — 完整组合方案

---

## License

MIT