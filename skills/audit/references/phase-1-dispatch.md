<!-- Dispatch reference. -->

# Phase 1 Dispatch Reference

Normative source for detailed Phase 1 dispatch behavior in this `audit` skill.

The parent `SKILL.md` must still retain the corresponding hard summaries for:
- parallel subagent architecture
- explicit `model: "opus"` requirement
- no-wait continuation into later phases
- high-level workflow skeleton

This file defines how the orchestrator prepares dispatch state, launches batches, reports progress, and binds the subagent template.

## 1.1 Prepare Report Header

The orchestrator prepares the report header metadata in memory.

Hard rule:
- Do not write the final report to disk during Phase 1.
- The final report is written only during Phase 2.

The prepared header metadata may already include:
- audit object / target name
- mode
- domain
- configuration note
- big round theme table
- final output report path

## 1.2 Dispatch Initial Batch

For the first batch, issue all subagent calls in a single message so they execute in parallel.

Pattern:

```text
// Batch 1 — all calls in the same message, executing in parallel
Agent(description: "AUDIT R1/R5: Scientific Accuracy", model: "opus", prompt: [populated subagent template])
Agent(description: "AUDIT R2/R5: Citation Verification", model: "opus", prompt: [populated subagent template])
Agent(description: "AUDIT R3/R5: Statistical Methods",   model: "opus", prompt: [populated subagent template])
...
```

Hard requirements:
- Explicitly specify `model: "opus"` on every subagent call.
- Do not rely on default model inheritance.
- This explicit setting applies regardless of the orchestrator's own model.
- Audit quality takes priority over convenience or inherited defaults.

Conversation output at dispatch time:
- `Batch [b] dispatched: R[k1], R[k2], ... ([n] subagents executing in parallel)`

## 1.3 Dispatch Remaining Batches

After the current batch has fully returned, the orchestrator displays one-line completion summaries for that batch.

Reference format:

```text
Batch 1 Complete:
  R1 · Scientific Accuracy: 3 issues (Critical 1 / Major 1 / Minor 1), 4D+3V, 8 tool calls (0 failed)
  R2 · Citation Verification: 5 issues (Critical 2 / Major 2 / Minor 1), 5D+4V, 15 tool calls (2 failed)
  R3 · Statistical Methods: 2 issues (Major 1 / Minor 1), 3D+2V, 5 tool calls (0 failed)
────────────────────────────────────────
```

Hard requirements:
- Keep the one-line-per-subagent completion structure.
- Wait for all subagents in the current batch before marking that batch complete.
- Each later batch follows the same single-message parallel dispatch pattern as the initial batch.
- If there is another batch, dispatch it immediately after the current batch completes.
- Do not wait for user confirmation between batches.

## 1.4 Progress Display And Temp Report Expectations

The orchestrator displays only the following in the conversation:
- Phase 0 planning summary, including batch plan and MCP status
- batch dispatch notices
- batch completion one-line summaries from each subagent
- merge-phase cross-round dedup results
- final completion summary, including report path

The orchestrator does not display:
- individual D-round progress
- individual V-round progress
- subagent-internal real-time audit traces

This reduced visibility is an intentional trade-off of the parallel architecture.

Temp report expectations for dispatched subagents:
- Every big round is expected to write to its own temp report path, as provided by the bound subagent template.
- The per-round temp report path contract is `[report_dir]/audit_R[k]_temp.md`; Phase 1 must bind a concrete path matching this contract for each big round.
- When multiple audit runs may execute in parallel (e.g., batch smoke via Agent tool), Phase 1 must include a run-unique token in the report directory path or filename (e.g., `[report_dir]/run_[timestamp]/audit_R[k]_temp.md` or `[report_dir]/audit_[pid]_R[k]_temp.md`) to prevent temp-file collisions across concurrent runs. Within a single audit run, each big round already uses a unique R[k] suffix, so no collision occurs. See also `templates/subagent-template.md` § Audit Task for the subagent-facing note on this topic.
- A normally completed `0-issue` big round must still produce a temp report file.
- Phase 1 binds and passes these temp-file expectations to subagents, but the actual write protocol, table format, incremental append behavior, and write-protection rules belong to `templates/subagent-template.md`.
- Phase 2 owns temp-file collection, merge behavior, and cleanup.

## 1.5 Template Binding

The orchestrator populates `templates/subagent-template.md` for each big round and passes the populated text as the `prompt` parameter of the subagent call.

This binding must provide at least:
- big round number
- big round theme
- audit target path list, including per-file role labels such as `main file`, `supplement`, or `code`
- target type
- for mixed targets, the bound dominant type plus secondary type(s), or an equivalent mixed-routing note that lets subagents apply the dominant-type fallback rule without guessing
- domain
- report language
- mode
- D round limit
- sub-round limit
- temp report path

Binding rules:
- Use the standard tool-table variant when MCP is available.
- Use the MCP-free tool-table variant when Phase 0 concluded that subagent MCP is unavailable.
- Keep the subagent template body in `templates/subagent-template.md`; do not duplicate the full template text here.
