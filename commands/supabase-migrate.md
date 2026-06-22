---
description: Supabase 数据库迁移工作流（生成、应用、回滚、种子数据、类型重新生成）。
---

# Supabase Migrate

Supabase 数据库迁移工作流。

## 适用场景

- 新增数据库表
- 修改表结构（添加/删除列、索引、约束）
- 新增 RLS 策略
- 新增函数、触发器
- 新增 Edge Functions
- 种子数据管理

## 工作流

### 1. 创建迁移文件

```bash
# 创建新迁移
supabase migration new <migration_name>

# 示例
supabase migration new add_profiles_table
supabase migration new add_messages_rls_policies
```

**命名规范**：
- 使用 snake_case
- 描述性名称（`add_`、`update_`、`remove_`）
- 避免使用日期（自动添加时间戳）

### 2. 编写迁移 SQL

**基本结构**：

```sql
-- migrations/20240115120000_add_profiles_table.sql

-- 开启事务
BEGIN;

-- 创建表
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 启用 RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略
CREATE POLICY "Users can read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- 创建索引
CREATE INDEX idx_profiles_username ON public.profiles(username);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at DESC);

-- 创建触发器（自动更新 updated_at）
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 提交事务
COMMIT;
```

**最佳实践**：
- ✅ 使用事务包裹（`BEGIN` / `COMMIT`）
- ✅ 使用 `IF NOT EXISTS` / `IF EXISTS` 避免重复创建
- ✅ 添加 `ON DELETE CASCADE` 处理外键
- ✅ 为外键和常用查询条件创建索引
- ✅ 使用 `timestamptz` 而非 `timestamp`
- ✅ 所有表启用 RLS
- ✅ 使用 `auth.uid()` 和 `auth.jwt()` 进行用户隔离

### 3. 本地验证

```bash
# 启动本地 Supabase
supabase start

# 应用迁移
supabase db reset

# Lint 检查
supabase db lint

# 测试迁移
psql -h localhost -p 54322 -U postgres -d postgres
```

**检查项**：
- [ ] 迁移文件语法正确
- [ ] RLS 策略覆盖所有表
- [ ] 索引创建成功
- [ ] 外键约束正确
- [ ] 触发器工作正常

### 4. 重新生成类型

```bash
# 生成 TypeScript 类型
supabase gen types --typescript --local > types/supabase.ts

# 或从远程项目生成
supabase gen types --typescript --project-id <project-id> > types/supabase.ts
```

**类型文件结构**：

```typescript
// types/supabase.ts
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          username: string
          full_name: string | null
          avatar_url: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          username: string
          full_name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          username?: string
          full_name?: string | null
          avatar_url?: string | null
          created_at?: string
          updated_at?: string
        }
      }
    }
  }
}
```

### 5. 更新 Zod Schema

确保 Zod schema 与数据库类型对齐：

```typescript
// lib/schemas/profile.ts
import { z } from 'zod'

export const profileSchema = z.object({
  username: z.string().min(3).max(50).regex(/^[a-zA-Z0-9_]+$/),
  full_name: z.string().max(100).optional().nullable(),
  avatar_url: z.string().url().optional().nullable()
})

export type ProfileInput = z.infer<typeof profileSchema>
```

### 6. 运行测试

```bash
# 单元测试
npm run test

# 类型检查
npm run typecheck

# E2E 测试
npm run test:e2e
```

### 7. 提交迁移

```bash
# 提交迁移文件 + 类型文件
git add supabase/migrations/
git add types/supabase.ts
git commit -m "feat: add profiles table with RLS policies"
```

## 回滚迁移

Supabase 不支持自动回滚，需要手动创建回滚迁移：

```bash
# 创建回滚迁移
supabase migration new remove_profiles_table
```

```sql
-- migrations/20240115130000_remove_profiles_table.sql

BEGIN;

-- 删除触发器
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
DROP FUNCTION IF EXISTS public.handle_updated_at();

-- 删除表（CASCADE 会删除依赖）
DROP TABLE IF EXISTS public.profiles CASCADE;

COMMIT;
```

## 种子数据

创建 `supabase/seed.sql`：

```sql
-- supabase/seed.sql

-- 插入测试用户（仅在开发环境）
INSERT INTO public.profiles (id, username, full_name)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'testuser1', 'Test User 1'),
  ('00000000-0000-0000-0000-000000000002', 'testuser2', 'Test User 2')
ON CONFLICT (id) DO NOTHING;
```

```bash
# 应用种子数据
supabase db reset
```

## Edge Functions 迁移

```bash
# 创建 Edge Function
supabase functions new <function-name>

# 本地测试
supabase functions serve <function-name> --env-file supabase/.env.local

# 部署
supabase functions deploy <function-name>
```

## 常见问题

### 迁移冲突

```bash
# 查看迁移状态
supabase migration list

# 强制重置（开发环境）
supabase db reset

# 修复迁移版本
supabase migration repair --status reverted <version>
```

### 类型生成失败

```bash
# 确保本地服务运行
supabase start

# 检查数据库连接
supabase db ping

# 重新生成
supabase gen types --typescript --local > types/supabase.ts
```

### RLS 策略测试

```sql
-- 测试 RLS 策略
SET ROLE authenticated;
SET request.jwt.claims = '{"sub": "user-uuid"}';

-- 应该只返回当前用户的数据
SELECT * FROM public.profiles;

-- 重置角色
RESET ROLE;
```

## 诊断命令

```bash
# 查看本地服务状态
supabase status

# 查看迁移历史
supabase migration list

# 数据库 Lint
supabase db lint

# 类型生成
supabase gen types --typescript --local > types/supabase.ts

# Edge Functions 部署检查
supabase functions deploy --dry-run

# 查看数据库差异
supabase db diff
```

## 相关命令

- `/supabase-review` — 迁移后审查 RLS 策略
- `/typecheck-e2e` — 验证类型安全
- `/fullstack-init` — 初始化项目

## 相关 Skills

- `supabase-patterns` — Supabase 最佳实践
- `type-safe-stack` — 端到端类型安全