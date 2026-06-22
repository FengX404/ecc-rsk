---
description: 端到端类型安全检查（PostgreSQL → Supabase 类型 → Zod schema → Server Action → React props）。
---

# Typecheck E2E

端到端类型安全检查。

## 适用场景

- 数据库迁移后
- 新增 Server Actions
- 新增 API 路由
- 新增 React 组件
- 定期类型审计

## 类型安全流

```
PostgreSQL Schema
       ↓
Supabase Type Generation
       ↓
Zod Schema Validation
       ↓
Server Action Input/Output
       ↓
TanStack Query Types
       ↓
React Component Props
```

## 工作流

### 1. 重新生成 Supabase 类型

```bash
# 从本地数据库生成
supabase gen types --typescript --local > src/types/supabase.ts

# 从远程项目生成
supabase gen types --typescript --project-id <project-id> > src/types/supabase.ts
```

**生成的类型文件**：

```typescript
// src/types/supabase.ts
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          username: string
          full_name: string | null
          avatar_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          username: string
          full_name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          username?: string
          full_name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: 'profiles_id_fkey'
            columns: ['id']
            isOneToOne: true
            referencedRelation: 'users'
            referencedColumns: ['id']
          }
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}

export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Row']

export type InsertTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Insert']

export type UpdateTables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]['Update']
```

### 2. 检查 Zod Schema 与 Database 类型对齐

**创建 Schema 文件**：

```typescript
// src/schemas/profile.ts
import { z } from 'zod'
import type { Tables, InsertTables, UpdateTables } from '@/types/supabase'

// ✅ 正确：Zod schema 与 Database 类型对齐
export const profileSchema = z.object({
  username: z.string().min(3).max(50).regex(/^[a-zA-Z0-9_]+$/),
  full_name: z.string().max(100).optional().nullable(),
  avatar_url: z.string().url().optional().nullable()
})

// 输入类型（用于表单）
export type ProfileInput = z.infer<typeof profileSchema>

// 数据库 Row 类型
export type Profile = Tables<'profiles'>

// 数据库 Insert 类型
export type ProfileInsert = InsertTables<'profiles'>

// 数据库 Update 类型
export type ProfileUpdate = UpdateTables<'profiles'>

// ❌ 错误：Zod schema 与 Database 类型不一致
export const profileSchema = z.object({
  username: z.string().min(3).max(50),
  full_name: z.string(), // 错误！数据库允许 null
  avatar_url: z.string().url() // 错误！数据库允许 null
})
```

**类型对齐检查工具**：

```typescript
// src/types/check.ts
import type { Tables } from './supabase'
import type { ProfileInput } from '@/schemas/profile'

// 编译时类型检查
type CheckProfileInput = ProfileInput extends Partial<Tables<'profiles'>>
  ? true
  : never

// 如果类型不匹配，编译时会报错
const _check: CheckProfileInput = true
```

### 3. 检查 Server Action 输入/输出类型

**Server Action 类型定义**：

```typescript
// src/types/actions.ts
import type { Tables, InsertTables, UpdateTables } from './supabase'

// 通用 Action 返回类型
export type ActionResult<T = void> =
  | { data: T; error: null }
  | { data: null; error: string; issues?: unknown }

// 创建 Action 输入类型
export type CreateActionInput<T extends keyof Database['public']['Tables']> =
  InsertTables<T>

// 更新 Action 输入类型
export type UpdateActionInput<T extends keyof Database['public']['Tables']> =
  UpdateTables<T> & { id: string }
```

**Server Action 实现**：

```typescript
// src/actions/profile.ts
'use server'

import { createClient } from '@/lib/supabase/server'
import { profileSchema, type ProfileInput } from '@/schemas/profile'
import type { Tables, ActionResult } from '@/types'
import type { Database } from '@/types/supabase'

// ✅ 正确：类型安全的 Server Action
export async function updateProfile(
  input: ProfileInput
): Promise<ActionResult<Tables<'profiles'>>> {
  const supabase = createClient()

  // 验证用户身份
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return { data: null, error: 'Unauthorized' }
  }

  // 验证输入
  const validated = profileSchema.safeParse(input)
  if (!validated.success) {
    return {
      data: null,
      error: 'Invalid input',
      issues: validated.error.issues
    }
  }

  // 更新数据库
  const { data, error } = await supabase
    .from('profiles')
    .update(validated.data)
    .eq('id', user.id)
    .select()
    .single()

  if (error) {
    return { data: null, error: error.message }
  }

  return { data, error: null }
}

// ❌ 错误：类型不安全
export async function updateProfile(formData: FormData) {
  const supabase = createClient()
  const { data } = await supabase
    .from('profiles')
    .update({
      username: formData.get('username') // 类型不安全！
    })
    .eq('id', formData.get('id')) // 类型不安全！
  return data
}
```

### 4. 检查 TanStack Query 类型

**Query Keys 类型定义**：

```typescript
// src/lib/query-keys.ts
import type { Tables } from '@/types/supabase'

export const queryKeys = {
  all: ['all'] as const,
  profiles: {
    all: ['profiles'] as const,
    lists: () => [...queryKeys.profiles.all, 'list'] as const,
    list: (filters: Record<string, unknown>) =>
      [...queryKeys.profiles.lists(), filters] as const,
    details: () => [...queryKeys.profiles.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.profiles.details(), id] as const
  },
  posts: {
    all: ['posts'] as const,
    lists: () => [...queryKeys.posts.all, 'list'] as const,
    list: (filters: { channelId: string }) =>
      [...queryKeys.posts.lists(), filters] as const,
    details: () => [...queryKeys.posts.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.posts.details(), id] as const
  }
} as const
```

**类型安全的 Query Hooks**：

```typescript
// src/hooks/use-profile.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { queryKeys } from '@/lib/query-keys'
import { getProfile, updateProfile } from '@/actions/profile'
import type { Tables, ProfileInput, ActionResult } from '@/types'

// ✅ 正确：类型安全的 Query Hook
export function useProfile(id: string) {
  return useQuery({
    queryKey: queryKeys.profiles.detail(id),
    queryFn: () => getProfile(id),
    enabled: !!id
  })
}

// 返回类型自动推断
// const { data } = useProfile('123')
// data: Tables<'profiles'> | undefined

// ✅ 正确：类型安全的 Mutation Hook
export function useUpdateProfile() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (input: ProfileInput) => updateProfile(input),
    onSuccess: (result: ActionResult<Tables<'profiles'>>) => {
      if (result.data) {
        queryClient.setQueryData(
          queryKeys.profiles.detail(result.data.id),
          result.data
        )
        queryClient.invalidateQueries({ queryKey: queryKeys.profiles.all })
      }
    }
  })
}

// ❌ 错误：类型不安全
export function useProfile(id: string) {
  return useQuery({
    queryKey: ['profile', id], // 缺少类型定义
    queryFn: async () => {
      const res = await fetch(`/api/profiles/${id}`)
      return res.json() // 类型不安全！
    }
  })
}
```

### 5. 检查 React 组件 Props 类型

**类型安全的组件**：

```typescript
// src/components/profile/profile-form.tsx
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useUpdateProfile } from '@/hooks/use-profile'
import { profileSchema, type ProfileInput } from '@/schemas/profile'
import type { Tables } from '@/types/supabase'

// ✅ 正确：类型安全的 Props
interface ProfileFormProps {
  profile: Tables<'profiles'>
  onSuccess?: (data: Tables<'profiles'>) => void
  onError?: (error: string) => void
}

export function ProfileForm({ profile, onSuccess, onError }: ProfileFormProps) {
  const form = useForm<ProfileInput>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      username: profile.username,
      full_name: profile.full_name,
      avatar_url: profile.avatar_url
    }
  })

  const { mutate, isPending } = useUpdateProfile()

  const onSubmit = (input: ProfileInput) => {
    mutate(input, {
      onSuccess: (result) => {
        if (result.data) {
          onSuccess?.(result.data)
        } else {
          onError?.(result.error)
        }
      }
    })
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* form fields */}
    </form>
  )
}

// ❌ 错误：类型不安全
interface ProfileFormProps {
  profile: any // 错误！使用 any
  onSuccess?: (data: any) => void // 错误！使用 any
}
```

### 6. 全量类型检查

```bash
# TypeScript 类型检查
tsc --noEmit

# 检查特定文件
tsc --noEmit src/actions/profile.ts

# 检查所有文件
tsc --noEmit --pretty
```

**常见类型错误**：

```typescript
// ❌ 错误：类型 'string | undefined' 不能赋值给类型 'string'
const username: string = profile.username // 错误！username 可能为 null

// ✅ 正确：处理可能为 null 的值
const username: string = profile.username ?? ''

// ❌ 错误：对象可能为 'null'
const id = user.id // 错误！user 可能为 null

// ✅ 正确：添加 null 检查
if (!user) return null
const id = user.id

// ❌ 错误：缺少属性 'id'
const profile: Tables<'profiles'> = {
  username: 'test'
  // 错误！缺少 id, created_at, updated_at
}

// ✅ 正确：提供所有必需属性
const profile: Tables<'profiles'> = {
  id: '123',
  username: 'test',
  full_name: null,
  avatar_url: null,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString()
}
```

### 7. 报告类型断点

**扫描类型断点**：

```bash
# 查找 any 类型
grep -r "any" src/ --include="*.ts" --include="*.tsx"

# 查找类型断言
grep -r "as " src/ --include="*.ts" --include="*.tsx"

# 查找 @ts-ignore
grep -r "@ts-ignore" src/ --include="*.ts" --include="*.tsx"

# 查找 @ts-expect-error
grep -r "@ts-expect-error" src/ --include="*.ts" --include="*.tsx"

# 查找 @ts-any
grep -r "@ts-any" src/ --include="*.ts" --include="*.tsx"
```

**生成报告**：

```
## 类型安全检查报告

### 类型断点统计
- `any` 类型使用：12 处
- 类型断言 (`as`)：8 处
- `@ts-ignore`：3 处
- `@ts-expect-error`：2 处

### CRITICAL（必须修复）
- [ ] `src/actions/auth.ts:23`: 使用 `any` 类型
- [ ] `src/components/chat.tsx:45`: 使用 `@ts-ignore`

### HIGH（强烈建议修复）
- [ ] `src/lib/utils.ts:12`: 类型断言 `as any`
- [ ] `src/hooks/use-realtime.ts:34`: 使用 `any` 类型

### MEDIUM（建议修复）
- [ ] `src/types/custom.ts:5`: 定义 `any` 类型别名
- [ ] `src/utils/format.ts:8`: 类型断言 `as unknown as`

### 建议
- 使用 `unknown` 替代 `any`
- 使用类型守卫替代类型断言
- 为第三方库添加类型定义
```

## 诊断命令

```bash
# 重新生成 Supabase 类型
supabase gen types --typescript --local > src/types/supabase.ts

# TypeScript 类型检查
tsc --noEmit

# ESLint 类型检查
next lint

# 查找类型断点
grep -r "any" src/ --include="*.ts" --include="*.tsx"
grep -r "@ts-ignore" src/ --include="*.ts" --include="*.tsx"
```

## 类型安全最佳实践

### 1. 使用 `unknown` 替代 `any`

```typescript
// ❌ 错误：使用 any
function parseJson(input: string): any {
  return JSON.parse(input)
}

// ✅ 正确：使用 unknown
function parseJson(input: string): unknown {
  return JSON.parse(input)
}

// 使用类型守卫
const data = parseJson('{"name": "test"}')
if (typeof data === 'object' && data !== null && 'name' in data) {
  console.log((data as { name: string }).name)
}
```

### 2. 使用类型守卫替代类型断言

```typescript
// ❌ 错误：使用类型断言
const profile = data as Tables<'profiles'>

// ✅ 正确：使用类型守卫
function isProfile(value: unknown): value is Tables<'profiles'> {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'username' in value
  )
}

if (isProfile(data)) {
  console.log(data.username)
}
```

### 3. 使用泛型约束

```typescript
// ✅ 正确：使用泛型约束
export async function getRecord<T extends keyof Database['public']['Tables']>(
  table: T,
  id: string
): Promise<Tables<T> | null> {
  const supabase = createClient()
  const { data } = await supabase.from(table).select().eq('id', id).single()
  return data as Tables<T> | null
}

// 使用
const profile = await getRecord('profiles', '123') // 类型自动推断
```

### 4. 使用 Zod 进行运行时验证

```typescript
// ✅ 正确：使用 Zod 进行运行时验证
import { z } from 'zod'

const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string(),
  SUPABASE_SERVICE_ROLE_KEY: z.string()
})

const env = envSchema.parse(process.env)
```

## 相关命令

- `/supabase-migrate` — 数据库迁移后重新生成类型
- `/supabase-review` — Supabase 审查
- `/nextjs-review` — Next.js 审查

## 相关 Skills

- `type-safe-stack` — 端到端类型安全
- `supabase-patterns` — Supabase 最佳实践
- `nextjs-app-router` — Next.js App Router