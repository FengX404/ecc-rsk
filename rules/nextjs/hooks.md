---
paths:
  - "**/app/**/*.tsx"
  - "**/app/**/*.ts"
  - "**/middleware.ts"
  - "**/next.config.*"
---
# Next.js Hooks

> Next.js App Router 专用 hook 配置与使用规范。

## 路由 Hooks

### `usePathname`

获取当前路由路径（Client Component only）。

```typescript
// ✅ 正确：在 Client Component 中使用
'use client'
import { usePathname } from 'next/navigation'

export function Breadcrumbs() {
  const pathname = usePathname()
  // pathname: "/dashboard/settings"
  return <nav>{pathname}</nav>
}
```

```typescript
// ❌ 错误：在 Server Component 中使用
import { usePathname } from 'next/navigation'

export default function Page() {
  const pathname = usePathname() // TypeError: usePathname is not a function
}
```

### `useRouter`

路由跳转（Client Component only）。

```typescript
'use client'
import { useRouter } from 'next/navigation'

export function LoginButton() {
  const router = useRouter()

  const handleLogin = async () => {
    await signIn()
    router.push('/dashboard')
    router.refresh() // 刷新 Server Component 数据
  }

  return <button onClick={handleLogin}>登录</button>
}
```

**注意**：App Router 的 `useRouter` 来自 `next/navigation`，而非 `next/router`（Pages Router）。

### `useSearchParams`

读取 URL 查询参数（Client Component only）。

```typescript
'use client'
import { useSearchParams } from 'next/navigation'

export function FilterPanel() {
  const searchParams = useSearchParams()
  const filter = searchParams.get('filter') ?? 'all'

  return <div>当前筛选: {filter}</div>
}
```

**CRITICAL**：`useSearchParams` 必须包裹在 `<Suspense>` 中，否则会导致整个页面降级为客户端渲染：

```typescript
// ✅ 正确：包裹 Suspense
import { Suspense } from 'react'

export default function Page() {
  return (
    <Suspense fallback={<div>加载中...</div>}>
      <FilterPanel />
    </Suspense>
  )
}
```

### `useParams`

获取动态路由参数（Client Component only）。

```typescript
'use client'
import { useParams } from 'next/navigation'

export function PostTitle() {
  const params = useParams<{ id: string }>()
  return <h1>Post {params.id}</h1>
}
```

## Server Component 中获取路由信息

Server Component 不能使用 hooks，应通过 `props` 或 `headers()` 获取：

```typescript
// ✅ 正确：Server Component 通过 props 获取动态路由参数
export default async function PostPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>
}) {
  const { id } = await params
  const { filter } = await searchParams

  return <div>Post {id}, Filter: {filter}</div>
}
```

## Web Vitals 上报

### `useReportWebVitals`

上报 Web Vitals 指标（Client Component only）。

```typescript
// app/_components/web-vitals.tsx
'use client'
import { useReportWebVitals } from 'next/web-vitals'
import { useCallback } from 'react'

export function WebVitals() {
  const handleReport = useCallback((metric) => {
    // 上报到 Analytics
    fetch('/api/web-vitals', {
      method: 'POST',
      body: JSON.stringify(metric),
    })
  }, [])

  useReportWebVitals(handleReport)
  return null
}

// app/layout.tsx
import { WebVitals } from './_components/web-vitals'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <WebVitals />
      </body>
    </html>
  )
}
```

## Hook 使用约定

### Server vs Client 边界

| Hook | 可用位置 | 说明 |
|---|---|---|
| `usePathname` | Client only | 获取当前路径 |
| `useRouter` | Client only | 路由跳转 |
| `useSearchParams` | Client only（需 Suspense） | 读取查询参数 |
| `useParams` | Client only | 读取动态路由参数 |
| `useReportWebVitals` | Client only | Web Vitals 上报 |
| `cookies()` | Server only | 读取请求 cookie |
| `headers()` | Server only | 读取请求头 |
| `params`（prop） | Server / Client | 动态路由参数 |
| `searchParams`（prop） | Server only | 查询参数 |

### 常见反模式

```typescript
// ❌ 错误：在 Server Component 中使用客户端 hook
import { useState } from 'react'

export default async function Page() {
  const [data, setData] = useState(null) // TypeError
  // ...
}
```

```typescript
// ❌ 错误：从 next/router 导入（Pages Router API）
import { useRouter } from 'next/router'

// ✅ 正确：从 next/navigation 导入（App Router API）
import { useRouter } from 'next/navigation'
```

```typescript
// ❌ 错误：useSearchParams 未包裹 Suspense
export default function Page() {
  return <FilterPanel /> // 导致整个页面客户端渲染
}

// ✅ 正确：包裹 Suspense
export default function Page() {
  return (
    <Suspense fallback={<Loading />}>
      <FilterPanel />
    </Suspense>
  )
}
```
