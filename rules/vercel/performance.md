---
paths:
  - "**/vercel.json"
  - "**/next.config.*"
  - "**/middleware.ts"
---
# Vercel Performance

> Vercel 部署性能优化规范。继承 [web/performance.md](../web/performance.md) 与 [nextjs/performance.md](../nextjs/performance.md)。

## Edge Runtime vs Node.js Runtime

### 决策矩阵

| 场景 | 推荐 Runtime | 理由 |
|---|---|---|
| 静态页面 | Edge | 全球 CDN，低延迟 |
| 简单 API（无重计算） | Edge | 冷启动快 |
| 复杂 API（数据库、文件） | Node.js | 完整 API 支持 |
| Server Action（数据库） | Node.js | 需要 Node.js SDK |
| Middleware | Edge | 必须使用 Edge |
| 图片处理 | Node.js | 需要 sharp |

### Edge Runtime 配置

```typescript
// app/api/geo/route.ts
export const runtime = 'edge'

export function GET(request: Request) {
  const country = request.headers.get('x-vercel-ip-country')
  return new Response(JSON.stringify({ country }))
}
```

### Node.js Runtime 配置

```typescript
// app/api/upload/route.ts
export const runtime = 'nodejs'
export const maxDuration = 60 // 秒

export async function POST(request: Request) {
  // 文件上传处理
}
```

## `vercel.json` 性能配置

### Regions 选择

```json
{
  "regions": ["sin1", "hkg1"]
}
```

**选择原则**：
- 选择离用户最近的区域
- 多区域部署提高可用性
- 数据库区域应与应用区域一致（降低延迟）

| 区域 | 代码 | 覆盖 |
|---|---|---|
| 华盛顿 | cle1 | 美东 |
| 旧金山 | sfo1 | 美西 |
| 伦敦 | lhr1 | 欧洲 |
| 新加坡 | sin1 | 东南亚 |
| 香港 | hkg1 | 亚洲 |
| 东京 | hnd1 | 日本 |

### Functions 配置

```json
{
  "functions": {
    "app/api/upload/route.ts": {
      "memory": 1024,
      "maxDuration": 60
    },
    "app/api/search/route.ts": {
      "memory": 512,
      "maxDuration": 10
    }
  }
}
```

| 场景 | memory | maxDuration |
|---|---|---|
| 轻量 API | 128MB | 10s |
| 普通 API | 256MB | 30s |
| 文件上传 | 1024MB | 60s |
| 重计算 | 2048MB | 300s |

## 渲染模式决策

### SSG（静态生成）

适用：博客、营销页、文档

```typescript
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await getAllPosts()
  return posts.map((post) => ({ slug: post.slug }))
}

export default async function PostPage({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug)
  return <article>{post.content}</article>
}
```

### SSR（服务端渲染）

适用：dashboard、个性化内容

```typescript
// app/dashboard/page.tsx
export const dynamic = 'force-dynamic'

export default async function Dashboard() {
  const data = await getUserData()
  return <div>{data}</div>
}
```

### ISR（增量静态再生）

适用：新闻、商品列表

```typescript
// app/products/page.tsx
export const revalidate = 60 // 60 秒

export default async function Products() {
  const products = await getProducts()
  return <ProductList products={products} />
}
```

### Streaming

适用：多个独立数据源

```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react'

export default function Dashboard() {
  return (
    <div>
      <Suspense fallback={<ChartSkeleton />}>
        <SlowChart />
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <SlowStats />
      </Suspense>
    </div>
  )
}
```

## Bundle 预算

### 配置 Bundle 预算

```json
// .bundlewatch.json
{
  "files": [
    {
      "path": ".next/static/chunks/main-*.js",
      "maxSize": "100kb"
    },
    {
      "path": ".next/static/chunks/framework-*.js",
      "maxSize": "150kb"
    }
  ]
}
```

### 分析 Bundle

```bash
# 安装
npm install -D @next/bundle-analyzer

# 配置 next.config.mjs
import bundleAnalyzer from '@next/bundle-analyzer'

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true',
})

export default withBundleAnalyzer({
  // 其他配置
})

# 运行
ANALYZE=true next build
```

## Web Vitals 目标

| 指标 | 目标 | 优化方式 |
|---|---|---|
| LCP | < 2.5s | `priority` 图片、SSR/SSG、CDN |
| INP | < 200ms | 减少主线程阻塞、代码分割 |
| CLS | < 0.1 | 固定尺寸、`next/font`、避免布局偏移 |
| FCP | < 1.8s | SSR/SSG、关键 CSS 内联 |
| TTFB | < 800ms | Edge Runtime、CDN、缓存 |

## Vercel Analytics

### 启用 Analytics

```bash
npm install @vercel/analytics
```

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
```

### Speed Insights

```bash
npm install @vercel/speed-insights
```

```typescript
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/react'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {children}
        <SpeedInsights />
      </body>
    </html>
  )
}
```

## 缓存策略

### CDN 缓存

```typescript
// app/api/cache/route.ts
export async function GET() {
  return new Response(JSON.stringify(data), {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  })
}
```

### Edge Config（高频读取）

```typescript
// lib/edge-config.ts
import { get } from '@vercel/edge-config'

export async function getConfig(key: string) {
  return await get(key)
}
```

**适用场景**：功能开关、配置项、白名单（读取延迟 < 5ms）

## 性能反模式

```typescript
// ❌ 错误：所有 API 使用 Node.js Runtime
export const runtime = 'nodejs' // 即使是简单 API

// ✅ 正确：简单 API 使用 Edge Runtime
export const runtime = 'edge'
```

```typescript
// ❌ 错误：未设置 maxDuration，默认 10s 超时
export async function POST(request: Request) {
  await longRunningTask() // 超时
}

// ✅ 正确：设置足够的 maxDuration
export const maxDuration = 60
export async function POST(request: Request) {
  await longRunningTask()
}
```

```json
// ❌ 错误：所有 functions 使用高内存
{
  "functions": {
    "**/*.ts": { "memory": 2048 }
  }
}

// ✅ 正确：按需配置
{
  "functions": {
    "app/api/heavy/route.ts": { "memory": 2048, "maxDuration": 300 },
    "app/api/light/route.ts": { "memory": 128, "maxDuration": 10 }
  }
}
```
