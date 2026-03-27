# Audit Release Checklist

Use this checklist before treating a changed `audit/` package as ready for continued personal use, wider sharing, or repo publication.

This is a maintenance gate, not a runtime authority. If this file conflicts with a canonical runtime source, the canonical runtime source wins.

## Release Gate

Release only when all `Blocker` items pass.

- `Blocker`: must pass before release or live rollout
- `Warning`: should be reviewed before release; can proceed only with an explicit rationale
- `Nice-to-have`: useful polish, not a release gate

## 1. Package Integrity

Severity: `Blocker`

- [ ] The root package still contains:
  - `SKILL.md`
  - `SKILL_ZH.md`
  - `README.md`
  - `pitfalls.md`
  - `release-checklist.md`
  - `audit-self-check-spec.md`
  - `verification-v2.md`
  - `verification-issue-ledger.md`
  - `examples.md`
  - `test-scenarios.md`
- [ ] `goldens/` still contains:
  - `normal-report.md`
  - `richer-normal-report.md`
  - `all-zero-report.md`
  - `partial-report.md`
  - `output-verification-warning.txt`
- [ ] `contracts/` still contains:
  - `maintenance-contracts.tsv`
- [ ] `references/` still contains:
  - `phase-0-planning.md`
  - `phase-1-dispatch.md`
  - `phase-2-merge.md`
  - `degradation-and-limitations.md`
- [ ] `templates/` still contains:
  - `subagent-template.md`
  - `report-template.md`
- [ ] `scripts/` still contains:
  - `audit-self-check.sh`
  - `check-smoke-evidence.sh`
  - `validate-report.sh`
  - `test-golden.sh`
  - `config-check.sh`
  - `config-optimal-values.sh`
  - `config-optimize.sh`
  - `config-restore.sh`
  - `parse-audit-args.py`
- [ ] No placeholder, scaffold, or partial-migration file has been left in the live package.
- [ ] [verification-issue-ledger.md](verification-issue-ledger.md) still preserves the canonical ledger table header with `Severity` and `Status` in the expected positions.
- [ ] Every ledger row still has a non-empty unique `ID`.
- [ ] Every ledger row still uses only allowed `Severity` values:
  - `blocker`
  - `warning`
  - `info`
- [ ] Every ledger row still uses only allowed `Status` values:
  - `open`
  - `recheck`
  - `resolved`
  - `stale`

## 2. Entry-Layer Parity

Severity: `Blocker`

- [ ] [SKILL.md](SKILL.md) frontmatter still uses only `name` and `description`.
- [ ] [SKILL.md](SKILL.md) description still describes when to use the skill, not how the workflow works.
- [ ] [SKILL_ZH.md](SKILL_ZH.md) frontmatter still remains a valid entry-file frontmatter block rather than drifting into ad hoc metadata.
- [ ] [SKILL_ZH.md](SKILL_ZH.md) still describes when to use the Chinese entry reference rather than summarising workflow.
- [ ] [SKILL_ZH.md](SKILL_ZH.md) remains semantically aligned with [SKILL.md](SKILL.md) at the entry-protocol level.
- [ ] The entry layer still clearly covers the supported target families:
  - `paper`
  - `code`
  - `plan`
  - `data`
  - `mixed`
- [ ] The entry layer still exposes the key boundaries:
  - explicit `---audit` trigger only
  - type/file-path priority rule
  - `--focus`
  - `--out`
  - `--lang`
  - `--lite`
  - no-target stop behaviour
  - no-argument recent-deliverable auto-target behaviour
- [ ] The entry layer still preserves ordered support-file loading as a section-scoped contract:
  - `Phase 0 -> references/phase-0-planning.md`
  - `Phase 1 -> references/phase-1-dispatch.md`, then `templates/subagent-template.md`
  - `Phase 2 -> references/phase-2-merge.md`, then `templates/report-template.md`
  - exceptional/degradation branches -> `references/degradation-and-limitations.md`
- [ ] The entry layer still preserves the hard degradation summary expected by the runtime references:
  - normal-path breakage routes to `references/degradation-and-limitations.md`
  - materially important platform-constraint / context-pressure note remains explicit
  - degraded paths must be declared explicitly
  - sequential fallback still lowers and reports the independence guarantee
- [ ] The entry layer still makes it obvious that the skill is `audit only`, not a fix-or-edit workflow.

## 3. Canonical Source Integrity

Severity: `Blocker`

- [ ] [README.md](README.md) still positions itself as a maintenance/orientation document rather than a runtime authority.
- [ ] The `Canonical Source Map` in [README.md](README.md) still matches the real file responsibilities.
- [ ] [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv) still matches the checker-driven canonical-source rows, coverage-checklist items, scenario-heading families, expected example headings, example-order invariants, and verification-ledger header / Severity / Status schema families it claims to own.
- [ ] No runtime-only rule has drifted into README as its sole authoritative home.
- [ ] No template-only rule has drifted into `examples.md` or `test-scenarios.md` as its sole authoritative home.
- [ ] No phase-specific execution rule has been silently copied back into the entry file in a way that creates two competing truth sources.

## 4. Heavyweight Capability Preservation

Severity: `Blocker`

- [ ] The package still preserves the heavyweight architecture rather than collapsing into a lighter review flow.
- [ ] Big-round execution still depends on independent subagents rather than prose-only independence.
- [ ] `model: "opus"` is still required for subagents.
- [ ] D/V cycle semantics are still preserved:
  - discovery and verification remain distinct
  - verification is not quietly turned into a second discovery round
  - stop conditions remain intact
- [ ] Cross-round deduplication and unified numbering remain intact.
- [ ] No-MCP supplement behaviour remains intact.
- [ ] Sequential fallback remains explicit and is not presented as equivalent to normal isolated execution.
- [ ] Merge interruption and partial-report salvage paths remain intact.
- [ ] Final report writeback, readback, and cleanup rules remain intact.

Primary files to inspect:

- [SKILL.md](SKILL.md)
- [phase-1-dispatch.md](references/phase-1-dispatch.md)
- [phase-2-merge.md](references/phase-2-merge.md)
- [degradation-and-limitations.md](references/degradation-and-limitations.md)
- [subagent-template.md](templates/subagent-template.md)

## 5. Template Authority Checks

Severity: `Blocker`

- [ ] [subagent-template.md](templates/subagent-template.md) remains the canonical source for subagent execution behaviour.
- [ ] [report-template.md](templates/report-template.md) remains the canonical source for final report structure.
- [ ] Entry files and README do not re-copy template details in a way that can drift.
- [ ] The subagent template still contains the critical anchors:
  - D/V cycle
  - temp report format
  - incremental write-to-disk rules
  - `R[k] Complete` return summary contract
  - `MCP-Free Tool-Table Variant`
- [ ] The report template still contains the critical anchors:
  - issue list structure
  - summary statistics
  - overall assessment
  - recommended next steps
  - appendix tables

## 6. Script-Layer Integrity

Severity: `Blocker`

- [ ] All runtime and maintenance scripts exist and are non-empty.
- [ ] [config-optimal-values.sh](scripts/config-optimal-values.sh) remains the only prose-independent source of optimal config values.
- [ ] [config-optimal-values.sh](scripts/config-optimal-values.sh) still exports the expected shared contract:
  - `OPTIMAL_MODEL`
  - `OPTIMAL_EFFORT`
  - `OPTIMAL_FAST`
  - `OPTIMAL_THINKING`
  - `SETTINGS_FILE`
  - `BACKUP_FILE`
  - `JQ_BIN`
- [ ] [config-check.sh](scripts/config-check.sh) still exposes the expected output contract:
  - `STATUS: OK`
  - `STATUS: MISMATCH`
  - `MODEL_MISMATCH: true`
  - `DIFF:`
  - `MATCH:`
- [ ] [config-check.sh](scripts/config-check.sh), [config-optimize.sh](scripts/config-optimize.sh), and [config-restore.sh](scripts/config-restore.sh) still bind `_shared` to [config-optimal-values.sh](scripts/config-optimal-values.sh), `source "$_shared"`, and preserve live-code patterns that actually derive runtime values/paths from that shared source rather than hiding hardcoded divergence behind comments or dead code.
- [ ] [config-optimize.sh](scripts/config-optimize.sh) still preserves backup-before-replace semantics and still exposes:
  - `OPTIMIZED:`
  - `BACKUP:`
- [ ] [config-restore.sh](scripts/config-restore.sh) still preserves audit-field restore behaviour and still exposes:
  - `RESTORED:`
  - `SKIP:`
- [ ] [config-restore.sh](scripts/config-restore.sh) still retains its documented fallback branches for:
  - `jq` unavailable
  - current `settings.json` missing or corrupted
- [ ] [audit-self-check.sh](scripts/audit-self-check.sh) still exposes:
  - `Summary`
  - `Findings`
  - `Manual Follow-Ups`
  - exit `0/1/2` semantics consistent with the spec
- [ ] [validate-report.sh](scripts/validate-report.sh) still accepts the intended markdown report-shape families:
  - canonical minimal normal full report
  - explicitly accepted richer full-report variant
  - simplified all-zero report
  - degraded partial report
- [ ] [validate-report.sh](scripts/validate-report.sh) still fails unsupported or weakened report shapes instead of silently accepting them.
- [ ] [check-smoke-evidence.sh](scripts/check-smoke-evidence.sh) still batch-revalidates archived markdown smoke reports via the current [validate-report.sh](scripts/validate-report.sh) boundary, using `reports/` subtrees when present and root-level `*.md` otherwise, and exits `0/1/2` consistently.
- [ ] [test-golden.sh](scripts/test-golden.sh) still validates the committed `goldens/` set and fails when a protected shape boundary drops out of those fixtures.
- [ ] [audit-self-check.sh](scripts/audit-self-check.sh) still guards the degraded-output anchor sections in [degradation-and-limitations.md](references/degradation-and-limitations.md):
  - `Partial Report Output Contract`
  - `Output Verification Warning Contract`
- [ ] [audit-self-check.sh](scripts/audit-self-check.sh) still proves those `0/1/2` semantics behaviourally against:
  - the live package root
  - an intentionally broken temp copy
  - an invocation error on a bad root
- [ ] Those `0/1/2` behavioural proofs still run even when [audit-self-check.sh](scripts/audit-self-check.sh) is invoked with an explicit live `PACKAGE_ROOT` that canonicalizes to the script's own package root, not only when the argument is omitted.
- [ ] README prerequisite notes about Bash-compatible shell and `jq` still match script reality.
- [ ] On Windows, the script layer still supports both `jq` and WinGet-style `jq.exe` discovery without weakening the active-profile Bash boundary.
- [ ] The maintenance guardrail still protects the stricter Windows config-check boundary:
  - Git Bash preference on Windows
  - active Claude profile resolution at `$HOME/.claude/settings.json`
  - explicit `C:/Windows/system32/bash.exe` / foreign-WSL incompatible examples remain documented
  - incompatible `bash` on `PATH` goes to the script-error branch rather than a silent happy path
- [ ] Entry and Phase 0 wording still preserve quoted target-path parsing:
  - quoted target paths with spaces remain single arguments through target identification
  - quoted target paths with spaces remain intact through pre-planning readability checks and target loading
- [ ] The maintenance guardrail still protects the stricter paper verification boundary:
  - PubMed-first paper routing remains explicit
  - original method-source verification remains explicit
  - Brave remains supplementary rather than replacing PubMed/original-source checks
- [ ] The maintenance guardrail still protects the fixed data-analysis and mixed verification routes:
  - dedicated data-analysis verification remains explicit
  - mixed-target issue-bearing-component routing remains explicit
  - dominant-type fallback for ambiguous mixed issues remains explicit
- [ ] No prose file promises script behaviour that the scripts no longer implement.

## 7. Regression Fixture Coverage

Severity: `Blocker`

- [ ] [test-scenarios.md](test-scenarios.md) still covers the minimum regression surface listed in its own `Coverage Checklist`.
- [ ] The maintenance guardrail still protects the fixed non-success summaries and success-only boundary introduced for degraded paths:
  - `AUDIT Partial Report`
  - `Partial Report Path`
  - `AUDIT Output Verification Warning`
  - `Manual Check: Readback failed; verify written outputs manually before trusting completion`
  - `AUDIT Complete` remains success-only
- [ ] The fixture set still covers all five target families:
  - `paper`
  - `code`
  - `plan`
  - `data analysis`
  - `mixed`
- [ ] The fixture set still covers the most failure-prone edges:
  - trigger boundary
  - config OK / mismatch / script anomaly
  - incompatible Windows bash path
  - no-target stop
  - no-argument auto-target
  - quoted target path with spaces
  - MCP unavailable
  - sequential fallback
  - merge interruption
  - final output readback
- [ ] Fixed-line scaffolds that protect drift-prone output remain present:
  - mismatch notice/title and table rows
  - `MODEL_MISMATCH` warning
  - quoted target-path parsing / quote-aware grouping line
  - quoted target-path no-fragment-probe line
  - quoted target-path parse-preflight line
  - planning announcement header block
  - `Target Components` planning field and multi-file/mixed boundary
  - canonical per-file `Target Components` mapping scaffold
  - explicit incompatible-Windows-bash example line
  - planning lines for `Mode Limits`, `Report Language`, `MCP Status`, `Subagent Model`, and `Output Report`
  - `R[k] Complete` return summary
  - final summary fixed labels and the full fixed `Configuration` line
  - key normal-report body lines (metadata block, issue-table scaffold, summary-statistics table header, appendix table headers)
  - key normal-report headings/scaffolds (`# AUDIT Report`, `### R[k] · ...`, `**P-[n]**: ...`, appendix headings and explanatory note)
- [ ] The thin executable harness remains additive rather than authority-blurring:
  - `goldens/normal-report.md` still encodes the canonical full-report shape
  - `goldens/richer-normal-report.md` still encodes an explicitly accepted richer full-report variant rather than an ad hoc shape drift, including the documented richer header-metadata bundle when present
  - `goldens/all-zero-report.md` still encodes the simplified all-zero short-circuit shape
  - `goldens/partial-report.md` still encodes the degraded partial-report shape
  - `goldens/output-verification-warning.txt` still encodes the degraded readback-warning summary shape
  - `goldens/` and the harness scripts do not replace `test-scenarios.md` as the semantic regression fixture
- [ ] Any new behaviour added in this release has either:
  - a matching new scenario or append-stable scenario-family extension in [test-scenarios.md](test-scenarios.md), or
  - a documented reason why a scenario was not added
- [ ] The config-mismatch maintenance fixture still encodes the conditional helper-script boundary:
  - `config-optimize.sh` is only suggested before restart if the user wants a temporary switch for the next audit session
  - `config-restore.sh` is only suggested after the audit if that optimise step was actually applied before restarting into the audit
  - the audit itself still does not require any restore action

## 8. Output Calibration Coverage

Severity: `Warning`

- [ ] [examples.md](examples.md) still covers:
  - a good report shape
  - an over-reporting anti-pattern
  - cross-round dedup presentation
  - no-MCP supplement presentation
  - zero-issue / all-zero presentation
  - D/V cycle distinction
  - tool degradation reporting
  - sequential fallback notice
- [ ] Example outputs do not accidentally teach a weaker or shorter report shape than the canonical template expects.
- [ ] Example 1 still preserves the canonical `---` separator between the metadata block and `## Issue List`.
- [ ] Example outputs do not become a second template authority.

## 9. Smoke-Test Matrix

Severity: `Blocker`

Before release, run at least one fresh-session smoke test for each of the following:

- [ ] `paper`
- [ ] `code`
- [ ] `plan`
- [ ] `data`
- [ ] `mixed`

In addition to target-family coverage, run at least one targeted degraded-path drill:

- [ ] one or more of:
  - MCP unavailable
  - sequential fallback
  - merge interruption / partial-output salvage
  - config-check anomaly or failure path
  - incompatible Windows bash path (`C:/Windows/system32/bash.exe` or foreign WSL bash)

For each smoke test, record:

- [ ] if Claude Code CLI was used for the run, `claude auth status` showed `"loggedIn": true` before the smoke attempt
- [ ] if the non-interactive prompt began with `---audit`, the run used stdin or another non-argv input path instead of a bare prompt argument
- [ ] exact input command
- [ ] resolved target or file path
- [ ] resolved mode / type
- [ ] visible planning announcement or equivalent runtime evidence
- [ ] whether any degradation or fallback path was entered
- [ ] output artefact path or final in-thread output branch

For each smoke test, confirm with observable evidence:

- [ ] the planning announcement explicitly names the resolved target, mode, and big-round plan
- [ ] the announced plan is consistent with the target family and any flags such as `--lite`, `--focus`, or `--lang`
- [ ] any degradation, fallback, or tool-unavailable branch is explicitly disclosed rather than silently absorbed
- [ ] the final output shape matches either the normal report scaffold or the documented all-zero / partial-output exception path
- [ ] at least one concrete artefact from the run can be compared against the relevant canonical source or scenario fixture
- [ ] any archived markdown smoke report being cited as report-shape evidence still passes the current `scripts/validate-report.sh` shape validator, or is explicitly marked stale and excluded from the acceptance decision
- [ ] archived non-markdown or in-thread smoke evidence is reviewed against its own canonical source or fixture rather than being misclassified as something `validate-report.sh` can prove
- [ ] archived markdown smoke reports generated against an older report shape are not silently counted as current release evidence
- [ ] if a CLI smoke attempt failed before the session started because Claude Code was unauthenticated or a leading `---audit` prompt was misparsed as an option, that result is recorded as an operator / harness prerequisite failure rather than a runtime `audit` regression
- [ ] If the direct fresh-session `paper` smoke on a quoted OneDrive absolute path with spaces still collapses to a prefix directory, that result is recorded explicitly as the documented platform limitation rather than being misreported as a normal pass.
- [ ] When that limitation is observed, at least one mitigated `paper` smoke has also been run using either a staged no-space temp path or `audit_object_temp.md`, and both the direct failure and the mitigated result are recorded.

## 10. Packaging And Versioning

Severity: `Warning`

- [ ] [README.md](README.md) version/date metadata still makes sense after the current change.
- [ ] The `What Changed In The Restructure` or later maintenance notes still describe the current package honestly.
- [ ] If this release changes structure or maintenance process, the newly relevant maintenance docs are discoverable from README.

## 11. Final Sign-Off

Severity: `Blocker`

Release only if all three answers are `yes`.

- [ ] This change does not weaken `audit`'s heavyweight review capability.
- [ ] This change does not blur or silently reassign canonical source ownership.
- [ ] This change does not introduce behaviour that lacks fixture coverage or an explicit smoke-test decision.

## Reviewer Note

If a change technically passes the checklist but still feels like it makes the skill softer, more ambiguous, or easier to mis-maintain, treat that as a real release concern. This package is meant to stay heavyweight and product-like, not merely “organised.”
