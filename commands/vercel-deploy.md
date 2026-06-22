---
description: Vercel 部署前检查与部署执行（环境变量、运行时、构建、Preview/Production）。
---

# Vercel Deploy

Vercel 部署前检查与部署执行。

## 适用场景

- 首次部署到 Vercel
- 更新部署配置
- 部署前检查
- Preview 部署
- Production 部署
- 部署后验证

## 工作流

### 1. 部署前检查

**检查清单**：

```bash
# 1. 检查 vercel.json 配置
cat vercel.json

# 2. 检查环境变量
vercel env ls

# 3. 本地构建测试
next build

# 4. 类型检查
tsc --noEmit

# 5. Lint 检查
next lint

# 6. 测试运行
npm run test
```

**vercel.json 配置示例**：

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "buildCommand": "next build",
  "devCommand": "next dev",
  "installCommand": "npm install",
  "regions": ["hnd1", "sfo1"],
  "functions": {
    "app/api/**/*.ts": {
      "runtime": "edge",
      "maxDuration": 30
    },
    "app/**/route.ts": {
      "runtime": "nodejs",
      "maxDuration": 60
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "s-maxage=60, stale-while-revalidate=300" }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/blog/:path*",
      "destination": "/posts/:path*"
    }
  ],
  "redirects": [
    {
      "source": "/old-path",
      "destination": "/new-path",
      "permanent": true
    }
  ]
}
```

### 2. 环境变量管理

**环境变量清单**：

```bash
# 列出所有环境变量
vercel env ls

# 添加环境变量
vercel env add NEXT_PUBLIC_SUPABASE_URL
vercel env add NEXT_PUBLIC_SUPABASE_ANON_KEY
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add DATABASE_URL

# 拉取环境变量到本地
vercel env pull .env.local

# 推送环境变量到 Vercel
vercel env push
```

**环境变量分类**：

| 变量 | 环境 | 说明 |
|------|------|------|
| `NEXT_PUBLIC_*` | Preview, Production | 客户端可见 |
| `SUPABASE_*` | Preview, Production | 服务端密钥 |
| `DATABASE_URL` | Preview, Production | 数据库连接 |
| `SENTRY_DSN` | Preview, Production | 错误监控 |

**安全检查**：
- [ ] 所有 secrets 使用服务端环境变量
- [ ] `NEXT_PUBLIC_*` 仅包含公开信息
- [ ] Preview 和 Production 环境变量分离
- [ ] 敏感变量不在 Git 中提交

### 3. 运行时选择

**Edge Runtime vs Node.js Runtime**：

| 特性 | Edge Runtime | Node.js Runtime |
|------|-------------|-----------------|
| 冷启动 | < 50ms | ~1s |
| 最大执行时间 | 30s | 60s (Pro) / 900s (Enterprise) |
| 内存限制 | 128MB | 1024MB (Pro) / 3008MB (Enterprise) |
| Node.js API | 有限 | 完整 |
| npm 包 | 有限 | 完整 |
| 数据库连接 | HTTP only | 支持 TCP |

**选择决策**：

```typescript
// ✅ 使用 Edge Runtime：轻量、快速响应
export const runtime = 'edge'

export async function GET() {
  // 简单的 API 调用
  const data = await fetch('https://api.example.com/data')
  return Response.json(data)
}

// ✅ 使用 Node.js Runtime：需要完整 Node.js API
export const runtime = 'nodejs'

import { createClient } from '@supabase/supabase-js'

export async function GET() {
  // 需要数据库连接
  const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)
  const { data } = await supabase.from('posts').select('*')
  return Response.json(data)
}
```

### 4. Bundle 分析

```bash
# 安装 bundle analyzer
npm install -D @next/bundle-analyzer

# next.config.mjs
import bundleAnalyzer from '@next/bundle-analyzer'

const withBundleAnalyzer = bundleAnalyzer({
  enabled: process.env.ANALYZE === 'true'
})

export default withBundleAnalyzer({
  // 其他配置
})

# 运行分析
ANALYZE=true next build
```

**Bundle 优化**：

```typescript
// ✅ 使用 dynamic import 代码分割
import dynamic from 'next/dynamic'

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <p>Loading...</p>,
  ssr: false
})

// ✅ 使用 tree shaking
import { debounce } from 'lodash-es' // 使用 lodash-es 而非 lodash

// ❌ 避免导入整个库
import _ from 'lodash' // 导入整个库！
```

### 5. Preview 部署

```bash
# 登录 Vercel
vercel login

# 部署到 Preview
vercel

# 查看部署状态
vercel ls

# 查看部署详情
vercel inspect <deployment-url>

# 查看日志
vercel logs <deployment-url>
```

**Preview 部署检查**：
- [ ] 构建成功
- [ ] 环境变量正确
- [ ] 页面加载正常
- [ ] API 路由工作正常
- [ ] 图片加载正常
- [ ] 重定向正确
- [ ] 认证流程正常

### 6. 审查 Preview URL

```bash
# 打开 Preview URL
open <deployment-url>

# 运行 E2E 测试
npm run test:e2e -- --base-url=<deployment-url>

# Lighthouse 测试
npx lighthouse <deployment-url> --view

# Web Vitals
npx web-vitals --url=<deployment-url>
```

**性能目标**：

| 指标 | 目标 |
|------|------|
| LCP (Largest Contentful Paint) | < 2.5s |
| FID (First Input Delay) | < 100ms |
| CLS (Cumulative Layout Shift) | < 0.1 |
| TTFB (Time to First Byte) | < 600ms |
| Bundle Size (gzipped) | < 200KB |

### 7. Promote to Production

```bash
# 部署到 Production
vercel --prod

# 或从 Preview Promote
vercel --prod <deployment-url>

# 查看生产部署
vercel ls --prod

# 查看生产日志
vercel logs --prod
```

**Production 部署检查**：
- [ ] 所有测试通过
- [ ] Preview 部署验证通过
- [ ] 环境变量正确
- [ ] 域名配置正确
- [ ] SSL 证书有效
- [ ] 监控配置正确

### 8. 部署后验证

**监控配置**：

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

export default function RootLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <html>
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
```

**Sentry 配置**：

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.VERCEL_ENV,
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0
})
```

**验证清单**：
- [ ] 首页加载正常
- [ ] 认证流程正常
- [ ] API 路由响应正常
- [ ] 图片优化正常
- [ ] 错误监控正常
- [ ] 性能监控正常
- [ ] 日志收集正常

## 常见问题

### 构建失败

```bash
# 查看构建日志
vercel logs <deployment-url> --output raw

# 本地复现
vercel build

# 检查 Node.js 版本
node --version
```

### 环境变量缺失

```bash
# 检查环境变量
vercel env ls

# 拉取环境变量
vercel env pull .env.local

# 添加缺失的环境变量
vercel env add <VARIABLE_NAME>
```

### 函数超时

```typescript
// 增加函数超时时间
export const maxDuration = 60 // 秒

export async function GET() {
  // 长时间运行的函数
}
```

### 内存不足

```typescript
// 使用流式响应
export async function GET() {
  const stream = new ReadableStream({
    async start(controller) {
      // 流式处理大数据
      controller.enqueue(new TextEncoder().encode('data'))
      controller.close()
    }
  })

  return new Response(stream)
}
```

## 诊断命令

```bash
# 部署列表
vercel ls

# 部署详情
vercel inspect <deployment-url>

# 部署日志
vercel logs <deployment-url>

# 环境变量
vercel env ls

# 域名管理
vercel domains ls

# 项目信息
vercel project ls

# 本地开发
vercel dev
```

## 相关命令

- `/nextjs-review` — Next.js 审查
- `/supabase-review` — Supabase 审查
- `/typecheck-e2e` — 类型检查

## 相关 Skills

- `vercel-deployment` — Vercel 部署模式
- `nextjs-app-router` — Next.js App Router
- `fullstack-auth` — 认证与授权