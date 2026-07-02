# 工程迭代审查规则

## 审查流程

1. 主 Agent 已完成通用审查（universal_criteria.csv 抽样 3 条）
2. 本阶段启动 3 个子 Agent 并行审查
3. 每个子 Agent 独立抽样对应 CSV 中的审核标准

## 子 Agent 配置

### Agent 1: 技术债审查

- **角色**: TypeScript 审查专家 + 代码架构师
- **CSV**: `references/engineering_criteria.csv`
- **抽样数**: 5 条（从 category='技术债' 的行中抽取）
- **Goal**: 审查 any 滥用、ts-ignore、strict mode、循环依赖、大文件、死代码
- **Context 需包含**: 代码实现 + tsconfig.json + 抽样标准条目(JSON)

### Agent 2: 工具链与自动化审查

- **角色**: DevOps 工程师 + CI/CD 工程师
- **CSV**: `references/engineering_criteria.csv`
- **抽样数**: 5 条（从 category='工具链' 或 category='自动化' 的行中抽取）
- **Goal**: 审查依赖版本、CI 门禁、测试覆盖率、自动化部署、commit 规范
- **Context 需包含**: package.json + CI 配置文件 + 抽样标准条目(JSON)

### Agent 3: 可观测性审查

- **角色**: 可观测性工程师，关注日志、监控、告警、trace
- **CSV**: `references/engineering_criteria.csv`
- **抽样数**: 5 条（从 category='可观测性' 的行中抽取）
- **Goal**: 审查错误监控、Server Action 错误上报、性能监控、日志链路、告警机制
- **Context 需包含**: 代码实现 + 监控配置（如有）+ 抽样标准条目(JSON)

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

- 抽样前运行 `python scripts/sample_criteria.py references/engineering_criteria.csv <count> --filter category=<value>`
- 若有 CI 配置文件（.github/workflows/*.yml）应一并传入
- 子 Agent 必须是 leaf 角色
- 上下文语言使用中文
