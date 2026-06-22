# Node.js Development Rules

> 本文件继承自 ECC 的 `.claude/rules/node.md`，并根据 ECC-RSK 全栈技术栈裁剪。

## 运行时约定

| 项 | 约定 |
|---|---|
| Node.js 版本 | ≥ 20（LTS） |
| 包管理器 | pnpm（首选）/ npm / yarn / bun |
| TypeScript | ≥ 5.4，`strict: true` |
| 模块系统 | ESM（`"type": "module"`） |

## TypeScript 配置

`tsconfig.json` 必须启用：

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

## 包管理

### 包管理器检测

优先级：`pnpm` > `npm` > `yarn` > `bun`

```bash
# 检测锁文件
[ -f "pnpm-lock.yaml" ] && PM="pnpm"
[ -f "package-lock.json" ] && PM="npm"
[ -f "yarn.lock" ] && PM="yarn"
[ -f "bun.lockb" ] && PM="bun"
```

### 脚本约定

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit",
    "test": "vitest",
    "test:run": "vitest run",
    "test:e2e": "playwright test",
    "test:coverage": "vitest run --coverage",
    "db:gen-types": "supabase gen types --typescript > src/types/supabase.ts",
    "db:migrate": "supabase migration up",
    "db:new": "supabase migration new",
    "db:lint": "supabase db lint",
    "db:seed": "supabase db reset --seed"
  }
}
```

## 环境变量

### 必备环境变量

```bash
# Supabase（公开）
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx

# Supabase（仅服务端）
SUPABASE_SERVICE_ROLE_KEY=eyJxxx

# Vercel（可选）
VERCEL_URL=xxx.vercel.app

# Sentry（可选）
SENTRY_DSN=https://xxx@sentry.io/xxx
```

### 校验

启动时校验必备环境变量：

```typescript
// lib/env.ts
function getEnv(key: string): string {
  const value = process.env[key]
  if (!value) {
    throw new Error(`Missing environment variable: ${key}`)
  }
  return value
}

export const env = {
  NEXT_PUBLIC_SUPABASE_URL: getEnv('NEXT_PUBLIC_SUPABASE_URL'),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: getEnv('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
  SUPABASE_SERVICE_ROLE_KEY: getEnv('SUPABASE_SERVICE_ROLE_KEY'),
}
```

## ESLint 配置

```javascript
// eslint.config.mjs
import eslintConfigPrettier from 'eslint-config-prettier'
import eslintConfigNext from 'eslint-config-next'

export default [
  ...eslintConfigNext,
  eslintConfigPrettier,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/consistent-type-imports': 'warn',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
    },
  },
]
```

## 常用命令

| 命令 | 用途 |
|---|---|
| `pnpm dev` | 启动开发服务器 |
| `pnpm build` | 生产构建 |
| `pnpm lint` | ESLint 检查 |
| `pnpm typecheck` | TypeScript 类型检查 |
| `pnpm test` | 运行测试 |
| `pnpm test:e2e` | E2E 测试 |
| `pnpm db:gen-types` | 生成 Supabase 类型 |
| `pnpm db:migrate` | 应用数据库迁移 |

## 排除的非 Web 内容

以下 ECC 内容**不适用**于 ECC-RSK（已剥离）：

- C/C++、Go、Rust、Java、Kotlin、Swift、Flutter、PHP、Python、Django、FastAPI
- C#、F#、Ruby、Perl、Vue、Angular、ArkTS、Dart
- PM2（使用 Vercel 部署）
- Jira（非全栈核心）
- 自主循环（santa-loop、loop-start、loop-status）
