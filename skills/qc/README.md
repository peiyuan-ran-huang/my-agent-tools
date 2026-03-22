# QC: Five-Dimensional Deep Review / 五维深度审查

**Version**: v0.8.0
**Last Updated**: 2026-03-22
**Author**: Peiyuan (Ran) Huang, with (*significant*) assistance from Claude Code

---

## What is this? / 这是什么？

A stupidly simple prompt template (despite its name "Deep Review") that runs a structured five-dimensional review (Correctness, Completeness, Optimality, Consistency, Standards) on whatever you just produced. No code, no dependencies, no magic — built for Claude Code (uses Read, Grep, and session-aware context detection). Other AI agents that read markdown instructions can use the core review framework, but blast radius scanning and auto-detection require Claude Code-compatible tool access.

一个极其轻量的 prompt 模板（尽管它名叫"深度审查"），对你刚产出的东西做五维结构化审查（正确性、完整性、最优性、一致性、规范性）。没有代码，没有依赖，没有黑魔法——为 Claude Code 设计（使用 Read、Grep 和会话感知的上下文检测）。其他能读取 markdown 指令的 AI agent 可使用核心审查框架，但影响范围扫描和自动检测需要 Claude Code 兼容的工具访问。

### Changelog / 版本历史

- **v0.3**: **Blast Radius Scan** — automatically checks cross-file dependencies when reviewing file modifications. / **影响范围扫描**——审查文件修改时自动检查跨文件依赖。
- **v0.4**: **Pitfalls** mechanism ("错题本") — user-supplied domain-specific mistake log, checked automatically. Inline severity definitions (Critical / Major / Minor). / **错题本**机制 + 内联严重性定义。
- **v0.5**: **Skill/Prompt** target overlay, **Open Questions** section for ambiguous findings, explicit **Coverage** + **Target Type** + **Blast Radius scope** declarations, formalized pitfalls tag semantics, omission-based evidence support, evidence-led principle. / **技能/提示词**对象叠加、**开放问题**部分、显式**覆盖范围** + **对象类型** + **影响范围边界声明**、形式化标签语义、缺失型证据支持、循证原则。
- **v0.6**: **Evolution Protocol** — post-review self-reflection that proposes new pitfalls/examples when QC encounters uncovered scenarios. Propose-and-confirm: skill suggests, user approves. / **进化协议**——审查后自我反思，遇到未覆盖场景时提议新的错题本/样例条目。提议确认制：skill 提议，用户批准。
- **v0.7**: **Calibration refinements** — meta-calibration principle (check severity bias before finalizing), expanded Skill/Prompt overlay (8 items: +degradation path, self-review bias, runtime/dev boundary), tighter auto-detect step 2 filtering. / **校准细化**——元校准原则（定稿前检查严重性偏差）、Skill/Prompt 叠加检查扩展至 8 项（+降级路径、自审偏差、运行时/开发边界）、自动检测步骤 2 过滤收紧。
- **v0.8**: **Loop Mode** (`--loop [N]` / `--循环 [N]`) — automated review-fix-review cycle until N consecutive passes (default 3) or 10 total rounds. / **循环模式**——自动化审查-修复-再审查循环，直到连续 N 轮 Pass（默认 3）或总计 10 轮。

For full version history, see `CHANGELOG.md`. / 完整版本历史见 `CHANGELOG.md`。

## Why? / 为什么做这个？

Honestly? I was too lazy to manually double-check my own work every time. So I automated my laziness into a structured framework. Self-entertainment at its finest.

说实话？每次自己核查产出物太累了，于是把"懒"系统化成了一个审查框架。纯属自娱自乐。

## Disclaimers / 免责声明

I'm a biomedical researcher, not a programmer. This isn't even vibe coding — there's literally no code here, haha. It's just prompt engineering with extra steps.

我是个生物医学研究者，编程小白一枚。这甚至算不上 vibe coding——因为根本没有 code，哈哈。充其量是 prompt engineering with extra steps。

This project does **not** represent the views of my employer or affiliated institutions. Please do **not** use this to cheat on assignments, fabricate data, or engage in any form of academic misconduct. QC is meant to *catch* problems, not *create* them.

本项目**不**代表本人所属机构的立场或观点。请**不要**用它来作弊、捏造数据或进行任何形式的学术不端行为。QC 的初衷是*发现*问题，不是*制造*问题。

**Important**: AI only provides suggestions. The final call is always yours, and so is the responsibility. Use your own judgement — this tool is an assistant, not a substitute for critical thinking.

**重要提示**：AI 只是提供建议。最终决策权始终在你手里，最终责任也是。请运用自己的判断力——这个工具是助手，不是替代你独立思考的借口。

## Files / 文件说明

| File | Language | Role |
|------|----------|------|
| `SKILL.md` | English | Primary (loaded by Claude Code; core framework adaptable to other agents) |
| `SKILL_ZH.md` | 中文 | Translation reference (not auto-loaded) |
| `examples.md` | EN/ZH | Output calibration: good example + anti-patterns |
| `pitfalls.md` | Any | User pitfalls ("错题本"); ships with starter entries (active during reviews) |
| `CHANGELOG.md` | EN/ZH | Version history (0.1+ increments only) |
| `README.md` | EN/ZH | This file; project overview and usage guide |

Changes to `SKILL.md` and `SKILL_ZH.md` **must** be mirrored in each other.

`SKILL.md` 和 `SKILL_ZH.md` 的改动**必须**互相同步。

## Prerequisites / 前置条件

**Required for full functionality / 完整功能必需**: [Claude Code](https://claude.ai/claude-code) (or other similar AI agents with file-reading and text-searching capabilities) — provides the Read and Grep tools used for file loading, blast radius scanning, and session-aware auto-detection. The core five-dimensional review framework can also be used by any AI agent that reads markdown instructions, with reduced automation. No additional software, packages, or API keys needed — zero external dependencies beyond the runtime itself.

**完整功能必需**：[Claude Code](https://claude.ai/claude-code)（或其他类似的具备文件读取和文本搜索能力的 AI agents）——提供 Read 和 Grep 工具，用于文件加载、影响范围扫描和会话感知的自动检测。核心五维审查框架也可被任何能读取 markdown 指令的 AI agent 使用，但自动化程度会降低。无需额外安装软件、包或 API 密钥——除运行时本身外零外部依赖。

**Included & customisable / 随附且可自定义**:

- `examples.md` — output format and severity calibration; edit to adjust how strict or lenient reviews are
- `pitfalls.md` — user pitfall log ("错题本"); ships with starter entries that are actively checked during reviews, but its real value comes from adding your own domain-specific entries over time

- `examples.md`——输出格式与严重性校准；可编辑以调整审查的严格/宽松程度
- `pitfalls.md`——用户错题本；附带初始条目（审查时会被实际检查），但其真正价值在于随时间积累你自己的领域特定条目

**Optional enhancement / 可选增强**: If project-level rule files (e.g., `rules/academic-workflow.md`) are already loaded in the current context, qc will prioritise them in relevant dimensions — no extra configuration needed, but qc does not search for or load these files on its own.

**可选增强**：如果项目级规则文件（如 `rules/academic-workflow.md`）已加载到当前上下文中，qc 会在相关维度优先应用它们——无需额外配置，但 qc 不会主动搜索或加载这些文件。

## Trigger / 触发方式

```
---qc [target] [extra criteria]
```

**Rules / 规则**:
- `---qc` must be the **first token** of your message / `---qc` 必须是消息的**首个 token**
- File paths with spaces must be **double-quoted** / 含空格的文件路径必须用**双引号**包裹: `---qc "OneDrive - University of Bristol/file.R"`
- Natural language (review / check / 审查 / 检查) does **not** trigger / 自然语言不会触发
- Target can be a word, quoted phrase, or file path / 目标可以是一个词、引号短语或文件路径

## Example Output / 输出示例

```text
## QC Review Report
**Review Target**: analysis.R
**Target Type**: Code
**Coverage**: Full — all 95 lines reviewed
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 2 matched context; 0 triggered findings

### Findings
#### Consistency — Minor
- **Evidence**: Line 12 uses `read.csv()` but line 45 uses `read_csv()` (mixed base R and tidyverse)
- **Issue**: Inconsistent data import functions within the same script
- **Suggested fix**: Standardise to `read_csv()` throughout for tidyverse consistency

✓ Correctness / Completeness / Optimality / Standards: No issues

### Summary
- **Overall Rating**: Minor
- One style inconsistency found; analysis logic is sound.
```

## Pitfalls / 错题本

`pitfalls.md` is your personal pitfall log. Record mistakes and easily-overlooked issues you encounter in daily work — each entry becomes an additional check item during QC reviews. The file ships with starter entries drawn from the author's workflow that are actively used during reviews; add, modify, or remove entries in any language to match your own.

`pitfalls.md` 是你的个人错题本。把日常工作中遇到的易错点、容易遗漏的问题记录在里面，QC 审查时会自动将每条作为额外检查项。文件附带作者工作流中的初始条目（审查时会被实际检查）；可按需增删改，用任意语言编写。

*Note: `sync.sh` will never overwrite your local `pitfalls.md` once it exists — your entries are safe across syncs.*

*注意：一旦本地存在 `pitfalls.md`，`sync.sh` 不会覆盖它——你的条目在同步时不会丢失。*

## See Also / 相关

*For heavier-duty multi-round audits, see the `audit` skill (`---audit`) (local only; not yet published to this repo). qc is the quick scan; audit is the deep dive.*

*如需更重量级的多轮深度审计，请看 `audit` skill（`---audit`）（仅本地可用，尚未发布至本仓库）。qc 是快速扫描，audit 是深度审计。*

## Acknowledgements / 致谢

Special thanks to [Codex](https://chatgpt.com/codex) for reviewing this skill and pointing out that a QC skill without evidence requirements is like a research paper without citations😂. v0.2 is significantly better thanks to its feedback.

v0.5 is based on a comprehensive second review by Codex (2026-03-16) — 4 parallel subagents + single-agent deep pass — which identified 17 issues across all skill files and sharpened the product boundary, evidence model, and portability claims.

特别感谢 [Codex](https://chatgpt.com/codex) 对本 skill 的审查和改进建议。Codex 指出，一个不要求附带证据的 QC skill，就像一篇不引用文献的科研论文😂。v0.2 的质量提升很大程度上归功于它的反馈。

v0.5 基于 Codex 的第二次全面审查（2026-03-16）——4 个并行 subagent + 单 agent 深度二审——共发现 17 个问题，涉及所有 skill 文件，强化了产品边界定义、证据模型和可移植性声明。

---

*Built with ☕, 🧠 (but without 🖐️), and Claude Code. Peer review, but make it instant and free.*

*用 ☕、🧠（但没用🖐️）和 Claude Code 打造。同行评审，但秒出结果且免费。*
