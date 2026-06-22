---
paths:
  - "**/app/**/*.test.{ts,tsx}"
  - "**/app/**/*.spec.{ts,tsx}"
  - "**/tests/**/*.ts"
  - "**/e2e/**/*.ts"
---
# Next.js Testing

> Next.js App Router 测试策略。继承 [common/testing.md](../common/testing.md) 与 [react/testing.md](../react/testing.md)。

## 测试分层

| 类型 | 工具 | 目标 |
|---|---|---|
| Server Component | Vitest + Testing Library | 渲染、数据展示 |
| Client Component | Vitest + Testing Library | 交互、状态、hooks |
| Server Action | Vitest | 输入校验、授权、返回值 |
| Middleware | Vitest | 重定向、cookie 操作 |
| Route Handler | Vitest | 方法校验、响应、CORS |
| E2E | Playwright | 关键用户流程 |

## Server Component 测试

```typescript
// app/profile/page.tsx
import { createServerClient } from '@/lib/supabase/server'

export default async function ProfilePage() {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()
  return <div>{user?.email}</div>
}

// __tests__/profile.test.tsx
import { render, screen } from '@testing-library/react'
import { vi } from 'vitest'
import ProfilePage from '@/app/profile/page'

vi.mock('@/lib/supabase/server', () => ({
  createServerClient: () => ({
    auth: {
      getUser: () => ({
        data: { user: { email: 'test@example.com' } },
      }),
    },
  }),
}))

test('renders user email', async () => {
  const ui = await ProfilePage()
  render(ui)
  expect(screen.getByText('test@example.com')).toBeInTheDocument()
})
```

## Client Component 测试

```typescript
// components/counter.tsx
'use client'
import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  return (
    <div>
      <span>{count}</span>
      <button onClick={() => setCount(c => c + 1)}>+</button>
    </div>
  )
}

// __tests__/counter.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { Counter } from '@/components/counter'

test('increments count', () => {
  render(<Counter />)
  expect(screen.getByText('0')).toBeInTheDocument()
  fireEvent.click(screen.getByText('+'))
  expect(screen.getByText('1')).toBeInTheDocument()
})
```

## Server Action 测试

```typescript
// lib/actions/create-post.ts
import { z } from 'zod'

const Schema = z.object({
  title: z.string().min(1).max(200),
})

export async function createPost(formData: FormData) {
  const parsed = Schema.safeParse({ title: formData.get('title') })
  if (!parsed.success) {
    return { error: 'Invalid title' }
  }
  // ...
  return { success: true }
}

// __tests__/create-post.test.ts
import { createPost } from '@/lib/actions/create-post'

test('rejects empty title', async () => {
  const formData = new FormData()
  formData.append('title', '')
  const result = await createPost(formData)
  expect(result.error).toBeDefined()
})

test('accepts valid title', async () => {
  const formData = new FormData()
  formData.append('title', 'Hello World')
  const result = await createPost(formData)
  expect(result.success).toBe(true)
})
```

## Middleware 测试

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  return NextResponse.next()
}

// __tests__/middleware.test.ts
import { NextRequest, NextResponse } from 'next/server'
import { middleware } from '@/middleware'

function createRequest(pathname: string, cookies: Record<string, string> = {}) {
  const url = `http://localhost${pathname}`
  const request = new NextRequest(url, {
    headers: {
      cookie: Object.entries(cookies)
        .map(([k, v]) => `${k}=${v}`)
        .join('; '),
    },
  })
  // 模拟 nextUrl
  Object.defineProperty(request, 'nextUrl', {
    get: () => new URL(url),
  })
  return request
}

test('redirects to login when no token on /dashboard', () => {
  const request = createRequest('/dashboard')
  const response = middleware(request)
  expect(response.status).toBe(307)
  expect(response.headers.get('location')).toContain('/login')
})

test('allows access to /dashboard with token', () => {
  const request = createRequest('/dashboard', { token: 'valid' })
  const response = middleware(request)
  expect(response.status).toBe(200)
})
```

## Route Handler 测试

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({ posts: [] })
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  return NextResponse.json({ id: 1, ...body }, { status: 201 })
}

// __tests__/api-posts.test.ts
import { GET, POST } from '@/app/api/posts/route'

test('GET returns posts', async () => {
  const response = await GET()
  const data = await response.json()
  expect(data.posts).toEqual([])
})

test('POST creates post', async () => {
  const request = new Request('http://localhost/api/posts', {
    method: 'POST',
    body: JSON.stringify({ title: 'New Post' }),
    headers: { 'Content-Type': 'application/json' },
  })
  const response = await POST(request as any)
  expect(response.status).toBe(201)
  const data = await response.json()
  expect(data.title).toBe('New Post')
})
```

## E2E 测试（Playwright）

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('user can login', async ({ page }) => {
  await page.goto('/login')
  await page.fill('[name="email"]', 'test@example.com')
  await page.fill('[name="password"]', 'password')
  await page.click('button[type="submit"]')

  await expect(page).toHaveURL('/dashboard')
  await expect(page.locator('h1')).toHaveText('Dashboard')
})
```

## 测试约定

### 命名规范

- 测试文件：`*.test.ts(x)` 或 `*.spec.ts(x)`
- E2E 测试：`e2e/*.spec.ts`
- 测试目录：`__tests__/` 或与源文件同目录

### Mock 约定

- 优先 mock 边界（API 调用、数据库、外部服务）
- 避免过度 mock 内部模块
- 使用 `vi.mock()` mock 模块

### 覆盖率目标

- 行覆盖率 ≥ 80%
- 分支覆盖率 ≥ 80%
- 关键路径（认证、支付、数据写入）100%
