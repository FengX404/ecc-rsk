---
name: nextjs-app-router
description: Next.js App Router 模式（RSC 边界、Server Actions、Route Handlers、Middleware、缓存策略、Streaming、Metadata）。
metadata:
  origin: ECC-RSK
---

# Next.js App Router Patterns

Next.js App Router 开发模式与最佳实践，覆盖 RSC 边界、Server Actions、Route Handlers、Middleware、缓存策略、Streaming、Metadata。

> **约束规则**（必须做 / 禁止做）见 [rules/nextjs/patterns.md](../../rules/nextjs/patterns.md)。本文件聚焦工作流与代码示例。

## When to Activate

- 设计 RSC / Client Component 边界
- 编写 Server Actions
- 配置 Route Handlers
- 编写 Middleware
- 设计缓存策略
- 实现 Streaming
- 配置 Metadata 与 SEO

---

## 1. RSC / Client Component 边界

### 1.1 默认 Server Component

所有 `app/` 目录下的组件默认为 Server Component，无需标记。

### 1.2 `"use client"` 最小化原则

只在以下情况使用 `"use client"`：
- 使用 React hooks（`useState`、`useEffect`、`useRef` 等）
- 使用事件处理器（`onClick`、`onChange` 等）
- 使用浏览器 API（`window`、`document`、`localStorage` 等）
- 使用 Context Provider

### 1.3 通过 `children` 传递 Server Component

```typescript
// ❌ Before: Client Component 直接导入 Server Component
'use client'
import ServerComponent from './ServerComponent'

export default function ClientWrapper() {
  return (
    <div>
      <ServerComponent /> // 错误：Client 不能导入 Server
    </div>
  )
}

// ✅ After: 通过 children 传递
'use client'
export default function ClientWrapper({ children }: { children: React.ReactNode }) {
  return (
    <div>
      {children}
    </div>
  )
}

// Server Component 使用
import ClientWrapper from './ClientWrapper'
import ServerComponent from './ServerComponent'

export default function Page() {
  return (
    <ClientWrapper>
      <ServerComponent />
    </ClientWrapper>
  )
}
```

### 1.4 `import "server-only"` 标记

```typescript
// lib/supabase/server.ts
import 'server-only' // 确保 Client Component 无法导入

import { createServerClient } from '@supabase/ssr'

export function createClient() {
  // ...
}
```

---

## 2. Server Actions

### 2.1 输入校验（Zod）

```typescript
// app/actions/create-post.ts
'use server'

import { z } from 'zod'
import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().optional(),
})

export async function createPost(input: unknown) {
  // 1. 校验输入
  const parsed = CreatePostSchema.safeParse(input)
  if (!parsed.success) {
    return { error: 'Invalid input', details: parsed.error.flatten() }
  }

  // 2. 校验授权
  const supabase = createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Unauthorized' }
  }

  // 3. 执行操作
  const { data, error } = await supabase
    .from('posts')
    .insert({
      user_id: user.id,
      title: parsed.data.title,
      content: parsed.data.content,
    })
    .select()
    .single()

  if (error) {
    return { error: error.message }
  }

  // 4. 刷新缓存
  revalidatePath('/posts')

  return { data }
}
```

### 2.2 使用 `useActionState` 集成

```typescript
// app/posts/create-form.tsx
'use client'

import { useActionState } from 'react'
import { createPost } from '@/app/actions/create-post'

export function CreatePostForm() {
  const [state, formAction, isPending] = useActionState(createPost, null)

  return (
    <form action={formAction}>
      <input name="title" type="text" required />
      <textarea name="content" />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
      {state?.error && <p className="error">{state.error}</p>}
    </form>
  )
}
```

### 2.3 返回可序列化类型

```typescript
// ❌ Before: 返回不可序列化类型
export async function getPost() {
  return new Date() // Date 不可序列化
}

// ✅ After: 返回可序列化类型
export async function getPost() {
  return {
    createdAt: new Date().toISOString(), // string 可序列化
  }
}
```

---

## 3. Route Handlers

### 3.1 方法校验

```typescript
// app/api/posts/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const supabase = createClient()
  const { data } = await supabase.from('posts').select()
  return NextResponse.json(data)
}

export async function POST(request: Request) {
  const supabase = createClient()
  const body = await request.json()

  const { data, error } = await supabase
    .from('posts')
    .insert(body)
    .select()
    .single()

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }

  return NextResponse.json(data)
}
```

### 3.2 CORS 处理

```typescript
// app/api/posts/route.ts
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders })
}

export async function GET(request: Request) {
  const data = await getPosts()
  return NextResponse.json(data, { headers: corsHeaders })
}
```

---

## 4. Middleware

### 4.1 会话刷新 + 路由保护

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request })

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
          response = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 刷新会话
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // 路由保护
  const protectedPaths = ['/dashboard', '/settings']
  const isProtectedPath = protectedPaths.some((path) =>
    request.nextUrl.pathname.startsWith(path)
  )

  if (!user && isProtectedPath) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    url.searchParams.set('redirect', request.nextUrl.pathname)
    return NextResponse.redirect(url)
  }

  return response
}

// matcher：排除静态资源
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

---

## 5. 缓存策略

### 5.1 `fetch` cache 选项

```typescript
// 默认：缓存（等同于 `cache: 'force-cache'`）
const data = await fetch('https://api.example.com/data')

// 不缓存（每次请求）
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store',
})

// 定时重新验证（ISR）
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 60 }, // 60秒后重新验证
})

// 按标签重新验证
const data = await fetch('https://api.example.com/data', {
  next: { tags: ['posts'] },
})
```

### 5.2 `unstable_cache`

```typescript
import { unstable_cache } from 'next/cache'

export const getPosts = unstable_cache(
  async () => {
    const supabase = createClient()
    const { data } = await supabase.from('posts').select()
    return data
  },
  ['posts'], // key 必须稳定
  {
    revalidate: 60,
    tags: ['posts'],
  }
)
```

### 5.3 `revalidatePath` / `revalidateTag`

```typescript
import { revalidatePath, revalidateTag } from 'next/cache'

// 刷新特定路径
revalidatePath('/posts')

// 刷新特定标签
revalidateTag('posts')

// 刷新所有路径
revalidatePath('/', 'layout')
```

---

## 6. Streaming 与 Suspense

### 6.1 Suspense 边界

```typescript
// app/posts/page.tsx
import { Suspense } from 'react'

export default function PostsPage() {
  return (
    <div>
      <h1>Posts</h1>
      <Suspense fallback={<PostsSkeleton />}>
        <PostsList />
      </Suspense>
    </div>
  )
}

// app/posts/posts-list.tsx
async function PostsList() {
  const posts = await getPosts() // 异步数据获取
  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 6.2 嵌套 Suspense

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react'

export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<HeaderSkeleton />}>
        <Header />
      </Suspense>
      <Suspense fallback={<ContentSkeleton />}>
        <Content />
      </Suspense>
    </div>
  )
}
```

---

## 7. Metadata 与 SEO

### 7.1 静态 Metadata

```typescript
// app/layout.tsx
import { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'My App',
  description: 'Description',
  openGraph: {
    title: 'My App',
    description: 'Description',
    type: 'website',
  },
}
```

### 7.2 动态 Metadata

```typescript
// app/posts/[id]/page.tsx
import { Metadata } from 'next'
import { createClient } from '@/lib/supabase/server'

export async function generateMetadata({
  params,
}: {
  params: { id: string }
}): Promise<Metadata> {
  const supabase = createClient()
  const { data: post } = await supabase
    .from('posts')
    .select('title, content')
    .eq('id', params.id)
    .single()

  return {
    title: post?.title || 'Post',
    description: post?.content?.slice(0, 160),
  }
}
```

### 7.3 `sitemap.ts` / `robots.ts`

```typescript
// app/sitemap.ts
import { MetadataRoute } from 'next'
import { createClient } from '@/lib/supabase/server'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const supabase = createClient()
  const { data: posts } = await supabase.from('posts').select('id')

  return [
    {
      url: 'https://example.com',
      lastModified: new Date(),
    },
    ...posts.map((post) => ({
      url: `https://example.com/posts/${post.id}`,
      lastModified: new Date(),
    })),
  ]
}

// app/robots.ts
import { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
    },
    sitemap: 'https://example.com/sitemap.xml',
  }
}
```

---

## Best Practices

1. **默认 Server Component** — 减少 Bundle 大小
2. **`"use client"` 最小化** — 仅在必要时使用
3. **Server Actions 输入校验** — Zod schema
4. **Server Actions 授权校验** — 检查用户身份
5. **Server Actions 刷新缓存** — `revalidatePath` / `revalidateTag`
6. **Middleware 排除静态资源** — matcher 配置
7. **`fetch` 设置 cache 选项** — 明确缓存策略
8. **Suspense 边界细化** — 渐进式渲染
9. **`next/image` 优化图片** — 设置 `priority` / `sizes`
10. **`next/font` 优化字体** — 减少字体加载时间