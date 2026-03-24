<!-- Merge reference. -->

# Phase 2 Merge Reference

Normative source for detailed Phase 2 merge behavior in this `audit` skill.

The parent `SKILL.md` must still retain the corresponding hard summaries for:
- merge-phase existence in the workflow skeleton
- output contract linkage to the report template
- report-language runtime rule
- degradation-policy linkage for merge failures

This file defines the normal orchestrator-side merge flow after all subagent batches have returned.

## 2.1 Collect Results

After all subagent batches return, the orchestrator performs the merge.

Collection rules:
- Read each `audit_R[k]_temp.md` temp file.
- Read each subagent return summary.
- Flag failed or incomplete big rounds for later handling under degradation rules.

No-MCP supplement protocol:
- If Phase 0 concluded that subagent MCP was unavailable, the orchestrator supplements tool-based verification during merge.
- For each issue that a subagent marked as `could not verify` due to MCP unavailability:
  - use orchestrator-level tools such as Read, Grep, or Brave Search to attempt verification
  - update `Verification Source` with the supplement result and mark provenance as `[orchestrator-supplemented]`
  - if the issue still cannot be verified, retain it and annotate `Verification Source` as `Unverified (MCP unavailable, orchestrator supplement inconclusive)`
- Do not retract an issue solely because it could not be tool-verified under MCP unavailability.

Tool degradation collection:
- Read the `Tool Degradation` field from each subagent return summary.
- If any subagent reports tool degradation (value other than `None`), aggregate entries by tool name and error type across all subagents, noting which big rounds were affected (e.g., `brave_web_search: 422 ×3 (R1, R3)`).
- Carry the aggregated tool degradation notes to the report header `**Tool Degradation**` field and the final conversation summary.
- If all subagents report `None`, set the aggregate to `None`.

All-zero short-circuit:
- If all big rounds completed successfully, with no failed or incomplete flags, and the total issue count across all big rounds is `0`, skip cross-round deduplication and unified numbering.
- In that case, generate the simplified final report directly in `2.4`.
- The simplified report must still retain:
  - header
  - `Audit complete, no issues found`
  - summary statistics with an all-zero row
  - overall assessment stating that the audit target showed no issues requiring remediation across `[N]` dimensions
- Do not include the appendix in the all-zero short-circuit path.
- If any big round is failed or incomplete, do not short-circuit even when the known issue count is `0`.
- In that case, generate the full report and include incomplete-round warnings.

## 2.2 Cross-Round Dedup

This capability exists because independent big rounds can now discover overlapping issues without seeing each other during execution.

Rules:
- Compare issues from different big rounds pairwise.
- Matching requires the same location plus semantic judgment that the issue is substantively the same.
- Semantic sameness requires all of the following:
  - same text location
  - consistent issue type
  - mergeable fix suggestions
- If only the location matches but the issue types differ, retain them as separate issues.
- After merging, keep the more detailed description.
- Append to `Verification Source`: `R[m]-[i] and R[n]-[j] independently discovered across big rounds (confidence: very high)`.
- The merged issue keeps the higher severity.
- Issues independently discovered across big rounds are marked with `⭐` as a high-confidence indicator.

## 2.3 Unified Numbering

Arrange all retained issues in `R1 -> R2 -> ... -> RN` order and renumber them as `P-1`, `P-2`, ..., `P-[total]`.

Requirements:
- Preserve original intra-round numbers in the number-mapping table.
- Replace all `R[k]-x` references in `Related Issues` fields with the corresponding `P-x` numbers.

## 2.4 Generate Final Report

The orchestrator writes the final report in one complete pass.

Runtime rules:
- Apply report language as a runtime decision:
  - `--lang zh/en` takes priority
  - otherwise auto-match the audit target's language
- Follow `templates/report-template.md` as the canonical structure source for the normal full-report path.
- When cross-round independent discoveries = 0, the `### Cross-Round Independent Discoveries` appendix section must still appear with its table header and a single no-discovery data row: `| None | None | No cross-round independent discoveries occurred in this run. |`. Do not substitute prose or omit the table — `validate-report.sh` requires the table header even when discoveries = 0.
- The all-zero short-circuit path is an explicit simplified-report exception and does not instantiate the full appendix-bearing report structure.
- Write header, issues, summary statistics, and appendix content in a single complete write pass for each output file.
- Do not write the same file incrementally.

Write policy:
- Default output is one report file.
- If the report exceeds the Write tool's output limit, split into:
  - main report: `[name].md`
  - appendix: `[name]_appendix.md`
- Each file must be written in a single Write call.
- Do not perform two sequential writes to the same file, because Write uses overwrite semantics.

Post-write verification:
- Before cleanup, use Read to confirm every written output file exists and is non-empty.
- If the output remained a single file, verify that report file.
- If output was split into `main report + appendix`, verify both files separately.
- If any verification fails, retain temp files and follow the degraded output-warning contract in `references/degradation-and-limitations.md`.
- On readback failure, do not emit the success summary from `2.7`.

## 2.5 Cleanup

After merge completion:
- delete all `audit_R[k]_temp.md` temp files
- if the audit target was in-conversation text, also delete `audit_object_temp.md`

## 2.6 Configuration Note

Phase `0.0` operates in detect-and-guide mode only.

Therefore:
- it does not modify `~/.claude/settings.json`
- no restore action is required by the audit itself
- if the user manually applied `scripts/config-optimize.sh` before restarting into this audit, `scripts/config-restore.sh` remains an optional post-audit user action outside the audit flow
- the merge flow proceeds directly to the final summary

## 2.7 Final Summary

This success summary applies only when final report writing and post-write readback verification both succeed.

Output the following final summary in the conversation. Field labels are fixed, while values adapt to the actual run:

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUDIT Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Big Rounds Executed: R1–R[N] ([B] batches, [N] subagents)
Total Issues: [n] (Critical [a] / Major [b] / Minor [c])
Cross-Round Independent Discoveries: [n] (⭐ high confidence)
Cross-Round Dedup Merges: [n] entries
Tool Degradation: None | [aggregated tool:error ×count (affected rounds)]
Report Path: [path]
Configuration: N/A (detect+guide mode; no settings were modified)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If output was split into `main report + appendix`, the `Report Path` value should surface both paths, for example:
- `[main path] (+ appendix: [appendix path])`
