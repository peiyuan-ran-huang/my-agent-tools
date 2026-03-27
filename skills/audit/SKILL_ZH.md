---
name: audit-zh
description: Use when the user explicitly invokes ---audit for a high-stakes paper, codebase, plan, data analysis, or mixed multi-component target where missed issues would be costly, and a Chinese-language entry reference is needed.
---

<!-- Keep this file semantically aligned with SKILL.md for the entry protocol only. Detailed canonical support files remain English unless explicitly localized. -->

# AUDIT

## 触发条件

仅在用户以任意大小写形式显式输入 `---audit` 时激活。

以下情况不激活：
- `检查`
- `审查`
- `审计`
- `复核`
- `audit this`
- 任何未使用显式触发词的自然语言表述

## 适用场景

适用于遗漏问题代价很高的高风险产出物，例如：
- 即将提交的论文或正式报告
- 生产环境或安全相关代码
- 由多个高风险组件组成的混合目标
- 重大方案或决策文档
- 重要数据分析

如果用户不确定是否需要深度审计，通常应先考虑较轻量的预扫，例如 `---qc`。

## 不适用场景

以下情况不使用：
- 用户没有显式触发 `---audit`
- 快速轻量检查已足够
- 任务目标是修改或修复对象，而不是审计对象

## 核心架构

本 skill 使用并行 subagent 架构。

- 每个 big round 由独立 subagent 执行。
- big round 的独立性主要由物理隔离保证，而不是靠自然语言提醒。
- 主 agent 负责规划、派发、合并与降级处理。
- 无论编排者使用什么模型，subagent 都必须显式使用 `model: "opus"`。

## 参数解析

读取 `---audit` 之后的参数。

- 首先按引号感知方式捕获参数。任何被成对引号包住的子串，在进一步解释前都算一个原始参数。
- 当存在带引号参数、或路径解析有歧义时，必须把 `---audit` 后面的原始参数串通过 stdin 或单个字符串参数喂给 `python scripts/parse-audit-args.py`，并把它输出的 JSON 结果当作后续启发式之前的 canonical parse。
- 第一个 token 可能表示审计对象、对象类型或文件路径。
- 如果第一个 token 同时匹配类型关键字和现有文件路径，文件路径优先。
- 支持的类型关键字包括：
  - `paper` / `论文`
  - `code` / `代码`
  - `plan` / `方案`
  - `data` / `数据`
  - `mixed` / `混合`
- 如果没有提供参数，识别当前对话中最近的 substantive deliverable。
- 如果第一个 token 是类型标识，后续非 `--` 参数都视为文件路径。
- 带空格的加引号 target 路径必须保留为单个路径参数，不得在目标识别阶段被拆成多个 token。
- 如果类型关键字后面跟着带引号的路径，只能去掉最外层引号并校验完整路径字符串；不得把 `C:/Users/jdoe/OneDrive` 之类的内部片段当成独立 target 去探测。
- 示例：`---audit paper "C:/Users/jdoe/OneDrive - Example Org/Desktop/paper_target.md"` 表示 `paper` 是类型，而完整引号内容才是唯一的 target 路径。
- 引号内部的完整原始子串才是 authoritative target path；在校验时不得把它重写成一个更短、但恰好存在的前缀目录。
- 只要 target 或 output 路径带引号且含空格，就要在真正校验前先显式输出一行 parse preflight，例如：`Parsed Args: type=paper | target=C:/.../paper_target.md | out=C:/.../paper_report.md`。
- 如果这行 parse preflight 没能保留完整的引号 target 子串，就必须停止并重新解析，而不是继续诊断路径片段。
- `--focus [theme]` 每次添加一个重点主题，可重复使用。
- 如果 `--focus` 导致超过模式上限，优先保留用户指定的 focus rounds，再裁减低优先级的自动主题；如果仅 focus 本身就超过上限，按用户指定顺序保留最早的若干主题，并提示其余主题被丢弃。
- `--out [path]` 设置报告路径。若省略，则使用默认相对报告路径；若路径已存在，则自动追加 `_2`、`_3` 等后缀。
- `--lang [zh/en]` 强制指定报告语言；否则按审计对象语言自动匹配。
- `--lite` 会缩减轮次上限，但不得跳过关键验证：
  - 关键验证包括论文引用真实性核查、代码安全漏洞查询、数值一致性验证
  - 非关键的辅助性检查可在 lite 模式下跳过
- 如果目标内容尚未进入上下文，必须先读取后再执行审计。
- 如果无法识别审计对象，停止并提示用户明确指定。

## 工作流骨架

### 阶段 0

- 加载 `references/phase-0-planning.md`
- 在 `jq` 可用、且 `$HOME/.claude/settings.json` 能解析到当前活动 Claude 配置的 bash 环境里运行 `scripts/config-check.sh`
- 在 Windows 上优先使用 Git Bash；若 `bash` 实际解析到 `C:/Windows/system32/bash.exe`，或解析到看不到当前活动 `~/.claude` 配置的 WSL bash，应视为不兼容并进入文档规定的 script-error fallback
- 仅做 detect-and-guide，不在 session 中途修改配置
- 分析对象、选择主题、分配批次、验证 MCP 可用性、宣告计划
- 规划宣告后不等待用户确认，直接进入阶段 1

### 阶段 1

- 加载 `references/phase-1-dispatch.md`
- 加载 `templates/subagent-template.md`
- 填充模板并并行派发 subagents

### 阶段 2

- 加载 `references/phase-2-merge.md`
- 加载 `templates/report-template.md`
- 收集结果、去重、重编号、写出最终报告、清理临时文件并输出总结

### 降级路径

- 任何失败路径、降级路径或平台限制分支，都加载 `references/degradation-and-limitations.md`

## 硬性不变项

- 只审不改：不修改审计对象，只产出审计输出。
- 穷尽优先于速度：宁可多跑几轮，也不能漏掉实质问题。
- 工具验证优先：能用工具验证时，不依赖记忆或猜测。
- 严格标准：宁可多报可疑问题，也不能漏掉真实风险。
- 精确定位：问题定位必须能落到章节、段落、行号或变量名。
- 建议可执行：初步建议必须具体到用户可直接行动。
- big round 的物理隔离是主要独立性保证；顺序降级时独立性降为协议级。
- 如上下文中存在 `~/.claude/rules/academic-workflow.md` 或等效的项目级学术规则文件，执行审计时需参考，尤其是引用核查与数值报告规范。
- 严重程度分类：
  - Critical = 事实错误、安全漏洞、数据丢失风险或根本性缺陷
  - Major = 影响结论或功能的实质问题
  - Minor = 风格、格式、文档精确度或防御性改进
- Canonical runtime limits：
  - 标准模式 = `3-8` 个 big rounds，每批最多 `5` 个 subagents，最多 `2` 个批次
  - Lite 模式 = `2-4` 个 big rounds，最多 `4` 个 subagents，最多 `1` 个批次
  - Discovery-round 上限 = `7 / 3`；总 sub-round 上限 = `14 / 6`
  - Subagent 重试上限 = `1`
- 配置检测只做 detect-and-guide。由于 `model`、`effortLevel`、`fastMode`、`alwaysThinkingEnabled` 会在 session 启动时缓存，不得在 session 中途自动修改配置。
- 每次 Agent 调用都要显式指定 subagent 使用 `model: "opus"`。

## 支持文件加载顺序

### 正常执行

- 阶段 0：`references/phase-0-planning.md`
- 阶段 1：先读 `references/phase-1-dispatch.md`，再读 `templates/subagent-template.md`
- 阶段 2：先读 `references/phase-2-merge.md`，再读 `templates/report-template.md`

### 异常执行

- 任何失败、降级或平台限制分支：`references/degradation-and-limitations.md`

### 输出校准

- 需要输出示例时，查阅 `examples.md`
- 需要避免常见执行错误时，查阅 `pitfalls.md`

## 输出契约

最终报告必须遵循 `templates/report-template.md`。

- `templates/report-template.md` 是最终报告结构的 canonical source。
- 报告语言的应用属于运行时决策，由参数解析与阶段 2 共同处理，而不是由模板定义。
- 全零问题的简化输出属于阶段 2 明确处理的例外路径。

## 降级策略

当正常路径的任一前提失效时，遵循 `references/degradation-and-limitations.md`。

如果 big rounds `>=6` 或审计对象很大，merge 阶段更容易出现 context pressure；若可用，优先启用 Context Mode MCP。

任何降级路径都必须显式声明，不得伪装成与正常并行隔离执行等价。

顺序 fallback 会降低独立性保证，必须明确告知这一点。

这包括：
- subagent 失败
- temp file 失败
- sequential fallback
- merge 中断
- MCP 不可用
- configuration-check script 失败
- context pressure
- platform limitations
