---
name: ecc-rsk
description: ECC-RSK Skills 薄路由入口 — 索引全部 21 个 skills（14 个复用 ECC + 7 个 ECC-RSK 新增），并指向 SKILL-ROUTES.md 的意图路由规则。
metadata:
  origin: ECC-RSK
  type: router
---

# ECC-RSK Skills 路由入口

本文件是 ECC-RSK 所有 skills 的**薄路由入口**：仅提供索引与路由指向，不重复 skill 正文。
AI 助手在收到用户请求后，应先查阅 [SKILL-ROUTES.md](SKILL-ROUTES.md) 中的路由规则，再激活对应 skill。

---

## 路由机制

```
用户请求
   │
   ▼
SKILL.md（本文件，索引层）
   │
   ▼
SKILL-ROUTES.md（路由规则层）
   │  ├─ 文件类型/路径 → skill
   │  ├─ 用户意图关键词 → skill
   │  └─ 开发阶段 → skill 编排链
   ▼
skills/<name>/SKILL.md（具体 skill 正文）
```

**薄路由原则**：
1. 本文件只做索引，不复制 skill 正文
2. 路由规则集中在 [SKILL-ROUTES.md](SKILL-ROUTES.md)
3. 命中多个 skill 时，按 SKILL-ROUTES.md 的优先级编排
4. 未命中路由规则时，回退到通用 agents（planner / code-reviewer）

---

## Skills 索引

### ECC-RSK 新增（7 个）— 全栈专项

| Skill | 职责 | 路径 |
|---|---|---|
| `supabase-patterns` | RLS 策略、Auth 集成、Realtime 订阅、Storage 上传、Edge Functions、类型生成、迁移工作流 | [skills/supabase-patterns/SKILL.md](skills/supabase-patterns/SKILL.md) |
| `nextjs-app-router` | RSC 边界、Server Actions、Route Handlers、Middleware、缓存策略、Streaming、Metadata | [skills/nextjs-app-router/SKILL.md](skills/nextjs-app-router/SKILL.md) |
| `vercel-deployment` | 部署模式、环境变量管理、运行时选择、渲染模式决策、`vercel.json` 配置、性能监控 | [skills/vercel-deployment/SKILL.md](skills/vercel-deployment/SKILL.md) |
| `fullstack-auth` | PKCE 流程、会话管理、授权架构、OAuth 集成、RBAC、多租户认证、安全加固 | [skills/fullstack-auth/SKILL.md](skills/fullstack-auth/SKILL.md) |
| `realtime-sync` | Realtime 订阅模式、React 集成、乐观更新、冲突解决、性能优化、离线支持 | [skills/realtime-sync/SKILL.md](skills/realtime-sync/SKILL.md) |
| `type-safe-stack` | 端到端类型安全（PostgreSQL → Supabase 类型 → Zod → Server Action → React） | [skills/type-safe-stack/SKILL.md](skills/type-safe-stack/SKILL.md) |
| `form-patterns` | React Hook Form + Zod + Server Actions 表单、多步向导、可访问性、文件上传 | [skills/form-patterns/SKILL.md](skills/form-patterns/SKILL.md) |

### 从 ECC 复用（14 个）— 通用工程能力

| Skill | 职责 | 路径 |
|---|---|---|
| `api-design` | REST API 设计模式（命名、状态码、分页、过滤、错误响应、版本、限流） | [skills/api-design/SKILL.md](skills/api-design/SKILL.md) |
| `blueprint` | 多会话、多 agent 工程项目的分步施工蓝图（含对抗性审查门） | [skills/blueprint/SKILL.md](skills/blueprint/SKILL.md) |
| `browser-qa` | 浏览器自动化视觉测试与 UI 交互验证 | [skills/browser-qa/SKILL.md](skills/browser-qa/SKILL.md) |
| `council` | 四声议会机制，用于模糊决策、权衡、go/no-go 判断 | [skills/council/SKILL.md](skills/council/SKILL.md) |
| `gateguard` | 事实强制门，阻止 Edit/Write/Bash 并要求具体调查后再放行 | [skills/gateguard/SKILL.md](skills/gateguard/SKILL.md) |
| `repo-scan` | 跨栈源码资产审计，分类文件、检测第三方库、四级评估报告 | [skills/repo-scan/SKILL.md](skills/repo-scan/SKILL.md) |
| `seo` | 技术性 SEO、页面优化、结构化数据、Core Web Vitals、内容策略 | [skills/seo/SKILL.md](skills/seo/SKILL.md) |
| `taste` | 音乐视频与短视频的创意方向层（angelcore / cloud-trance / hyperpop） | [skills/taste/SKILL.md](skills/taste/SKILL.md) |
| `ui-demo` | 使用 Playwright 录制精美的 UI 演示视频 | [skills/ui-demo/SKILL.md](skills/ui-demo/SKILL.md) |
| `github-ops` | GitHub 仓库运营（issue 分诊、PR 管理、CI/CD、发布管理、安全监控） | [skills/github-ops/SKILL.md](skills/github-ops/SKILL.md) |
| `benchmark` | 性能基线测量、PR 前后回归检测、技术栈对比 | [skills/benchmark/SKILL.md](skills/benchmark/SKILL.md) |
| `config-gc` | Claude Code 配置垃圾回收（skills、memory、hooks、permissions 清理） | [skills/config-gc/SKILL.md](skills/config-gc/SKILL.md) |
| `agent-sort` | 按项目实际需求将 ECC 内容分类为 DAILY vs LIBRARY 桶 | [skills/agent-sort/SKILL.md](skills/agent-sort/SKILL.md) |
| `code-tour` | 创建 CodeTour `.tour` 文件，带文件行号锚点的分步讲解 | [skills/code-tour/SKILL.md](skills/code-tour/SKILL.md) |

---

## 使用方式

### AI 助手路由流程

1. **接收用户请求** → 读取本文件确认可用 skills
2. **查阅路由规则** → 打开 [SKILL-ROUTES.md](SKILL-ROUTES.md) 匹配意图
3. **激活 skill** → 读取对应 `skills/<name>/SKILL.md` 正文
4. **编排多 skill** → 按 SKILL-ROUTES.md 的"编排链"章节顺序执行

### 人工查阅

- 寻找某个能力 → 直接看上方索引表
- 想知道"什么场景用什么 skill" → 看 [SKILL-ROUTES.md](SKILL-ROUTES.md)
- 想看 skill 具体内容 → 点索引表中的路径链接

---

## 相关文件

- [SKILL-ROUTES.md](SKILL-ROUTES.md) — 路由规则文件（文件类型/意图/阶段 → skill 映射）
- [AGENTS.md](AGENTS.md) — Agent 索引与编排规则
- [CLAUDE.md](CLAUDE.md) — Claude Code 使用指南
- [docs/ECC-RSK-PROPOSAL.md](docs/ECC-RSK-PROPOSAL.md) — 完整组合方案
