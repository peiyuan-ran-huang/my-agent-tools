# AUDIT

**Version baseline:** `v0.3.2`
**Baseline date:** `2026-03-18`
**Refactor date:** `2026-03-20`

---

## Overview / 概述

`audit` is the heavyweight review layer in this skill family. It is meant for high-stakes targets where missing issues would be costly: papers, codebases, plans, consequential data analyses, and mixed multi-component targets.
`audit` 是本技能家族中的重量级审查层。它面向高风险对象——遗漏问题代价高昂的场景：论文、代码库、计划、关键数据分析以及多组件混合目标。

The core value is not "more prompt text." It is the architecture:
其核心价值不在于"更多的提示词文本"，而在于架构：

- an orchestrator plans the audit\
  由编排器规划审计
- independent subagents execute big rounds in physical isolation\
  独立子代理在物理隔离环境中执行大轮次
- each round uses D/V cycles\
  每轮使用 D/V（发现/验证）循环
- the orchestrator merges results with cross-round deduplication\
  编排器合并结果并进行跨轮去重

This README is a maintenance and orientation document. It is **not** the canonical runtime authority for execution rules.
本 README 是维护与导航文档，**不是**执行规则的权威运行时来源。

---

## Quick Start / 快速开始

This section is an operator-facing orientation note only.
本节仅为面向操作者的导航说明。

Canonical runtime behaviour still belongs to:
权威运行时行为仍归属于：
- [SKILL.md](SKILL.md)

Recommended starting pattern:
推荐的使用模式：

1. Use `---qc` first if you only need a quick triage pass.\
   如果只需快速分诊，先使用 `---qc`。
2. Use `---audit --lite [target]` when the target looks consequential and you want a lower-cost multi-round audit.\
   当目标有一定重要性且希望以较低成本进行多轮审计时，使用 `---audit --lite [target]`。
3. Use `---audit [target]` only when the target is high-stakes enough to justify the full heavyweight path.\
   仅当目标足够高风险、值得启动完整重量级流程时，才使用 `---audit [target]`。

Practical invocation examples:
实际调用示例：

```text
---audit --lite analysis/model.py
---audit paper manuscript.md
---audit mixed src/app.py docs/design.md
```

If a target path contains spaces, quote the full path.
如果目标路径包含空格，请用引号括住完整路径。

---

## Cost And Scope Note / 成本与范围说明

`---audit` is intentionally much heavier than `---qc`.
`---audit` 在设计上比 `---qc` 重量级得多。

- It plans multiple big rounds instead of doing a single quick pass.\
  它会规划多个大轮次，而非仅做单次快速检查。
- Standard mode may launch multiple Opus subagents plus merge-time verification work.\
  标准模式可能启动多个 Opus 子代理，外加合并阶段的验证工作。
- `--lite` reduces breadth and cost, but it does **not** mean "same audit, just faster"; it preserves key verification while trimming rounds.\
  `--lite` 降低了广度和成本，但**并不**意味着"同样的审计，只是更快"；它在缩减轮次的同时保留了关键验证。

If you are unsure whether the full audit is warranted, start with either:
如果不确定是否需要完整审计，可先从以下任一方式开始：
- `---qc`
- `---audit --lite`

Treat slow or expensive execution as expected behaviour for a heavyweight audit, not as evidence that the skill is malfunctioning.
请将缓慢或高成本的执行视为重量级审计的预期行为，而非技能故障的证据。

---

## Relationship With `qc` / 与 `qc` 的关系

- `---qc`: lightweight pre-scan, suitable for quick triage\
  `---qc`：轻量级预扫描，适合快速分诊
- `---audit`: heavyweight deep review, suitable for high-stakes targets\
  `---audit`：重量级深度审查，适合高风险对象
- `--lite`: in between the two, retaining key verification while reducing rounds\
  `--lite`：介于两者之间，在缩减轮次的同时保留关键验证

Recommended workflow:
推荐工作流：

1. Start with `---qc` for triage\
   先用 `---qc` 进行分诊
2. If the target is high-risk, or `qc` has already surfaced Major+ issues, escalate to `---audit`\
   如果目标属于高风险，或 `qc` 已发现 Major 及以上级别问题，升级至 `---audit`

---

## Canonical Source Map / 权威来源映射

If conflicts arise between different files, the canonical source defined here takes precedence.
如果不同文件之间出现冲突，以此处定义的权威来源为准。

| File | Canonical responsibility |
|---|---|
| `SKILL.md` | English orchestrator entry protocol |
| `references/phase-0-planning.md` | Detailed planning behaviour |
| `references/phase-1-dispatch.md` | Dispatch and batch-management behaviour |
| `references/phase-2-merge.md` | Merge, dedup, content verification, writeout, cleanup behaviour |
| `references/degradation-and-limitations.md` | Failure handling, degradation paths, context-pressure guidance, platform limitations |
| `templates/subagent-template.md` | Canonical subagent execution protocol |
| `templates/report-template.md` | Canonical final report structure |
| `scripts/config-optimal-values.sh` | Single source of truth for optimal config values |
| `scripts/config-check.sh` | Canonical source for raw config-check output shape only; Phase 0 detect-and-guide behaviour belongs to `SKILL.md` plus `references/phase-0-planning.md` |
| `scripts/config-optimize.sh` | Canonical source for backup-and-apply config optimisation behaviour and its output contract |
| `scripts/config-restore.sh` | Canonical source for audit-field restore behaviour, restore fallback branches, and restore output contract |
| `scripts/parse-audit-args.py` | Canonical source for deterministic quote-aware argument parsing of the raw `---audit` argument string |

README is responsible only for explaining structure, versioning, maintenance entry points, and open questions; it should not become the sole bearer of runtime-authoritative rules.
README 仅负责说明结构、版本管理、维护入口和待决问题；不应成为运行时权威规则的唯一承载者。

In the current version, entry / references / templates / scripts have all completed their layered restructuring; `scripts/` remains the deterministic runtime layer.
在当前版本中，入口 / 参考文档 / 模板 / 脚本均已完成分层重构；`scripts/` 仍为确定性运行时层。

---

## File Layout / 文件布局

```text
audit/
  SKILL.md
  README.md
  pitfalls.md
  release-checklist.md
  audit-self-check-spec.md
  verification-v2.md
  verification-issue-ledger.md
  examples.md
  test-scenarios.md
  goldens/
    normal-report.md
    richer-normal-report.md
    all-zero-report.md
    partial-report.md
    output-verification-warning.txt
  contracts/
    maintenance-contracts.tsv
  references/
    phase-0-planning.md
    phase-1-dispatch.md
    phase-2-merge.md
    degradation-and-limitations.md
  templates/
    subagent-template.md
    report-template.md
  scripts/
    audit-self-check.sh
    check-smoke-evidence.sh
    execution-test.sh
    validate-report.sh
    test-golden.sh
    config-check.sh
    config-optimal-values.sh
    config-optimize.sh
    config-restore.sh
    parse-audit-args.py
```

Design principles:
设计原则：

- Main entry files retain only the entry protocol\
  主入口文件仅保留入口协议
- Detailed phase rules live in `references/`\
  详细阶段规则存放于 `references/`
- Canonical templates live in `templates/`\
  权威模板存放于 `templates/`
- Deterministic config logic lives in `scripts/`\
  确定性配置逻辑存放于 `scripts/`
- Checker-driven maintenance literals live in `contracts/maintenance-contracts.tsv`\
  检查器驱动的维护字面量存放于 `contracts/maintenance-contracts.tsv`
- Release gates and automated maintenance check specs live in root-level maintenance assets\
  发布门控和自动化维护检查规范存放于根级维护资产中
- Lightweight automated maintenance check scripts live in `scripts/`\
  轻量级自动化维护检查脚本存放于 `scripts/`
- Calibration and regression materials live in `examples.md` / `test-scenarios.md`\
  校准和回归材料存放于 `examples.md` / `test-scenarios.md`

---

## Maintenance Assets / 维护资产

The following files are maintenance-layer assets, not runtime authorities:
以下文件为维护层资产，不是运行时权威来源：

- [release-checklist.md](release-checklist.md): gate checklist for releases or major changes\
  [release-checklist.md](release-checklist.md)：发布或重大变更的门控检查清单
- [audit-self-check-spec.md](audit-self-check-spec.md): specification for the current automated maintenance checker and its planned extensions\
  [audit-self-check-spec.md](audit-self-check-spec.md)：当前自动化维护检查器的规范及其计划扩展
- [verification-v2.md](verification-v2.md): design and execution rules for the accelerated high-quality verification workflow\
  [verification-v2.md](verification-v2.md)：加速高质量验证工作流的设计和执行规则
- [verification-issue-ledger.md](verification-issue-ledger.md): verification issue ledger, used to prevent the same issue from being repeatedly treated as "new" and having its count reset\
  [verification-issue-ledger.md](verification-issue-ledger.md)：验证问题台账，用于防止同一问题被反复视为"新问题"并重置计数
- [pitfalls.md](pitfalls.md): non-authoritative common-mistake navigation file that helps new sessions / new maintainers avoid known pitfalls quickly and jump to the correct canonical owner\
  [pitfalls.md](pitfalls.md)：非权威的常见错误导航文件，帮助新会话/新维护者快速避开已知陷阱并跳转到正确的权威来源
- [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv): checker-driven maintenance contract source, carrying canonical map rows, coverage checklist items, scenario headings, expected example headings, example-order invariants, and verification ledger header / Severity / Status schema families\
  [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv)：检查器驱动的维护合约来源，承载权威映射行、覆盖检查项、场景标题、预期示例标题、示例顺序不变量以及验证台账表头 / 严重性 / 状态模式族
- [scripts/audit-self-check.sh](scripts/audit-self-check.sh): current minimal viable automated maintenance checker implementation\
  [scripts/audit-self-check.sh](scripts/audit-self-check.sh)：当前最小可行自动化维护检查器实现
- [scripts/check-smoke-evidence.sh](scripts/check-smoke-evidence.sh): batch re-validator that checks whether archived markdown smoke reports still conform to the current `validate-report.sh` report-shape boundaries, and helps distinguish current vs stale evidence; scans the `reports/` subtree first, falling back to root-level `*.md` if it does not exist\
  [scripts/check-smoke-evidence.sh](scripts/check-smoke-evidence.sh)：批量重验证器，检查归档的 Markdown 烟雾测试报告是否仍符合当前 `validate-report.sh` 的报告格式边界，并帮助区分当前证据与过时证据；优先扫描 `reports/` 子树，若不存在则回退到根级 `*.md`
- [scripts/validate-report.sh](scripts/validate-report.sh): thin-layer report-shape validator for verifying normal / all-zero / partial markdown report shapes, as well as the documented richer full-report variant\
  [scripts/validate-report.sh](scripts/validate-report.sh)：薄层报告格式验证器，用于验证正常 / 全零 / 部分 Markdown 报告格式，以及文档中记录的更丰富的完整报告变体
- [scripts/execution-test.sh](scripts/execution-test.sh): dynamic behaviour test harness covering config-check/optimize/restore, validate-report, and parse-audit-args execution paths\
  [scripts/execution-test.sh](scripts/execution-test.sh)：动态行为测试脚手架，覆盖 config-check/optimize/restore、validate-report 和 parse-audit-args 的执行路径
- [scripts/test-golden.sh](scripts/test-golden.sh): minimal executable regression check against committed goldens\
  [scripts/test-golden.sh](scripts/test-golden.sh)：针对已提交黄金标准的最小可执行回归检查
- [examples.md](examples.md): output calibration examples\
  [examples.md](examples.md)：输出校准示例
- [test-scenarios.md](test-scenarios.md): text-level regression fixtures\
  [test-scenarios.md](test-scenarios.md)：文本级回归测试固件
- [goldens/](goldens/): thin-layer executable golden artefacts; used to supplement rather than replace `test-scenarios.md`, preserving both the canonical minimal normal report and the explicitly permitted richer full-report variant\
  [goldens/](goldens/)：薄层可执行黄金标准产物；用于补充而非替代 `test-scenarios.md`，同时保留权威最小正常报告和明确允许的更丰富完整报告变体

These files can all be important, but they should not become the sole authoritative source for runtime-only rules.
这些文件都可能很重要，但不应成为仅运行时规则的唯一权威来源。

---

## What Changed In The Restructure / 重构变更内容

The focus of this restructure was not "simplifying capabilities" but "layered ownership":
本次重构的重点不是"简化功能"，而是"分层职责"：

- `SKILL.md` no longer carries full templates, long tables, or platform-limitation background\
  `SKILL.md` 不再承载完整模板、长表格或平台限制背景信息
- `SKILL_ZH.md` no longer mirrors the entire detailed manual; it retains only the semantically equivalent entry protocol\
  `SKILL_ZH.md` 不再镜像整个详细手册；仅保留语义等价的入口协议
- `templates/` becomes the single source of truth, preventing template rules from drifting across multiple files\
  `templates/` 成为唯一真相来源，防止模板规则在多个文件间漂移
- `references/` takes over phase details and degradation logic, preventing main-entry overload\
  `references/` 接管阶段详情和降级逻辑，防止主入口过载
- README no longer duplicates runtime details; it retains only structural explanation and maintenance entry points\
  README 不再复制运行时细节；仅保留结构说明和维护入口

---

## Runtime Guardrails / 运行时护栏

The following boundaries must be maintained by the maintenance layer:
以下边界必须由维护层保持：

- Do not allow the parallel subagent architecture to silently degrade into sequential review by default\
  不允许并行子代理架构默默退化为默认的顺序审查
- Do not allow big-round independence to silently shift from physical isolation to a mere textual requirement\
  不允许大轮次独立性从物理隔离悄然降级为仅文本要求
- Do not allow removal of D/V cycles, cross-round dedup, unified numbering, or no-MCP supplement\
  不允许移除 D/V 循环、跨轮去重、统一编号或无 MCP 补充机制
- Do not allow README to become the sole source for runtime limits, report schema, or subagent behaviour\
  不允许 README 成为运行时限制、报告模式或子代理行为的唯一来源
- Do not allow a state where "README says A, SKILL says B, and the template says C"\
  不允许出现"README 说 A、SKILL 说 B、模板说 C"的不一致状态

---

## Prerequisites / 前提条件

| Dependency | Status | Notes |
|---|---|---|
| Claude Code / agent runtime | Required | Must support Agent calls and explicit model selection |
| Claude Code authentication | Required for CLI-based live acceptance | If fresh-session smoke tests are run through the Claude Code CLI, `claude auth status` should report `"loggedIn": true` before the run starts |
| Bash-compatible shell | Required for config scripts | `config-check.sh`, `config-optimize.sh`, and `config-restore.sh` are bash scripts; the shell must expose the active Claude profile at `$HOME/.claude/settings.json` |
| `jq` | Required | Used by config scripts; on Windows, a WinGet-installed `jq.exe` is acceptable if the active Bash environment can resolve it or discover it via `where.exe` |
| MCP tools | Recommended | Especially useful for citation and fact verification |
| LSP | Optional | Helpful for `.R` / `.py` audit targets |
| Context Mode MCP | Optional | Recommended for large targets or many big rounds |
| Academic rules file | Optional | Create a project- or user-level rules file (e.g., `~/.claude/rules/academic-workflow.md`) with citation verification standards, numerical reporting rules, and domain-specific constraints; automatically applied when loaded in context |

Windows note:
Windows 注意事项：

- Prefer Git Bash for the config scripts.\
  配置脚本优先使用 Git Bash。
- On Windows, the scripts accept either `jq` or `jq.exe`; a WinGet-installed `jq.exe` is acceptable if the active Bash environment can resolve it directly or via `where.exe`.\
  在 Windows 上，脚本同时接受 `jq` 和 `jq.exe`；通过 WinGet 安装的 `jq.exe` 是可接受的，只要当前 Bash 环境能直接或通过 `where.exe` 解析到它。
- WSL or another bash environment is acceptable only if `jq` is installed there and `~/.claude/settings.json` inside that environment is the same active Claude profile that the running session is using.\
  WSL 或其他 bash 环境仅在其中安装了 `jq` 且该环境内的 `~/.claude/settings.json` 与当前运行会话使用的活跃 Claude 配置文件相同时才可接受。
- Treat `C:/Windows/system32/bash.exe` or a WSL bash whose `~/.claude` does not match the running session as incompatible; that branch should enter the documented script-error fallback.\
  应将 `C:/Windows/system32/bash.exe` 或 `~/.claude` 与当前运行会话不匹配的 WSL bash 视为不兼容；该分支应进入文档中记录的脚本错误回退路径。
- If `bash` on `PATH` resolves to an incompatible environment, Phase 0 should fall back to the documented script-error branch rather than pretending the normal config-check path succeeded.\
  如果 `PATH` 中的 `bash` 解析到不兼容的环境，Phase 0 应回退到文档中记录的脚本错误分支，而非假装正常的配置检查路径成功。

Fresh-session acceptance note:
新会话验收注意事项：

- If live acceptance is being run through the Claude Code CLI, check `claude auth status` first and require `"loggedIn": true` before treating any smoke attempt as meaningful evidence.\
  如果通过 Claude Code CLI 进行实时验收，请先检查 `claude auth status` 并要求 `"loggedIn": true`，然后才能将任何烟雾测试尝试视为有意义的证据。
- If a non-interactive CLI smoke prompt begins with `---audit`, pass it through stdin or another non-argv channel rather than as a bare prompt argument; a leading dashed prompt can be parsed as a CLI option before the session starts.\
  如果非交互式 CLI 烟雾测试提示以 `---audit` 开头，请通过 stdin 或其他非 argv 通道传递，而非作为裸命令行参数；以连字符开头的提示可能在会话启动前被解析为 CLI 选项。

---

## Known Runtime Limitation / 已知运行时限制

One live entry limitation remains explicitly documented.
一个实时入口限制仍被明确记录。

- A direct fresh-session `paper` invocation with a quoted OneDrive absolute path containing spaces can still collapse to a prefix directory in some sessions, even though the skill now requires the parser helper and parse preflight.\
  在某些会话中，使用带引号的含空格 OneDrive 绝对路径直接发起新会话 `paper` 调用，仍可能折叠为前缀目录，即使技能现在要求使用解析器辅助工具和解析预检。
- This is treated as a platform / entry-adherence limitation, not as evidence that the quoted-path contract should be weakened.\
  这被视为平台/入口遵守性限制，而非引号路径合约应被削弱的证据。
- If it occurs, disclose it and use one of the documented mitigations:\
  如果发生此情况，请披露并使用以下文档中记录的缓解措施之一：
  - stage the paper at a no-space temp path and audit the staged file\
    将论文暂存到无空格的临时路径并审计暂存文件
  - materialise the paper content into `audit_object_temp.md`\
    将论文内容物化到 `audit_object_temp.md`
- The canonical wording lives in `references/degradation-and-limitations.md`.\
  权威措辞存放于 `references/degradation-and-limitations.md`。

---

## Maintenance Rules / 维护规则

1. If changing entry behaviour, update `SKILL.md` as the single canonical source.\
   如需更改入口行为，更新 `SKILL.md` 作为唯一权威来源。
2. If changing detailed phase behaviour, update the relevant `references/*.md` file instead of expanding the main entry again.\
   如需更改详细阶段行为，更新相关的 `references/*.md` 文件，而非再次扩展主入口。
3. If changing subagent execution semantics, update `templates/subagent-template.md` as the canonical source.\
   如需更改子代理执行语义，更新 `templates/subagent-template.md` 作为权威来源。
4. If changing report structure, update `templates/report-template.md` as the canonical source.\
   如需更改报告结构，更新 `templates/report-template.md` 作为权威来源。
5. If changing config values, update `scripts/config-optimal-values.sh`; do not fork those values into prose.\
   如需更改配置值，更新 `scripts/config-optimal-values.sh`；不要将这些值分散到散文描述中。
6. If changing canonical runtime behaviour, update `test-scenarios.md` so the regression fixture still covers the changed behaviour surface; update `examples.md` as well when output calibration would otherwise drift.\
   如需更改权威运行时行为，更新 `test-scenarios.md` 以确保回归测试固件仍覆盖变更的行为面；当输出校准可能漂移时，同步更新 `examples.md`。
7. If a README explanation conflicts with a canonical source file, the canonical source wins and README must be corrected.\
   如果 README 的说明与权威来源文件冲突，以权威来源为准，README 必须修正。
8. If changing a contract-backed maintenance family, update `contracts/maintenance-contracts.tsv` first, then sync `scripts/audit-self-check.sh`, `audit-self-check-spec.md`, `release-checklist.md`, and any affected maintenance docs. Current contract-backed families include canonical source map rows, coverage checklist items, scenario-heading families, expected example headings, example-order invariants, and verification-ledger header / Severity / Status schema families.\
   如需更改合约支撑的维护族，先更新 `contracts/maintenance-contracts.tsv`，然后同步 `scripts/audit-self-check.sh`、`audit-self-check-spec.md`、`release-checklist.md` 及所有受影响的维护文档。当前合约支撑的维护族包括：权威来源映射行、覆盖检查项、场景标题族、预期示例标题、示例顺序不变量以及验证台账表头 / 严重性 / 状态模式族。
9. If a concentrated verification cycle produces concrete findings, record them in `verification-issue-ledger.md` so the next round can distinguish true new issues from already-known/resolved ones.\
   如果集中验证周期产生了具体发现，将其记录到 `verification-issue-ledger.md`，以便下一轮能区分真正的新问题和已知/已解决的问题。
10. If updating [pitfalls.md](pitfalls.md), keep it non-authoritative and ensure every pitfall still points back to the correct canonical owner instead of restating rules as a second truth source.\
    如需更新 [pitfalls.md](pitfalls.md)，保持其非权威性，并确保每个陷阱仍指向正确的权威来源，而非作为第二真相来源重新陈述规则。
11. If updating `goldens/` or the thin harness scripts, keep them additive: they may validate report shapes and degraded-output boundaries, but they must not replace `test-scenarios.md` as the semantic regression fixture or become a second runtime authority.\
    如需更新 `goldens/` 或薄层测试脚手架脚本，保持其增量性：它们可以验证报告格式和降级输出边界，但不得替代 `test-scenarios.md` 作为语义回归固件，也不得成为第二运行时权威。
12. If archived markdown smoke reports are reused as report-shape evidence, revalidate them with `scripts/validate-report.sh` or mark them stale; non-markdown or in-thread smoke evidence must be reviewed against its own canonical source or fixture instead. Do not edit old smoke artefacts to simulate current compliance.\
    如果归档的 Markdown 烟雾测试报告被作为报告格式证据重新使用，请用 `scripts/validate-report.sh` 重新验证或标记为过时；非 Markdown 或会话内的烟雾测试证据必须对照其自身的权威来源或固件进行审查。不要编辑旧烟雾测试产物来模拟当前合规。
13. `scripts/check-smoke-evidence.sh` is a maintenance helper for archived markdown smoke reports only; do not use it to overclaim anything about non-markdown evidence or actual fresh-session runtime behaviour.\
    `scripts/check-smoke-evidence.sh` 仅作为归档 Markdown 烟雾测试报告的维护辅助工具；不要用它对非 Markdown 证据或实际新会话运行时行为做过度声明。
14. If documenting or running CLI-based live acceptance, treat Claude Code authentication and leading-dash prompt delivery as operator prerequisites. Do not misclassify a `claude auth status` failure or bare-argv `---audit` parse collision as an `audit` runtime regression.\
    在记录或运行基于 CLI 的实时验收时，将 Claude Code 认证和以连字符开头的提示投递视为操作者前提条件。不要将 `claude auth status` 失败或裸 argv `---audit` 解析冲突误分类为 `audit` 运行时回归。

Script-layer note:
脚本层注意事项：

- The four config-management scripts were restored byte-identically from the preserved baseline:\
  四个配置管理脚本已从保留基线逐字节恢复：
  - `config-check.sh`
  - `config-optimal-values.sh`
  - `config-optimize.sh`
  - `config-restore.sh`
- `audit-self-check.sh` is a new maintenance checker added after the refactor baseline; it is not part of the preserved runtime-script snapshot.\
  `audit-self-check.sh` 是重构基线之后新增的维护检查器；它不属于保留的运行时脚本快照。
- The current structure preserves the original runtime config-script behaviour at the file-content level while also allowing maintenance-stage automation to evolve.\
  当前结构在文件内容层面保留了原始运行时配置脚本行为，同时允许维护阶段自动化继续演进。

---

## Version And Changelog / 版本与变更日志

### Baseline Carried Forward / 继承基线

- `v0.3.0` (`2026-03-18`): source snapshot used as the refactor baseline\
  `v0.3.0` (`2026-03-18`)：用作重构基线的源代码快照

### Refactor Update / 重构更新

- `2026-03-20`: structural refactor\
  `2026-03-20`：结构性重构
  - entry protocol split cleanly into `SKILL.md` and `SKILL_ZH.md`\
    入口协议干净地拆分为 `SKILL.md` 和 `SKILL_ZH.md`
  - detailed execution moved into `references/`\
    详细执行规则迁移至 `references/`
  - canonical templates isolated in `templates/`\
    权威模板隔离至 `templates/`
  - README reduced to maintenance/orientation role\
    README 精简为维护/导航角色
  - script layer restored from the frozen baseline instead of remaining as scaffolds\
    脚本层从冻结基线恢复，而非保留为脚手架
  - added `scripts/audit-self-check.sh` as the first live maintenance checker implementation\
    新增 `scripts/audit-self-check.sh` 作为首个实时维护检查器实现

### Credits / 致谢

The 2026-03-20 structural refactor, live maintenance-system hardening (canonical ownership, maintenance contracts, checker-backed drift control, executable harness and goldens), Windows/script compatibility work, and initial real fresh-session release acceptance for all five target families (`paper`, `code`, `plan`, `data`, `mixed`) were contributed by Codex.
2026-03-20 的结构性重构、实时维护系统加固（权威所有权、维护合约、检查器支撑的漂移控制、可执行测试脚手架和黄金标准）、Windows/脚本兼容性工作，以及所有五个目标家族（`paper`、`code`、`plan`、`data`、`mixed`）的首次真实新会话发布验收，均由 Codex 贡献。

### Scope, Calibration, And Release Updates / 范围、校准与发布更新

- `2026-03-27`: `v0.3.2` — deferred tasks completion + post-write verification + execution testing\
  `2026-03-27`：`v0.3.2` — 延期任务全部完成 + 写后验证规则 + 执行级测试
  - `execution-test.sh` added: 550 lines, 57 dynamic behaviour tests covering config-check/optimize/restore, validate-report, and parse-audit-args\
    新增 `execution-test.sh`：550 行，57 项动态行为测试覆盖 config-check/optimize/restore、validate-report 和 parse-audit-args
  - T8h (Tool Degradation Transparency) and T2k (Config Mismatch With Declined Optimize Suggestion) test scenarios added\
    新增 T8h（工具降级透明度）和 T2k（配置不匹配拒绝优化建议）测试场景
  - §2.4.1 post-write content verification rules added to phase-2-merge.md (6 categories: cross-ref, star-set, field compliance, counts, arithmetic, severity)\
    §2.4.1 写后内容验证规则加入 phase-2-merge.md（6 类：交叉引用、星标集合、字段合规、计数、算术、严重性）
  - T10d (Post-Write Content Verification) test scenario and coverage item added\
    新增 T10d（写后内容验证）测试场景和覆盖项
  - 4 Chinese reference translations created then removed (low practical value for LLM); SKILL_ZH.md dual-path loading reverted to EN-only\
    4 个中文参考翻译创建后移除（LLM 实用价值低）；SKILL_ZH.md 双路径加载恢复为纯英文
  - phase-0-planning.md: explicit declined-optimize-does-not-block-audit clause\
    phase-0-planning.md：显式说明拒绝优化不阻塞审计
  - regex_rule namespace collision fix in audit-self-check.sh\
    audit-self-check.sh 中 regex_rule 命名空间碰撞修复
  - test-scenarios.md: batch rename subagent-prompt.md → templates/subagent-template.md (13 occurrences)\
    test-scenarios.md：批量重命名 subagent-prompt.md → templates/subagent-template.md（13 处）
  - smoke tests (§1): 6 target families + degraded-path drill completed, 35 mechanical errors found and fixed\
    烟雾测试（§1）：6 个目标家族 + 降级路径演练完成，发现并修复 35 个机械性错误
  - audit-self-check: 419/419 pass\
    自检：419/419 通过

- `2026-03-26`: `v0.3.1` — formatting cleanup + release checklist pass\
  `2026-03-26`：`v0.3.1` — 格式清理 + 发布检查通过
  - all American English spellings normalised to British English across the package\
    全包美式拼写统一为英式拼写
  - bilingual EN/CN documentation reformatted: English and Chinese translations now on separate lines (previously on the same line)\
    双语文档重新排版：英中翻译分行显示（原先挤在同一行）
  - release checklist §1–§11 verified: audit-self-check 412/412, golden 15/15, all blockers pass\
    发布检查清单 §1–§11 验证通过：自检 412/412，golden 15/15，所有阻塞项通过
  - no logic, architecture, or runtime behaviour changes\
    无逻辑、架构或运行时行为变更

- `2026-03-24`: pre-publication QC pass\
  `2026-03-24`：发布前 QC 检查
  - repo synced to match local (12 files updated from 2026-03-23/24 fixes)\
    仓库与本地同步（12 个文件更新自 2026-03-23/24 修复）
  - `verification-issue-ledger.md` added to `sync.sh` no-clobber list\
    `verification-issue-ledger.md` 加入 `sync.sh` 免覆盖列表
  - README Quick Start updated from "future distribution" framing to current installation instruction\
    README 快速开始从"未来分发"措辞更新为当前安装说明
  - `sync.sh` trap lifecycle comment added for clarity\
    `sync.sh` 添加 trap 生命周期注释以提高可读性

- `2026-03-23`: release acceptance — all five target families (`paper`, `code`, `plan`, `data`, `mixed`) passed `validate-report.sh`; sequential fallback (Agent tool unavailable to nested agents) declared in all runs; 5/5 current under batch validator. Smoke reports archived locally.\
  `2026-03-23`：发布验收——所有五个目标家族（`paper`、`code`、`plan`、`data`、`mixed`）均通过 `validate-report.sh`；所有运行中声明了顺序回退（嵌套代理不可用 Agent 工具）；批量验证器下 5/5 通过。烟雾测试报告已本地归档。

- `2026-03-22`: scope reduction + calibration enhancement\
  `2026-03-22`：范围缩减 + 校准增强
  - `test-scenarios.md` trimmed from ~2057 to ~343 lines (verbose scenarios condensed to compact summaries + preserved Coverage Checklist and all checker-required literals)\
    `test-scenarios.md` 从约 2057 行精简至约 343 行（冗长场景压缩为紧凑摘要 + 保留覆盖检查清单和所有检查器所需字面量）
  - `audit-self-check-spec.md` trimmed from ~629 to ~160 lines (detailed check lists replaced by module index + manual reviews kept)\
    `audit-self-check-spec.md` 从约 629 行精简至约 160 行（详细检查列表替换为模块索引 + 保留人工审查）
  - `pitfalls.md` linked into SKILL.md/SKILL_ZH.md Output Calibration and subagent-template.md Calibration Reference\
    `pitfalls.md` 链接至 SKILL.md/SKILL_ZH.md 的输出校准部分和 subagent-template.md 的校准参考
  - Example 6 (D/V cycle: Discovery vs Verification) added to `examples.md` + contracts TSV\
    新增示例 6（D/V 循环：发现 vs 验证）至 `examples.md` + 合约 TSV
  - `release-checklist.md` §1 goldens/ inventory sync gap fixed (added `richer-normal-report.md`)\
    `release-checklist.md` §1 goldens/ 清单同步缺口已修复（新增 `richer-normal-report.md`）
  - `audit-self-check.sh` example_heading expected count updated from 5 to 6\
    `audit-self-check.sh` 预期示例标题计数从 5 更新为 6

---

## Known Maintenance Targets / 已知维护目标

These items are not runtime faults but rather maintenance goals worth continuing to pursue:
以下条目不是运行时故障，而是值得持续推进的维护目标：

- `examples.md` has been restored as a usable output calibration set; additional boundary examples can still be added over time\
  `examples.md` 已恢复为可用的输出校准集；额外的边界示例仍可随时间推移逐步添加
- `test-scenarios.md` has been restored as a minimal regression fixture set; additional scenario coverage can still be expanded over time\
  `test-scenarios.md` 已恢复为最小回归测试固件集；额外的场景覆盖仍可随时间推移逐步扩展
- The four config-management scripts have been restored from the preserved baseline; `audit-self-check.sh` is a subsequently added maintenance checker. If stronger guarantees are needed, deeper execution-level verification can be added\
  四个配置管理脚本已从保留基线恢复；`audit-self-check.sh` 是后续新增的维护检查器。如果需要更强的保证，可以添加更深层的执行级验证
- If a better Chinese maintenance experience is desired, a decision can be made on whether to add Chinese `references/` documents\
  如果需要更好的中文维护体验，可以决定是否添加中文 `references/` 文档
- Installation: copy the `audit/` directory into `~/.claude/skills/` (see repo-level README for details)\
  安装方式：将 `audit/` 目录复制到 `~/.claude/skills/`（详见仓库级 README）
- ~~`templates/subagent-template.md` / `references/phase-2-merge.md` do not yet explicitly require outputting an empty table when `### Cross-Round Independent Discoveries` has zero findings~~ — **Resolved** (V-20260323-001): `phase-2-merge.md` §2.4 line 84 and `report-template.md` lines 114-118 now contain the explicit zero-discovery row requirement; goldens updated; `validate-report.sh` enforces the table header (`subagent-template.md` governs only temp-report format; the zero-discovery table is a final-report concern handled by `phase-2-merge.md` and `report-template.md`, so it required no direct change)\
  ~~`templates/subagent-template.md` / `references/phase-2-merge.md` 尚未明确要求在零发现时输出空表格~~ — **已解决** (V-20260323-001)：`phase-2-merge.md` §2.4 第 84 行和 `report-template.md` 第 114-118 行现已包含显式零发现行要求；goldens 已更新；`validate-report.sh` 强制检查表头（`subagent-template.md` 仅管辖 temp-report 格式；零发现表格是 `phase-2-merge.md` 和 `report-template.md` 负责的 final-report 事项，无需直接修改）

---

## Final Note / 结语

The goal of this restructured version is to make `audit` more maintainable, more auditable, and less prone to silent degradation during subsequent edits, **without sacrificing any heavyweight capabilities**.
本次重构版本的目标是让 `audit` 更易维护、更易审计、更不易在后续编辑中悄然退化，**同时不牺牲任何重量级能力**。
