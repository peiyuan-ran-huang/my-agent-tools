# QC: Five-Dimensional Deep Review / 五维深度审查

**Version**: v0.3.1
**Last Updated**: 2026-03-16
**Author**: Peiyuan (Ran) Huang, with (*significant*) assistance from Claude Code

---

## What is this? / 这是什么？

A stupidly simple prompt-based skill for Claude Code that runs a structured five-dimensional review (Correctness, Completeness, Optimality, Consistency, Standards) on whatever you just produced. v0.3 adds a **Blast Radius Scan** that automatically checks cross-file dependencies when reviewing file modifications — so stale references in MEMORY.md or changelog never slip through again. No code, no dependencies, no magic — just a well-crafted prompt template.

一个极其轻量的 Claude Code prompt skill，对你刚产出的东西做五维结构化审查（正确性、完整性、最优性、一致性、规范性）。v0.3 新增**影响范围扫描**，在审查文件修改时自动检查跨文件依赖——MEMORY.md 或 changelog 中的过时引用再也不会漏网。没有代码，没有依赖，没有黑魔法——就是一个精心打磨的 prompt 模板。

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
| `SKILL.md` | English | Primary (loaded by Claude Code) |
| `SKILL_ZH.md` | 中文 | Translation reference (not auto-loaded) |
| `examples.md` | EN/ZH | Output calibration: good example + anti-patterns |

Changes to `SKILL.md` and `SKILL_ZH.md` **must** be mirrored in each other.
`SKILL.md` 和 `SKILL_ZH.md` 的改动**必须**互相同步。

## Trigger / 触发方式

```
---qc [target] [extra criteria]
```

Three dashes + two characters (no space). Target can be a word, quoted phrase, or file path.
三个短横线加两个字符（中间不加空格）。目标可以是一个词、引号短语或文件路径。

## Example Output / 输出示例

```text
## QC Review Report
**Review Target**: analysis.R
**Blast Radius**: N/A — standalone content

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

## See Also / 相关

*For heavier-duty multi-round audits, see the `audit` skill (`---audit`) (local only; not yet published to this repo). qc is the quick scan; audit is the deep dive.*
*如需更重量级的多轮深度审计，请看 `audit` skill（`---audit`）（仅本地可用，尚未发布至本仓库）。qc 是快速扫描，audit 是深度审计。*

## Acknowledgements / 致谢

Special thanks to [Codex](https://chatgpt.com/codex) for reviewing this skill and pointing out that a QC skill without evidence requirements is like a research paper without citations😂. v0.2 is significantly better thanks to its feedback.

特别感谢 [Codex](https://chatgpt.com/codex) 对本 skill 的审查和改进建议。Codex 指出，一个不要求附带证据的 QC skill，就像一篇不引用文献的科研论文😂。v0.2 的质量提升很大程度上归功于它的反馈。

---

*Built with ☕, 🧠, and Claude Code. Peer review, but make it instant and free.*
*用 ☕、🧠 和 Claude Code 打造。同行评审，但秒出结果且免费。*
