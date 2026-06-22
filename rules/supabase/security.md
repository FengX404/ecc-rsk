---
paths:
  - "**/supabase/**/*.sql"
  - "**/supabase/functions/**/*.ts"
  - "**/lib/supabase/**/*.ts"
  - "**/lib/actions/**/*.ts"
---
# Supabase Security

> Supabase 安全规范。**CRITICAL** — 违反此文件可能导致数据泄露。继承 [common/security.md](../common/security.md)。

## RLS 必备（CRITICAL）

**所有表必须启用 RLS**。无 RLS 的表对所有用户完全暴露。

### 启用 RLS

```sql
-- ✅ 正确：启用 RLS
CREATE TABLE public.posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id uuid REFERENCES auth.users(id) NOT NULL,
  title text NOT NULL,
  content text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- 创建策略
CREATE POLICY "Users can read own posts"
  ON public.posts FOR SELECT
  USING (auth.uid() = author_id);

CREATE POLICY "Users can create own posts"
  ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update own posts"
  ON public.posts FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts"
  ON public.posts FOR DELETE
  USING (auth.uid() = author_id);
```

```sql
-- ❌ 错误：未启用 RLS
CREATE TABLE public.posts (
  id uuid PRIMARY KEY,
  author_id uuid,
  title text
);
-- 缺少 ALTER TABLE ... ENABLE ROW LEVEL SECURITY
-- 任何用户可读取/修改所有数据
```

### 禁止宽松策略

```sql
-- ❌ CRITICAL：USING (true) 等同于无 RLS
CREATE POLICY "Allow all" ON public.posts
  FOR SELECT USING (true);

-- ❌ CRITICAL：public 读 + 任意写
CREATE POLICY "Public read" ON public.posts
  FOR SELECT USING (true);
CREATE POLICY "Anyone insert" ON public.posts
  FOR INSERT WITH CHECK (true);
```

### 多租户隔离

```sql
-- 多租户表
CREATE TABLE public.tenant_members (
  tenant_id uuid PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  role text NOT NULL DEFAULT 'member'
);

CREATE TABLE public.projects (
  id uuid PRIMARY KEY,
  tenant_id uuid REFERENCES public.tenant_members(tenant_id),
  name text
);

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- ✅ 正确：通过 tenant_members 关联校验
CREATE POLICY "Tenant members can read projects"
  ON public.projects FOR SELECT
  USING (
    tenant_id IN (
      SELECT tenant_id FROM public.tenant_members
      WHERE user_id = auth.uid()
    )
  );
```

## SQL 注入防护（CRITICAL）

### 参数化查询

```typescript
// ✅ 正确：使用 .eq() / .filter() 参数化
const { data } = await supabase
  .from('posts')
  .select('*')
  .eq('author_id', userId)
  .order('created_at', { ascending: false })

// ✅ 正确：RPC 调用参数化
const { data } = await supabase.rpc('search_posts', {
  query: userInput,
  limit: 10,
})
```

```typescript
// ❌ CRITICAL：字符串拼接 SQL
const { data } = await supabase.rpc(
  `search_posts('${userInput}')` // SQL 注入
)
```

### Edge Functions 中使用参数化

```typescript
// supabase/functions/query.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

Deno.serve(async (req) => {
  const { userId } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // ✅ 正确：参数化
  const { data } = await supabase
    .from('posts')
    .select('*')
    .eq('author_id', userId)

  return new Response(JSON.stringify(data))
})
```

## Service Role Key 隔离（CRITICAL）

### 永不暴露给 Client

```bash
# ✅ 正确：Service Role Key 无 NEXT_PUBLIC_ 前缀
SUPABASE_SERVICE_ROLE_KEY=eyJxxx

# ❌ CRITICAL：暴露给 Client
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=eyJxxx
```

### 仅服务端使用

```typescript
// lib/supabase/admin.ts
import 'server-only' // 防止 Client Component 导入
import { createClient } from '@supabase/supabase-js'

export function createAdminClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}
```

### Service Role 绕过 RLS

**注意**：Service Role Key 绕过所有 RLS 策略。仅在以下场景使用：
- 后台管理任务（用户管理、数据迁移）
- Edge Functions 中需要跨用户操作
- Webhook 处理

**禁止**在普通用户请求中使用 Service Role。

## Auth PKCE（CRITICAL）

### 启用 PKCE

```typescript
// lib/supabase/client.ts
import { createClient } from '@supabase/supabase-js'

export function createBrowserClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: {
        flowType: 'pkce', // ✅ 启用 PKCE
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: true,
      },
    }
  )
}
```

### 会话存储

```typescript
// ❌ CRITICAL：会话存储在 localStorage（XSS 可窃取）
{
  auth: {
    storageKey: 'supabase.auth.token',
    storage: window.localStorage,
  }
}

// ✅ 正确：使用 httpOnly cookie（通过 @supabase/ssr）
import { createBrowserClient } from '@supabase/ssr'

export function createBrowserClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

### 会话刷新（Middleware）

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next()

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            request.cookies.set(name, value)
            response.cookies.set(name, value, options)
          })
        },
      },
    }
  )

  // 刷新会话
  await supabase.auth.getUser()

  return response
}
```

## Storage 桶权限

### Private 桶（默认）

```typescript
// ✅ 正确：Private 桶，通过 Signed URL 访问
const { data } = await supabase.storage
  .from('private-documents')
  .createSignedUrl('user/file.pdf', 60) // 60 秒有效

// ❌ 错误：Public 桶存储敏感文件
// supabase.storage.from('documents').getPublicUrl('sensitive.pdf')
```

### 文件类型与大小限制

```typescript
// ✅ 正确：校验文件类型与大小
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']
const MAX_SIZE = 5 * 1024 * 1024 // 5MB

async function uploadAvatar(file: File) {
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('不支持的文件类型')
  }
  if (file.size > MAX_SIZE) {
    throw new Error('文件过大')
  }

  const { data, error } = await supabase.storage
    .from('avatars')
    .upload(`${userId}/avatar`, file)

  if (error) throw error
  return data.path
}
```

## Edge Functions JWT 校验（CRITICAL）

```typescript
// supabase/functions/secure-endpoint/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

Deno.serve(async (req) => {
  // ✅ 校验 JWT
  const authHeader = req.headers.get('Authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401 })
  }

  const jwt = authHeader.replace('Bearer ', '')

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!
  )

  // 验证 JWT
  const { data: { user }, error } = await supabase.auth.getUser(jwt)
  if (error || !user) {
    return new Response('Unauthorized', { status: 401 })
  }

  // 业务逻辑
  return new Response(JSON.stringify({ user: user.email }))
})
```

```typescript
// ❌ CRITICAL：未校验 JWT
Deno.serve(async (req) => {
  // 任何人可调用
  const data = await doSomething()
  return new Response(JSON.stringify(data))
})
```

### CORS 处理

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGIN')!,
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // 业务逻辑
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
```
