---
name: fullstack-auth
description: 全栈认证模式（PKCE 流程、会话管理、授权架构、OAuth 集成、RBAC、多租户认证、安全加固）。
metadata:
  origin: ECC-RSK
---

# Fullstack Authentication Patterns

React + Next.js + Supabase 认证与授权模式，覆盖 PKCE 流程、会话管理、授权架构、OAuth 集成、RBAC、多租户认证、安全加固。

## When to Activate

- 配置 Supabase Auth
- 实现会话管理
- 设计授权架构
- 集成 OAuth Provider
- 实现 RBAC
- 设计多租户认证
- 加固安全防护

---

## 1. 认证流程（PKCE）

### 1.1 PKCE 流程图

```
┌─────────────────────────────────────────────────────────────┐
│                     Login Page                               │
│  (supabase.auth.signInWithPassword)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Supabase Auth                            │
│  (PKCE flow, generate session tokens)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     httpOnly Cookie                          │
│  (store access_token, refresh_token)                         │
│  (XSS safe, not accessible to JavaScript)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Middleware                               │
│  (every request: refresh session if expired)                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Server Component                         │
│  (read session from cookie, fetch user data)                 │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Client Component                         │
│  (receive user data via SSR props)                           │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 登录实现

```typescript
// app/login/page.tsx
'use client'

import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClient()

  const handleLogin = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      return { error: error.message }
    }

    router.push('/dashboard')
    router.refresh()
  }

  return (
    <form onSubmit={(e) => {
      e.preventDefault()
      const formData = new FormData(e.currentTarget)
      handleLogin(formData.get('email') as string, formData.get('password') as string)
    }}>
      <input name="email" type="email" required />
      <input name="password" type="password" required />
      <button type="submit">Login</button>
    </form>
  )
}
```

---

## 2. 会话管理

### 2.1 Middleware 会话刷新

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
  await supabase.auth.getUser()

  return response
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
```

### 2.2 Server Component 读取会话

```typescript
// app/dashboard/page.tsx
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Welcome, {user.email}</p>
    </div>
  )
}
```

---

## 3. 授权架构

### 3.1 三层防御

```
┌─────────────────────────────────────────────────────────────┐
│                     UI Layer                                 │
│  (conditional rendering based on user role/permissions)      │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  (Server Action authorization check)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Database Layer                           │
│  (RLS policies enforce row-level access)                     │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Server Action 授权校验

```typescript
// app/actions/admin-action.ts
'use server'

import { createClient } from '@/lib/supabase/server'

export async function adminAction() {
  const supabase = createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Unauthorized' }
  }

  // 检查角色
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (profile?.role !== 'admin') {
    return { error: 'Forbidden' }
  }

  // 执行管理员操作
  // ...
}
```

---

## 4. OAuth 集成

### 4.1 Google OAuth

```typescript
// app/login/page.tsx
const handleGoogleLogin = async () => {
  const supabase = createClient()

  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${window.location.origin}/auth/callback`,
    },
  })

  if (error) {
    return { error: error.message }
  }
}
```

### 4.2 OAuth Callback

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

## 5. RBAC（基于角色的访问控制）

### 5.1 角色表设计

```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users,
  role text NOT NULL DEFAULT 'user',
  created_at timestamptz DEFAULT now()
);

-- RLS 策略：用户只能查看自己的 profile
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);
```

### 5.2 角色检查 Hook

```typescript
// hooks/use-role.ts
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useRole() {
  const [role, setRole] = useState<string | null>(null)
  const supabase = createClient()

  useEffect(() => {
    const fetchRole = async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser()

      if (!user) {
        setRole(null)
        return
      }

      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()

      setRole(profile?.role || 'user')
    }

    fetchRole()
  }, [supabase])

  return role
}
```

---

## 6. 多租户认证

### 6.1 租户解析

```typescript
// middleware.ts
export async function middleware(request: NextRequest) {
  // 租户解析：域名、子路径、claim
  const hostname = request.headers.get('host')
  const tenantId = getTenantIdFromHostname(hostname)

  // 设置租户上下文
  request.headers.set('x-tenant-id', tenantId)

  return NextResponse.next({ request })
}
```

### 6.2 租户隔离 RLS

```sql
CREATE TABLE tenant_members (
  tenant_id uuid REFERENCES tenants NOT NULL,
  user_id uuid REFERENCES auth.users NOT NULL,
  role text NOT NULL DEFAULT 'member',
  PRIMARY KEY (tenant_id, user_id)
);

-- RLS 策略：用户只能访问所属租户的数据
CREATE POLICY "Tenant members can access data"
  ON table FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM tenant_members
      WHERE tenant_id = table.tenant_id
      AND user_id = auth.uid()
    )
  );
```

---

## 7. 安全加固

### 7.1 CSRF 保护（SameSite cookie）

Supabase Auth 默认使用 httpOnly cookie，SameSite=lax，提供 CSRF 保护。

### 7.2 XSS 保护（httpOnly cookie）

会话 token 存储在 httpOnly cookie，JavaScript 无法访问，防止 XSS 窃取。

### 7.3 会话固定防护

每次登录生成新的 session token，防止会话固定攻击。

### 7.4 暴力破解防护（限流）

```typescript
// app/login/page.tsx
import { useState } from 'react'

export default function LoginPage() {
  const [attempts, setAttempts] = useState(0)
  const [locked, setLocked] = useState(false)

  const handleLogin = async (email: string, password: string) => {
    if (locked) {
      return { error: 'Account temporarily locked' }
    }

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setAttempts((prev) => prev + 1)
      if (attempts >= 5) {
        setLocked(true)
        setTimeout(() => setLocked(false), 300000) // 5分钟后解锁
      }
      return { error: error.message }
    }

    setAttempts(0)
    router.push('/dashboard')
  }
}
```

---

## Best Practices

1. **使用 PKCE 流程** — CSRF 保护
2. **会话存储在 httpOnly cookie** — XSS 安全
3. **Middleware 刷新会话** — 每请求刷新
4. **三层授权防御** — UI + Application + Database
5. **角色存储在数据库** — 灵活、可更新
6. **OAuth Provider 配置** — Google、GitHub、Apple
7. **RBAC 实现** — 基于角色的访问控制
8. **多租户 RLS 隔离** — 数据库层隔离
9. **暴力破解限流** — 防止暴力破解
10. **定期轮换密钥** — 安全最佳实践