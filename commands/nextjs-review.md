---
description: Next.js App Router 专项审查（RSC 边界、Server Actions、缓存、Middleware、Metadata）。调用 nextjs-reviewer agent。
---

# Next.js Review

调用 `nextjs-reviewer` agent 进行 Next.js App Router 专项审查。

## 适用场景

- 新增 Server Components / Client Components
- 新增 Server Actions
- 新增 Route Handlers
- 新增 Middleware
- 缓存策略变更
- 性能优化
- SEO 优化
- 定期代码审计

## 工作流

### 1. 环境检测

```bash
# 检测 Next.js 版本
npx next --version

# 检测 App Router 使用
ls -la app/

# 检测配置
cat next.config.mjs
cat middleware.ts
```

### 2. 构建与 Lint

```bash
# 构建检查
next build

# Lint 检查
next lint

# 类型检查
tsc --noEmit

# Bundle 分析
ANALYZE=true next build
```

### 3. RSC 边界审查

扫描 `"use client"` / `"use server"` 指令：

**检查项**：
- [ ] 是否正确区分 Server Component 和 Client Component
- [ ] 是否避免在 Server Component 中使用客户端 API
- [ ] 是否避免在 Client Component 中使用服务端 API
- [ ] Server Actions 是否正确标记 `"use server"`
- [ ] 是否正确传递 props（可序列化）

**RSC 边界规则**：

```typescript
// ✅ 正确：Server Component（默认）
// app/profile/page.tsx
import { createServerClient } from '@/lib/supabase/server'

export default async function ProfilePage() {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  return <div>{user?.email}</div>
}

// ✅ 正确：Client Component
// components/counter.tsx
'use client'

import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}

// ✅ 正确：Server Action
// app/actions/update-profile.ts
'use server'

import { createServerClient } from '@/lib/supabase/server'

export async function updateProfile(formData: FormData) {
  const supabase = createServerClient()
  // ...
}

// ❌ 错误：Server Component 中使用 useState
export default function Page() {
  const [count, setCount] = useState(0) // Error!
  return <div>{count}</div>
}

// ❌ 错误：Client Component 中使用服务端 API
'use client'

export function Component() {
  const supabase = createServerClient() // Error! 不能在客户端使用
}

// ✅ 正确：通过 props 传递可序列化数据
export default async function Page() {
  const data = await fetchData()
  return <ClientComponent data={data} />
}

// ❌ 错误：传递不可序列化的 props
export default function Page() {
  const fn = () => {}
  return <ClientComponent onClick={fn} /> // Error! 函数不可序列化
}
```

### 4. Server Actions 审查

扫描 `app/**/*actions*.ts` 和 `"use server"` 文件：

**检查项**：
- [ ] 是否正确标记 `"use server"`
- [ ] 是否验证输入（Zod schema）
- [ ] 是否验证用户身份
- [ ] 是否正确处理错误
- [ ] 是否避免暴露敏感数据
- [ ] 是否使用 `revalidatePath` / `revalidateTag` 刷新缓存

**Server Actions 安全模式**：

```typescript
// ✅ 正确：验证输入 + 授权检查 + 错误处理
'use server'

import { createServerClient } from '@/lib/supabase/server'
import { z } from 'zod'
import { revalidatePath } from 'next/cache'

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  channel_id: z.string().uuid()
})

export async function createPost(formData: FormData) {
  // 1. 验证用户身份
  const supabase = createServerClient()
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (authError || !user) {
    return { error: 'Unauthorized' }
  }

  // 2. 验证输入
  const input = createPostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    channel_id: formData.get('channel_id')
  })

  if (!input.success) {
    return { error: 'Invalid input', issues: input.error.issues }
  }

  // 3. 执行操作
  const { data, error } = await supabase
    .from('posts')
    .insert({
      ...input.data,
      author_id: user.id
    })
    .select()
    .single()

  if (error) {
    return { error: error.message }
  }

  // 4. 刷新缓存
  revalidatePath('/posts')
  revalidateTag('posts')

  return { data }
}

// ❌ 错误：未验证输入
export async function createPost(formData: FormData) {
  const supabase = createServerClient()
  await supabase
    .from('posts')
    .insert({
      title: formData.get('title'), // 未验证！
      content: formData.get('content') // 未验证！
    })
}

// ❌ 错误：未验证用户身份
export async function createPost(formData: FormData) {
  const supabase = createServerClient()
  // 任何人都可以创建！
  await supabase.from('posts').insert({ ... })
}
```

### 5. 缓存策略审查

扫描 `fetch`、`revalidate`、`cache` 配置：

**检查项**：
- [ ] 是否正确设置 `fetch` cache 选项
- [ ] 是否使用 `revalidatePath` / `revalidateTag` 刷新缓存
- [ ] 是否避免过度缓存动态数据
- [ ] 是否正确使用 ISR / SSG / SSR

**缓存策略**：

```typescript
// ✅ 正确：静态数据使用 force-cache（默认）
const data = await fetch('https://api.example.com/data', {
  cache: 'force-cache'
})

// ✅ 正确：动态数据使用 no-store
const data = await fetch('https://api.example.com/data', {
  cache: 'no-store'
})

// ✅ 正确：ISR 使用 next.revalidate
const data = await fetch('https://api.example.com/data', {
  next: { revalidate: 60 } // 60秒重新验证
})

// ✅ 正确：页面级 ISR
export const revalidate = 3600 // 1小时

export default async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <div>{data}</div>
}

// ✅ 正确：动态渲染
export const dynamic = 'force-dynamic'

export default async function Page() {
  const data = await fetch('https://api.example.com/data')
  return <div>{data}</div>
}

// ✅ 正确：使用 revalidateTag 刷新缓存
import { revalidateTag } from 'next/cache'

export async function refreshPosts() {
  'use server'
  revalidateTag('posts')
}

// ✅ 正确：使用 revalidatePath 刷新缓存
import { revalidatePath } from 'next/cache'

export async function refreshPage() {
  'use server'
  revalidatePath('/posts')
}
```

### 6. Middleware 审查

扫描 `middleware.ts`：

**检查项**：
- [ ] 是否正确配置 `matcher`
- [ ] 是否正确处理认证重定向
- [ ] 是否避免在 Middleware 中执行耗时操作
- [ ] 是否正确使用 `NextResponse`

**Middleware 模式**：

```typescript
// ✅ 正确：认证检查 + 会话刷新
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
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

  // 刷新会话
  const {
    data: { user }
  } = await supabase.auth.getUser()

  // 保护路由
  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'
  ]
}

// ❌ 错误：在 Middleware 中执行耗时操作
export async function middleware(request: NextRequest) {
  // 危险！Middleware 应该快速返回
  await fetch('https://api.example.com/data')
  return NextResponse.next()
}

// ❌ 错误：Matcher 配置错误
export const config = {
  matcher: '*' // 错误！应该使用数组
}
```

### 7. Metadata 审查

扫描 `metadata`、`generateMetadata`：

**检查项**：
- [ ] 是否正确设置 `title`、`description`、`keywords`
- [ ] 是否正确设置 Open Graph 标签
- [ ] 是否正确设置 Twitter Card 标签
- [ ] 是否使用 `generateMetadata` 动态生成

**Metadata 模式**：

```typescript
// ✅ 正确：静态 Metadata
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'My App',
  description: 'A Next.js app',
  keywords: ['Next.js', 'React', 'TypeScript'],
  openGraph: {
    title: 'My App',
    description: 'A Next.js app',
    type: 'website',
    url: 'https://myapp.com',
    images: [
      {
        url: 'https://myapp.com/og.png',
        width: 1200,
        height: 630
      }
    ]
  },
  twitter: {
    card: 'summary_large_image',
    title: 'My App',
    description: 'A Next.js app',
    images: ['https://myapp.com/og.png']
  }
}

// ✅ 正确：动态 Metadata
export async function generateMetadata({
  params
}: {
  params: { id: string }
}): Promise<Metadata> {
  const post = await getPost(params.id)

  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      type: 'article',
      url: `https://myapp.com/posts/${params.id}`,
      images: [
        {
          url: post.cover_image,
          width: 1200,
          height: 630
        }
      ]
    }
  }
}
```

### 8. 性能审查

```bash
# Bundle 分析
ANALYZE=true next build

# Lighthouse
npx lighthouse https://localhost:3000 --view

# Web Vitals
npx next-bundle-analyzer
```

**检查项**：
- [ ] 是否使用 `next/image` 优化图片
- [ ] 是否使用 `next/font` 优化字体
- [ ] 是否使用 `next/link` 预加载
- [ ] 是否避免大型客户端 bundle
- [ ] 是否使用 `dynamic` 代码分割

### 9. 生成审查报告

调用 `nextjs-reviewer` agent 输出结构化报告：

```
## Next.js 审查报告

### CRITICAL（必须修复）
- [ ] `app/actions/create-post.ts`: Server Action 未验证用户身份
- [ ] `middleware.ts`: Matcher 配置错误，可能导致无限重定向

### HIGH（强烈建议修复）
- [ ] `app/dashboard/page.tsx`: 未使用 `force-dynamic`，可能导致缓存问题
- [ ] `components/chat.tsx`: Realtime 订阅未清理

### MEDIUM（建议修复）
- [ ] `app/layout.tsx`: 缺少 Open Graph 标签
- [ ] `app/posts/page.tsx`: 建议使用 ISR 而非 SSR

### 性能建议
- 使用 `next/dynamic` 延迟加载 `components/chat.tsx`
- 为 `app/posts/page.tsx` 添加 `revalidate = 60`
- 使用 `next/image` 替换 `<img>` 标签
```

## 诊断命令

```bash
# 构建
next build

# Lint
next lint

# 类型检查
tsc --noEmit

# Bundle 分析
ANALYZE=true next build
npx @next/bundle-analyzer

# 开发服务器
next dev

# 生产服务器
next start
```

## 相关命令

- `/supabase-review` — Supabase 审查
- `/vercel-deploy` — Vercel 部署
- `/typecheck-e2e` — 端到端类型检查

## 相关 Skills

- `nextjs-app-router` — Next.js App Router 模式
- `vercel-deployment` — Vercel 部署
- `fullstack-auth` — 认证与授权