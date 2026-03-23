<p align="center">
  <img src="sharingan.jpg" alt="Sharingan" width="280" />
  <br>
  <em>”你的剑就是我的剑”</em>
</p>

# Sharingan: Self-Optimisation via External Resources / 写轮眼：外部资源自优化

**Version**: v0.7.1
**Last Updated**: 2026-03-23
**Author**: Peiyuan (Ran) Huang, with (*significant*) assistance from Claude Code
**Status**: Personal demo / 个人 demo

---

## Why "Sharingan"? / 为什么叫"写轮眼"？

In *Naruto*, the Sharingan can instantly copy and absorb others' techniques. This skill does something similar — it reads external resources (GitHub repos, blog posts, config files, etc.) and extracts actionable insights to optimise your Claude Code setup. Analyse, learn, optimise.

火影忍者里的写轮眼能瞬间复制和吸收他人的技术。这个 skill 做的事差不多——读取外部资源（GitHub 仓库、博客、配置文件等），提取可操作的洞察来优化你的 Claude Code 配置。分析，学习，优化。

## What is this? / 这是什么？

A prompt-only skill (no code, no dependencies) that provides a structured 10-phase workflow for extracting insights from external resources and applying them to your Claude Code configuration. It includes:

- **Dual EXIT POINTs** — normalises "no changes needed" as a legitimate outcome (Phase 3 and Phase 5), fighting the action bias that plagues AI agents
- **13-category taxonomy** — classifies insights across skills, hooks, MCP, security, memory, and more
- **Built-in QC** — inline quality checks requiring 2 consecutive passes (max 6 rounds) before changes are applied
- **Reference Value Assessment** — even when no config changes are warranted, optionally captures long-term reference value from the source
- **Security preflight** — refuses to read credentials, flags prompt injection attempts

一个纯 prompt 的 skill（无代码、无依赖），提供结构化的 10 阶段工作流，从外部资源中提取洞察并应用到你的 Claude Code 配置中。包含：

- **双 EXIT POINT** — 将"无需修改"正常化为合理结果（Phase 3 和 Phase 5），对抗 AI agent 的行动偏差
- **13 类分类体系** — 涵盖技能、hooks、MCP、安全、记忆等
- **内置 QC** — 行内质量检查，需连续 2 轮通过（最多 6 轮）才能执行修改
- **参考价值评估** — 即使不需要修改配置，也可选择性地从资源中提取长期参考价值
- **安全预检** — 拒绝读取凭据，标记 prompt 注入尝试

## Disclaimers / 免责声明

**This is a personal demo.** Built for my own workflow, shared for reference. Specifically:

- **Not designed for generality** — hardcoded assumptions about my file structure, memory layout, and tool ecosystem
- **Bilingual mess** — the skill prompt is English, but calibration files (`pitfalls.md`, `examples.md`) freely mix English and Chinese
- **Opinionated** — reflects how *I* want my agent to handle external resources, which may not match your preferences

If you find something useful, feel free to adapt it. But don't expect plug-and-play.

**这是一个个人 demo。** 为自己的工作流打造，分享仅供参考。具体来说：

- **没有追求通用性** — 硬编码了我自己的文件结构、记忆布局和工具生态的假设
- **中英混杂** — skill prompt 是英文，但校准文件（`pitfalls.md`、`examples.md`）中英文随意切换
- **有主见** — 反映的是*我*希望 agent 如何处理外部资源，未必适合你

如果你觉得有用，欢迎自行适配。但别指望开箱即用。

## Content & Copyright / 内容与版权

This skill reads publicly available resources and extracts structural patterns to inform your personal configuration. It does not reproduce, store, or redistribute original content. Source material is processed transiently in the agent's context window and discarded after insight extraction.

Users are responsible for ensuring their use of this skill complies with applicable copyright laws and the terms of service of any platforms or resources they access. This skill is intended for use with publicly available, open-source, or user-owned content.

本 skill 读取公开资源并提取结构性模式，用于优化你的个人配置。它不复制、存储或再分发原始内容。源材料仅在 agent 上下文窗口中临时处理，洞察提取完成后即丢弃。

用户有责任确保对本 skill 的使用符合适用的版权法律及所访问平台或资源的服务条款。本 skill 仅供处理公开可用、开源或用户自有的内容。

## Trigger / 触发方式

```
---sharingan <source> [--target <category>] [--auto] [--dry-run] [--no-ref]
---写轮眼 <source> [--target <category>] [--auto] [--dry-run] [--no-ref]
```

Source can be: GitHub URL, any URL, local file/directory, or an image.

源可以是：GitHub URL、任意 URL、本地文件/目录、或图片。

## Workflow / 工作流

```
Phase 1  Deep Reading       — fetch and thoroughly read the source
Phase 2  Classification     — map to 13-category taxonomy
Phase 3  Extract Insights   — structured extraction + filtering
         ╰─ EXIT POINT 1: all insights filtered → "No applicable targets"
Phase 4  Self-Review        — challenge own extractions
Phase 5  Optimization       — draft concrete config changes
         ╰─ EXIT POINT 2: current config already optimal → "No changes"
Phase 6  Proposal QC        — 2 consecutive passes required (max 6 rounds)
Phase 7  User Approval      — you decide what gets applied
Phase 8  Execute Changes    — apply with three-check protocol
Phase 9  Changes QC         — 2 consecutive passes required (max 6 rounds)
Phase 10 Safety Verification — final safety check (max 4 rounds)
```

## Files / 文件说明

| File | Language | Role |
|------|----------|------|
| `SKILL.md` | English | Core workflow (loaded by Claude Code) |
| `taxonomy.md` | English | 13-category classification taxonomy |
| `examples.md` | EN/ZH | Output calibration: good patterns + anti-patterns |
| `pitfalls.md` | EN/ZH | Pitfall checklist (starter entries; extend with your own) |
| `references/` | English | Parameter parsing, source handling, edge cases, test scenarios |
| `CHANGELOG.md` | English | Version history |

## Prerequisites / 前置条件

[Claude Code](https://claude.ai/claude-code) — the skill uses Read, Grep, WebFetch, and context-mode tools. Pure markdown prompt, zero external dependencies.

## See Also / 相关

- `qc` — quick five-dimensional review (the complementary "check what you just did" skill)
- `audit` — heavy-duty multi-round deep audit

---

*Built with ☕, 🧠, and Claude Code. "I see through your technique."*

*用 ☕、🧠 和 Claude Code 打造。"你的招式，我看穿了。"*
