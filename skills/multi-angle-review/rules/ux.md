# 体验迭代审查规则

## 审查流程

1. 主 Agent 已完成通用审查（universal_criteria.csv 抽样 3 条）
2. 本阶段启动 3 个子 Agent 并行审查
3. 每个子 Agent 独立抽样对应 CSV 中的审核标准

## 子 Agent 配置

### Agent 1: 交互完整性审查

- **角色**: UX 审查专家，关注加载态/空态/错误态、操作步数、反馈机制
- **CSV**: `references/ux_criteria.csv`
- **抽样数**: 5 条（从 category='交互完整性' 的行中抽取）
- **Goal**: 审查三态完整性（加载/空/错误）、关键路径步数、表单校验反馈、操作 loading
- **Context 需包含**: 页面/组件代码 + 用户流程描述 + 抽样标准条目(JSON)

### Agent 2: 视觉一致性与设计系统审查

- **角色**: 设计系统审查专家，关注组件统一性、设计 Token、暗色模式
- **CSV**: `references/ux_criteria.csv`
- **抽样数**: 5 条（从 category='视觉一致性' 的行中抽取）
- **Goal**: 审查组件复用、间距/色彩/字体一致性、圆角/阴影统一、暗色模式
- **Context 需包含**: 组件代码 + tailwind.config + 抽样标准条目(JSON)

### Agent 3: 微交互与信息架构审查

- **角色**: 交互设计专家 + 信息架构专家
- **CSV**: `references/ux_criteria.csv`
- **抽样数**: 5 条（从 category='微交互' 或 category='信息架构' 的行中抽取，微交互类至少 2 条）
- **Goal**: 审查 hover/active/focus 反馈、过渡动画、Toast、骨架屏、导航层级、面包屑
- **Context 需包含**: 页面/组件代码 + 路由结构 + 抽样标准条目(JSON)

## 子 Agent 输出格式

```
## [视角名]
> 审查身份：[角色]
| 严重度 | 问题 | 位置 | 抽样标准 | 修复建议 |
|--------|------|------|----------|----------|
| 🔴严重 | ...  | 文件:行N | 标准原文 | ...      |
| 🟡建议 | ...  | 文件:行N | 标准原文 | ...      |
```

无问题则输出：「✅ 未发现相关问题。」

## 注意事项

- 抽样前运行 `python scripts/sample_criteria.py references/ux_criteria.csv <count> --filter category=<value>`
- 若有 Figma 设计稿或截图应一并传入
- 子 Agent 必须是 leaf 角色
- 上下文语言使用中文
