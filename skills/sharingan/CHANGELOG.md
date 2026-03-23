# Changelog

All notable changes to this project are documented here.
Only version increments of 0.1 or above get their own entry heading.
Dates represent when the version was committed, not when development started.

本文件记录所有重要变更。0.1 及以上的版本增量有独立标题。日期为提交时间，非开发开始时间。

## [v0.7.0] — 2026-03-23

### Added

- **Reference Value Assessment** at EXIT POINTs: even when no config changes are warranted, optionally captures long-term reference value from the source. Creates `ref_*.md` in memory with YAML frontmatter. Suppressed by `--no-ref`.
- `--no-ref` flag added to parameter parsing.
- New pitfall: "Reference Assessment scope creep" (`[all]`).
- Test scenario S-9 (4 variants) covering `--no-ref`, dry-run, irrelevant source, and normal ref creation.

### Patch (v0.7.1)

- Examples.md synced with SKILL.md Phase 6/9 format changes
- Self-review bias note added to QC Sub-Procedure
- Phase 4 dedup: files already read during Phase 3 Pre-filter Verification are not re-read
- Pitfalls entry count references changed to generic phrasing for distributable files

## [v0.5.0] — 2026-03-20

### Changed

- **Major refactor** of the core workflow structure.
- Rule liveness check (S-8): 17 rules checked, 17 live, 0 dead post-refactor.
- New pitfalls from ecosystem hardening: "Pitfall entry freshness" and "Taxonomy rename drift" (`[skills]`).

## [v0.3.0] — 2026-03-18

### Added

- **TDD verification** completed (8/8 scenarios PASS). Full TDD artifacts archived locally.
- **Phase 10 formal 2-pass gate**: "2 consecutive passes, max 4 rounds" — previously the weakest enforcement point.
- **Phase 3 pre-filter verification**: mandatory file read before applying "already implemented" filters.
- **Before Snapshot expansion**: control-flow modifications now capture up to 50 lines (was 10).
- 5 new pitfalls from TDD green-refactor: abort logging, Phase 10 gate (now [FIXED]), QC confirmation bias, Phase 3 pre-read, snapshot narrowness.
- 3 new pitfalls from evolution proposals: state-machine drift, fail-open parser, declaration-execution gap.

### Changed

- Rationalization Table (28 entries) and Red Flags Checklist (22 items) formalised in `references/tdd-summary.md`.

## [v0.1.0] — 2026-03-17

### Added

- Initial release: 10-phase workflow for extracting insights from external resources.
- Dual EXIT POINTs (Phase 3 and Phase 5) normalising "no changes" as legitimate outcome.
- 13-category taxonomy (`taxonomy.md`).
- Security preflight (deny list for credentials, prompt injection detection).
- Inline QC sub-procedure (2 consecutive passes, max 6 rounds).
- Three-check protocol integration.
- `SKILL.md`, `taxonomy.md`, `examples.md`, `pitfalls.md` (7 initial entries).
- `references/`: parameter-parsing, source-handling, edge-cases (14 scenarios), test-scenarios, tdd-summary.
- `--target`, `--auto`, `--dry-run` flags.
- Context management strategy with pressure valve.

---

*Note: versions v0.2, v0.4, and v0.6 involved incremental refinements not individually documented at the time of development. Key changes from those versions are incorporated into the next documented version above.*
