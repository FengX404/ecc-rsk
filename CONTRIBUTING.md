# Contributing to ECC-RSK

感谢你对 ECC-RSK 的贡献兴趣！

---

## 贡献类型

### 新增内容

ECC-RSK 接受以下类型的贡献：

- **新 Agents** — Supabase/Next.js/Vercel 专项审查或执行 agents
- **新 Skills** — 全栈开发工作流或领域知识
- **新 Commands** — 全栈开发相关命令
- **新 Rules** — Next.js/Supabase/Vercel 规则
- **文档改进** — 技术栈详解、迁移指南、使用示例

### ECC 上游贡献

如贡献适用于 ECC 上游（非 ECC-RSK 特有），请直接向 ECC 提交 PR：

- ECC 仓库：https://github.com/affaan-m/ECC

---

## 贡献流程

### 1. Fork 并克隆

```bash
gh repo fork <your-org>/ecc-rsk --clone
cd ecc-rsk
```

### 2. 创建分支

```bash
git checkout -b feat/my-contribution
```

### 3. 编写贡献

- 新增 agents/skills/commands/rules 放在对应目录（本地文件，非 symlink）
- 文档放在 `docs/`
- 测试放在 `tests/`（如有）

### 4. 测试

- 运行相关命令测试功能
- 检查文档格式

### 5. 提交 PR

```bash
git add .
git commit -m "feat: add <description>"
git push -u origin feat/my-contribution
```

创建 PR，描述贡献内容、测试结果。

---

## 文件格式

### Agents

Markdown 文件，YAML frontmatter：

```markdown
---
name: agent-name
description: 简短描述
tools: ["Read", "Grep", "Glob", "Bash"]
model: sonnet
---

## 职责

...

## 审查优先级

...
```

### Skills

`skills/<skill-name>/SKILL.md`：

```markdown
---
name: skill-name
description: 简短描述
metadata:
  origin: ECC-RSK
---

# Skill Title

## When to Activate

...

## How It Works

...
```

### Commands

Markdown 文件，YAML frontmatter：

```markdown
---
description: 简短描述
---

# Command Title

## What This Command Does

...
```

### Rules

Markdown 文件，放在对应目录：

- `rules/nextjs/*.md`
- `rules/supabase/*.md`
- `rules/vercel/*.md`

---

## 代码风格

- 文件命名：小写 + 连字符（如 `supabase-reviewer.md`）
- Markdown 格式：遵循 CommonMark
- 中文文档：使用简体中文

---

## License

MIT — 与 ECC 上游保持一致。