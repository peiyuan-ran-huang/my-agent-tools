# Changelog

All notable changes to this project are documented here.
Only version increments of 0.1 or above get their own entry heading.
Dates represent when the version was committed, not when development started.

本文件记录所有重要变更。0.1 及以上的版本增量有独立标题。日期为提交时间，非开发开始时间。

## [v0.9.0] — 2026-03-28

### Added

- **Leverage Exploration (能力建设借鉴)**: Post-pipeline extension for capability-building proposals. 5 opportunity types (SKILL/TOOL/FLOW/INFRA/ENHANCE), feasibility matrix (Build Now/Plan First/Incubate/Skip), Build Test quality gate, ai-dev-idea-todo.md integration with deduplication.
- `--explore` / `--no-explore` flags for controlling LE activation.
- RVA-LE cross-reference mechanism: bidirectional linking between ref_*.md and LE proposals.
- `references/leverage-exploration.md`: detailed LE framework (opportunity types, feasibility matrix, proposal format, integration rules, anti-bias rules).
- 3 new pitfalls (#23-#25): Opportunity inflation, Config backflow, Build Now threshold (`[le]` tag).
- 2 new examples: LE opportunity proposals + anti-pattern (Opportunity inflation).
- 5 new edge cases covering LE scenarios.
- 2 new test scenarios (S-11, S-12) for LE verification.

### Changed

- Post-pipeline extension note updated to include LE alongside RVA.
- Phase 10 Final Report template gains "Leverage Exploration" line.
- `--dry-run` now terminates main pipeline only; LE can proceed in read-only mode.
- Hard Limits table gains 2 new entries (LE opportunities: 5, todo additions: 3).
- Context Management Strategy gains LE bullet.

### Post-QC Cleanup (2026-03-28)

- `references/source-handling.md`: version string v0.5.0 → v0.9.0; Playwright CLI `goto`/`snapshot` as primary (was MCP); `/tmp/` clone convention simplified; `.git/hooks/` check excludes `.sample` files.
- `pitfalls.md`: added `[le]` to suggested tags in FORMAT comment; updated entries #12 (v0.8.0 counterfactual mitigation note) and #14 (v0.3.0 snapshot expansion note) for freshness.
- `references/test-scenarios.md`: S-8 re-run (23 mechanisms, all live), S-11 PASS (regression), S-12 PASS (regression).

### Post-QC Cleanup Round 2 (2026-03-28)

- `memory/plugin-details.md`: sharingan version v0.8.0 → v0.9.0, description updated with LE features, entry counts (25 pitfalls, 22 edge cases, S-1~S-15+P-1/P-3), leverage-exploration reference added.
- `references/source-handling.md`: 5 WNF design enhancements implemented — remote PDF URL row in tool table; git availability check before clone; symlink check in post-clone scan (step 3); deny-pattern expanded with `*.ps1, *.cmd` for Windows; no-key-files fallback guidance in Read Scope.
- `pitfalls.md`: explicit ordinal numbering `#1`–`#25` added to all entries; FORMAT comment updated to `**#N. Bold title**` pattern.
- `references/test-scenarios.md`: 3 new deferred scenarios (S-13: --no-explore suppression, S-14: LE anti-bias enforcement, S-15: RVA-LE cross-ref isolation) derived from S-8 coverage gaps; S-8 Notes updated to reference S-13/S-14/S-15.
- `SKILL.md`: File Map scenario count 12 → 15 (blast-radius fix from test-scenarios.md S-13/S-14/S-15 addition).
- `references/source-handling.md`: Remote PDF tool corrected from `WebFetch download` to `curl -sLo` (WebFetch returns text, not binary files).
- `README.md`: Files table `references/` description expanded to include `tdd-summary` and `leverage-exploration` (pre-existing gap from v0.5.0/v0.9.0).

### Post-QC Cleanup Round 3 (2026-03-29)

- `references/test-scenarios.md`: S-13 PASS (code-review: --no-explore suppression wiring), S-14 PARTIAL PASS (code-review + opportunistic: anti-bias wiring verified, no rejection in ECC run), S-15 PASS (opportunistic + code-review: RVA-LE content isolation confirmed from ECC run).
- `pitfalls.md`: added #26 (RVA-LE content isolation, `[le]` tag). Total: 26 entries (22 general + 4 `[le]`).
- `memory/plugin-details.md`: pitfall count 25 → 26 (blast-radius fix from #26 addition).
- `references/test-scenarios.md`: S-8 Notes pitfall count 25 → 26 (intra-file blast-radius fix); S-14 Notes "4 opportunities" softened to "all opportunities" (verifiability).

### Post-QC Cleanup Round 4 (2026-03-29)

- `SKILL.md`: line 406 (dry-run path) added inline "Suppressed by `--no-explore`." for consistency with lines 194/342/473 (pre-existing gap from v0.9.0 implementation, surfaced by R2 QC subagent).
- `references/test-scenarios.md`: S-8 Notes "all deferred" → "S-13 PASS, S-14 PARTIAL PASS, S-15 PASS (all verified 2026-03-29)" (historical note updated to reflect current verification status).
- `references/leverage-exploration.md`: Section B Verdict Rules added "Borderline" case guidance (Build Now + risk note for uncertain dependencies, formalized from Session Cost Tracker precedent).

### Post-QC Cleanup Round 5 (2026-03-29)

- `references/leverage-exploration.md`: Section C Dependencies field added Risk sub-field for Borderline risk notes; Section B Maintenance dimension clarified as intentionally informational-only (not factored into verdict rules).
- `references/test-scenarios.md`: S-16 added (Borderline verdict → Build Now + risk note, deferred).
- `SKILL.md`: File Map scenario count 15 → 16.
- `memory/plugin-details.md`: test-scenarios count S-1~S-15 → S-1~S-16 (blast-radius fix from S-16 addition).
- `references/leverage-exploration.md`: Section C Feasibility enum gains Borderline→Build Now display note; Section D verdict-to-section mapping adds Borderline + Skip exclusion (QC subagent: cross-file consistency).
- `SKILL.md`: LE-2 Maintenance clarified as context-only (`+ Maintenance for context`); Final Report template gains `[includes Borderline]` note (QC subagent: SKILL.md/reference alignment).
- `references/leverage-exploration.md`: Build Now verdict rule Dependencies expanded None/Low → None/Low/Med (closes Medium dependencies gap — Medium = "New reference files", internal to ecosystem, no external risk).

## [v0.8.0] — 2026-03-26

### Added

- **Implementation Depth Assessment** (L0/L1/L2): Replaces binary "already implemented" filter with three-level system using two-column comparison across Coverage/Depth/Quality dimensions. "Lowest dimension wins" aggregation. L1 Verification Gate requires file:line + source section evidence.
- **14th taxonomy category: `patterns`**: Transferable design principles and cross-domain techniques. Must name specific application scenario.
- **Non-config Insight Routing**: Pattern-only and user-growth-only insights follow dedicated path through Phase 4-5 with reclassification possibility. Reference-value candidates listed separately.
- **User model consultation** (Phase 2): Reads MEMORY.md User Profile to inform classification scope.
- **Expanded extraction format**: 6 fields (Source, Direct applicability, Transferable pattern, User growth, Depth, Priority) replacing old 3-field format. Anti-laziness rule for "None" fields.
- **Two-sided Counterfactual**: (a) action bias test + (b) source value test with explicit resolution rules. L1 insights not penalized for source-dependency.
- **L1 attrition metric**: Structural check in Phase 5 output against completion bias. Zero attrition = red flag.
- **Enhanced Reference Value Distillation**: 4-step gated process (Essence Extraction → Application Mapping → Conflict & Overlap Scan → Compression Draft) with ≤50-line budget, structured template, and Self-Critique Gate. Trigger expanded to include Phase 10 Final Report.
- Test scenario S-10 (L1 insight passes Phase 3 filter).
- 4 new pitfalls (#19-#22): L2 overconfidence, patterns dumping, L1 inflation, reference compression.
- 3 new examples: L1 depth assessment, L1 full-journey, patterns category anti-pattern.
- 3 new edge cases (pattern-only source, user-growth-only, mixed batch).

### Changed

- **Calibrated Acceptance Principle** replaces "Critical Acceptance": L2 filters confidently, L0/L1 passes forward for deeper evaluation, hard filters remain absolute.
- **Completion bias awareness** note added to QC Sub-Procedure.
- EXIT POINT 1 and 2 templates updated with L-level vocabulary and pattern/growth awareness.
- Phase 4 output restructured into L0/L1/reference-value sections.
- Phase 5 gains Reference-Value Candidates subsection.
- Final Report template gains "Reference Value" line.
- All counterfactual examples in examples.md updated to two-sided format.

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
