---
paths:
  - "**/tests/deploy/**/*.ts"
  - "**/tests/vercel/**/*.ts"
  - "**/e2e/deploy*.ts"
---
# Vercel Testing

> Vercel 部署测试策略。继承 [common/testing.md](../common/testing.md)。

## 测试分层

| 类型 | 工具 | 目标 |
|---|---|---|
| 构建验证 | `next build` | 零错误、Bundle 大小达标 |
| 环境变量 | 脚本检查 | Production/Preview/Development 分层完整 |
| 部署 Smoke Test | Playwright | Preview 部署关键路由可达 |
| 性能回归 | Lighthouse CI | LCP < 2.5s、INP < 200ms、CLS < 0.1 |
| 安全 Headers | 脚本检查 | CSP、X-Frame-Options、HSTS 正确返回 |
| E2E | Playwright | 生产环境关键用户流程 |

## 部署前验证（CI）

在 CI 中部署前必须通过以下检查：

```yaml
# .github/workflows/deploy.yml（关键步骤）
- name: Build check
  run: pnpm build

- name: Type check
  run: pnpm typecheck

- name: Lint check
  run: pnpm lint

- name: Unit & component tests
  run: pnpm test:run

- name: E2E tests (against preview)
  run: pnpm test:e2e
  env:
    BASE_URL: ${{ steps.deploy.outputs.preview-url }}
```

### 必须做

- `next build` 零错误、零 `exported but not used` 警告
- `tsc --noEmit` 零类型错误
- `next lint` 零 error（warning 可接受）
- 所有 Production 环境变量已在 Vercel Dashboard 配置
- `vercel.json` schema 合法（CI 中用 `ajv` 或 `vercel inspect` 校验）

### 禁止做

- ❌ 跳过 `next build` 直接部署
- ❌ 在 CI 中硬编码 Production 环境变量
- ❌ 部署未经 E2E 测试的 Preview URL 到 Production
- ❌ 忽略 `next build` 输出的 Bundle 大小警告

## Preview 部署 Smoke Test

每次 Preview 部署后自动运行 smoke test：

```typescript
// tests/deploy/smoke.spec.ts
import { test, expect } from '@playwright/test'

const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000'

test.describe('Deployment Smoke Test', () => {
  test('homepage returns 200', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/`)
    expect(response.status()).toBe(200)
  })

  test('API health endpoint returns 200', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/health`)
    expect(response.status()).toBe(200)
    const body = await response.json()
    expect(body).toHaveProperty('status', 'ok')
  })

  test('static assets are served correctly', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/favicon.ico`)
    expect(response.status()).toBe(200)
  })

  test('404 page renders correctly', async ({ page }) => {
    await page.goto(`${BASE_URL}/non-existent-page`)
    await expect(page.getByText('Not Found')).toBeVisible()
  })
})
```

## 性能回归测试

使用 Lighthouse CI 检测性能回归：

```yaml
# .github/workflows/lighthouse.yml
- name: Run Lighthouse CI
  uses: treosh/lighthouse-ci-action@v11
  with:
    urls: |
      ${{ steps.deploy.outputs.preview-url }}
      ${{ steps.deploy.outputs.preview-url }}/dashboard
    budgetPath: .lighthouse-budget.json
    uploadArtifacts: true
```

### Lighthouse Budget

```json
// .lighthouse-budget.json
[
  {
    "path": "/*",
    "timings": [
      { "metric": "largest-contentful-paint", "budget": 2500 },
      { "metric": "interactive", "budget": 3500 },
      { "metric": "cumulative-layout-shift", "budget": 0.1 }
    ],
    "resourceSizes": [
      { "resourceType": "script", "budget": 150 },
      { "resourceType": "stylesheet", "budget": 50 },
      { "resourceType": "image", "budget": 300 }
    ]
  }
]
```

### 必须做

- 每次 Preview 部署运行 Lighthouse CI
- 设定性能预算（budget），超标则 CI 失败
- 记录 LCP / INP / CLS 历史数据，用于趋势分析

### 禁止做

- ❌ 在 Production 部署后才首次运行性能测试
- ❌ 忽略 Lighthouse CI 的性能回归告警
- ❌ 使用 `console.log` 替代正式监控工具

## 安全 Headers 验证

部署后验证安全响应头：

```typescript
// tests/deploy/security-headers.spec.ts
import { test, expect } from '@playwright/test'

const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000'

test.describe('Security Headers', () => {
  test('homepage has required security headers', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/`)

    expect(response.headers()['x-content-type-options']).toBe('nosniff')
    expect(response.headers()['x-frame-options']).toBe('DENY')
    expect(response.headers()['referrer-policy']).toBe('strict-origin-when-cross-origin')
  })

  test('no sensitive env vars exposed in client bundle', async ({ page }) => {
    await page.goto(`${BASE_URL}/`)

    // SUPABASE_SERVICE_ROLE_KEY should NOT appear in client-side code
    const html = await page.content()
    expect(html).not.toContain('service_role')
    expect(html).not.toContain('SUPABASE_SERVICE_ROLE_KEY')
  })
})
```

## E2E 测试（Production）

Production 部署后运行完整 E2E 套件：

### 必须做

- 关键用户流程（登录、注册、核心操作）必须在 Production 环境验证
- E2E 测试使用独立测试账号，不使用真实用户数据
- E2E 失败时自动告警（Slack / GitHub Issue）

### 禁止做

- ❌ E2E 测试写入 Production 真实数据
- ❌ 在 Production E2E 中执行 `DELETE` 或破坏性操作
- ❌ 在 Peak 时段运行重负载 E2E 测试
