---
paths:
  - "**/app/**/*.ts"
  - "**/app/**/*.tsx"
  - "**/middleware.ts"
  - "**/lib/actions/**/*.ts"
---
# Next.js Security

> Next.js App Router 安全规范。继承 [common/security.md](../common/security.md) 与 [react/security.md](../react/security.md)。

## Server Actions 安全（CRITICAL）

### 输入校验

所有 Server Action 必须使用 Zod 校验输入：

```typescript
// ✅ 正确：Zod 校验
import { z } from 'zod'

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().max(10000).optional(),
  published: z.boolean().default(false),
})

export async function createPost(formData: FormData) {
  const parsed = CreatePostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    published: formData.get('published') === 'true',
  })

  if (!parsed.success) {
    return { error: parsed.error.flatten() }
  }

  // 使用 parsed.data
}
```

```typescript
// ❌ 错误：未校验输入
export async function createPost(formData: FormData) {
  const title = formData.get('title') as string // 任意输入
  await db.post.create({ data: { title } })
}
```

### 授权校验

所有 Server Action 必须校验用户授权：

```typescript
// ✅ 正确：校验认证与授权
import { createServerClient } from '@/lib/supabase/server'

export async function deletePost(postId: string) {
  const supabase = createServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  // 1. 校验认证
  if (!user) {
    throw new Error('Unauthorized')
  }

  // 2. 校验授权（用户是否拥有该 post）
  const { data: post } = await supabase
    .from('posts')
    .select('author_id')
    .eq('id', postId)
    .single()

  if (post?.author_id !== user.id) {
    throw new Error('Forbidden')
  }

  // 3. 执行操作
  await supabase.from('posts').delete().eq('id', postId)
}
```

### 可序列化返回值

Server Action 不能返回非可序列化值：

```typescript
// ❌ 错误：返回 Map / Set / Date / 函数
export async function getData() {
  return {
    items: new Map(), // 不可序列化
    timestamp: new Date(), // Date 在某些场景下有问题
    callback: () => {}, // 函数不可序列化
  }
}

// ✅ 正确：返回纯对象
export async function getData() {
  return {
    items: { key: 'value' },
    timestamp: new Date().toISOString(),
  }
}
```

## 环境变量安全（CRITICAL）

### `NEXT_PUBLIC_*` 前缀约定

- `NEXT_PUBLIC_*` 前缀的变量会暴露给 Client，**仅用于公开信息**
- Service Role Key、密钥等**永不**使用 `NEXT_PUBLIC_*` 前缀

```bash
# ✅ 正确：公开信息使用 NEXT_PUBLIC_
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx

# ❌ 错误：Service Role Key 暴露给 Client
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=eyJxxx # CRITICAL 泄露

# ✅ 正确：Service Role Key 仅服务端
SUPABASE_SERVICE_ROLE_KEY=eyJxxx
```

### 服务端密钥访问

```typescript
// ✅ 正确：服务端访问密钥
import 'server-only'

const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!serviceRoleKey) {
  throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY')
}
```

## Server / Client 边界安全

### `"server-only"` 标记

服务端专用模块必须标记 `"server-only"`：

```typescript
// lib/supabase/admin.ts
import 'server-only'
import { createClient } from '@supabase/supabase-js'

export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )
}
```

```typescript
// ❌ 错误：Client Component 导入 server-only 模块
'use client'
import { createAdminClient } from '@/lib/supabase/admin' // 构建错误
```

### `"client-only"` 标记

客户端专用模块可标记 `"client-only"`：

```typescript
// lib/window-size.ts
import 'client-only'
import { useState, useEffect } from 'react'

export function useWindowSize() {
  const [size, setSize] = useState({ width: 0, height: 0 })
  useEffect(() => {
    setSize({ width: window.innerWidth, height: window.innerHeight })
  }, [])
  return size
}
```

## Middleware 安全

### Matcher 配置

Middleware 应排除静态资源：

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  // 会话刷新逻辑
  return NextResponse.next()
}

// ✅ 正确：排除静态资源
export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### 避免重计算

Middleware 在每个请求执行，**禁止**重计算：

```typescript
// ❌ 错误：Middleware 中查询数据库
export async function middleware(request: NextRequest) {
  const user = await db.user.findById(request.cookies.get('user-id'))
  // 每个请求都查询数据库，性能灾难
}

// ✅ 正确：仅检查 cookie 存在性
export function middleware(request: NextRequest) {
  const token = request.cookies.get('supabase-auth-token')
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  return NextResponse.next()
}
```

## `headers()` / `cookies()` 安全

### 同步调用

`headers()` 和 `cookies()` 在 Server Component 中是同步的，但在 Server Actions / Route Handlers 中是异步的：

```typescript
// Server Component（同步）
import { cookies, headers } from 'next/headers'

export default function Page() {
  const cookieStore = cookies()
  const headerList = headers()
  const token = cookieStore.get('token')?.value
  // ...
}

// Server Action / Route Handler（Next.js 15+ 异步）
export async function action() {
  const cookieStore = await cookies()
  const headerList = await headers()
  // ...
}
```

### 不要在 Client Component 中使用

```typescript
// ❌ 错误：Client Component 中调用
'use client'
import { cookies } from 'next/headers'

export function Component() {
  const token = cookies().get('token') // 构建错误
}
```

## Route Handler 安全

### 方法校验

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  // GET 逻辑
}

export async function POST(request: NextRequest) {
  // POST 逻辑
}

// ❌ 未导出的方法会自动返回 405
```

### CORS 处理

```typescript
// app/api/posts/route.ts
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://yourdomain.com',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
}

export async function OPTIONS() {
  return new NextResponse(null, { status: 204, headers: corsHeaders })
}

export async function GET() {
  const data = await getPosts()
  return NextResponse.json(data, { headers: corsHeaders })
}
```
