---
paths:
  - "**/vercel.json"
  - "**/.env*"
  - "**/next.config.*"
---
# Vercel Security

> Vercel 部署安全规范。继承 [common/security.md](../common/security.md)。

## 环境变量安全（CRITICAL）

### 分层管理

Vercel 环境变量分三层，**严格区分**：

| 层级 | 用途 | 示例 |
|---|---|---|
| Production | 生产环境 | `SUPABASE_SERVICE_ROLE_KEY` |
| Preview | 预览环境（PR 部署） | `STAGING_API_URL` |
| Development | 本地开发 | `LOCAL_SUPABASE_URL` |

```bash
# ✅ 正确：Production 密钥仅 Production
vercel env add SUPABASE_SERVICE_ROLE_KEY production

# ✅ 正确：公开 URL 所有环境共享
vercel env add NEXT_PUBLIC_SUPABASE_URL production preview development
```

### `NEXT_PUBLIC_*` 审查

```bash
# ❌ CRITICAL：Service Role Key 使用 NEXT_PUBLIC_ 前缀
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=xxx # 暴露给 Client

# ✅ 正确：仅公开信息使用 NEXT_PUBLIC_
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx
```

### 密钥轮换

定期轮换密钥（建议每 90 天）：

```bash
# 1. 在 Supabase Dashboard 生成新密钥
# 2. 更新 Vercel 环境变量
vercel env rm SUPABASE_SERVICE_ROLE_KEY production
vercel env add SUPABASE_SERVICE_ROLE_KEY production

# 3. 重新部署
vercel --prod

# 4. 在 Supabase Dashboard 吊销旧密钥
```

## Preview 环境隔离

### 独立数据库

Preview 环境应使用独立的 Supabase 项目或 schema：

```bash
# Production
NEXT_PUBLIC_SUPABASE_URL=https://prod.supabase.co
SUPABASE_SERVICE_ROLE_KEY=prod-key

# Preview
NEXT_PUBLIC_SUPABASE_URL=https://staging.supabase.co
SUPABASE_SERVICE_ROLE_KEY=staging-key
```

### 防止数据污染

```typescript
// lib/supabase/admin.ts
import 'server-only'

const env = process.env.NODE_ENV // 'production' | 'development'
const isProduction = env === 'production'

export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!url || !key) {
    throw new Error('Missing Supabase credentials')
  }

  // ✅ 在非生产环境打标记
  const client = createClient(url, key)
  if (!isProduction) {
    console.warn('⚠️ Using non-production Supabase')
  }

  return client
}
```

## 防火墙规则

### Vercel Firewall

配置 Vercel Firewall 防止恶意流量：

```json
// vercel.json
{
  "firewall": {
    "rules": [
      {
        "action": "deny",
        "condition": {
          "type": "rate_limit",
          "limit": 100,
          "window": "1m"
        }
      }
    ]
  }
}
```

### IP 白名单（Edge Config）

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

const ALLOWED_IPS = ['192.168.1.1', '10.0.0.1']

export function middleware(request: NextRequest) {
  const ip = request.headers.get('x-forwarded-for')?.split(',')[0]

  if (process.env.ADMIN_IP_WHITELIST === 'true' && ip && !ALLOWED_IPS.includes(ip)) {
    return new NextResponse('Forbidden', { status: 403 })
  }

  return NextResponse.next()
}
```

## Headers 配置

### 安全 Headers

```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Permissions-Policy", "value": "camera=(), microphone=(), geolocation=()" },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains; preload"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://*.supabase.co;"
        }
      ]
    }
  ]
}
```

## 域名安全

### HTTPS 强制

Vercel 默认启用 HTTPS，但应配置 HSTS：

```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=31536000; includeSubDomains; preload"
        }
      ]
    }
  ]
}
```

### 重定向配置

```json
// vercel.json
{
  "redirects": [
    {
      "source": "/old-path",
      "destination": "/new-path",
      "permanent": true
    },
    {
      "source": "/:path*",
      "has": [{ "type": "host", "value": "old-domain.com" }],
      "destination": "https://new-domain.com/:path*",
      "permanent": true
    }
  ]
}
```

## 部署安全

### 部署令牌管理

```bash
# ❌ CRITICAL：硬编码 token
git commit -m "deploy" && vercel --token abc123

# ✅ 正确：使用环境变量
vercel --token $VERCEL_TOKEN
```

### GitHub 集成安全

- 使用 Vercel GitHub App（而非 Personal Access Token）
- 限制部署权限到特定仓库
- 启用 Vercel Protection Bypass for Automation（仅 Preview）

## 监控与告警

### Sentry 集成

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
  // 过滤敏感信息
  beforeSend(event) {
    if (event.request?.headers) {
      delete event.request.headers.authorization
      delete event.request.headers.cookie
    }
    return event
  },
})
```

### 告警规则

| 事件 | 阈值 | 动作 |
|---|---|---|
| 5xx 错误率 | > 1% | PagerDuty 告警 |
| 响应时间 | P95 > 2s | Slack 通知 |
| 部署失败 | 任何 | 通知团队 |
| 异常流量 | QPS > 1000 | 触发防火墙 |
