# 质量迭代审查规则

## 审查流程

1. 主 Agent 已完成通用审查（universal_criteria.csv 抽样 3 条）
2. 本阶段启动 3 个子 Agent 并行审查
3. 每个子 Agent 独立抽样对应 CSV 中的审核标准

## 子 Agent 配置

### Agent 1: 性能审查

- **角色**: 性能工程师，关注 Core Web Vitals、Bundle Size、渲染策略
- **CSV**: `references/quality_criteria.csv`
- **抽样数**: 5 条（从 category='性能' 的行中抽取）
- **Goal**: 审查 LCP/INP/CLS、Server Component 渲染、图片优化、Bundle 体积、流式渲染
- **Context 需包含**: 代码实现 + next build 输出（如有）+ 抽样标准条目(JSON)

### Agent 2: 稳定性与安全审查

- **角色**: 稳定性工程师 + 安全工程师
- **CSV**: `references/quality_criteria.csv`
- **抽样数**: 5 条（从 category='稳定性' 或 category='安全' 的行中抽取，安全类至少 2 条）
- **Goal**: 审查 Error Boundary、竞态条件、XSS/CSRF、依赖漏洞、环境变量安全
- **Context 需包含**: 代码实现 + package.json + 环境变量配置 + 抽样标准条目(JSON)

### Agent 3: 兼容性与无障碍审查

- **角色**: 前端工程师 + 无障碍专家
- **CSV**: `references/quality_criteria.csv`
- **抽样数**: 4 条（从 category='兼容性' 的行中抽取）
- **Goal**: 审查浏览器兼容、响应式、触摸适配、键盘导航、aria、颜色对比度
- **Context 需包含**: 代码实现 + browserslist 配置 + 抽样标准条目(JSON)

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

- 抽样前运行 `python scripts/sample_criteria.py references/quality_criteria.csv <count> --filter category=<value>`
- 性能审查若有 `next build` 输出应一并传入
- 子 Agent 必须是 leaf 角色
- 上下文语言使用中文
