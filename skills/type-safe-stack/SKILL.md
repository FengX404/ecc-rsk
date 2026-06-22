---
name: type-safe-stack
description: 端到端类型安全流（Supabase 类型生成、Zod schema 设计、Server Action 类型安全、TanStack Query 类型安全、React props 类型）。
metadata:
  origin: ECC-RSK
---

# Type-Safe Stack Patterns

端到端类型安全：PostgreSQL → Supabase 类型 → Zod → Server Action → React。

## When to Activate

- 生成 Supabase TypeScript 类型
- 设计 Zod schema
- 编写类型安全的 Server Action
- 配置 TanStack Query 类型
- 定义 React 组件 props 类型
- 测试类型安全

---

## 1. 端到端类型安全流

```
┌─────────────────────────────────────────────────────────────┐
│                     PostgreSQL Schema                        │
│  (CREATE TABLE statements)                                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     supabase gen types                       │
│  (generate TypeScript types from schema)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Zod Schema                               │
│  (runtime validation from Database types)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     Server Action Input                      │
│  (validate with Zod, type-safe execution)                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     React Component Props                    │
│  (type-safe props from Server Component)                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Supabase 类型生成

### 2.1 自动生成

```bash
# 生成 TypeScript 类型
supabase gen types --typescript > types/supabase.ts

# 或使用 CLI（本地数据库）
supabase gen types typescript --local > types/supabase.ts

# 或从远程项目生成
supabase gen types typescript --project-id your-project-id > types/supabase.ts
```

### 2.2 生成的类型示例

```typescript
// types/supabase.ts（自动生成）
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
      posts: {
        Row: {
          id: string
          user_id: string
          title: string
          content: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          content?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          content?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
    Views: {}
    Functions: {}
    Enums: {}
  }
}

export type Tables<T extends keyof Database['public']['Tables']> =
  Database['public']['Tables'][T]

export type Row<T extends keyof Database['public']['Tables']> =
  Tables<T>['Row']

export type Insert<T extends keyof Database['public']['Tables']> =
  Tables<T>['Insert']

export type Update<T extends keyof Database['public']['Tables']> =
  Tables<T>['Update']
```

### 2.3 使用生成的类型

```typescript
// lib/actions/post.ts
import { Database } from '@/types/supabase'

type PostRow = Database['public']['Tables']['posts']['Row']
type PostInsert = Database['public']['Tables']['posts']['Insert']
type PostUpdate = Database['public']['Tables']['posts']['Update']

export async function getPosts(): Promise<PostRow[]> {
  const supabase = createClient()
  const { data } = await supabase.from('posts').select()
  return data || []
}

export async function createPost(post: PostInsert): Promise<PostRow> {
  const supabase = createClient()
  const { data } = await supabase.from('posts').insert(post).select().single()
  return data!
}
```

---

## 3. Zod Schema 设计

### 3.1 从 Database 类型推导

```typescript
// lib/validations/post.ts
import { z } from 'zod'
import { Database } from '@/types/supabase'

// 从 Database 类型推导 Zod schema
export const PostInsertSchema = z.object({
  id: z.string().uuid().optional(),
  user_id: z.string().uuid(),
  title: z.string().min(1).max(200),
  content: z.string().optional(),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
})

export const PostUpdateSchema = z.object({
  id: z.string().uuid().optional(),
  user_id: z.string().uuid().optional(),
  title: z.string().min(1).max(200).optional(),
  content: z.string().optional(),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
})

// 类型推导
export type PostInsertInput = z.infer<typeof PostInsertSchema>
export type PostUpdateInput = z.infer<typeof PostUpdateSchema>
```

---

## 4. Server Action 类型安全

### 4.1 输入校验

```typescript
// lib/actions/post.ts
'use server'

import { PostInsertSchema, PostUpdateSchema } from '@/lib/validations/post'
import { createClient } from '@/lib/supabase/server'
import { revalidatePath } from 'next/cache'

export async function createPost(input: unknown) {
  // 1. 校验输入
  const parsed = PostInsertSchema.safeParse(input)
  if (!parsed.success) {
    return {
      error: 'Invalid input',
      details: parsed.error.flatten(),
    }
  }

  // 2. 校验授权
  const supabase = createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    return { error: 'Unauthorized' }
  }

  // 3. 执行操作（TypeScript 知道 parsed.data 是 PostInsertInput）
  const { data, error } = await supabase
    .from('posts')
    .insert({
      ...parsed.data,
      user_id: user.id,
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

### 4.2 返回类型定义

```typescript
// types/action.ts
export type ActionState<T = any> = {
  data?: T
  error?: string
  details?: any
}

// lib/actions/post.ts
import { ActionState } from '@/types/action'
import { Database } from '@/types/supabase'

type PostRow = Database['public']['Tables']['posts']['Row']

export async function createPost(
  input: unknown
): Promise<ActionState<PostRow>> {
  // ...
}
```

---

## 5. TanStack Query 类型安全

### 5.1 Query 类型

```typescript
// app/posts/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { getPosts } from '@/lib/actions/post'
import { Database } from '@/types/supabase'

type PostRow = Database['public']['Tables']['posts']['Row']

export default function PostsPage() {
  const { data: posts, isLoading } = useQuery<PostRow[]>({
    queryKey: ['posts'],
    queryFn: getPosts,
  })

  return (
    <ul>
      {posts?.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

### 5.2 Mutation 类型

```typescript
// app/posts/create-form.tsx
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createPost } from '@/lib/actions/post'
import { Database } from '@/types/supabase'

type PostInsert = Database['public']['Tables']['posts']['Insert']
type PostRow = Database['public']['Tables']['posts']['Row']

export function CreatePostForm() {
  const queryClient = useQueryClient()

  const mutation = useMutation<PostRow, Error, PostInsert>({
    mutationFn: (input) => createPost(input).then((res) => {
      if (res.error) throw new Error(res.error)
      return res.data!
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['posts'] })
    },
  })

  return (
    <form onSubmit={(e) => {
      e.preventDefault()
      const formData = new FormData(e.currentTarget)
      mutation.mutate({
        title: formData.get('title') as string,
        content: formData.get('content') as string,
        user_id: 'current-user-id',
      })
    }}>
      <input name="title" type="text" required />
      <textarea name="content" />
      <button type="submit" disabled={mutation.isPending}>
        {mutation.isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  )
}
```

---

## 6. React 组件 Props 类型

### 6.1 Server Component Props

```typescript
// app/posts/[id]/page.tsx
import { Database } from '@/types/supabase'
import { createClient } from '@/lib/supabase/server'

type PostRow = Database['public']['Tables']['posts']['Row']

export default async function PostPage({ params }: { params: { id: string } }) {
  const supabase = createClient()
  const { data: post } = await supabase
    .from('posts')
    .select()
    .eq('id', params.id)
    .single()

  return <PostCard post={post!} />
}
```

### 6.2 Client Component Props

```typescript
// components/post-card.tsx
'use client'

import { Database } from '@/types/supabase'

type PostRow = Database['public']['Tables']['posts']['Row']

interface PostCardProps {
  post: PostRow
}

export function PostCard({ post }: PostCardProps) {
  return (
    <div>
      <h2>{post.title}</h2>
      <p>{post.content}</p>
    </div>
  )
}
```

---

## 7. 类型测试

### 7.1 `expect-type`

```typescript
// tests/types/post.test.ts
import { expectType } from 'expect-type'
import { Database } from '@/types/supabase'
import { PostInsertSchema } from '@/lib/validations/post'

type PostRow = Database['public']['Tables']['posts']['Row']
type PostInsert = Database['public']['Tables']['posts']['Insert']

// 测试类型
expectType<PostRow>({
  id: 'uuid',
  user_id: 'uuid',
  title: 'title',
  content: 'content',
  created_at: 'timestamp',
  updated_at: 'timestamp',
})

// 测试 Zod 推导类型
expectType<z.infer<typeof PostInsertSchema>>({
  user_id: 'uuid',
  title: 'title',
})
```

### 7.2 `tsc --noEmit`

```bash
# 运行类型检查
tsc --noEmit

# CI 中运行
npm run typecheck
```

---

## 8. CI 自动类型生成

### 8.1 GitHub Actions

```yaml
# .github/workflows/gen-types.yml
name: Generate Supabase Types

on:
  push:
    paths:
      - 'supabase/migrations/**'

jobs:
  gen-types:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1

      - name: Generate types
        run: |
          supabase gen types typescript --local > types/supabase.ts

      - name: Commit types
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add types/supabase.ts
          git commit -m "chore: regenerate supabase types" || echo "No changes"
          git push
```

---

## Best Practices

1. **自动生成类型** — `supabase gen types`
2. **CI 自动重新生成** — 迁移后自动更新
3. **Zod schema 与 Database 类型对齐** — 端到端一致
4. **Server Action 输入使用 `unknown`** — 安全、渐进
5. **TanStack Query 类型化** — `useQuery<PostRow[]>`
6. **React props 使用 Database 类型** — 端到端一致
7. **类型测试** — `expect-type` + `tsc --noEmit`
8. **避免 `any`** — 使用 `unknown` + 类型收窄
9. **避免 `as` 断言** — 使用类型守卫
10. **`import type` 分离类型导入** — 减少运行时导入