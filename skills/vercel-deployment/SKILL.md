---
name: vercel-deployment
description: Vercel 部署模式（部署模式、环境变量管理、运行时选择、渲染模式决策、vercel.json 配置、性能监控）。
metadata:
  origin: ECC-RSK
---

# Vercel Deployment Patterns

Vercel 部署配置与优化，覆盖部署模式、环境变量管理、运行时选择、渲染模式决策、`vercel.json` 配置、性能监控。

> **约束规则**（必须做 / 禁止做）见 [rules/vercel/patterns.md](../../rules/vercel/patterns.md)。本文件聚焦工作流与代码示例。

## When to Activate

- 配置 Vercel 部署
- 管理环境变量
- 选择运行时（Edge vs Node）
- 决定渲染模式（ISR/SSG/SSR）
- 配置 `vercel.json`
- 启用性能监控

---

## 1. 部署模式

### 1.1 Preview Deployment

```bash
# Preview 部署（分支推送自动触发）
vercel

# 或手动触发
vercel --branch feature-branch
```

### 1.2 Production Deployment

```bash
# Production 部署
vercel --prod

# 或从 Preview promote
vercel --prod --yes
```

### 1.3 Rollback

```bash
# 查看部署历史
vercel ls

# Rollback 到上一个部署
vercel rollback

# Rollback 到特定部署
vercel rollback <deployment-url>
```

---

## 2. 环境变量管理

### 2.1 分层（Production / Preview / Development）

```bash
# Production 环境变量
vercel env add NEXT_PUBLIC_SUPABASE_URL production
vercel env add SUPABASE_SERVICE_ROLE_KEY production

# Preview 环境变量
vercel env add NEXT_PUBLIC_SUPABASE_URL preview

# Development 环境变量
vercel env add NEXT_PUBLIC_SUPABASE_URL development
```

### 2.2 `NEXT_PUBLIC_*` 命名约定

- `NEXT_PUBLIC_*` — 公开信息，暴露给 Client
- 非 `NEXT_PUBLIC_*` — 私密信息，仅 Server 可访问

```bash
# ✅ 正确：公开信息
NEXT_PUBLIC_SUPABASE_URL=your-project-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# ✅ 正确：私密信息（仅 Server）
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# ❌ 错误：私密信息暴露给 Client
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 2.3 密钥轮换

定期轮换以下密钥：
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`（如需）
- 第三方 API Key

---

## 3. 运行时选择

### 3.1 Edge vs Node.js

| 运行时 | 适用场景 | 限制 |
|---|---|---|
| **Edge Runtime** | 低延迟、全球分布、轻量逻辑 | API 受限（无 Node.js fs、部分 npm 包不支持） |
| **Node.js Runtime** | 完整 Node.js API、重计算 | 冷启动慢（~1s）、区域固定 |

### 3.2 决策矩阵

| 场景 | 推荐 |
|---|---|
| Middleware | Edge |
| Auth callback | Edge |
| API Route（轻量） | Edge |
| API Route（重计算、Node.js API） | Node.js |
| Server Action（数据库操作） | Node.js（默认） |

### 3.3 配置 Edge Runtime

```typescript
// app/api/light/route.ts
export const runtime = 'edge'

export async function GET() {
  return new Response('Hello from Edge')
}
```

---

## 4. 渲染模式决策

### 4.1 SSG / SSR / ISR / Streaming

| 模式 | 适用场景 | 特点 |
|---|---|
| **SSG**（Static Site Generation） | 静态内容（博客、文档） | 构建时生成，最快 |
| **SSR**（Server-Side Rendering） | 个性化内容（用户仪表盘） | 每请求渲染，动态 |
| **ISR**（Incremental Static Regeneration） | 周期性更新（新闻、商品） | 构建时生成 + 定时更新 |
| **Streaming** | 大数据页面（列表、详情） | 渐进式渲染，用户体验好 |

### 4.2 决策矩阵

| 场景 | 推荐 |
|---|---|
| 静态页面（首页、关于） | SSG |
| 用户个性化页面 | SSR |
| 周期性更新内容 | ISR（`revalidate: 60`） |
| 大数据列表 | Streaming + Suspense |

---

## 5. `vercel.json` 配置

### 5.1 示例配置

```json
{
  "regions": ["sfo1", "iad1"],
  "functions": {
    "app/api/heavy/route.ts": {
      "memory": 1024,
      "maxDuration": 30
    }
  },
  "redirects": [
    {
      "source": "/old-path",
      "destination": "/new-path",
      "permanent": true
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
```

### 5.2 `regions` 选择

选择靠近用户的区域：
- `sfo1` — San Francisco
- `iad1` — Washington, D.C.
- `eu-west1` — Dublin
- `ap-northeast1` — Tokyo

---

## 6. 性能优化

### 6.1 性能目标

| 指标 | 目标 |
|---|---|
| Bundle 大小（First Load JS） | < 100KB |
| LCP（Largest Contentful Paint） | < 2.5s |
| FID（First Input Delay） | < 100ms |
| CLS（Cumulative Layout Shift） | < 0.1 |
| INP（Interaction to Next Paint） | < 200ms |

### 6.2 优化手段

- `next/image` 优化图片
- `next/font` 优化字体
- Dynamic Import 拆分 Bundle
- Suspense 边界细化
- Edge Runtime 减少冷启动

---

## 7. 监控配置

### 7.1 Vercel Analytics

在 Vercel Dashboard 启用 Analytics。

### 7.2 Speed Insights

在 Vercel Dashboard 启用 Speed Insights。

### 7.3 Web Vitals 上报

```typescript
// app/layout.tsx
import { useReportWebVitals } from 'next/web-vitals'

export function WebVitals() {
  useReportWebVitals((metric) => {
    // 发送到 Sentry 或其他分析工具
    console.log(metric)
  })
}
```

### 7.4 Sentry 集成

```bash
# 安装 Sentry
npm install @sentry/nextjs

# 配置 sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 1,
})
```

---

## 8. 部署前检查清单

1. **构建通过** — `next build` 无错误
2. **Lint 通过** — `next lint` 无错误
3. **环境变量配置** — Production 环境变量已设置
4. **Bundle 大小** — First Load JS < 100KB
5. **运行时选择** — Edge/Node.js 已正确配置
6. **性能预算** — LCP < 2.5s、INP < 200ms、CLS < 0.1
7. **监控启用** — Analytics、Speed Insights、Sentry

---

## Best Practices

1. **Preview 部署验证** — 推送前测试 Preview URL
2. **环境变量分层** — Production/Preview/Development
3. **密钥定期轮换** — 安全最佳实践
4. **Edge Runtime 优先** — 低延迟场景
5. **ISR 用于周期性更新** — 平衡性能与更新
6. **Streaming 用于大数据** — 渐进式渲染
7. **`vercel.json` 配置 headers** — 安全加固
8. **启用 Analytics** — 性能监控
9. **启用 Sentry** — 错误追踪
10. **Rollback 策略** — 快速回滚