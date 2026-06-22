# ECC-RSK Cursor Rules

> 本文件为 Cursor IDE 提供 ECC-RSK 的规则索引。

## 项目概述

ECC-RSK 是 ECC 的全栈 Web 开发子集，聚焦 React + Next.js + Vercel + Supabase 技术栈。

## 技术栈

| 层 | 技术 |
|---|---|
| 框架 | Next.js 15 (App Router) |
| UI | React 19 + Tailwind CSS + shadcn/ui |
| 状态 | TanStack Query + Zustand |
| 表单 | React Hook Form + Zod |
| 后端 | Supabase |
| 测试 | Vitest + Playwright |
| 类型 | TypeScript strict |

## 规则索引

### 复用 ECC（通过 symlink）

- `rules/common/` — 通用规则
- `rules/react/` — React 规则
- `rules/typescript/` — TypeScript 规则
- `rules/web/` — Web 规则

### ECC-RSK 新增

- `rules/nextjs/` — Next.js App Router 规则
  - `patterns.md` — RSC 边界、Server Actions、缓存
  - `hooks.md` — Next.js 专用 hooks
  - `security.md` — Server Action 安全、环境变量
  - `testing.md` — App Router 测试策略
  - `performance.md` — 性能优化
- `rules/supabase/` — Supabase 规则
  - `patterns.md` — RLS、Auth、Realtime、Storage
  - `hooks.md` — Supabase 专用 hooks
  - `security.md` — RLS 必备、SQL 注入防护
  - `testing.md` — RLS 测试、Edge Functions 测试
- `rules/vercel/` — Vercel 部署规则
  - `patterns.md` — 部署模式、环境变量
  - `hooks.md` — 部署 hook 配置
  - `security.md` — 环境变量安全、防火墙
  - `performance.md` — Edge Runtime、Bundle 优化

## 安全约定（CRITICAL）

- **所有 Supabase 表必须启用 RLS**
- **Server Action 必须用 Zod 校验输入**
- **Server Action 必须校验授权**
- **Service Role Key 永不暴露给 Client**
- **Edge Functions 必须校验 JWT**
- **`NEXT_PUBLIC_*` 仅用于公开信息**

## 编码约定

- TypeScript strict 模式
- 优先 Server Component，最小化 `"use client"`
- 使用 `import type` 导入类型
- 永不突变现有对象（immutability）
- 文件 200-400 行，不超过 800 行

## 测试约定

- 单元测试：Vitest
- 组件测试：Vitest + Testing Library
- E2E 测试：Playwright
- 覆盖率：≥ 80%
- RLS 策略：100% 覆盖

## 常用命令

- `/nextjs-review` — Next.js 专项审查
- `/supabase-review` — Supabase 专项审查
- `/vercel-deploy` — Vercel 部署
- `/fullstack-init` — 全栈项目脚手架
- `/typecheck-e2e` — 端到端类型安全检查
