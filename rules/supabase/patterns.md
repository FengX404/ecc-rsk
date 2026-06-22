# Supabase Rules

> Supabase **约束规则**。代码示例与工作流见 [skills/supabase-patterns/SKILL.md](../../skills/supabase-patterns/SKILL.md)。

## RLS（Row Level Security）

### 必须做

- **所有表必须启用 RLS**（`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`）
- 用户数据使用 `auth.uid()` 进行行级隔离
- 多租户场景使用 `EXISTS` 子查询验证成员关系
- `SECURITY DEFINER` 函数必须验证 `auth.uid()` 不为 NULL
- 公开读 / 私有写场景分别创建 SELECT 与 INSERT/UPDATE/DELETE 策略

### 禁止做

- ❌ 创建表后不启用 RLS
- ❌ `SECURITY DEFINER` 函数不验证调用者身份
- ❌ RLS 策略中使用动态 SQL（SQL 注入风险）
- ❌ 依赖应用层鉴权替代 RLS（RLS 是最后一道防线）

## Auth

### 必须做

- 使用 `@supabase/ssr` 实现 PKCE 流程
- Server Component 使用 `createServerClient`（带 cookie 处理）
- Client Component 使用 `createBrowserClient`
- Middleware 中调用 `supabase.auth.getUser()` 刷新会话
- 登录后通过 `redirect` 参数回跳原页面

### 禁止做

- ❌ 使用 `getSession()` 读取会话（已过期会返回旧会话，必须用 `getUser()`）
- ❌ 在 Client Component 中创建 Server Client
- ❌ 将 `SUPABASE_SERVICE_ROLE_KEY` 暴露给客户端

## Server Actions / Route Handlers

### 必须做

- 所有 Server Action 必须校验输入（Zod schema）
- 所有 Server Action 必须校验用户身份
- 数据库操作依赖 RLS 自动隔离（仍需校验 user.id 一致性）

### 禁止做

- ❌ 直接信任 `formData.get()` 并类型断言
- ❌ 未校验用户身份执行写操作
- ❌ 使用 `formData.get('id')` 作为数据所有权判断依据（必须用 `user.id`）

## Edge Functions

### 必须做

- 使用 Deno 运行时
- 校验 `Authorization` header 中的 JWT
- 处理 `OPTIONS` 预检请求（CORS）
- 通过 `Deno.env.get()` 读取环境变量

### 禁止做

- ❌ 硬编码 Supabase URL / Key
- ❌ 未校验 JWT 直接执行业务逻辑
- ❌ 在 Edge Function 中使用 Node.js 专用 API

## Realtime

### 必须做

- 订阅特定表 + 特定 `filter`（避免订阅所有变更）
- `useEffect` 中返回清理函数调用 `supabase.removeChannel(channel)`
- 使用 `channel` 名称区分不同订阅

### 禁止做

- ❌ 订阅 `schema: '*'`（订阅所有表变更，性能与安全风险）
- ❌ 不清理订阅（内存泄漏）

## Storage

### 必须做

- 私有文件使用签名 URL（`createSignedUrl`）
- 上传前校验文件类型（白名单）和大小限制
- 文件路径包含 `user.id` 做隔离
- 私有桶设为 `private`

### 禁止做

- ❌ 未校验文件类型 / 大小直接上传
- ❌ 公开桶存储敏感文件
- ❌ 使用原始文件名作为存储路径（路径冲突 + 信息泄露）

## 密钥管理

### 必须做

- `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` 可暴露给客户端
- `SUPABASE_SERVICE_ROLE_KEY` 仅服务端使用（Server Component / Server Action / Route Handler / Edge Function）
- 定期轮换 `SERVICE_ROLE_KEY`

### 禁止做

- ❌ `NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY`（前缀错误，暴露密钥）
- ❌ 在客户端代码中导入 `service_role` key
- ❌ 将 service_role key 写入 `.env.local` 后提交到 git

## 类型安全

### 必须做

- 使用 `supabase gen types typescript` 生成类型
- 生成的类型文件纳入版本控制
- 数据库 schema 变更后重新生成类型
- CI 中校验类型是否与远程数据库同步

### 禁止做

- ❌ 手动维护 Supabase 类型
- ❌ 使用 `as any` 绕过类型检查

## 迁移

### 必须做

- 使用 `supabase migration new` 创建迁移
- 迁移 SQL 包裹在事务中（`BEGIN ... COMMIT`）
- 种子数据与迁移分离（`seed.sql`）
- 外键必须创建索引

### 禁止做

- ❌ 直接在数据库中修改 schema（不通过迁移）
- ❌ 迁移中混入种子数据
- ❌ 删除已应用的迁移文件

## 相关 Skills

- `supabase-patterns` — 完整代码示例与工作流
- `fullstack-auth` — 认证与授权
- `realtime-sync` — Realtime 订阅模式

## 相关 Commands

- `/supabase-review` — Supabase 审查
- `/supabase-migrate` — 数据库迁移
