<!-- Planning reference. -->

# Phase 0 Planning Reference

Normative source for detailed Phase 0 planning behaviour in this `audit` skill.

The parent `SKILL.md` must still retain the corresponding hard summaries for:
- trigger and when-to-use boundaries
- parameter parsing semantics
- configuration-detection guardrails
- dispatch continuation behaviour

This file expands the planning details that were previously embedded in the monolithic `SKILL.md`.

## Parameter-Linked Planning Details

The parent `SKILL.md` remains the canonical summary for argument semantics. This reference carries the planning-specific detail that must not be lost during refactor.

- If `--out` is omitted, the default output path is `audit_reports/audit_[target_name]_[YYYYMMDD].md`, relative to the current working directory.
- If the requested output path already exists, append `_2`, `_3`, and so on to avoid overwriting an older report.
- `{report_dir}` always refers to the parent directory of the final report path.
- Under Windows OneDrive folder redirection, the default relative path can behave unreliably. Prefer an explicit absolute path, for example: `--out "C:/Users/jdoe/OneDrive - Example Org/audit_reports/audit_paper_20260314.md"`.
- Quote-aware grouping must happen before type-vs-path heuristics and before any file/directory diagnosis.
- When quoted arguments are present or path parsing is ambiguous, you must feed the raw args after `---audit` to `python scripts/parse-audit-args.py` via stdin or a single string argument and use its JSON output as the authoritative argument list before readability checks.
- A quoted target path containing spaces must remain a single target argument through parameter parsing, readability checks, and pre-planning target loading.
- If a type keyword precedes that quoted path, validate only the full quoted path string; never probe internal fragments such as `C:/Users/jdoe/OneDrive` as if they were standalone targets.
- The exact raw substring inside the quotes is the authoritative target path; do not rewrite it to a shorter existing prefix directory during readability diagnosis.
- For any quoted target or output path containing spaces, emit a short parse preflight line before readability diagnosis so the preserved `type / target / out` values are visible.
- If the parse preflight loses the exact quoted target substring, stop and re-parse instead of attempting fragment-level path repair.
- If a fresh-session runtime still rewrites that quoted OneDrive-style paper path to an existing prefix directory after the mandatory helper plus parse-preflight flow, classify the branch as a documented platform limitation rather than a successful parse; mitigate by staging the paper at a no-space temp path or by materialising the content into `audit_object_temp.md`.
- If the target content is not already in context, read it before planning begins.
- If no audit target can be identified, stop and prompt the user to specify one.

## 0.0 Configuration Detection

Run `scripts/config-check.sh` from the current skill package before starting formal planning.

Execution environment requirement:
- The script must run in a bash environment where `jq` is installed and `$HOME/.claude/settings.json` resolves to the active Claude profile for the current session.
- On Windows, prefer Git Bash unless the active Claude profile is intentionally located inside WSL or another bash environment with the same `~/.claude` contents.
- On Windows, `C:/Windows/system32/bash.exe` or a WSL bash whose `~/.claude` does not match the active session profile is incompatible and belongs to the documented script-error fallback branch.
- If `bash` on `PATH` points to an incompatible environment, treat that as a script-error fallback rather than a silent success path.

Decide the next action based on script output:

- Output `STATUS: OK`
  - Silently proceed to `0.1`.
  - Do not display anything to the user.
- Output `STATUS: MISMATCH`
  - Display the following detection notice.
  - List only the rows that correspond to actual `DIFF` lines from the script output.
  - Immediately proceed to `0.1` without waiting for user confirmation.

```text
ℹ️ Configuration Check: Current settings differ from AUDIT optimal configuration

| Setting | Current Value | AUDIT Optimal Value |
|---------|---------------|---------------------|
| [extract from DIFF line] | [current=X] | [optimal=Y] |

⚠️ Platform note: effortLevel, fastMode, alwaysThinkingEnabled, and model are cached at
session start — modifying settings.json mid-session has no effect on the running session
(GitHub Issues #30726, #13532).

To use optimal configuration: close this session → modify ~/.claude/settings.json
→ restart Claude Code → re-send ---audit.

The audit will proceed with the current configuration.
```

Tip: if the skill package exposes the helper scripts, the planning layer may recommend:
- `scripts/config-optimize.sh` before restart, if the user wants to temporarily switch settings for the next audit session
- `scripts/config-restore.sh` after the audit, but only if the user previously applied `scripts/config-optimize.sh` before restarting into the audit

These recommendations are informational only — the audit continues regardless of whether the user applies them. Declining the optimize suggestion does not block or alter the audit flow.

If the script output contains `MODEL_MISMATCH: true`, additionally append:

```text
⚠️ Current model is not Opus. Subagents are explicitly set to `model: "opus"` and will use Opus regardless. The orchestrator model cannot be changed mid-session; restart the session if you need the orchestrator on Opus too.
```

Fallback behaviour:
- If the script exits non-zero, explain: `Configuration check script encountered an error; skipping configuration check.`
- Continue to `0.1`.
- `STATUS: MISMATCH` is not treated as an error path here; it should already have been handled above because that case exits successfully.
- If stdout exists but no `STATUS:` line is present, display the raw script output and flag the anomaly.

## 0.1 Target Analysis

If `{report_dir}` does not exist, create it before doing any further planning.

Read the audit target thoroughly, with at least one complete pass over the target material, and identify:
- target type (`paper`, `code`, `plan`, `data analysis`, or `mixed`)
- domain (`epidemiology`, `bioinformatics`, `clinical`, `statistics`, or `other`)
- complexity and scale
- preliminary high-risk areas for internal planning
- file inventory when the target spans multiple files, including which big rounds each file mainly belongs to
- when the target is multi-file or `mixed`, surface that file inventory explicitly in the `0.5` planning announcement instead of keeping it as internal planning state only

Large file handling:
- For very large targets (`code >500 lines` or `document >8000 words`), prioritise core sections first.
- For papers: methods, results, discussion.
- For code: main logic and key functions.
- For plans: core steps and risks.
- For data analyses: results narrative, figures/tables, and methods or data-source sections.
- For mixed targets: prioritise the dominant-type core sections first, then the highest-risk supporting material from the secondary type.
- Read remaining sections as needed in later D rounds.
- For excessively large files, use segmented reading with `offset` and `limit`.

In-conversation text handling:
- If the audit target is pasted directly in the conversation rather than stored in a file, first save it as `{report_dir}/audit_object_temp.md`.
- Pass that temporary file path to all subagents instead of raw conversation text.
- If the pasted text exceeds `50,000` characters, warn that coverage may be incomplete for very large in-conversation content.
- Delete `audit_object_temp.md` during Phase 2 cleanup.

## 0.2 Theme Selection

Based on the target type, determine `3-8` independent big round themes.

Minimum enforcement:
- Standard mode must not drop below `3` big rounds.
- Lite mode must not drop below `2` big rounds.
- If initial theme selection falls below the minimum, add supplementary themes from the relevant reference list.

Big round theme reference:

- Academic paper
  - Scientific Accuracy and Logic
  - Citation and Literature Verification
  - Statistical Methods and Reporting Standards
  - Study Design and Methodology
  - Writing Quality and Language
  - Structure and Completeness
  - Numerical Internal Consistency
  - Formatting and Typesetting
- R or Python code
  - Correctness and Logic
  - Security and Risks
  - Performance and Efficiency
  - Readability and Comments
  - Standards and Style
  - Dependencies and Environment
  - Error Handling and Edge Cases
- Research plan
  - Scientific Soundness
  - Feasibility and Resources
  - Ethics and Compliance
  - Risk Identification and Mitigation
  - Completeness and Omissions
  - Logic and Internal Consistency
- Data analysis report
  - Data Quality and Sources
  - Statistical Method Appropriateness
  - Result Interpretation Accuracy
  - Figure and Table Accuracy
  - Citations and Standards
  - Reproducibility

Mixed-type targets:
- Select the primary table based on dominant content.
- Overlay key themes from the secondary type where needed.
- Example: paper plus R script uses the paper table as primary, with code themes `1` and `3` overlaid.

User-specified focus areas:
- Each `--focus` topic is either appended as an independent big round or merged into the most relevant existing theme.
- If `--lite` plus `--focus` would exceed the four-round cap, retain `--focus` rounds first and trim the lowest-priority auto-selected themes.
- In standard mode, if `--focus` additions would exceed eight rounds, apply the same trimming rule.
- If `--focus` topics alone exceed the mode cap after all auto themes are removed, retain only the first `N` focus topics in user-specified order and warn that the excess focus topics were dropped.

## 0.3 Batching

Assign big rounds to batches by number, with a maximum of five subagents running in parallel per batch.

- Standard mode
  - Batch 1 = `R1-R5`
  - Batch 2 = `R6-R8`
- Lite mode
  - Single batch `R1-R4`
- If total big rounds are `<=5`, use a single batch.

The directory creation requirement is already handled in `0.1`; do not duplicate it here.

## 0.4 MCP Verification

This check is first-use-only. If MCP availability has already been confirmed earlier in the same session, the orchestrator may skip this step.

Before formal dispatch, send a lightweight MCP test subagent:

```text
Agent tool:
  description: "MCP availability test"
  prompt: "Call mcp__plugin_bio-research_pubmed__search_articles to search for 'test', and report whether the call succeeded (success/failure). If this specific tool is unavailable, try any MCP tool from the Available Tools list."
```

Decision rules:
- Success
  - Proceed with normal dispatch.
- Failure
  - Note in the planning announcement: `⚠️ Subagent MCP unavailable; tool-based verification will be supplemented by the orchestrator during the merge phase`.
  - When instantiating the subagent template, use the MCP-free tool-table variant from `templates/subagent-template.md`.
  - Subagents still execute the audit, but they skip MCP tool calls.
  - The orchestrator-side no-MCP supplement procedure is defined in `references/phase-2-merge.md`.

## 0.5 Announcement

Field labels are fixed. Values adapt to the actual run configuration.

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT Initiated (Parallel Subagent Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target: [target name/type]
Mode: [Paper / Code / Plan / Data Analysis / Mixed (note primary + secondary type)]
Domain: [identified domain]
Target Components: [omit for single-file targets; required for multi-file or mixed targets]
  - [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...
  - [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R2 | R5 | ...
Big Round Plan:
  Batch 1 (parallel): R1·[theme] | R2·[theme] | R3·[theme] | ...
  Batch 2 (parallel): R6·[theme] | R7·[theme] | ...
Mode Limits: [Standard / Lite (4 rounds/3D)]
Report Language: [zh / en / auto]
MCP Status: [Available / ⚠️ Unavailable]
Subagent Model: opus (explicitly specified)
Configuration: [OK (no changes needed) / MISMATCH detected — continuing with current settings (restart session for optimal config) / Check skipped (script error)]
Output Report: [path]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Announcement rules:
- For single-file targets, omit `Target Components`.
- For multi-file or `mixed` targets, `Target Components` is mandatory and must preserve file-to-big-round visibility in the surfaced planning summary.
- In `mixed` mode, each component line must make the role visible enough for users and subagents to see which file is primary versus secondary/supporting.

The parent `SKILL.md` keeps the explicit runtime rule: `Do not wait for user confirmation; proceed immediately to Phase 1 dispatch.`
