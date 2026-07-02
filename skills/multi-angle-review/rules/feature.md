# 功能迭代审查规则

## 审查流程

1. 主 Agent 已完成通用审查（universal_criteria.csv 抽样 3 条）
2. 本阶段启动 3 个子 Agent 并行审查
3. 每个子 Agent 独立抽样对应 CSV 中的审核标准

## 子 Agent 配置

### Agent 1: 需求覆盖审查

- **角色**: 产品审查专家，关注功能完整性和用户故事覆盖
- **CSV**: `references/feature_criteria.csv`
- **抽样数**: 4 条（从 category='需求覆盖' 或 category='功能完整性' 的行中抽取）
- **Goal**: 审查功能是否覆盖所有需求、异常路径、边界场景
- **Context 需包含**: 功能描述 + 需求文档（如有）+ 代码实现 + 抽样标准条目(JSON)

### Agent 2: 竞品对标与 A/B 实验审查

- **角色**: 数据分析师 + 竞品分析专家
- **CSV**: `references/feature_criteria.csv`
- **抽样数**: 3 条（从 category='竞品对标' 或 category='A/B实验' 的行中抽取）
- **Goal**: 审查功能完成度、竞品对标、实验设计科学性
- **Context 需包含**: 功能描述 + 竞品信息（如有）+ 实验配置（如有）+ 抽样标准条目(JSON)

### Agent 3: 功能完整性深度审查

- **角色**: 全栈功能审查专家，关注 Server Action 错误分支、乐观更新回滚
- **CSV**: `references/feature_criteria.csv`
- **抽样数**: 5 条（从所有行中随机抽取）
- **Goal**: 审查 Server Action 错误处理、乐观更新回滚、操作反馈、灰度回滚
- **Context 需包含**: 功能描述 + 代码实现 + 抽样标准条目(JSON)

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

- 抽样前运行 `python scripts/sample_criteria.py references/feature_criteria.csv <count> --filter category=<value>`
- 子 Agent 必须是 leaf 角色
- 上下文语言使用中文
