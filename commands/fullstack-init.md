---
description: 全栈项目脚手架（Next.js + Supabase + Tailwind + shadcn/ui + TanStack Query + Zustand + React Hook Form + Zod + Vitest + Playwright）。
---

# Fullstack Init

全栈项目脚手架生成。

## 适用场景

- 新项目初始化
- 快速原型开发
- 团队标准化项目结构

## 技术栈

| 类别 | 技术 | 用途 |
|------|------|------|
| 框架 | Next.js 15+ (App Router) | 全栈框架 |
| 数据库 | Supabase (PostgreSQL) | 数据库、认证、存储、实时 |
| 样式 | Tailwind CSS + shadcn/ui | UI 组件库 |
| 状态管理 | TanStack Query + Zustand | 服务端状态 + 客户端状态 |
| 表单 | React Hook Form + Zod | 表单处理 + 验证 |
| 测试 | Vitest + Playwright | 单元测试 + E2E 测试 |
| 类型 | TypeScript (strict) | 类型安全 |

## 工作流

### 1. 创建 Next.js 项目

```bash
# 创建项目
npx create-next-app@latest my-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# 进入项目目录
cd my-app
```

**选项说明**：
- `--typescript`: 使用 TypeScript
- `--tailwind`: 使用 Tailwind CSS
- `--eslint`: 使用 ESLint
- `--app`: 使用 App Router
- `--src-dir`: 使用 src 目录
- `--import-alias "@/*"`: 使用 @ 别名

### 2. 初始化 shadcn/ui

```bash
# 初始化 shadcn/ui
npx shadcn@latest init

# 添加常用组件
npx shadcn@latest add button
npx shadcn@latest add input
npx shadcn@latest add form
npx shadcn@latest add dialog
npx shadcn@latest add toast
npx shadcn@latest add dropdown-menu
npx shadcn@latest add avatar
npx shadcn@latest add card
npx shadcn@latest add table
```

### 3. 安装核心依赖

```bash
# Supabase
npm install @supabase/supabase-js @supabase/ssr

# TanStack Query
npm install @tanstack/react-query

# Zustand
npm install zustand

# React Hook Form + Zod
npm install react-hook-form @hookform/resolvers zod

# 工具库
npm install date-fns clsx tailwind-merge
```

### 4. 安装开发依赖

```bash
# 测试
npm install -D vitest @testing-library/react @testing-library/jest-dom @vitejs/plugin-react jsdom

# E2E 测试
npm install -D @playwright/test

# 类型
npm install -D @types/node

# ESLint + Prettier
npm install -D eslint-config-prettier prettier
```

### 5. 配置 Supabase

```bash
# 初始化 Supabase
npx supabase init

# 启动本地 Supabase
npx supabase start

# 生成类型
npx supabase gen types --typescript --local > src/types/supabase.ts
```

**环境变量**：

```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=http://localhost:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

**Supabase 客户端配置**：

```typescript
// src/lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { Database } from '@/types/supabase'

export function createClient() {
  const cookieStore = cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Server Component 中调用时可能失败
          }
        }
      }
    }
  )
}
```

```typescript
// src/lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr'
import { Database } from '@/types/supabase'

export function createClient() {
  return createBrowserClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

```typescript
// src/lib/supabase/middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({
            request
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        }
      }
    }
  )

  const {
    data: { user }
  } = await supabase.auth.getUser()

  if (!user && !request.nextUrl.pathname.startsWith('/login')) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
```

```typescript
// src/middleware.ts
import { updateSession } from '@/lib/supabase/middleware'
import { type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  return await updateSession(request)
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'
  ]
}
```

### 6. 配置 TanStack Query

```typescript
// src/lib/query-provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60 * 1000, // 1分钟
            gcTime: 5 * 60 * 1000, // 5分钟
            refetchOnWindowFocus: false
          }
        }
      })
  )

  return (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}
```

```typescript
// src/app/layout.tsx
import { QueryProvider } from '@/lib/query-provider'

export default function RootLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <html>
      <body>
        <QueryProvider>{children}</QueryProvider>
      </body>
    </html>
  )
}
```

### 7. 配置目录结构

```
src/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── signup/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   ├── (dashboard)/
│   │   ├── dashboard/
│   │   │   └── page.tsx
│   │   └── layout.tsx
│   ├── api/
│   │   └── webhooks/
│   │       └── stripe/
│   │           └── route.ts
│   ├── actions/
│   │   └── auth.ts
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   ├── ui/
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   └── ...
│   ├── forms/
│   │   ├── login-form.tsx
│   │   └── signup-form.tsx
│   └── layouts/
│       ├── header.tsx
│       └── sidebar.tsx
├── lib/
│   ├── supabase/
│   │   ├── server.ts
│   │   ├── client.ts
│   │   └── middleware.ts
│   ├── utils.ts
│   └── constants.ts
├── hooks/
│   ├── use-user.ts
│   └── use-realtime.ts
├── types/
│   ├── supabase.ts
│   └── index.ts
├── schemas/
│   ├── auth.ts
│   └── profile.ts
└── middleware.ts
```

### 8. 配置 TypeScript

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### 9. 配置 ESLint + Prettier

```json
// .eslintrc.json
{
  "extends": ["next/core-web-vitals", "prettier"],
  "rules": {
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-explicit-any": "error"
  }
}
```

```json
// .prettierrc
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "none",
  "printWidth": 100
}
```

### 10. 配置 Vitest

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}']
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})
```

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom'
```

### 11. 配置 Playwright

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry'
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] }
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] }
    }
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI
  }
})
```

### 12. 配置 GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run typecheck

      - name: Unit tests
        run: npm run test

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: E2E tests
        run: npm run test:e2e

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

### 13. 配置 Vercel

```bash
# 登录 Vercel
vercel login

# 创建项目
vercel

# 配置环境变量
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
```

## 项目模板

使用 `templates/nextjs-supabase/` 作为脚手架：

```
templates/nextjs-supabase/
├── src/
│   ├── app/
│   ├── components/
│   ├── lib/
│   ├── hooks/
│   ├── types/
│   └── schemas/
├── supabase/
│   ├── migrations/
│   ├── seed.sql
│   └── config.toml
├── e2e/
│   ├── auth.spec.ts
│   └── dashboard.spec.ts
├── .env.example
├── .eslintrc.json
├── .prettierrc
├── next.config.mjs
├── tailwind.config.ts
├── tsconfig.json
├── vitest.config.ts
├── playwright.config.ts
└── package.json
```

## 验证清单

- [ ] Next.js 项目创建成功
- [ ] shadcn/ui 初始化成功
- [ ] Supabase 本地服务启动成功
- [ ] TanStack Query 配置成功
- [ ] TypeScript strict 模式启用
- [ ] ESLint + Prettier 配置成功
- [ ] Vitest 配置成功
- [ ] Playwright 配置成功
- [ ] GitHub Actions CI 配置成功
- [ ] Vercel 项目配置成功

## 相关命令

- `/supabase-migrate` — 数据库迁移
- `/nextjs-review` — Next.js 审查
- `/vercel-deploy` — Vercel 部署

## 相关 Skills

- `supabase-patterns` — Supabase 最佳实践
- `nextjs-app-router` — Next.js App Router
- `fullstack-auth` — 认证与授权
- `type-safe-stack` — 端到端类型安全