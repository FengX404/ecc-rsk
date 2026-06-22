# Next.js App Router Rules

> Next.js App Router **约束规则**。代码示例与工作流见 [skills/nextjs-app-router/SKILL.md](../../skills/nextjs-app-router/SKILL.md)。

## RSC / Client Component 边界

### 必须做

- `app/` 目录下组件默认为 Server Component，无需标记
- 仅在需要客户端功能时使用 `"use client"`：hooks、事件处理、浏览器 API、Context Provider
- 通过 `children` 传递 Server Component 给 Client Component
- 服务端专用模块使用 `import "server-only"` 标记

### 禁止做

- ❌ Client Component 中导入 Server Component（直接 import）
- ❌ Client Component 中导入 `server-only` 模块
- ❌ Server Component 中使用 `useState` / `useEffect` / `useRef` 等 hooks
- ❌ Server Component 中使用事件处理器（`onClick` / `onChange`）
- ❌ Server Component 中使用浏览器 API（`window` / `document` / `localStorage`）
- ❌ Server Component 中使用 `cookies()` / `headers()`（仅限 Server Component 内部使用，不可跨边界）

## Server Actions

### 必须做

- 文件级 Server Action 在文件顶部标记 `"use server"`
- 内联 Server Action 在函数体首行标记 `"use server"`
- 所有 Server Action 必须用 Zod 校验输入
- 所有 Server Action 必须校验用户身份（`supabase.auth.getUser()`）
- 执行写操作后必须调用 `revalidatePath` 或 `revalidateTag` 刷新缓存
- 返回值必须可序列化（避免 `Date` / `Map` / `Set` / 类实例）

### 禁止做

- ❌ 缺少 `"use server"` 标记的 async 函数被用作 form action
- ❌ 未校验输入直接 `formData.get()` + 类型断言
- ❌ 未校验用户身份直接执行写操作
- ❌ 返回 `Date` 对象（应转为 ISO string）
- ❌ 返回函数、类实例、Symbol 等不可序列化值

## Route Handlers

### 必须做

- 显式处理 HTTP 方法（`GET` / `POST` / `PUT` / `DELETE`）
- 返回 `NextResponse.json()` 或标准 `Response`
- 配置 CORS（如需跨域访问）

### 禁止做

- ❌ 未处理 `OPTIONS` 预检请求（CORS 场景）
- ❌ 在 Route Handler 中调用 `cookies()` 时不处理异常

## Middleware

### 必须做

- 配置 `matcher` 排除静态资源（`_next/static` / `_next/image` / `favicon.ico` / 图片文件）
- 使用 `supabase.auth.getUser()` 刷新会话（而非 `getSession()`）
- 路由保护时设置 `redirect` 参数，登录后回跳

### 禁止做

- ❌ `matcher: '*'`（匹配所有路径，包括静态资源）
- ❌ Middleware 中匹配 API 路由（可能导致无限循环）
- ❌ 使用 `getSession()` 读取会话（已过期会返回旧会话，必须用 `getUser()`）

## 缓存策略

### 必须做

- 显式设置 `fetch` 的 `cache` 选项（`force-cache` / `no-store` / `next.revalidate`）
- 用户特定数据使用 `cache: 'no-store'` 或 `dynamic = 'force-dynamic'`
- 静态数据使用 `force-cache`（默认）
- 周期性更新数据使用 ISR（`revalidate: N`）

### 禁止做

- ❌ 用户特定数据使用 `force-cache`（会导致数据串号）
- ❌ Server Action 写操作后不调用 `revalidatePath` / `revalidateTag`

## Metadata

### 必须做

- 为每个页面设置 `metadata`（静态）或 `generateMetadata`（动态）
- 包含 `title` / `description` / `openGraph`
- 提供 `sitemap.ts` 和 `robots.ts`

## 性能

### 必须做

- 使用 `next/image` 替代 `<img>`
- 使用 `next/font` 替代外部字体链接
- 大型组件使用 `next/dynamic` 代码分割
- 使用 `Suspense` 边界细化 Streaming

### 禁止做

- ❌ 使用原生 `<img>` 标签
- ❌ 通过 `<link>` 引入 Google Fonts
- ❌ 直接导入大型第三方组件而不做代码分割

## Props 序列化

### 禁止做

- ❌ Server Component 向 Client Component 传递函数 props
- ❌ Server Component 向 Client Component 传递类实例 props
- ❌ Server Component 向 Client Component 传递 `Date` / `Map` / `Set` / `Symbol`

### 必须做

- 传递可序列化的纯对象（JSON 兼容）
- `Date` 转为 ISO string
- 复杂结构用 `JSON.parse(JSON.stringify(obj))` 预处理

## 相关 Skills

- `nextjs-app-router` — 完整代码示例与工作流
- `fullstack-auth` — 认证与授权
- `type-safe-stack` — 端到端类型安全

## 相关 Commands

- `/nextjs-review` — Next.js App Router 审查
- `/vercel-deploy` — Vercel 部署
