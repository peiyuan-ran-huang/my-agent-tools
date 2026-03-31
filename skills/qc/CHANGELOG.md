# Changelog

All notable changes to this project are documented here.
Only version increments of 0.1 or above get their own entry heading; patch-level (0.0.1) fixes are recorded as ### Patched subsections within the parent version entry.
Dates represent when the version was committed to the repo, not when development started.

本文件记录所有重要变更。0.1 及以上的版本增量有独立的标题条目；0.0.1 级别的修补记录为父版本条目内的 ### Patched 子节。
日期为提交至 repo 的时间，非开发开始时间。

## [v1.3] — 2026-03-31

- **WNF Register for subagent**: `findings_temp.md` now includes `## WNF Register` section in loop mode, listing all won't-fix items so the subagent can distinguish re-identifications from genuinely new findings. Subagent JSON output gains `wnf_reidentified` field. Dispatch logic updated with post-dispatch cross-check: `new_findings` matching WNF register entries are reclassified; WNF-only reopens are overridden to confirmed (no pass counter reset). New `Confirmed + wnf_reidentified` note parallels existing `Confirmed + severity_adjustments`. Additional Context guidance added for WNF instructions. WNF register format: `[WNF-N] Dimension: description (Reason: reason)`; >20 items summarized to top 5 by severity. Affected files: SKILL.md, SKILL_ZH.md, examples.md (+WNF-aware example), pitfalls.md (+entry #25).
- **Root cause**: v1.2.0 `--loop --sub` R4+ subagents repeatedly reopened with all-WNF findings because `findings_temp.md` lacked WNF state. Observed in /work v1.1.0 session (7 rounds, R4 subagent reported 6 WNF items as new).

## [v1.2] — 2026-03-29

- **Session-unique temp directory**: replaced hardcoded `C:/tmp/qc_sub/` with per-session `C:/tmp/qc_sub_<timestamp>_<random>/` (`QC_SUB_DIR`) to eliminate temp file collisions between concurrent sessions (pitfalls #21/#23). New "Session directory" step generates unique ID via `date +%s` + `$RANDOM`. Prompt template gains 5th fill-in field `{{QC_SUB_DIR}}`. Affected files: SKILL.md, SKILL_ZH.md, pitfalls.md (#14 field list updated).

## [v1.1] — 2026-03-26

- **6-subagent parallel QC round**: identified and fixed 13 findings (5 Major + 8 Minor) from 6 independent opus subagent reviews
- **Fix recurrence cap**: same finding recurring 3 times triggers user escalation instead of infinite fix loops
- **Non-WNF fix queue**: "fix all findings" → "fix all non-WNF findings" (explicit WNF exclusion from fix queue)
- **In-context content fix mechanism**: defined how loop mode handles fixes for non-file targets (Claude outputs corrected version; subsequent rounds review it)
- **Auto-detect rejection path**: defined fallback when user rejects auto-detected target in loop mode
- **Depth checkpoint + subagent interaction**: explicitly documented that both rules apply independently on checkpoint rounds
- **Cross-validation fallback**: subagent handles original file unreadable gracefully
- **Post-reopen History update**: pseudocode now updates round history when subagent reopens a Pass to non-Pass
- **Sync rule expanded**: added (4) translation-process notes as allowed difference
- **Evolution Protocol cross-reference**: section now notes loop-only timing restriction
- **Version bump**: 1.0.0 → 1.1.0

### Patched — 2026-03-26

- **Parameter parsing clarification**: documented that only double quotes are supported for path quoting; single quotes, backslash-escaped spaces, and empty quoted strings are not supported
- **Confirmed + severity_adjustments note**: added blockquote clarifying that confirmed verdicts may still include severity adjustments
- **Write tool failure degradation**: added loop-mode degradation path for Write tool failures during fix application
- **MEMORY.md version sync**: updated stale qc v0.9.2 → v1.1.0
- **README.md changelog reorder**: fixed ascending chronological ordering for v1.0/v1.1 entries; added "(changed in v1.0)" to v0.9 subagent description
- **Temp path reverted to `C:/tmp/qc_sub/`**: `~/.claude/tmp/qc_sub/` is inside the sensitive `~/.claude/` directory, causing Claude Code to prompt for Edit/Write permissions on every temp file write. Reverted to `C:/tmp/qc_sub/` which is outside the protected zone. Affected files: SKILL.md, SKILL_ZH.md, pitfalls.md

## [v1.0] — 2026-03-25

### Changed

- **Subagent dispatch simplified**: removed `consecutive_passes == N - 1` condition in loop mode — subagent now fires on **every pass round**, not just the final round. Eliminates cross-round counter tracking that was error-prone in long contexts.
- **No-shortcut rule for pass rounds**: replaced "brief confirmation suffices" with mandatory re-read from disk + five-dimension assessment + different counterfactual focus area each round. Pass rounds must show genuine re-examination, not copied verdicts.
- **Depth checkpoint rounds**: every 5th round (5, 10, 15) requires a full expanded report regardless of pass streak, counteracting late-round shallow repetition.
- **Round cap raised**: 10 → 15 total rounds, accommodating the increased rigor per round.
- **Canonical subagent prompt template**: fixed verbatim ~55-line template with 4 fill-in fields (`{{TARGET_TYPE}}`, `{{DOMAIN_CONTEXT}}`, `{{TARGET_OVERLAYS}}`, `{{ORIGINAL_FILE_PATH}}`). Main agent must use template verbatim — cannot narrow scope or prioritise dimensions. Includes cross-validation step (subagent reads original file from disk to detect stale temp copies).
- **Anti-downgrade self-check**: explicit self-verification step before writing the counterfactual line — catches silent subagent→inline downgrades.
- **Evolution Protocol timing**: "final round only" → "loop exit round only" (covers both consecutive-pass exit and round-cap exit).

### Token Cost Trade-off

v1.0 deliberately trades token efficiency for review reliability. Every pass round now dispatches a subagent (previously only the final round did), and pass rounds require genuine five-dimension re-examination instead of one-line confirmations. This is a conscious design choice: a QC skill that doesn't reliably execute its own QC is not worth the tokens it saves.

### Patched (2026-03-26) — v1.0.1 (superseded by v1.1.0)

- ~~**Temp path reverted**: subagent temp path changed back from `~/.claude/tmp/qc_sub/` to `C:/tmp/qc_sub/`~~ — **Superseded then re-applied**: v1.1.0 initially kept `~/.claude/tmp/qc_sub/` for portability, but v1.1 Patched (see above) reverted back to `C:/tmp/qc_sub/` after permission prompt issues were confirmed in practice.

## [v0.9] — 2026-03-23

### Patched (2026-03-23) — v0.9.2

- **Loop Mode WNF specification** (Major fix): Added explicit rejected-fix handling — when the user declines a proposed fix, the finding is marked won't-fix (WNF); WNF items are excluded from subsequent severity ratings and tracked in the round status header (e.g., `History: [M, P(1 WNF), P, P]`). Previously this was only an optional pitfalls.md entry, leaving the loop behavior undefined.
- **Emoji override comment on Loop Mode header**: The `🔄 Round X/10 | Passes: Y/N` status header template now carries `<!-- emoji is part of this template's format spec; overrides default no-emoji rule -->`, consistent with the Evolution Proposal template.
- **Emoji override comment in examples.md**: The good-example Evolution Proposal block in `examples.md` now mirrors the SKILL.md template with the override comment on its `🔄 **Proposed Evolution**` line.
- **Rating-aware counterfactual test**: Counterfactual question is now selected by current rating — for Pass/Minor: "would I still find no Critical or Major issues?"; for Major/Critical: "Am I understating severity?". Previous phrasing presupposed a near-Pass state and was unhelpful when the overall rating was already Major or Critical.
- Fixes applied to: `SKILL.md`, `SKILL_ZH.md`, `examples.md` (local and repo).

### Patched (2026-03-23) — v0.9.1

- **Portability fix**: subagent temp path changed from `C:/tmp/qc_sub/` to `~/.claude/tmp/qc_sub/` — previous path failed silently on Linux/Mac
- **Parameter Parsing rewritten**: eliminated self-contradiction between "remaining tokens" and "order-independent"; now explicitly states flag tokens (identified by `--` prefix) are excluded from target/criteria identification regardless of position
- **`--loop [N]` N-consumption rule**: explicit note that a positive integer immediately following `--loop`/`--循环` is consumed as N and not treated as the review target
- **Degradation path expanded**: "tool error, timeout, etc." → "tool error, timeout, unavailable model, etc." — covers the most common failure mode for distributed installs on restricted subscription tiers
- **Write Mechanics header fixed**: `## Entries / 条目` → `## Entries` to match the actual header in the distributable `pitfalls.md`
- **README trigger syntax completed**: added missing `--loop [N]` and `--sub` flags to the syntax example
- **pitfalls.md**: added 4th starter entry — "Instruction-file section header mismatch" `[skill/prompt/file-modification]`

### Added

- **Subagent Counterfactual Mode** (`--sub` / `--子代理`): optional flag that delegates the counterfactual test to a physically isolated subagent (model: opus), providing genuine context isolation instead of inline role-playing. Subagent receives target content + findings via temp files, returns structured JSON (verdict, area_examined, reasoning, severity_adjustments, new_findings). In loop mode, subagent fires only on the final round to save tokens; non-final rounds use inline counterfactual.
- **Dispatch logic with post-subagent recalculation**: if subagent reopens findings, new issues are appended, severity adjustments applied, and overall rating recalculated before the loop continues.
- **Degradation path**: subagent failure falls back to inline counterfactual with `[degraded: inline fallback]` tag in report.
- **Output format source tags**: Counterfactual line now shows `[subagent]`, `[degraded: inline fallback]`, or no tag (inline default).
- Subagent counterfactual examples (confirmed, reopened, anti-pattern) added to `examples.md`.
- New pitfall: "subagent prompt must be fully self-contained" (`[skill/prompt]`).

### Changed

- Parameter Parsing step 1 refactored from single `--loop` scan to order-independent flag list (`--loop`/`--循环`, `--sub`/`--子代理`).

## [v0.8] — 2026-03-22

### Added

- **Loop Mode** (`--loop [N]` / `--循环 [N]`): automated review-fix-review cycle that repeats until N consecutive passes (default 3) or 10 total rounds. Suspends "review only — no auto-fixes" principle during the loop. Target resolved once at invocation; calibration files read once; Evolution Protocol on final round only.
- **Counterfactual Test**: mandatory meta-calibration question for all ratings — "If this exact target were submitted by a stranger for first-time review, would I still find no Critical or Major issues?" Requires specific reasoning (file:line or logic point), not rubber-stamp "Confirmed". Summary template includes `**Counterfactual**:` line with Confirmed/Reopened options (no N/A escape).
- **Adversarial Re-framing** (Loop Mode): in rounds 2+, reviewer adopts stance "This was written by someone else. My job is to find problems, not confirm correctness." Counteracts confirmation bias when reviewing own fixes.
- Counterfactual good/anti-pattern examples added to `examples.md` (standard + Loop Mode pairs).
- Loop mode example added to `examples.md`.

### Changed

- Parameter Parsing step 1 extended to scan for `--loop`/`--循环` flag after target and criteria extraction.
- Key Principles: "Review only — no auto-fixes" now notes loop mode suspension.

## [v0.7] — 2026-03-20

### Added

- **Meta-calibration principle**: New Key Principle — before writing the Summary, re-read all findings and check for severity inflation/deflation bias.
- **3 new Skill/Prompt overlay items**: Degradation path coverage (Major if missing), self-review bias risk (Minor), runtime vs development material boundary (Minor).
- **Tighter auto-detect step 2**: No-argument cascade step 2 now has explicit inclusion criteria (code ≥3 lines, plan ≥5 items, prose ≥5 lines) and exclusion criteria (pure tables, data dumps, tool-status output); uncertain → skip to step 3.

### Changed

- README version updated to v0.7.0, date to 2026-03-20.

## [v0.6] — 2026-03-17 (patched 2026-03-19)

### Patched (2026-03-19)

- **Distributable sanitization**: `set.seed(<personal-seed>)` → `set.seed(7)` in examples (personal seed removed); "checked 11 entries" → "checked N entries" (hardcoded local count → generic placeholder); README date updated to 2026-03-19
- **pitfalls.md repo template**: restored to 2 English-only starter entries; personal entries removed from repo (no-clobber violation incident)

### Patched (2026-03-18)

- **README ability claim narrowed**: "automatically incorporate project rules" → "prioritise if already loaded in context; does not search or load on its own"
- **EN/ZH semantic drift fixed**: SKILL_ZH.md "三步联检规则" → "联动更新规则" to match EN "linked-update rules"
- **Frontmatter description tightened**: added "starts with ---qc" / "以 ---qc 开头" to match body's first-token rule
- **Blast radius boundary clarified**: explicit note that scan does not reach fixed paths outside workspace; encode external deps as pitfalls entries
- **Pitfalls tag system simplified**: mixed-dimension tags (`[config/skill/file-modification]`, `[code/script/R/Python]`) → single-dimension (`[file-modification]`, `[code/R/Python]`); added tag dimension guidance
- **Pitfalls description corrected**: "illustrative defaults" → "starter entries (active during reviews)" across README
- **examples.md Good Example aligned**: removed `(Code)` from Review Target to match template

### Added

- **Evolution Protocol**: post-review self-reflection mechanism that proposes new pitfalls/examples entries when QC encounters scenarios not covered by existing rules. Propose-and-confirm design: skill suggests, user approves before any file is written.
- **Write Mechanics**: specifies append location, provenance comments (`<!-- via: evolution-proposal, YYYY-MM-DD -->`), and semantic overlap detection before writing.
- **Provenance comments** in `pitfalls.md`: optional `<!-- via: -->` trailing comment to distinguish auto-proposed from manually added entries.

### Changed

- Evolution Protocol placed after Key Principles (end of SKILL.md) as a post-review section.
- "When to Propose" uses "pattern worth capturing" instead of "recurring pattern" (single review cannot judge recurrence).

## [v0.5] — 2026-03-17

### Added

- **Skill/Prompt target overlay**: skills and prompts are now a first-class review target type with dedicated checks (trigger logic, description quality, checklist completeness, portability claims)
- **Open Questions section**: ambiguous findings with insufficient evidence are routed to a separate "Open Questions" block instead of being reported as findings
- **Coverage + Target Type + Blast Radius scope declarations**: every report now explicitly states what was reviewed, what type of target it is, and the blast radius boundary
- **Formalized pitfalls tag semantics**: tags like `[code]`, `[writing]`, `[all]` now have documented matching rules and context-relevance filtering
- **Omission-based evidence support**: findings can now cite the *absence* of expected content as evidence (e.g., "Line X defines a function but no corresponding test exists")
- **Evidence-led principle**: all findings must lead with evidence before stating the issue

### Changed

- Portability claims narrowed from "any markdown agent" to "Claude Code primary; other tool-aware agents may use core framework"
- Trigger contract tightened: `---qc` must be first token; code blocks / quotes ignored; spaces in paths require double quotes
- EN/ZH sync standard upgraded from "line-count parity" to "section-by-section semantic equivalence"
- README rewritten with accurate pitfalls description (no longer claims template ships blank)

## [v0.4] — 2026-03-16

### Added

- **Pitfalls mechanism** (引入"错题本"机制): user-supplied domain-specific mistake log (`pitfalls.md`), checked automatically during every QC review
- **Inline severity definitions**: Critical / Major / Minor now have explicit, documented thresholds
- Trigger tag precision matching for pitfalls entries

## [v0.3] — 2026-03-16

### Added

- **Blast Radius Scan**: automatically checks cross-file dependencies when reviewing file modifications (Grep-based import/reference tracing)
- Anti-pattern #4 in `examples.md` (missing blast radius check)

## [v0.2] — 2026-03-15

### Changed

- Evidence requirements added to all findings (no more unsupported claims)
- Output template standardised with structured fields
- First external review by Codex; major quality improvements based on feedback

## [v0.1] — 2026-03-15

### Added

- Initial release: five-dimensional structured review (Correctness, Completeness, Optimality, Consistency, Standards)
- `SKILL.md` (EN) + `SKILL_ZH.md` (ZH) bilingual skill definitions
- `examples.md` for output calibration
- `README.md` with usage guide
