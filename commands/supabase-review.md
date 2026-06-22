---
description: Supabase 专项代码审查（RLS、SQL 注入、Auth、Edge Functions、Realtime、Storage）。调用 supabase-reviewer agent。
---

# Supabase Review

调用 `supabase-reviewer` agent 进行 Supabase 专项代码审查。

## 适用场景

- 新增数据库迁移文件
- 新增或修改 RLS 策略
- 新增 Edge Functions
- 新增 Realtime 订阅
- 新增 Storage 上传逻辑
- Auth 流程变更
- 定期安全审计

## 工作流

### 1. 环境检测

```bash
# 检测 Supabase CLI
supabase --version

# 检测项目配置
ls -la supabase/config.toml
ls -la supabase/migrations/

# 检测依赖
grep -E "@supabase/(ssr|supabase-js|auth-helpers-nextjs)" package.json
```

### 2. 数据库迁移审查

扫描 `supabase/migrations/*.sql` 文件：

**检查项**：
- [ ] RLS 策略是否覆盖所有表
- [ ] 是否存在 SQL 注入风险（动态 SQL、字符串拼接）
- [ ] 索引是否合理（外键、常用查询条件）
- [ ] 是否存在 N+1 查询风险
- [ ] 是否使用事务包裹相关操作
- [ ] 是否正确使用 `auth.uid()` 和 `auth.jwt()`

**RLS 策略模板检查**：

```sql
-- ✅ 正确：使用 auth.uid() 进行用户隔离
CREATE POLICY "Users can read own data"
ON public.profiles FOR SELECT
USING (auth.uid() = id);

-- ❌ 错误：缺少 RLS 策略
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY,
  email text
); -- 缺少 ALTER TABLE ... ENABLE ROW LEVEL SECURITY;

-- ✅ 正确：使用 SECURITY DEFINER 时验证调用者
CREATE OR REPLACE FUNCTION public.get_user_data(user_id uuid)
RETURNS json
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- 验证调用者是已认证用户
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN (
    SELECT row_to_json(profiles.*)
    FROM public.profiles
    WHERE id = user_id
  );
END;
$$;
```

### 3. Edge Functions 审查

扫描 `supabase/functions/**/*.ts` 文件：

**检查项**：
- [ ] 是否正确验证 Authorization header
- [ ] 是否使用 `supabaseClient.auth.getUser()` 验证用户
- [ ] 是否正确处理 CORS
- [ ] 是否正确处理错误响应
- [ ] 是否避免硬编码 secrets
- [ ] 是否使用环境变量

**Edge Function 安全模式**：

```typescript
// ✅ 正确：验证用户身份
import { createClient } from '@supabase/supabase-js'

Deno.serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )

  // 验证用户
  const authHeader = req.headers.get('Authorization')!
  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error } = await supabaseClient.auth.getUser(token)

  if (error || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  // 业务逻辑...
})

// ❌ 错误：未验证用户身份
Deno.serve(async (req) => {
  const { data } = await supabaseClient
    .from('profiles')
    .select('*') // 任何人都可以访问！
  return new Response(JSON.stringify(data))
})
```

### 4. Server Actions / Route Handlers 审查

扫描 `app/**/*.{ts,tsx}` 中的 Supabase 调用：

**检查项**：
- [ ] Server Component 是否使用 `createServerClient`
- [ ] Client Component 是否使用 `createBrowserClient`
- [ ] Server Action 是否正确验证输入
- [ ] 是否正确处理 Supabase 错误
- [ ] 是否避免暴露敏感数据

**Server Action 安全模式**：

```typescript
// ✅ 正确：验证输入 + 授权检查
'use server'

import { createServerClient } from '@/lib/supabase/server'
import { z } from 'zod'

const updateProfileSchema = z.object({
  username: z.string().min(3).max(50),
  avatar_url: z.string().url().optional()
})

export async function updateProfile(formData: FormData) {
  const supabase = createServerClient()

  // 验证用户身份
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return { error: 'Unauthorized' }
  }

  // 验证输入
  const input = updateProfileSchema.safeParse({
    username: formData.get('username'),
    avatar_url: formData.get('avatar_url')
  })
  if (!input.success) {
    return { error: 'Invalid input', issues: input.error.issues }
  }

  // 更新（RLS 自动限制只能更新自己的数据）
  const { error } = await supabase
    .from('profiles')
    .update(input.data)
    .eq('id', user.id)

  if (error) {
    return { error: error.message }
  }

  return { success: true }
}

// ❌ 错误：未验证用户身份
export async function updateProfile(formData: FormData) {
  const supabase = createServerClient()
  // 任何人都可以更新任何人的数据！
  await supabase
    .from('profiles')
    .update({ username: formData.get('username') })
    .eq('id', formData.get('user_id')) // 危险！
}
```

### 5. Realtime 订阅审查

扫描 `useRealtime`、`onSnapshot`、`.on('*')` 等订阅代码：

**检查项**：
- [ ] 是否正确处理连接状态
- [ ] 是否在组件卸载时取消订阅
- [ ] 是否实现乐观更新
- [ ] 是否处理冲突解决
- [ ] 是否限制订阅范围（避免 `*`）

**Realtime 安全模式**：

```typescript
// ✅ 正确：限制订阅范围 + 清理订阅
'use client'

import { useEffect, useState } from 'react'
import { createBrowserClient } from '@/lib/supabase/client'

export function useRealtimeMessages(channelId: string) {
  const [messages, setMessages] = useState<Message[]>([])
  const supabase = createBrowserClient()

  useEffect(() => {
    const channel = supabase
      .channel(`messages:${channelId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'messages',
          filter: `channel_id=eq.${channelId}` // 限制范围
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setMessages((prev) => [...prev, payload.new as Message])
          } else if (payload.eventType === 'DELETE') {
            setMessages((prev) =>
              prev.filter((m) => m.id !== payload.old.id)
            )
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [channelId, supabase])

  return messages
}

// ❌ 错误：订阅所有表的变更
supabase
  .channel('*') // 危险！订阅所有表
  .on('postgres_changes', { event: '*', schema: '*' }, callback)
  .subscribe()
```

### 6. Storage 上传审查

扫描 `storage.from().upload()` 调用：

**检查项**：
- [ ] 是否验证文件类型
- [ ] 是否限制文件大小
- [ ] 是否使用用户隔离的 bucket
- [ ] 是否正确设置 cacheControl
- [ ] 是否处理上传错误

**Storage 安全模式**：

```typescript
// ✅ 正确：验证文件类型 + 大小限制
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp']
const MAX_SIZE = 5 * 1024 * 1024 // 5MB

export async function uploadAvatar(file: File) {
  const supabase = createServerClient()

  // 验证用户
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return { error: 'Unauthorized' }

  // 验证文件
  if (!ALLOWED_TYPES.includes(file.type)) {
    return { error: 'Invalid file type' }
  }
  if (file.size > MAX_SIZE) {
    return { error: 'File too large' }
  }

  // 上传（使用用户 ID 作为路径）
  const path = `${user.id}/avatar.${file.name.split('.').pop()}`
  const { error } = await supabase.storage
    .from('avatars')
    .upload(path, file, {
      cacheControl: '3600',
      upsert: true
    })

  if (error) return { error: error.message }
  return { path }
}
```

### 7. 生成审查报告

调用 `supabase-reviewer` agent 输出结构化报告：

```
## Supabase 审查报告

### CRITICAL（必须修复）
- [ ] `migrations/20240101.sql`: 表 `profiles` 缺少 RLS 策略
- [ ] `functions/api/index.ts`: 未验证 Authorization header

### HIGH（强烈建议修复）
- [ ] `app/actions/update-profile.ts`: 未验证用户身份
- [ ] `components/chat.tsx`: Realtime 订阅未清理

### MEDIUM（建议修复）
- [ ] `migrations/20240102.sql`: 缺少 `created_at` 索引
- [ ] `lib/storage.ts`: 文件大小限制未设置

### 建议
- 考虑为 `messages` 表添加复合索引 `(channel_id, created_at)`
- Edge Functions 建议使用 `SUPABASE_SERVICE_ROLE_KEY` 进行管理操作
```

## 诊断命令

```bash
# 数据库 Lint
supabase db lint

# Edge Functions 部署检查
supabase functions deploy --dry-run

# 类型生成
supabase gen types --typescript > types/supabase.ts

# 本地开发
supabase start
supabase db reset

# 查看本地服务
supabase status
```

## 相关命令

- `/supabase-migrate` — 数据库迁移工作流
- `/typecheck-e2e` — 端到端类型安全检查
- `/nextjs-review` — Next.js App Router 审查

## 相关 Skills

- `supabase-patterns` — Supabase 最佳实践
- `fullstack-auth` — 认证与授权
- `realtime-sync` — Realtime 订阅模式