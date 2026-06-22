# ECC-RSK for Qoder（中文版）

> ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase。

## 快速开始

### 方式 1：本地安装

```bash
cd /path/to/your/project
.qoder/install.sh
```

### 方式 2：全局安装

```bash
.qoder/install.sh ~
```

## 包含内容

### Commands（~61）

**复用 ECC（~55）**：`/plan`、`/code-review`、`/tdd` 等

**ECC-RSK 新增（6）**：`/supabase-review`、`/nextjs-review`、`/vercel-deploy` 等

### Agents（22）

**复用 ECC（17）** + **新增（5）**：typescript-reviewer、supabase-reviewer 等

### Skills（21）

**复用 ECC（14）** + **新增（7）**：supabase-patterns、nextjs-app-router 等

## 安全检查清单

- **所有 Supabase 表启用 RLS**
- **Server Action 用 Zod 校验输入**
- **Server Action 校验授权**
- **Service Role Key 不暴露给 Client**

## 卸载

```bash
cd .qoder
./uninstall.sh
```