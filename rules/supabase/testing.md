---
paths:
  - "**/supabase/**/*.test.ts"
  - "**/supabase/functions/**/*.test.ts"
  - "**/tests/supabase/**/*.ts"
---
# Supabase Testing

> Supabase 测试策略。继承 [common/testing.md](../common/testing.md)。

## 测试分层

| 类型 | 工具 | 目标 |
|---|---|---|
| RLS 策略 | `pgTAP` / `supabase test` | 行级安全策略 |
| Auth 流 | Vitest + mock | 登录、注册、会话 |
| Realtime | Vitest + mock | 订阅、清理 |
| Storage | Vitest + mock | 上传、下载、权限 |
| Edge Functions | `deno test` | 函数逻辑、JWT 校验 |
| E2E | Playwright | 完整用户流程 |

## RLS 策略测试

使用 `pgTAP` 测试 RLS 策略：

```sql
-- supabase/tests/rls_posts.test.sql
BEGIN;
SELECT plan(4);

-- 创建测试用户
SELECT tests.authenticate('user-1@example.com');

-- 测试 SELECT 策略
SELECT lives_ok(
  $$ INSERT INTO posts (id, author_id, title) VALUES ('1', auth.uid(), 'My Post') $$,
  'User can insert own post'
);

SELECT results_eq(
  $$ SELECT title FROM posts $$,
  ARRAY['My Post'],
  'User can read own post'
);

-- 切换到其他用户
SELECT tests.authenticate('user-2@example.com');

SELECT is_empty(
  $$ SELECT * FROM posts WHERE author_id != auth.uid() $$,
  'User cannot read others posts'
);

SELECT throws_ok(
  $$ INSERT INTO posts (id, author_id, title) VALUES ('2', 'user-1-uuid', 'Hack') $$,
  'User cannot insert post as another user'
);

SELECT finish();
ROLLBACK;
```

运行测试：

```bash
supabase db test
```

## Auth 流测试

```typescript
// __tests__/auth.test.ts
import { describe, test, expect, vi } from 'vitest'

vi.mock('@/lib/supabase/client', () => ({
  createBrowserClient: () => ({
    auth: {
      signInWithPassword: vi.fn().mockResolvedValue({
        data: { user: { id: '123', email: 'test@example.com' } },
        error: null,
      }),
      signUp: vi.fn().mockResolvedValue({
        data: { user: null },
        error: { message: 'User already registered' },
      }),
      signOut: vi.fn().mockResolvedValue({ error: null }),
    },
  }),
}))

import { signIn, signUp, signOut } from '@/lib/actions/auth'

test('signIn returns user on success', async () => {
  const result = await signIn('test@example.com', 'password')
  expect(result.user?.email).toBe('test@example.com')
})

test('signUp returns error on duplicate', async () => {
  const result = await signUp('test@example.com', 'password')
  expect(result.error).toBeDefined()
})
```

## Realtime 测试

```typescript
// __tests__/realtime.test.ts
import { renderHook, act } from '@testing-library/react'
import { vi } from 'vitest'

const mockSubscribe = vi.fn()
const mockUnsubscribe = vi.fn()
const mockChannel = {
  on: vi.fn().mockReturnThis(),
  subscribe: mockSubscribe.mockReturnValue({
    unsubscribe: mockUnsubscribe,
  }),
}

vi.mock('@/lib/supabase/client', () => ({
  createBrowserClient: () => ({
    channel: vi.fn().mockReturnValue(mockChannel),
    removeChannel: vi.fn(),
    from: () => ({
      select: vi.fn().mockResolvedValue({ data: [] }),
    }),
  }),
}))

import { useRealtime } from '@/hooks/use-realtime'

test('subscribes and cleans up', () => {
  const { unmount } = renderHook(() => useRealtime('posts'))

  expect(mockSubscribe).toHaveBeenCalled()

  unmount()

  expect(mockUnsubscribe).toHaveBeenCalled()
})
```

## Storage 测试

```typescript
// __tests__/storage.test.ts
import { vi } from 'vitest'

const mockUpload = vi.fn()
const mockGetPublicUrl = vi.fn()
const mockCreateSignedUrl = vi.fn()
const mockRemove = vi.fn()

vi.mock('@/lib/supabase/client', () => ({
  createBrowserClient: () => ({
    storage: {
      from: () => ({
        upload: mockUpload,
        getPublicUrl: mockGetPublicUrl,
        createSignedUrl: mockCreateSignedUrl,
        remove: mockRemove,
      }),
    },
  }),
}))

import { useStorage } from '@/hooks/use-storage'

test('upload calls storage API', async () => {
  mockUpload.mockResolvedValue({
    data: { path: 'avatars/123' },
    error: null,
  })
  mockGetPublicUrl.mockReturnValue({
    data: { publicUrl: 'https://example.com/avatars/123' },
  })

  const { result } = renderHook(() => useStorage('avatars'))

  await act(async () => {
    const url = await result.current.upload('123', new File([], 'test.png'))
    expect(url).toBe('https://example.com/avatars/123')
  })

  expect(mockUpload).toHaveBeenCalled()
})
```

## Edge Functions 测试

使用 `deno test`：

```typescript
// supabase/functions/secure-endpoint/index.test.ts
import { assertEquals } from 'https://deno.land/std/testing/asserts.ts'

Deno.test('returns 401 without Authorization header', async () => {
  const request = new Request('https://example.com', {
    method: 'POST',
    body: JSON.stringify({}),
  })

  const response = await handler(request)
  assertEquals(response.status, 401)
})

Deno.test('returns 200 with valid JWT', async () => {
  const request = new Request('https://example.com', {
    method: 'POST',
    headers: {
      Authorization: 'Bearer valid-jwt',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({}),
  })

  // Mock supabase.auth.getUser
  const response = await handler(request)
  assertEquals(response.status, 200)
})
```

运行测试：

```bash
deno test --allow-all supabase/functions/
```

## E2E 测试（Playwright）

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('user can register and login', async ({ page }) => {
  await page.goto('/register')
  await page.fill('[name="email"]', 'newuser@example.com')
  await page.fill('[name="password"]', 'SecurePassword123!')
  await page.click('button[type="submit"]')

  await expect(page).toHaveURL('/dashboard')
})

test('user cannot access dashboard without login', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page).toHaveURL('/login')
})
```

## 测试约定

### 本地开发

```bash
# 启动本地 Supabase
supabase start

# 重置数据库（应用迁移 + 种子数据）
supabase db reset

# 运行 RLS 测试
supabase db test

# 生成类型
supabase gen types --local > src/types/supabase.ts
```

### CI 环境

```yaml
# .github/workflows/ci.yml
- name: Start Supabase
  run: supabase start

- name: Run RLS tests
  run: supabase db test

- name: Run Edge Function tests
  run: deno test --allow-all supabase/functions/

- name: Stop Supabase
  if: always()
  run: supabase stop
```

### 覆盖率目标

- RLS 策略：100%（所有表、所有操作）
- Auth 流：≥ 90%
- Edge Functions：≥ 80%
- Storage 操作：≥ 80%
