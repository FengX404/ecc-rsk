---
description: 多角度审查（四维迭代：功能/质量/体验/工程）。调用 multi-angle-review skill 进行意图路由 → 加载规则 → 抽样标准 → 子 Agent 并行审查 → 汇总报告。
---

# Multi-Angle Review

对代码、架构、API、文档等任意技术产出物，从功能/质量/体验/工程四个迭代维度进行多角色并行审查。

## 适用场景

- PR 审查（从单一代码审查扩展到四维审查）
- 功能上线前验收
- 迭代回顾时的质量评估
- 架构决策审查
- 任何需要多视角审查的技术产出物

## 工作流

### 1. 意图路由

按以下优先级匹配审查维度，**命中即停止**：

| 优先级 | 特征判断 | 审查维度 | 规则文件 |
|--------|----------|----------|----------|
| 1 | 含需求/功能描述/验收标准/用户故事 | 功能迭代 | rules/feature.md |
| 2 | 含代码块/性能/安全/Bug/兼容性 | 质量迭代 | rules/quality.md |
| 3 | 含交互/UX/UI/设计/体验/空态/加载态 | 体验迭代 | rules/ux.md |
| 4 | 含重构/CI/CD/技术债/监控/日志 | 工程迭代 | rules/engineering.md |
| 5 | 以上都不匹配 | 通用内容 | rules/general.md |

> 用户也可直接指定维度：`/multi-review --feature`、`/multi-review --ux` 等

### 2. 通用审查（Layer 0）

```bash
python skills/multi-angle-review/scripts/sample_criteria.py skills/multi-angle-review/references/universal_criteria.csv 3
```

主 Agent 按抽样的 3 条通用标准审查原始内容。

### 3. 加载规则 + 抽样标准

读取 `skills/multi-angle-review/rules/<dimension>.md`，按规则启动子 Agent。

### 4. 子 Agent 并行审查

使用 `Task` 工具并行启动子 Agent，每个注入角色 + 抽样标准 + 原始内容。

### 5. 运行验证

检测并运行项目的 test / lint / typecheck 命令。

### 6. 汇总报告

```
## 审查报告
- 审查维度：[维度]
- 审查视角：[N + 1] 个（含通用审查）

### 通用审查
...

### 视角 1：[名称]
...

### 运行验证
...

## 问题汇总
| 严重度 | 问题 | 视角 | 修复建议 |
|--------|------|------|----------|
| 🔴严重 | ...  | ...  | ...      |

## 待用户决策
1. [修复项 1] — 是否执行？
2. [修复项 2] — 是否执行？
```

## 维度选项

| 选项 | 维度 | 覆盖范围 |
|------|------|----------|
| `--feature` | 功能迭代 | 需求覆盖、竞品对标、A/B 实验、功能完整性 |
| `--quality` | 质量迭代 | 性能、稳定性、安全、兼容性、a11y |
| `--ux` | 体验迭代 | 交互完整性、视觉一致性、微交互、信息架构 |
| `--engineering` | 工程迭代 | 技术债、工具链、自动化、可观测性 |
| `--all` | 全维度 | 依次执行四个维度（耗时较长） |

## 与专项审查的关系

- `/code-review` — 单一代码质量审查（`code-reviewer` agent）
- `/supabase-review` — Supabase 专项审查（`supabase-reviewer` agent）
- `/nextjs-review` — Next.js 专项审查（`nextjs-reviewer` agent）
- `/multi-review` — **多维度综合审查**（本命令，编排多个视角）

专项审查是"深度"，多角度审查是"广度"。PR 审查推荐：先专项审查（深度），再多角度审查（广度查盲区）。
