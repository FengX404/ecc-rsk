# Vercel Deployment Rules

> Vercel 部署**约束规则**。代码示例与工作流见 [skills/vercel-deployment/SKILL.md](../../skills/vercel-deployment/SKILL.md)。

## 环境变量

### 必须做

- 使用 Vercel 环境变量管理（`vercel env add`），不硬编码
- 分层配置：Production / Preview / Development
- `NEXT_PUBLIC_*` 前缀仅用于公开信息（URL、anon key）
- 私密信息（service_role_key、数据库连接串）不使用 `NEXT_PUBLIC_` 前缀
- 定期轮换 `SUPABASE_SERVICE_ROLE_KEY` 与第三方 API Key

### 禁止做

- ❌ `NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY`（前缀错误，暴露密钥）
- ❌ 在代码中硬编码 URL / Key
- ❌ 将 `.env.local` 提交到 git
- ❌ 在客户端代码中引用非 `NEXT_PUBLIC_*` 环境变量

## 运行时选择

### 必须做

- 路由级显式声明 `export const runtime = 'edge' | 'nodejs'`
- Middleware 使用 Edge Runtime
- Auth callback 使用 Edge Runtime
- 数据库操作（TCP 连接）使用 Node.js Runtime
- 文件系统操作使用 Node.js Runtime
- 重计算任务使用 Node.js Runtime 并配置 `maxDuration`

### 禁止做

- ❌ Edge Runtime 中使用 `fs` / `path` / `child_process` 等 Node.js API
- ❌ Edge Runtime 中使用依赖 TCP 的数据库驱动
- ❌ 超过运行时执行时间限制（Edge 30s / Node.js Pro 60s）
- ❌ 未设置 `maxDuration` 导致长任务被截断

## 部署流程

### 必须做

- 推送前验证 Preview 部署
- Production 部署使用 `vercel --prod` 或从 Preview promote
- 部署前检查清单：构建通过 / Lint 通过 / 环境变量配置 / Bundle 大小 / 运行时配置
- 配置 Rollback 策略

### 禁止做

- ❌ 直接推送主分支触发 Production 部署（应先 Preview 验证）
- ❌ 部署后不验证关键用户流程

## 性能

### 必须做

- First Load JS < 100KB
- LCP < 2.5s
- INP < 200ms
- CLS < 0.1
- 使用 `next/image` 优化图片
- 使用 `next/font` 优化字体
- 大型组件使用 `next/dynamic` 代码分割
- 配置 `Cache-Control` 头（`s-maxage` + `stale-while-revalidate`）

### 禁止做

- ❌ 使用原生 `<img>` 标签
- ❌ 通过 `<link>` 引入 Google Fonts
- ❌ Bundle 大小超过预算不优化

## 监控

### 必须做

- 启用 Vercel Analytics
- 启用 Vercel Speed Insights
- 配置错误追踪（Sentry 或类似工具）
- 配置 Web Vitals 上报

### 禁止做

- ❌ 生产环境无错误追踪
- ❌ 无性能监控

## vercel.json 配置

### 必须做

- 配置安全 headers（`X-Content-Type-Options` / `X-Frame-Options` / `X-XSS-Protection`）
- 配置 `regions` 选择靠近用户的区域
- 函数级配置 `memory` 与 `maxDuration`

### 禁止做

- ❌ 全局 `Cache-Control: no-cache`（性能损失）
- ❌ 函数 `maxDuration` 设置过高导致成本失控

## 多账号与 Git 集成

### 必须做

- 多 Vercel 账号场景使用 GitHub Actions + Vercel CLI 部署（绕过 Git 集成）
- `vercel link` 用 `--token` 参数认证，避免浏览器 OAuth 干扰
- GitHub Secrets 管理 `VERCEL_TOKEN` / `VERCEL_ORG_ID` / `VERCEL_PROJECT_ID`
- GitHub Actions deploy 前 `rm -rf .git` 绕过 commit author email 校验
- GitHub PAT 至少包含 `repo` + `workflow`（Classic）或 Actions/Contents/Secrets 读写（Fine-grained）

### 禁止做

- ❌ 同一 GitHub 账号关联多个 Vercel 账号（Vercel 硬限制，会互相覆盖）
- ❌ 在 workflow 中硬编码 Vercel token
- ❌ 不断开 Vercel Git 集成就同时跑 GitHub Actions 部署（webhook 冲突）
- ❌ 期望 `git config user.email` 能改变已有 commit 的 author（只影响新 commit）

## 相关 Skills

- `vercel-deployment` — 完整代码示例与工作流
- `nextjs-app-router` — Next.js App Router
- `fullstack-auth` — 认证与授权

## 相关 Commands

- `/vercel-deploy` — Vercel 部署
- `/nextjs-review` — Next.js 审查
