# Next.js + Supabase App Template

这是一个使用 Next.js 15+ 和 Supabase 构建的全栈应用模板。

## 技术栈

- **框架**: Next.js 15+ (App Router)
- **数据库**: Supabase (PostgreSQL)
- **认证**: Supabase Auth (PKCE)
- **状态管理**: TanStack Query + Zustand
- **表单**: React Hook Form + Zod
- **样式**: Tailwind CSS + shadcn/ui
- **测试**: Vitest + Playwright
- **类型**: TypeScript (strict)

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env.local
```

编辑 `.env.local` 文件，填入你的 Supabase 配置：

```bash
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. 启动本地 Supabase

```bash
npm run supabase:start
```

### 4. 应用数据库迁移

```bash
npm run supabase:reset
```

### 5. 生成类型

```bash
npm run supabase:gen
```

### 6. 启动开发服务器

```bash
npm run dev
```

## 目录结构

```
src/
├── app/                 # Next.js App Router
│   ├── layout.tsx       # 根布局
│   ├── page.tsx         # 首页
│   └── globals.css      # 全局样式
├── components/          # React 组件
├── lib/                 # 工具库
│   ├── supabase/        # Supabase 客户端
│   ├── query-provider.tsx # TanStack Query Provider
│   └── utils.ts         # 工具函数
├── hooks/               # React Hooks
├── types/               # TypeScript 类型
│   └── supabase.ts      # Supabase 类型
├── schemas/             # Zod Schema
│   ├── auth.ts          # 认证 Schema
│   └── profile.ts       # Profile Schema
├── test/                # 测试配置
│   └── setup.ts         # Vitest setup
└── middleware.ts        # Next.js Middleware

supabase/
├── config.toml          # Supabase 配置
├── migrations/          # 数据库迁移
└── seed.sql             # 种子数据

e2e/                     # Playwright E2E 测试
├── auth.spec.ts         # 认证测试
└── dashboard.spec.ts    # Dashboard 测试
```

## 可用命令

| 命令 | 说明 |
|------|------|
| `npm run dev` | 启动开发服务器 |
| `npm run build` | 构建生产版本 |
| `npm run start` | 启动生产服务器 |
| `npm run lint` | 运行 ESLint |
| `npm run typecheck` | TypeScript 类型检查 |
| `npm run test` | 运行 Vitest 测试 |
| `npm run test:e2e` | 运行 Playwright 测试 |
| `npm run format` | 格式化代码 |
| `npm run supabase:start` | 启动本地 Supabase |
| `npm run supabase:stop` | 停止本地 Supabase |
| `npm run supabase:reset` | 重置数据库 |
| `npm run supabase:gen` | 生成类型 |

## 相关文档

- [Next.js 文档](https://nextjs.org/docs)
- [Supabase 文档](https://supabase.com/docs)
- [TanStack Query 文档](https://tanstack.com/query/latest)
- [React Hook Form 文档](https://react-hook-form.com)
- [Zod 文档](https://zod.dev)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)
- [shadcn/ui 文档](https://ui.shadcn.com)