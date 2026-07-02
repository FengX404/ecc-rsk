---
name: multi-angle-review
description: "对代码、架构、API、文档、UX、工程实践等任意技术产出物，按四维迭代框架（功能/质量/体验/工程）进行多角色并行审查，输出结构化审查报告。"
metadata:
  origin: ECC-RSK
---

# 多角度审查系统

## 概述

薄路由架构。SKILL.md 只负责**意图识别**和**流程编排**。审查逻辑按三层分布：

| 层 | 位置 | 内容 | 职责 |
|---|------|------|------|
| 方法论文档 | `rules/<type>.md` | 审查方法论 | 定义该场景的审查流程、子 Agent 角色分配、输出要求 |
| 审核标准库 | `references/<type>_criteria.csv` | CSV 标准条目 | 维护可量化、可抽样的审查标准 |
| 抽样脚本 | `scripts/sample_criteria.py` | Python 脚本 | 从 CSV 中随机抽取 N 条标准，输出 JSON |

审查覆盖**软件产品迭代的四个维度**：

| 维度 | 回答的问题 | Rules |
|------|-----------|-------|
| 功能迭代 | 做的事对不对？全不全？ | `rules/feature.md` |
| 质量迭代 | 做的事稳不稳？快不快？ | `rules/quality.md` |
| 体验迭代 | 用户用着爽不爽？ | `rules/ux.md` |
| 工程迭代 | 团队跑得快不快？ | `rules/engineering.md` |

---

## Phase 1: 意图路由

拿到被审查内容后，按以下优先级顺序匹配审查维度，**命中即停止**。**只判定类型，不执行审查。**

| 优先级 | 特征判断 | 审查维度 | 规则文件 |
|--------|----------|----------|----------|
| 1 | 含 UI 组件 / 页面 / 交互流程 / 设计系统内容 | 体验迭代 | rules/ux.md |
| 2 | 含性能指标 / 错误处理 / 安全漏洞 / 兼容性描述 | 质量迭代 | rules/quality.md |
| 3 | 含 CI/CD / 监控 / 日志 / 重构 / 技术债描述 | 工程迭代 | rules/engineering.md |
| 4 | 含功能需求 / 用户故事 / 竞品对比 / A/B 实验 | 功能迭代 | rules/feature.md |
| 5 | 以上都不匹配 | 通用内容 | rules/general.md |

**用户也可显式指定维度**：

```
从体验角度审查这个登录页
从质量角度审查这个 API
从工程角度审查这个 CI 配置
从功能角度审查这个需求文档
四维全审  ← 同时激活全部四个维度
```

**路由完成后输出：**

> 「识别为 [审查维度]。加载审查方法 `rules/<type>.md`」

---

## Phase 2: 加载审查方法论文档

使用 `Read` 工具加载 `rules/<type>.md`。

该文档定义：
- 该维度的审查流程
- 需要启动几个子 Agent、每个负责什么视角
- 每个子 Agent 使用的 CSV 和抽样数量
- 子 Agent 输出格式要求

**必须严格遵守 rules/<type>.md 中的指令。不可自行决定子 Agent 数量和角色。**

---

## Phase 3: 通用审查（Layer 0）

在启动子 Agent 前，主 Agent 必须先用 `universal_criteria.csv` 做一轮通用审查。

**执行步骤：**

1. 运行抽样脚本：
   ```
   python scripts/sample_criteria.py references/universal_criteria.csv 3
   ```
2. 获取 3 条随机标准（JSON 输出），主 Agent 自行按标准审查原始内容
3. 审查维度：幻觉审核、一致性、完整性、简洁性
4. 输出格式：与子 Agent 格式一致（见 Phase 5），作为报告第一节

通用审查由主 Agent 直接执行，不启动子 Agent。

---

## Phase 4: 抽取审核标准 + 启动子 Agent

按 `rules/<type>.md` 的指令执行：

### 4.1 运行抽样脚本

对 `rules/<type>.md` 中每个 Agent 配置，运行抽样脚本获取审核标准：

```
python scripts/sample_criteria.py references/<type>_criteria.csv <count> [--filter category=<值>] [--seed <n>]
```

输出为 JSON，包含随机抽取的审核标准条目。

### 4.2 为每个审查视角启动子 Agent

使用 `Task` 工具并行启动子 Agent。对每个 Agent 配置，按以下模板构造调用：

- `subagent_type`: `"general_purpose_task"`
- `description`: `"[视角名]审查"`
- `query`: 由以下内容拼接：
  ```
  ## 角色
  [rules 中该 Agent 的角色描述]
  ## 审核标准
  [抽样脚本输出的 JSON]
  ## 被审查内容
  [用户提供的原始内容]
  ## 输出要求
  [rules 中定义的输出格式]
  请严格按上述标准审查，按指定格式输出结果。
  ```

每个子 Agent 的 `query` 中必须注入：
- 该视角的角色设定
- 抽样得到的审核标准（JSON）
- 被审查的原始内容（完整传入，子 Agent 是独立上下文）
- 输出格式要求

所有子 Agent 并行启动，全部完成后进入 Phase 5。

### 4.3 与项目现有 Agent 协同

当审查维度与项目已有专项 Agent 重叠时，`rules/<type>.md` 会指示激活对应 Agent 作为子 Agent 的补充：

| 审查维度 | 可协同的现有 Agent |
|----------|-------------------|
| 质量迭代 | `typescript-reviewer`、`supabase-reviewer`、`nextjs-reviewer`、`react-reviewer` |
| 体验迭代 | `a11y-architect`、`seo-specialist`、`ux-reviewer` |
| 工程迭代 | `refactor-cleaner`、`code-simplifier`、`observability-reviewer` |
| 功能迭代 | `feature-reviewer`、`fullstack-architect` |

协同方式：子 Agent 用 CSV 标准做结构化审查，现有 Agent 做专项深度审查，结果统一汇总。

---

## Phase 4.5: 运行验证（若可执行）

在子 Agent 审查完成后、汇总报告前，主 Agent 必须尝试运行验证。

**执行步骤：**

1. **检测测试命令**：查找项目中的 `package.json` scripts、`pytest` 等测试入口。若存在，运行测试并记录结果。
2. **检测 lint/typecheck**：若项目配置了 lint 或 typecheck 命令，运行并记录结果。
3. **路径解析验证**（针对涉及文件移动/拆分的重构变更）：对每个新增/移动的文件，验证其 `import` 路径在目标运行环境中能正确解析。
4. **输出**：将验证结果列入汇总报告的"运行验证"节。若验证失败，对应问题严重度标记为 🔴。

**若无任何可执行的测试/lint 命令**：跳过本 Phase，在报告中注明"未找到可执行验证命令"。

---

## Phase 5: 汇总报告

收集通用审查结果 + 所有子 Agent 输出，生成汇总报告：

```
## 审查报告

- 审查维度：[功能/质量/体验/工程]
- 审查视角：[N + 1] 个（含通用审查）
- 子 Agent：[N] 个

### 通用审查
[主 Agent 的 Layer 0 输出]

### 视角 1：[名称]
[子 Agent 1 输出]

### 视角 2：[名称]
[子 Agent 2 输出]
...

### 运行验证
[若 Phase 4.5 执行了验证，输出结果；否则注明"未找到可执行验证命令"]

## 问题汇总

| 严重度 | 问题 | 视角 | 修复建议 |
|--------|------|------|----------|
| 🔴严重 | ...  | ...  | ...      |
| 🟡建议 | ...  | ...  | ...      |

## 待用户决策

请确认以下修复方案：
1. [修复项 1] — 是否执行？
2. [修复项 2] — 是否执行？
...
```

**不要替用户决定修复内容。列出所有问题，让用户选择。**

---

## 四维全审模式

当用户请求"四维全审"或"全面审查"时，按以下编排执行：

```
Phase 3: 通用审查（universal_criteria.csv）
    │
    ▼
Phase 4: 四维并行
    ├─ 功能迭代（feature_criteria.csv → 2 子 Agent）
    ├─ 质量迭代（quality_criteria.csv → 3 子 Agent）
    ├─ 体验迭代（ux_criteria.csv → 2 子 Agent）
    └─ 工程迭代（engineering_criteria.csv → 2 子 Agent）
    │
    ▼
Phase 4.5: 运行验证
    │
    ▼
Phase 5: 四维汇总报告
```

四维全审共启动 1（通用）+ 9（子 Agent）= 10 个审查视角。

---

## 常见陷阱

1. **跳过 rules/<type>.md 自行决定子 Agent 数量和角色。** 每个维度的子 Agent 配置在对应 rules 文件中已定义，必须加载并遵循。
2. **不给子 Agent 注入原始内容。** 子 Agent 是独立上下文，必须把被审查内容完整传入 context。
3. **替用户做修复决策。** 汇总报告列出问题和修复建议后，必须等待用户确认。
4. **跳过通用审查。** 无论什么审查维度，Phase 3（Layer 0 通用审查）必须执行。
5. **忘记运行抽样脚本。** 不要从 CSV 文件中直接读取——必须通过 scripts/sample_criteria.py 随机抽取，保证每次审查覆盖不同标准。
6. **跳过重构前置检查。** 当变更涉及文件移动/拆分/重命名时，必须执行 rules 中的重构前置检查。
7. **用测试通过作为唯一验证。** 测试通过不等于运行时正确，必须在 Phase 4.5 中注明此差异。
8. **忽略现有专项 Agent。** 当审查内容涉及 Supabase/Next.js/TypeScript 时，应协同对应专项 Agent 做深度审查，而非仅靠 CSV 标准。
