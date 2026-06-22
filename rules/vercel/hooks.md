---
paths:
  - "**/vercel.json"
  - "**/.vercel/project.json"
  - "**/next.config.*"
---
# Vercel Hooks

> Vercel 部署专用 hook 配置与自动化规范。

## 部署后通知 Hook

### Slack 通知

```typescript
// scripts/hooks/notify-deployment.ts
import { WebClient } from '@slack/web-api'

const slack = new WebClient(process.env.SLACK_TOKEN!)

export async function notifyDeployment(deploymentUrl: string, env: 'preview' | 'production') {
  const emoji = env === 'production' ? ':rocket:' : ':eyes:'
  const message = `${emoji} 部署完成 (${env}): ${deploymentUrl}`

  await slack.chat.postMessage({
    channel: '#deployments',
    text: message,
  })
}
```

### GitHub Deployment API

```typescript
// scripts/hooks/create-github-deployment.ts
import { Octokit } from '@octokit/rest'

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN })

export async function createDeployment(
  owner: string,
  repo: string,
  environment: 'preview' | 'production',
  deploymentUrl: string
) {
  await octokit.repos.createDeployment({
    owner,
    repo,
    ref: process.env.GITHUB_REF!,
    environment,
    required_contexts: [],
    payload: {
      url: deploymentUrl,
    },
  })
}
```

## Preview 部署触发 Hook

### 自动创建 Preview 部署

```typescript
// scripts/hooks/trigger-preview.ts
const response = await fetch('https://api.vercel.com/v13/deployments', {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.VERCEL_TOKEN}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    name: process.env.VERCEL_PROJECT_NAME,
    target: 'preview',
    gitSource: {
      type: 'github',
      org: process.env.GITHUB_OWNER,
      repo: process.env.GITHUB_REPO,
      ref: process.env.BRANCH_NAME,
    },
  }),
})

const deployment = await response.json()
console.log('Preview URL:', deployment.url)
```

## 环境变量同步 Hook

### Vercel ↔ Supabase 同步

```typescript
// scripts/hooks/sync-env.ts
import { createClient } from '@supabase/supabase-js'

async function syncEnvToVercel() {
  // 从 Supabase Vault 读取密钥
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  )

  const { data } = await supabase
    .from('vault_decrypted_secrets')
    .select('name, secret')

  // 同步到 Vercel
  for (const secret of data ?? []) {
    await fetch(`https://api.vercel.com/v9/projects/${process.env.VERCEL_PROJECT_ID}/env`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.VERCEL_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        key: secret.name,
        value: secret.secret,
        type: 'encrypted',
        target: ['production', 'preview'],
      }),
    })
  }
}
```

## Web Vitals 上报 Hook

```typescript
// app/api/web-vitals/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  const metric = await request.json()

  // 上报到 Vercel Analytics / DataDog / Sentry
  console.log('Web Vital:', metric)

  return NextResponse.json({ ok: true })
}
```

## Hook 配置约定

### `hooks.json` 集成

Vercel 相关 hook 可集成到 ECC 的 `hooks/hooks.json`：

```json
{
  "hooks": [
    {
      "event": "post-deploy",
      "command": "node scripts/hooks/notify-deployment.js",
      "match": "vercel"
    }
  ]
}
```

### CI/CD 集成

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Vercel
        run: vercel --prod --token ${{ secrets.VERCEL_TOKEN }}

      - name: Notify deployment
        run: node scripts/hooks/notify-deployment.js
        env:
          DEPLOYMENT_URL: ${{ steps.deploy.outputs.url }}
          ENV: production
```

## 常用 Hook 场景

| 场景 | 触发时机 | 动作 |
|---|---|---|
| Slack 通知 | 部署完成 | 发送部署 URL 到 Slack |
| GitHub Deployment | 部署完成 | 创建 GitHub Deployment 记录 |
| 环境变量同步 | 密钥轮换后 | 从 Vault 同步到 Vercel |
| Web Vitals 上报 | 每次页面访问 | 上报 LCP/INP/CLS |
| Rollback 通知 | 部署失败 | 通知团队并触发 Rollback |
| Preview 清理 | PR 关闭 | 删除对应 Preview 部署 |
