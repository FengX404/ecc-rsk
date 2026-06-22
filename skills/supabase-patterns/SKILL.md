---
name: supabase-patterns
description: Supabase 开发模式（RLS 策略模板、Auth 集成、Realtime 订阅、Storage 上传、Edge Functions、类型生成、迁移工作流）。
metadata:
  origin: ECC-RSK
---

# Supabase Patterns

Supabase 开发模式与最佳实践，覆盖 RLS 策略、Auth 集成、Realtime 订阅、Storage 上传、Edge Functions、类型生成、迁移工作流。

> **约束规则**（必须做 / 禁止做）见 [rules/supabase/patterns.md](../../rules/supabase/patterns.md)。本文件聚焦工作流与代码示例。

## When to Activate

- 设计 RLS 策略
- 配置 Supabase Auth
- 实现 Realtime 订阅
- 上传文件到 Storage
- 编写 Edge Functions
- 生成 TypeScript 类型
- 执行数据库迁移

---

## 1. RLS 策略模板

### 1.1 行级所有权（用户只能访问自己的数据）

```sql
CREATE TABLE posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  title text NOT NULL,
  content text,
  created_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的 posts
CREATE POLICY "Users can view own posts"
  ON posts FOR SELECT
  USING (auth.uid() = user_id);

-- 用户只能插入自己的 posts
CREATE POLICY "Users can insert own posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 用户只能更新自己的 posts
CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 用户只能删除自己的 posts
CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING (auth.uid() = user_id);
```

### 1.2 多租户隔离

```sql
CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL
);

CREATE TABLE tenant_members (
  tenant_id uuid REFERENCES tenants NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  role text NOT NULL DEFAULT 'member',
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants NOT NULL,
  name text NOT NULL
);

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- 用户只能访问所属租户的 projects
CREATE POLICY "Tenant members can view projects"
  ON projects FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tenant_members
      WHERE tenant_id = projects.tenant_id
      AND user_id = auth.uid()
    )
  );
```

### 1.3 公开读 / 私有写

```sql
-- 公开读
CREATE POLICY "Public can view published posts"
  ON posts FOR SELECT
  USING (status = 'published');

-- 用户只能写入自己的 posts
CREATE POLICY "Users can manage own posts"
  ON posts FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### 1.4 列级安全（Column-level Security）

```sql
-- 用户只能查看部分列
CREATE POLICY "Users can view limited user info"
  ON users FOR SELECT
  USING (auth.uid() = id);
```

---

## 2. Auth 集成

### 2.1 PKCE 流程（Next.js App Router）

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export function createClient() {
  const cookieStore = cookies()

  return createServerClient(
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
            // Middleware 中调用会失败，忽略
          }
        },
      },
    }
  )
}
```

### 2.2 Middleware 会话刷新

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
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
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 刷新会话
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // 如需保护路由
  if (!user && request.nextUrl.pathname.startsWith('/protected')) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### 2.3 OAuth Provider 配置

```typescript
// app/auth/callback/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

  if (code) {
    const supabase = createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(new URL(next, request.url))
    }
  }

  return NextResponse.redirect(new URL('/login', request.url))
}
```

---

## 3. Realtime 订阅

### 3.1 Postgres Changes 订阅

```typescript
// hooks/use-realtime-posts.ts
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useRealtimePosts() {
  const [posts, setPosts] = useState<Post[]>([])
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase
      .channel('posts-changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'posts',
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setPosts((prev) => [...prev, payload.new as Post])
          } else if (payload.eventType === 'UPDATE') {
            setPosts((prev) =>
              prev.map((p) =>
                p.id === payload.new.id ? payload.new as Post : p
              )
            )
          } else if (payload.eventType === 'DELETE') {
            setPosts((prev) =>
              prev.filter((p) => p.id !== payload.old.id)
            )
          }
        }
      )
      .subscribe()

    // 清理订阅
    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase])

  return posts
}
```

### 3.2 Broadcast（客户端事件）

```typescript
// hooks/use-broadcast.ts
import { useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useBroadcast(channelName: string) {
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase.channel(channelName)

    channel
      .on('broadcast', { event: 'message' }, (payload) => {
        console.log('Received:', payload)
      })
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase, channelName])

  const send = (message: any) => {
    supabase.channel(channelName).send({
      type: 'broadcast',
      event: 'message',
      payload: message,
    })
  }

  return { send }
}
```

---

## 4. Storage 上传

### 4.1 服务端代传（安全）

```typescript
// app/actions/upload.ts
'use server'

import { createClient } from '@/lib/supabase/server'

export async function uploadFile(file: File) {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Unauthorized' }
  }

  const filename = `${user.id}/${Date.now()}-${file.name}`

  const { data, error } = await supabase.storage
    .from('private-files')
    .upload(filename, file, {
      contentType: file.type,
      upsert: false,
    })

  if (error) {
    return { error: error.message }
  }

  return { data }
}
```

### 4.2 签名 URL（私有文件访问）

```typescript
// lib/storage/get-signed-url.ts
import { createClient } from '@/lib/supabase/server'

export async function getSignedUrl(bucket: string, path: string) {
  const supabase = createClient()

  const { data, error } = await supabase.storage
    .from(bucket)
    .createSignedUrl(path, 3600) // 1小时有效期

  if (error) {
    return { error: error.message }
  }

  return { url: data.signedUrl }
}
```

---

## 5. Edge Functions

### 5.1 Deno 运行时约定

```typescript
// supabase/functions/hello/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const data = {
    message: "Hello from Edge Function!",
  };

  return new Response(JSON.stringify(data), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});
```

### 5.2 JWT 校验

```typescript
// supabase/functions/protected/index.ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

Deno.serve(async (req) => {
  // CORS 处理
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  // 校验 JWT
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const token = authHeader.replace('Bearer ', '')

  // 使用 Supabase client 校验 token
  const { createClient } = await import('@supabase/supabase-js')
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

  const { data: { user }, error } = await supabase.auth.getUser(token)
  if (error || !user) {
    return new Response(JSON.stringify({ error: 'Invalid token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  // 业务逻辑
  return new Response(JSON.stringify({ message: 'Hello', user }), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  })
})
```

---

## 6. 类型生成

### 6.1 自动生成

```bash
# 生成 TypeScript 类型
supabase gen types --typescript > types/supabase.ts

# 或使用 CLI
supabase gen types typescript --local > types/supabase.ts
```

### 6.2 使用生成的类型

```typescript
// types/supabase.ts（自动生成）
export type Json = string | number | boolean | null | { [key: string]: Json } | Json[]

export interface Database {
  public: {
    Tables: {
      posts: {
        Row: {
          id: string
          user_id: string
          title: string
          content: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          content?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          content?: string | null
          created_at?: string
        }
      }
    }
  }
}

// 使用类型
import { Database } from '@/types/supabase'

type PostRow = Database['public']['Tables']['posts']['Row']
type PostInsert = Database['public']['Tables']['posts']['Insert']
```

---

## 7. 迁移工作流

### 7.1 创建迁移

```bash
# 创建新迁移
supabase migration new create_posts_table
```

### 7.2 编写迁移 SQL

```sql
-- supabase/migrations/20240101000000_create_posts_table.sql
BEGIN;

CREATE TABLE posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  title text NOT NULL,
  content text,
  created_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- 创建策略
CREATE POLICY "Users can view own posts"
  ON posts FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own posts"
  ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 创建索引
CREATE INDEX idx_posts_user_id ON posts(user_id);

COMMIT;
```

### 7.3 应用迁移

```bash
# 本地应用迁移
supabase migration up

# 重置数据库（包含种子数据）
supabase db reset

# 推送到远程
supabase db push
```

---

## Best Practices

1. **所有表必须启用 RLS** — 安全第一
2. **使用参数化查询** — 防止 SQL 注入
3. **外键必须创建索引** — 性能优化
4. **迁移使用事务** — 数据一致性
5. **种子数据分离** — 不混入迁移
6. **Edge Functions 校验 JWT** — 认证安全
7. **Realtime 订阅必须清理** — 防止内存泄漏
8. **Storage 桶设为 Private** — 安全控制
9. **类型自动生成** — 端到端类型安全
10. **CI 中自动重新生成类型** — 保持同步