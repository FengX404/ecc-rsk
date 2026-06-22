---
paths:
  - "**/hooks/use-supabase*.ts"
  - "**/hooks/use-realtime*.ts"
  - "**/hooks/use-storage*.ts"
  - "**/lib/supabase/**/*.ts"
---
# Supabase Hooks

> Supabase 专用 React hook 配置与使用规范。

## `useSupabase`

获取 Supabase 客户端实例（Client Component）。

```typescript
// hooks/use-supabase.ts
'use client'
import { createContext, useContext } from 'react'
import { createClient, SupabaseClient } from '@supabase/supabase-js'

const SupabaseContext = createContext<SupabaseClient | null>(null)

export function SupabaseProvider({
  children,
  client,
}: {
  children: React.ReactNode
  client: SupabaseClient
}) {
  return (
    <SupabaseContext.Provider value={client}>
      {children}
    </SupabaseContext.Provider>
  )
}

export function useSupabase(): SupabaseClient {
  const client = useContext(SupabaseContext)
  if (!client) {
    throw new Error('useSupabase must be used within SupabaseProvider')
  }
  return client
}
```

## `useUser`

获取当前登录用户（Client Component）。

```typescript
// hooks/use-user.ts
'use client'
import { useEffect, useState } from 'react'
import { User } from '@supabase/supabase-js'
import { useSupabase } from './use-supabase'

export function useUser() {
  const supabase = useSupabase()
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // 初始获取
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUser(user)
      setLoading(false)
    })

    // 监听变化
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null)
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [supabase])

  return { user, loading }
}
```

## `useRealtime`

订阅 Postgres Changes（Client Component）。

```typescript
// hooks/use-realtime.ts
'use client'
import { useEffect, useState } from 'react'
import { useSupabase } from './use-supabase'

export function useRealtime<T extends { id: string }>(
  table: string,
  filter?: string
) {
  const supabase = useSupabase()
  const [data, setData] = useState<T[]>([])

  useEffect(() => {
    // 初始加载
    let query = supabase.from(table).select('*')
    if (filter) {
      query = query.filter(filter)
    }
    query.then(({ data: initial }) => {
      if (initial) setData(initial as T[])
    })

    // 订阅变更
    const channel = supabase
      .channel(`${table}-changes`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table,
          filter: filter as any,
        },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setData((prev) => [...prev, payload.new as T])
          } else if (payload.eventType === 'UPDATE') {
            setData((prev) =>
              prev.map((item) =>
                item.id === (payload.new as T).id ? payload.new as T : item
              )
            )
          } else if (payload.eventType === 'DELETE') {
            setData((prev) =>
              prev.filter((item) => item.id !== (payload.old as T).id)
            )
          }
        }
      )
      .subscribe()

    // ✅ 清理订阅
    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase, table, filter])

  return data
}
```

### 使用示例

```typescript
'use client'
import { useRealtime } from '@/hooks/use-realtime'

interface Post {
  id: string
  title: string
  content: string
}

export function PostsList({ userId }: { userId: string }) {
  // 订阅当前用户的 posts
  const posts = useRealtime<Post>('posts', `author_id=eq.${userId}`)

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

## `useStorage`

文件上传与下载（Client Component）。

```typescript
// hooks/use-storage.ts
'use client'
import { useState } from 'react'
import { useSupabase } from './use-supabase'

export function useStorage(bucket: string) {
  const supabase = useSupabase()
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)

  const upload = async (
    path: string,
    file: File
  ): Promise<string | null> => {
    setUploading(true)
    setProgress(0)

    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(path, file, {
          cacheControl: '3600',
          upsert: false,
        })

      if (error) throw error

      // 获取公开 URL（public bucket）
      const { data: urlData } = supabase.storage
        .from(bucket)
        .getPublicUrl(data.path)

      return urlData.publicUrl
    } catch (error) {
      console.error('Upload failed:', error)
      return null
    } finally {
      setUploading(false)
    }
  }

  const getSignedUrl = async (path: string, expiresIn = 60): Promise<string | null> => {
    const { data, error } = await supabase.storage
      .from(bucket)
      .createSignedUrl(path, expiresIn)

    if (error) return null
    return data.signedUrl
  }

  const remove = async (path: string): Promise<boolean> => {
    const { error } = await supabase.storage.from(bucket).remove([path])
    return !error
  }

  return { upload, getSignedUrl, remove, uploading, progress }
}
```

## Hook 使用约定

### Server vs Client

| Hook | 可用位置 | 说明 |
|---|---|---|
| `useSupabase` | Client only | 获取浏览器端 client |
| `useUser` | Client only | 当前用户（响应式） |
| `useRealtime` | Client only | Realtime 订阅 |
| `useStorage` | Client only | 文件上传/下载 |
| `createServerClient` | Server only | 服务端 client |
| `createAdminClient` | Server only（service role） | 管理员 client |

### 清理订阅（CRITICAL）

所有 Realtime 订阅必须在 `useEffect` cleanup 中清理：

```typescript
// ✅ 正确：清理订阅
useEffect(() => {
  const channel = supabase
    .channel('posts-changes')
    .on('postgres_changes', { ... }, handler)
    .subscribe()

  return () => {
    supabase.removeChannel(channel)
  }
}, [supabase])

// ❌ 错误：未清理，导致内存泄漏
useEffect(() => {
  supabase
    .channel('posts-changes')
    .on('postgres_changes', { ... }, handler)
    .subscribe()
  // 缺少 return cleanup
}, [supabase])
```

### 去重订阅

同一表多个组件订阅时，应复用 channel：

```typescript
// ✅ 正确：复用 channel
const channel = supabase.channel('posts-changes')

// 组件 A
channel.on('postgres_changes', { event: 'INSERT', table: 'posts' }, handlerA)

// 组件 B
channel.on('postgres_changes', { event: 'UPDATE', table: 'posts' }, handlerB)

channel.subscribe()
```
