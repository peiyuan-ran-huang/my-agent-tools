# Test Scenarios

This file is a maintenance regression fixture for the `audit` skill.

It is **not** a runtime rule file.

Use it to verify that structural edits did not silently weaken behavior.

Scenario IDs are stable maintenance labels, not a globally sorted taxonomy. Inserted scenarios may therefore appear out of numeric order when preserving existing references is safer than renumbering the whole fixture.

Recommended use:

- choose a scenario
- identify the canonical files that should carry the behavior
- verify that each required behavior still has an explicit home
- treat any missing invariant as a regression until proven otherwise

---

## T1. Config OK

### Scenario

The configuration check script returns `STATUS: OK`.

### Input

```text
---audit paper manuscript.md
```

### Preconditions

- `scripts/config-check.sh` exists
- the script is executed in a compatible bash environment where `jq` is installed and `$HOME/.claude/settings.json` resolves to the active Claude profile
- `scripts/config-check.sh` returns `STATUS: OK`
- no script anomaly or stderr-triggering fallback path is active

### Expected Behavior

- Phase 0 runs the config check before normal planning
- no mismatch notice is shown
- the planning announcement carries `Configuration: OK (no changes needed)`
- audit proceeds directly into target analysis and planning

### Must-Preserve Invariants

- config checking still happens at audit start
- `STATUS: OK` remains a silent continue path
- no mid-session settings modification occurs

### Common Failure Modes

- skipping config check entirely
- treating an incompatible bash environment as a normal `STATUS: OK` path
- showing a mismatch notice even though status is `OK`
- treating `OK` as a reason to rewrite settings

---

## T1b. Trigger Boundary

Tests explicit `---audit` (case-insensitive) activates; natural-language does not. **Owner**: `SKILL.md` entry-parsing. **Invariant**: activation is explicit-trigger only.

## T2. Config Mismatch

Tests `STATUS: MISMATCH` produces detect-and-guide notice (fixed title/table/cached-settings semantics, `MODEL_MISMATCH` branch) without blocking or auto-modifying. **Owner**: `SKILL.md` Phase 0 config-check. **Invariant**: mismatch is informational, not blocking; fixed notice lines remain canonical.

## T2b. No Target Stop

Tests `---audit` with no identifiable target stops and prompts user. **Owner**: `SKILL.md` Phase 0 target-identification. **Invariant**: "no identifiable target" is a stop-and-prompt boundary.

## T2c. Config Check Script Error Or Anomalous Output

Tests script-error/anomalous-output/incompatible-Windows-bash fallback: non-zero exit or missing `STATUS:` triggers "skip and continue", not mismatch. **Owner**: `SKILL.md` Phase 0 config-check, `scripts/config-check.sh`. **Invariant**: script error distinct from mismatch; incompatible Windows bash is script-error fallback.

## T2d. No-Argument Recent Deliverable Auto-Target

Tests `---audit` without arguments auto-targets most recent substantive deliverable (materializing to `audit_object_temp.md` if needed). **Owner**: `SKILL.md` Phase 0 target-identification. **Invariant**: no-argument positive path distinct from no-target stop path.

## T2e. Phase 0 Output Path Planning

Tests default output-path derivation, overwrite avoidance (`_2`, `_3`), `{report_dir}` creation, and OneDrive warning. **Owner**: `SKILL.md` Phase 0 output-path. **Invariant**: overwrite avoidance is Phase 0 responsibility.

## T2f. Planning Announcement Continuation Boundary

Tests fixed-structure planning announcement (all canonical fields) emitted then proceeds directly to Phase 1 without pausing. **Owner**: `SKILL.md` Phase 0 planning-announcement. **Invariant**: announcement is informational, not a stop point.

## T2g. Phase 0 Batching And Runtime Caps

Tests standard-mode (`3-8` rounds, `<=5`/batch, `<=2` batches) and lite-mode (`2-4` rounds, single batch) including minimum-floor enforcement. **Owner**: `SKILL.md` Phase 0 batching. **Invariant**: round caps are runtime boundaries, not soft suggestions.

## T2h. Merge-Phase Context-Pressure Recommendation

Tests `>=6` rounds or large target triggers Context Mode MCP recommendation before heavy merge. **Owner**: `SKILL.md` Phase 0 planning. **Invariant**: recommendation tied to merge-phase context pressure.

## T2i. Large-Target Planning Strategy

Tests target-type-specific core-section prioritization for large files with deferred segmented reading. **Owner**: `SKILL.md` Phase 0 large-target planning. **Invariant**: large-target planning is explicit and target-type-specific.

## T2j. Phase 0 Target Loading Before Planning

Tests Phase 0 reads target thoroughly (complete pass) before theme planning. **Owner**: `SKILL.md` Phase 0 target-loading. **Invariant**: target loading is prerequisite for planning.

## T3. Single-File Code Audit

Tests code-target recognition, parallel dispatch, D1 LSP pre-scan (silent skip if unavailable), language-aware verification (R/Python: LSP+Grep; others: Grep-only). **Owner**: `SKILL.md` Phase 0 type-routing, `subagent-prompt.md`. **Invariant**: D/V cycle intact; LSP pre-scan D1-only; verification split is language-aware.

## T3b. Ambiguous First Token Priority

Tests first token as both type keyword and existing file path: file-path interpretation wins. **Owner**: `SKILL.md` parameter-parsing. **Invariant**: ambiguous first-token is file-path first.

## T3c. Quoted Target Path With Spaces

Tests quoted OneDrive-style path with spaces preserved as single target via quote-aware grouping and deterministic helper parser. Verifies: the quoted target path remains one target argument instead of being split into multiple tokens; quote-aware grouping happens before type-vs-path heuristics, so the full quoted OneDrive-style path is captured as the single post-type target argument; the exact raw substring inside the quotes remains the authoritative target path instead of being rewritten to a shorter existing prefix directory; fragmentary probes such as `C:/Users/jdoe/OneDrive` are not treated as candidate targets when the full quoted path is available; a short parse preflight line is emitted before target validation so the preserved `type / target / out` values are visible; if a fresh-session runtime still rewrites the quoted path to a prefix directory after the mandatory helper plus parse-preflight flow, classify that result as a documented platform limitation and switch to a documented mitigation such as a no-space staged path or `audit_object_temp.md` rather than weakening this contract. Common failure mode: treating `C:/Windows/system32/bash.exe` or a foreign WSL bash as a normal config-check success path. **Owner**: `SKILL.md` parameter-parsing. **Invariant**: quoted paths with spaces remain valid single-target inputs.

## T3d. Unreadable Target-File Branch

Tests partial unreadability (skip, continue on remaining) vs. total unreadability (abort big round). **Owner**: `subagent-prompt.md` target-loading. **Invariant**: partial = continue; total = abort.

## T3e. Big-Round Physical Isolation

Tests parallel big rounds run in separate subagent contexts; cross-round comparison only at orchestrator merge. **Owner**: `SKILL.md` Phase 1 dispatch. **Invariant**: physical isolation is primary independence guarantee.

## T3f. Phase 1 Dispatch Contract

Tests batch-level parallel launch, explicit `model: "opus"`, fixed batch-dispatch/completion notices, no-confirmation inter-batch handoff, bound subagent fields, temp-path binding, MCP template-variant selection, multi-file role-labels, visible-progress limits, Phase 1 header preparation. **Owner**: `SKILL.md` Phase 1, `subagent-prompt.md`. **Invariant**: true batch-level parallel; final report writing is Phase 2.

## T4. Paper Audit

Tests paper-target theme selection, tool-first citation verification (PubMed mandatory, Brave supplementary), original-method/source verification, `academic-workflow.md` conditional reference (applied when the file or equivalent rules exist in context). **Owner**: `SKILL.md` Phase 0 type-routing, `subagent-prompt.md` verification. **Invariant**: PubMed-backed citation verification mandatory; `could not verify` is fallback. PubMed-backed citation verification remains mandatory for paper claims even when Brave Search or Brave LLM context search is used for supplementary cross-checks. Also, original method-source verification remains distinct from general paper fact-checking rather than collapsing into a single vague web-search path.

## T4b. Lite Mode Critical Verification Boundary

Tests `--lite` preserves critical checks (citation authenticity, numerical consistency) for paper targets. **Owner**: `SKILL.md` lite-mode. **Invariant**: `--lite` compresses effort, not critical verification.

## T4c. Lite Mode Code Security Boundary

Tests `--lite` on code preserves security-critical verification. **Owner**: `SKILL.md` lite-mode. **Invariant**: lite mode must not weaken code security verification.

## T4d. Intra-Round Parallel Tool Invocation

Tests multiple independent tool calls within a single D/V round may execute in parallel. **Owner**: `subagent-prompt.md` tool-usage. **Invariant**: intra-round parallel tool invocation is allowed.

## T5. Mixed Audit

Tests mixed-target routing: primary type table + secondary overlay, `Target Components`, explicit dominant/secondary binding, component-aware V-round verification, dominant-type fallback for ambiguous ownership. The planning phase surfaces canonical per-file mapping lines of the form `- [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...`. Also, mixed-target verification remains component-aware rather than collapsing to one generic or arbitrary verification rule. **Owner**: `SKILL.md` Phase 0 mixed-target. **Invariant**: mixed-mode routing is explicit; verification is component-aware.

## T5b. Focus Overflow Priority

Tests `--focus` topics retained first when total rounds exceed mode cap. **Owner**: `SKILL.md` Phase 0 theme-selection. **Invariant**: `--focus` overflow priority is user-first.

## T5c. In-Conversation Target Lifecycle

Tests materialization to `{report_dir}/audit_object_temp.md`, subagent receives temp-file path, cleanup after merge, large-content warning. **Owner**: `SKILL.md` Phase 0 target-materialization. **Invariant**: in-conversation targets materialized before dispatch; cleanup removes temp file.

## T5d. Research Plan Audit

Tests `plan` as first-class target type with own theme table and `web search verification` V-round path, distinct from paper. **Owner**: `SKILL.md` Phase 0 type-routing. **Invariant**: `plan` has distinct routing and verification.

## T5e. Data Analysis Audit

Tests `data analysis` as first-class target type with own theme table and dedicated V-round path (Grep + Brave Search), distinct from paper/code. V rounds use the dedicated data-analysis verification path: local consistency checks via `Grep`, plus `Brave Search` for external statistical, methodological, or standards verification. **Owner**: `SKILL.md` Phase 0 type-routing. **Invariant**: `data analysis` has distinct routing and verification.

## T6. Zero-Issue Big Round

Tests zero-issue temp-file shape, merge interpretation (successful not failed), simplified all-zero report, D1-no-issue skip to D2, two-consecutive-empty-D stop, guard against all-zero short-circuit when rounds are failed/incomplete. **Owner**: `subagent-prompt.md` stop-conditions, `SKILL.md` Phase 2 merge. **Invariant**: zero-issue rounds not treated as crash; all-zero short-circuit only when all rounds complete.

## T6b. D/V Edge-Case Branches

Tests D/V fixed completion lines, per-D fresh rereads, D3+ segmented reading, context-exhaustion interruption note, final-V overflow handling (annotation, severity escalation, already-Critical guard). **Owner**: `subagent-prompt.md` D/V cycle. **Invariant**: completion lines canonical; final-V overflow is explicit exceptional branch.

## T6c. Per-Big-Round Execution Limits

Tests standard (`D=7`, `D+V=14`) and lite (`D=3`, `D+V=6`) per-big-round caps as hard boundaries. **Owner**: `subagent-prompt.md` execution-limits. **Invariant**: caps are execution boundaries, not soft suggestions.

## T7. MCP Unavailable

Tests Phase 0 MCP failure produces fixed planning note, downgraded tool availability, orchestrator no-MCP supplement, and `Unverified (MCP unavailable, orchestrator supplement inconclusive)` annotation. **Owner**: `SKILL.md` Phase 0 MCP-check, Phase 2 no-MCP supplement. **Invariant**: no-MCP does not silently disappear; fixed planning note and annotation remain canonical.

## T7b. MCP Verification First-Use-Only

Tests repeated MCP verification skipped within same session. **Owner**: `SKILL.md` Phase 0 MCP-check. **Invariant**: MCP verification is first-use-only.

## T8. Sequential Fallback

Tests degradation at `>=50%` first-batch failure: fixed degradation note, reduced independence warning, clearing protocol with separator, auto-downgrade to lite-mode (max 4 rounds), retention of successful results, `--focus`/list-order priority, same tool list, same 9-field format, target-only rereading. **Owner**: `SKILL.md` sequential-fallback. **Invariant**: sequential fallback is a downgrade; trigger is `>=50%` first-batch failure.

## T8b. Temp Report Incremental Write Protection

Tests read-append-write for temp reports; write-anomaly triggers fixed note; unwritten issues retained in canonical draft-line format. **Owner**: `subagent-prompt.md` temp-report writing. **Invariant**: write-anomaly protection is explicit.

## T8c. Temp Report 9-Field Completeness

Tests every issue entry uses full 9-field table (Category through User Response) with fixed scaffold. **Owner**: `subagent-prompt.md` issue-table. **Invariant**: 9-field structure is canonical; no field silently omitted.

## T8d. Subagent Return Summary Contract

Tests canonical structured summary: `R[k] Complete · [theme]`, Issues (severity breakdown), D/V Rounds, Tool Calls (with failed count), Tool Degradation, Temp File. **Owner**: `subagent-prompt.md` return-summary. **Invariant**: return-summary is machine-checkable; `Temp File` part of contract.

## T8e. Partial Report Salvage Paths

Tests merge-interruption and non-first-batch all-fail: partial report with fixed header `# AUDIT Partial Report`, fixed metadata lines, temp-file retention, degraded conversation summary with fixed labels. **Owner**: `SKILL.md` Phase 2 degradation. **Invariant**: salvage mandatory when recoverable work exists; degraded output distinct from `AUDIT Complete`.

## T8f. Subagent Retry And Temp-File Failure Handling

Tests single retry on timeout/crash, fixed retry-failure note, missing-temp-file as failure, incomplete-temp-file retained with warning. **Owner**: `SKILL.md` Phase 1 retry. **Invariant**: retry capped at one; temp-file missing and incomplete are distinct branches.

## T8g. Intra-Big-Round Deduplication

Tests subagent-side dedup after D/V: merge overlapping location+issue-type duplicates, append fixed independent-discovery note to Verification Source, rewrite temp report. **Owner**: `subagent-prompt.md` intra-round dedup. **Invariant**: intra-big-round dedup separate from cross-round orchestrator dedup.

## T9. Report Language Decision

Tests `--lang` priority over target-language auto-match. **Owner**: `SKILL.md` Phase 0 language-selection. **Invariant**: explicit language selection has priority.

## T10. Final Output Readback And Split Output

Tests single-file and split-output (`[name].md` + `[name]_appendix.md`) write-then-readback, single complete write per file, both paths in summary, failed-readback handling. **Owner**: `SKILL.md` Phase 2 output-verification. **Invariant**: post-write verification mandatory; readback failure is non-success.

## T10b. Normal Full-Report Structure And Cleanup

Tests standard full-report contract: canonical headings, fixed header metadata, full 9-field issue entries under `### R[k] · [theme]` groups, summary/appendix tables, post-success temp-file cleanup. Verifies: the header metadata block keeps the fixed lines `**Audit Target**: [name/path]`; final issue entries keep the fixed field rows `| Category | R[k] · [theme name] |`; the `Configuration` line uses the fixed format `Configuration: N/A (detect+guide mode; no settings were modified)`. **Owner**: `SKILL.md` Phase 2 report-writing. **Invariant**: canonical headings, metadata, and issue scaffold remain fixed.

## T10c. Final Summary Contract

Tests fixed conversation summary: `AUDIT Complete`, `Big Rounds Executed`, `Total Issues`, `Cross-Round Independent Discoveries` (`⭐ high confidence`), `Cross-Round Dedup Merges`, `Report Path`, `Configuration: N/A (detect+guide mode; no settings were modified)`. **Owner**: `SKILL.md` Phase 2 final-summary. **Invariant**: labels and line formats fixed; `AUDIT Complete` is success-only.

## T11. Cross-Round Dedup And Unified Numbering

Tests cross-round semantic dedup (not location-only), higher severity + more detail kept, fixed cross-round annotation in Verification Source, `⭐` marking, `R[k]-x` to `P-x` renumbering, Related Issues rewrite, number mapping table, same-location-different-type non-merge guard. **Owner**: `SKILL.md` Phase 2 merge/dedup. **Invariant**: cross-round dedup is semantic; `⭐` reserved for independent cross-round discovery.

---

## Fixed-Line Fixtures

The following canonical literals must appear in this file for `audit-self-check.sh` fixture verification (T001-T050). Each line is an exact string the checker expects via `grep -F`.

<!-- T001 --> ℹ️ Configuration Check: Current settings differ from AUDIT optimal configuration
<!-- T002 --> | Setting | Current Value | AUDIT Optimal Value |
<!-- T003 --> ⚠️ Current model is not Opus. Subagents are explicitly set to `model: "opus"` and will use Opus regardless. The orchestrator model cannot be changed mid-session; restart the session if you need the orchestrator on Opus too.
<!-- T004 --> Target: [target name/type]
<!-- T005 --> Mode: [Paper / Code / Plan / Data Analysis / Mixed (note primary + secondary type)]
<!-- T006 --> Domain: [identified domain]
<!-- T007 --> Target Components: [omit for single-file targets; required for multi-file or mixed targets]
<!-- T008 --> - [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...
<!-- T009 --> Big Round Plan:
<!-- T010 --> Mode Limits: [Standard / Lite (4 rounds/3D)]
<!-- T011 --> Report Language: [zh / en / auto]
<!-- T012 --> MCP Status: [Available / ⚠️ Unavailable]
<!-- T013 --> Subagent Model: opus (explicitly specified)
<!-- T014 --> Output Report: [path]
<!-- T015 --> `Target Components` remains omitted for single-file targets but mandatory for multi-file and `mixed` targets
<!-- T016 --> - when the helper scripts are exposed, the planning layer may recommend `scripts/config-optimize.sh` before restart only if the user wants to temporarily switch settings for the next audit session
<!-- T017 --> - when the helper scripts are exposed, the planning layer may recommend `scripts/config-restore.sh` after the audit only if the user previously applied `scripts/config-optimize.sh` before restarting into the audit
<!-- T018 --> - the audit itself still does not require any restore action; `scripts/config-restore.sh` remains an optional post-audit user action outside the audit flow
<!-- T019 --> R[k] Complete · [theme name]
<!-- T020 --> AUDIT Partial Report
<!-- T021 --> Completed Big Rounds
<!-- T022 --> Incomplete Big Rounds
<!-- T023 --> Partial Report Path
<!-- T024 --> Retained Temp Files
<!-- T025 --> Next Action: Manual follow-up required before trusting audit completeness
<!-- T026 --> AUDIT Output Verification Warning
<!-- T027 --> Manual Check: Readback failed; verify written outputs manually before trusting completion
<!-- T028 --> AUDIT Complete
<!-- T029 --> Big Rounds Executed
<!-- T030 --> Total Issues
<!-- T031 --> Cross-Round Independent Discoveries
<!-- T032 --> Cross-Round Dedup Merges
<!-- T033 --> Report Path
<!-- T034 --> Configuration
<!-- T035 --> Configuration: N/A (detect+guide mode; no settings were modified)
<!-- T036 --> **Audit Target**: [name/path]
<!-- T037 --> **Model**: [actual model used, if known from session context; omit if unavailable] | Extended thinking: [ON/OFF, if determinable; omit if unavailable]
<!-- T038 --> # AUDIT Report
<!-- T039 --> ### R[k] · [big round theme name]
<!-- T040 --> **P-[n]**: [short title (≤15 characters)] [⭐ cross-round independent discovery]
<!-- T041 --> | Field | Content |
<!-- T042 --> | Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |
<!-- T043 --> | Final Number | Original Number | Big Round Theme |
<!-- T044 --> | Issue | Source | Explanation |
<!-- T045 --> ### Number Mapping Table
<!-- T046 --> ### Cross-Round Independent Discoveries
<!-- T047 --> > Original numbers are listed in ascending R order (R1 before R2, etc.) within each merged entry.
<!-- T048 --> `AUDIT Complete` remains success-only and must not be reused for degraded partial-report or readback-warning branches
<!-- T049 --> R[m]-[i] and R[n]-[j] independently discovered across big rounds (confidence: very high)
<!-- T050 --> | Issue | Sources | Explanation |

---

## Coverage Checklist

These scenarios are the minimum regression surface for this skill:

- config `OK`
- trigger boundary
- config `MISMATCH`
- config script error / anomalous output
- incompatible Windows bash path
- no-target stop
- no-argument recent-deliverable auto-target
- Phase 0 output-path planning
- planning-announcement continuation boundary
- Phase 0 batching and runtime caps
- merge-phase context-pressure recommendation
- large-target planning strategy
- Phase 0 target loading before planning
- single-file code audit
- quoted target path with spaces
- ambiguous first-token file-path priority
- unreadable target-file handling
- big-round physical isolation
- Phase 1 dispatch contract
- paper audit
- intra-round parallel tool invocation
- lite-mode critical verification boundary
- lite-mode code security boundary
- mixed audit
- research plan audit
- data analysis audit
- in-conversation target lifecycle
- `--focus` overflow priority
- zero-issue big round
- D/V edge-case branches
- per-big-round execution limits
- MCP unavailable
- MCP verification first-use-only / same-session skip
- sequential fallback
- standard-to-lite fallback downgrade transition
- temp report incremental write protection
- temp report 9-field completeness
- subagent return-summary contract
- partial-report salvage paths
- subagent retry and temp-file failure handling
- intra-big-round deduplication
- report language decision
- final output readback and split-output verification
- normal full-report structure and successful temp cleanup
- final summary contract
- cross-round dedup and unified numbering
- cross-round non-merge guard for same-location different-issue findings

If one of these scenarios no longer has an explicit behavior home, the skill should be treated as incomplete.
