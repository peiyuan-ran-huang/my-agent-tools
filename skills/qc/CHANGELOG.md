# Changelog

All notable changes to this project are documented here.
Only version increments of 0.1 or above are recorded; patch-level (0.0.1) changes are omitted.
Dates represent when the version was committed to the repo, not when development started.

本文件记录所有重要变更。仅记录 0.1 及以上的版本增量；0.0.1 级别的修补不记录。
日期为提交至 repo 的时间，非开发开始时间。

## [v0.6] — 2026-03-17 (patched 2026-03-18)

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
