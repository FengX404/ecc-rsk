---
name: realtime-sync
description: Realtime 同步模式（订阅模式、React 集成、乐观更新、冲突解决、性能优化、离线支持）。
metadata:
  origin: ECC-RSK
---

# Realtime Sync Patterns

Supabase Realtime + React 同步模式，覆盖订阅模式、React 集成、乐观更新、冲突解决、性能优化、离线支持。

## When to Activate

- 实现 Realtime 订阅
- 集成 TanStack Query 与 Realtime
- 实现乐观更新
- 处理冲突
- 优化订阅性能
- 实现离线支持

---

## 1. Realtime 订阅模式

### 1.1 Postgres Changes 订阅

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

### 1.2 Broadcast（客户端事件）

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

### 1.3 Presence（在线状态）

```typescript
// hooks/use-presence.ts
import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export function usePresence(channelName: string) {
  const [users, setUsers] = useState<{ [key: string]: any }>({})
  const supabase = createClient()

  useEffect(() => {
    const channel = supabase.channel(channelName, {
      config: {
        presence: {
          key: 'user',
        },
      },
    })

    channel
      .on('presence', { event: 'sync' }, () => {
        const state = channel.presenceState()
        setUsers(state as any)
      })
      .on('presence', { event: 'join' }, ({ newPresences }) => {
        console.log('Joined:', newPresences)
      })
      .on('presence', { event: 'leave' }, ({ leftPresences }) => {
        console.log('Left:', leftPresences)
      })
      .subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          await channel.track({
            user: 'current-user',
            online_at: new Date().toISOString(),
          })
        }
      })

    return () => {
      supabase.removeChannel(channel)
    }
  }, [supabase, channelName])

  return users
}
```

---

## 2. React 集成

### 2.1 自定义 Hook

```typescript
// hooks/use-realtime.ts
import { useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useQueryClient } from '@tanstack/react-query'

export function useRealtime(table: string, queryKey: string[]) {
  const supabase = createClient()
  const queryClient = useQueryClient()
  const channelRef = useRef<RealtimeChannel | null>(null)

  useEffect(() => {
    channelRef.current = supabase
      .channel(`${table}-changes`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table,
        },
        (payload) => {
          // 刷新 TanStack Query cache
          queryClient.invalidateQueries({ queryKey })
        }
      )
      .subscribe()

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current)
      }
    }
  }, [supabase, table, queryKey, queryClient])
}
```

### 2.2 组件使用

```typescript
// app/posts/page.tsx
'use client'

import { useQuery } from '@tanstack/react-query'
import { useRealtime } from '@/hooks/use-realtime'
import { getPosts } from '@/lib/actions/post'

export default function PostsPage() {
  const { data: posts } = useQuery({
    queryKey: ['posts'],
    queryFn: getPosts,
  })

  // 启用 Realtime
  useRealtime('posts', ['posts'])

  return (
    <ul>
      {posts?.map((post) => (
        <li key={post.id}>{post.title}</li>
      ))}
    </ul>
  )
}
```

---

## 3. 乐观更新

### 3.1 TanStack Query 乐观更新

```typescript
// app/posts/create-form.tsx
'use client'

import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createPost } from '@/lib/actions/post'

export function CreatePostForm() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: createPost,
    onMutate: async (newPost) => {
      // 取消正在进行的查询
      await queryClient.cancelQueries({ queryKey: ['posts'] })

      // 获取当前数据
      const previousPosts = queryClient.getQueryData(['posts'])

      // 乐观更新：立即添加新 post
      queryClient.setQueryData(['posts'], (old: any) => [
        ...old,
        { id: 'temp-id', ...newPost },
      ])

      // 返回上下文（用于回滚）
      return { previousPosts }
    },
    onError: (err, newPost, context) => {
      // 回滚乐观更新
      queryClient.setQueryData(['posts'], context?.previousPosts)
    },
    onSettled: () => {
      // 重新获取数据
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

## 4. 冲突解决

### 4.1 Last-Write-Wins

```typescript
// 使用时间戳决定胜负
const updatePost = async (post: Post) => {
  const supabase = createClient()

  // 获取当前版本
  const { data: current } = await supabase
    .from('posts')
    .select('updated_at')
    .eq('id', post.id)
    .single()

  // 检查版本
  if (current?.updated_at > post.updated_at) {
    return { error: 'Conflict: newer version exists' }
  }

  // 更新
  const { data, error } = await supabase
    .from('posts')
    .update(post)
    .eq('id', post.id)
    .select()
    .single()

  return { data, error }
}
```

### 4.2 版本号

```sql
-- 添加版本列
ALTER TABLE posts ADD COLUMN version integer DEFAULT 1;

-- 更新时检查版本
UPDATE posts
SET title = 'New Title', version = version + 1
WHERE id = 'post-id' AND version = 1;
```

---

## 5. 性能优化

### 5.1 订阅粒度

```typescript
// 只订阅特定列
.on(
  'postgres_changes',
  {
    event: 'UPDATE',
    schema: 'public',
    table: 'posts',
    filter: 'id=eq.post-id', // 只订阅特定行
  },
  (payload) => {
    // 只处理特定行的更新
  }
)
```

### 5.2 节流 / 去抖

```typescript
// hooks/use-realtime-throttled.ts
import { useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useRealtimeThrottled(table: string, delay: number = 1000) {
  const supabase = createClient()
  const timeoutRef = useRef<NodeJS.Timeout | null>(null)

  useEffect(() => {
    const channel = supabase
      .channel(`${table}-changes`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table,
        },
        (payload) => {
          // 节流处理
          if (timeoutRef.current) {
            clearTimeout(timeoutRef.current)
          }
          timeoutRef.current = setTimeout(() => {
            console.log('Processed:', payload)
          }, delay)
        }
      )
      .subscribe()

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
      }
      supabase.removeChannel(channel)
    }
  }, [supabase, table, delay])
}
```

---

## 6. 离线支持

### 6.1 离线队列

```typescript
// lib/offline-queue.ts
const offlineQueue: Action[] = []

export function addToQueue(action: Action) {
  offlineQueue.push(action)
  localStorage.setItem('offlineQueue', JSON.stringify(offlineQueue))
}

export function processQueue() {
  const queue = JSON.parse(localStorage.getItem('offlineQueue') || '[]')
  queue.forEach(async (action: Action) => {
    await executeAction(action)
  })
  localStorage.removeItem('offlineQueue')
}

// 监听网络状态
window.addEventListener('online', processQueue)
```

### 6.2 本地持久化（IndexedDB）

```typescript
// lib/local-db.ts
import { openDB } from 'idb'

export async function getLocalDB() {
  return openDB('app-db', 1, {
    upgrade(db) {
      db.createObjectStore('posts')
    },
  })
}

export async function savePostLocal(post: Post) {
  const db = await getLocalDB()
  await db.put('posts', post, post.id)
}

export async function getPostsLocal() {
  const db = await getLocalDB()
  return db.getAll('posts')
}
```

---

## Best Practices

1. **订阅必须清理** — 防止内存泄漏
2. **使用 TanStack Query 乐观更新** — 用户体验
3. **冲突解决策略** — Last-Write-Wins 或版本号
4. **订阅粒度细化** — 只订阅必要数据
5. **节流高频更新** — 防止性能问题
6. **离线队列** — 网络恢复后重试
7. **本地持久化** — IndexedDB 存储
8. **频道复用** — 减少连接数
9. **错误处理** — 订阅失败重试
10. **监控连接状态** — `SUBSCRIBED` / `CLOSED` / `CHANNEL_ERROR`