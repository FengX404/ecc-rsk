---
paths:
  - "**/app/**/*.tsx"
  - "**/app/**/*.ts"
  - "**/next.config.*"
---
# Next.js Performance

> Next.js App Router 性能优化规范。继承 [web/performance.md](../web/performance.md)。

## `next/image`

所有 `<img>` 应替换为 `next/image`：

```typescript
// ✅ 正确：使用 next/image
import Image from 'next/image'

export function Avatar({ src, alt }: { src: string; alt: string }) {
  return (
    <Image
      src={src}
      alt={alt}
      width={48}
      height={48}
      className="rounded-full"
    />
  )
}

// ❌ 错误：使用原生 img
export function Avatar({ src, alt }: { src: string; alt: string }) {
  return <img src={src} alt={alt} className="rounded-full" />
}
```

### `priority` 用于 LCP 图片

首屏 LCP 图片必须设置 `priority`：

```typescript
// ✅ 正确：首屏大图设置 priority
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority
/>

// ❌ 错误：首屏图片未设置 priority，导致懒加载延迟 LCP
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
/>
```

### `sizes` 用于响应式图片

```typescript
// ✅ 正确：设置 sizes 避免下载过大图片
<Image
  src="/hero.jpg"
  alt="Hero"
  fill
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

## `next/font`

使用 `next/font` 优化字体加载：

```typescript
// app/layout.tsx
import { Inter } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter',
})

export default function RootLayout({ children }) {
  return (
    <html lang="zh-CN" className={inter.variable}>
      <body>{children}</body>
    </html>
  )
}
```

**优势**：
- 自动自托管字体文件（不向 Google 发请求）
- 零布局偏移（FOUT 消除）
- 自动预加载

## `next/script`

第三方脚本使用 `next/script`：

```typescript
import Script from 'next/script'

export function Analytics() {
  return (
    <Script
      src="https://example.com/analytics.js"
      strategy="afterInteractive"
    />
  )
}
```

| strategy | 加载时机 | 适用场景 |
|---|---|---|
| `beforeInteractive` | 页面交互前 | 关键脚本（极少使用） |
| `afterInteractive` | 页面交互后 | 分析、A/B 测试 |
| `lazyOnload` | 空闲时 | 非关键脚本 |
| `worker` | Web Worker | 第三方脚本隔离（实验性） |

## 缓存策略

### `fetch` 缓存

```typescript
// ✅ 默认缓存（SSG）
fetch('https://api.example.com/data')

// ✅ 强制缓存 + revalidate（ISR）
fetch('https://api.example.com/data', {
  next: { revalidate: 60 }, // 60 秒后重新验证
})

// ✅ 不缓存（SSR）
fetch('https://api.example.com/data', {
  cache: 'no-store',
})

// ✅ 标签缓存（可手动 revalidate）
fetch('https://api.example.com/data', {
  next: { tags: ['posts'] },
})

// 在 Server Action 中手动 revalidate
import { revalidateTag } from 'next/cache'
revalidateTag('posts')
```

### `unstable_cache`

```typescript
import { unstable_cache } from 'next/cache'

const getCachedUser = unstable_cache(
  async (userId: string) => {
    return await db.user.findById(userId)
  },
  ['user'], // cache key
  {
    revalidate: 60,
    tags: ['user'],
  }
)

// 使用
const user = await getCachedUser('123')
```

## Streaming 与 Suspense

### 渐进式渲染

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react'

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>

      <Suspense fallback={<ChartSkeleton />}>
        <Chart /> {/* 慢查询 */}
      </Suspense>

      <Suspense fallback={<StatsSkeleton />}>
        <Stats /> {/* 另一个慢查询 */}
      </Suspense>
    </div>
  )
}
```

### `loading.tsx`

```typescript
// app/dashboard/loading.tsx
export default function Loading() {
  return <div>加载中...</div>
}
```

## Bundle 优化

### 动态导入

```typescript
import dynamic from 'next/dynamic'

const HeavyChart = dynamic(() => import('@/components/heavy-chart'), {
  loading: () => <div>加载中...</div>,
  ssr: false, // 仅客户端渲染
})

export default function Page() {
  return <HeavyChart />
}
```

### 分析 Bundle

```bash
# 安装
npm install -D @next/bundle-analyzer

# 使用
ANALYZE=true next build
```

## 渲染模式选择

| 模式 | 适用场景 | 配置 |
|---|---|---|
| SSG | 静态内容（博客、营销页） | 默认 |
| SSR | 个性化内容（dashboard） | `cache: 'no-store'` |
| ISR | 周期性更新（新闻、商品） | `revalidate: 60` |
| Streaming | 多个独立数据源 | `<Suspense>` |

## Web Vitals 目标

| 指标 | 目标 | 说明 |
|---|---|---|
| LCP | < 2.5s | 最大内容绘制 |
| FID/INP | < 200ms | 首次输入延迟 / 交互延迟 |
| CLS | < 0.1 | 累积布局偏移 |
| FCP | < 1.8s | 首次内容绘制 |
| TTFB | < 800ms | 首字节时间 |

## 性能反模式

```typescript
// ❌ 错误：Client Component 中 fetch 数据
'use client'
import { useEffect, useState } from 'react'

export function Posts() {
  const [posts, setPosts] = useState([])
  useEffect(() => {
    fetch('/api/posts').then(r => r.json()).then(setPosts)
  }, [])
  return <div>{posts.map(p => <div key={p.id}>{p.title}</div>)}</div>
}

// ✅ 正确：Server Component 中 fetch
export default async function Posts() {
  const res = await fetch('https://api.example.com/posts', {
    next: { revalidate: 60 },
  })
  const posts = await res.json()
  return (
    <div>
      {posts.map(p => <div key={p.id}>{p.title}</div>)}
    </div>
  )
}
```

```typescript
// ❌ 错误：不必要的 "use client"
'use client'
import { useState } from 'react'

export function StaticComponent() {
  // 无任何客户端功能
  return <div>静态内容</div>
}

// ✅ 正确：移除 "use client"
export function StaticComponent() {
  return <div>静态内容</div>
}
```
