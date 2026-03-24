<!-- Report template. -->

# Report Template

This file is the canonical source for final report structure in this `audit` skill.

This file defines report structure only.

- It does not define report-language selection logic.
- It does not define write policy or split-write behavior.
- It does not define failure or degradation handling.

All sections, tables, and field labels below must appear in the final report unless a documented simplified all-zero path explicitly overrides the full structure.

The minimal headers shown below are canonical anchors.

Where this template explicitly says so, a documented richer variant is also acceptable as long as the same core structure and meaning are preserved.

# AUDIT Report

**Audit Target**: [name/path]
**Target Type**: [Paper / Code / Plan / Data Analysis / Mixed (note primary + secondary type)]
**Domain**: [Epidemiology / Bioinformatics / Clinical / Statistics / Other]
**Audit Date**: [YYYY-MM-DD]
**Audit Architecture**: Parallel subagent mode | [B] batches [N] subagents
**Big Rounds Executed**: R1–R[N] ([N] rounds total)
**Total Issues**: [n] (Critical [a] / Major [b] / Minor [c])
**Cross-Round Independent Discoveries**: [n] ⭐
**Model**: [actual model used, if known from session context; omit if unavailable] | Extended thinking: [ON/OFF, if determinable; omit if unavailable]
**Tool Degradation**: None | [tool_name: error_type ×count (affected rounds)]

Allowed richer full-report metadata variant:

- instead of the minimal `**Total Issues**:` line, the header may use `**Total Issues (post-dedup)**: [n] (Critical [a] / Major [b] / Minor [c])`
- when that richer total line is used, it must be accompanied by both `**Pre-dedup Total**: ...` and `**Cross-Round Dedup Merges**: ...`
- `**Cross-Round Independent Discoveries**:` remains required and is not replaced by the richer dedup-accounting lines

---

## Issue List

### R[k] · [big round theme name]

---

**P-[n]**: [short title (≤15 characters)] [⭐ cross-round independent discovery]

| Field | Content |
|-------|---------|
| Category | R[k] · [theme name] |
| Severity | 🔴 Critical / 🟡 Major / ⚪ Minor |
| Location | [section/line number/paragraph opening/variable name — precise locator] |
| Issue Description | [detailed description explaining why this constitutes an issue] |
| Verification Source | [tool call result / in-text cross-reference / logical inference] |
| Related Issues | [P-x: relation description / None] |
| Potential Impact | [specific impact on the paper/code/plan/data analysis/mixed target if left unfixed] |
| AI Preliminary Suggestion | [specific, actionable fix suggestion] |
| User Response | _(to be filled)_ |

---

[Repeat below; one entry per P-n]

---

## Summary Statistics

| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |
|-----------|-------|----------|-------|-------|------------|------------|
| R1        | ...   | [n]      | [n]   | [n]   | [d]D+[v]V  | [n]        |
| ...       |       |          |       |       |            |            |
| Total     |       | [n]      | [n]   | [n]   |            | [n]        |

Allowed richer full-report variant:

- the table may insert `Total (pre-dedup)` between `Minor` and `D/V Rounds`
- the totals block may distinguish `Pre-dedup Total` and `Post-dedup Total`

## Overall Assessment

[3–5 sentences synthesizing findings from all big rounds, providing an overall quality judgment of the target and identifying the most critical areas for improvement]

## Recommended Next Steps

1. [Critical issue remediation suggestions, by priority]
2. ...

---

## Appendix

### Number Mapping Table

| Final Number | Original Number | Big Round Theme |
|--------------|-----------------|-----------------|
| P-1          | R1-1            | ...             |
| P-2          | R1-2            | ...             |
| P-3 ⭐       | R1-3 + R3-2     | Cross-round merge |
| ...          | ...             | ...             |

> Original numbers are listed in ascending R order (R1 before R2, etc.) within each merged entry.

Allowed richer full-report variants:

- the richer appendix header may use `| Final Number | Original Number(s) | Big Round Theme | Notes |` when a row maps to multiple original identifiers and the extra notes column improves merge traceability
- the appendix note may also use the concise form `> Original numbers listed in ascending R order within each merged entry.`

### Cross-Round Independent Discoveries

| Issue | Source | Explanation |
|-------|--------|-------------|
| P-[n] ⭐ | R[m]-[i] + R[n]-[j] | Two independent big rounds discovered the same issue from different perspectives |

When cross-round independent discoveries = 0, use this zero-discovery variant instead of prose:

| Issue | Sources | Explanation |
|-------|---------|-------------|
| None | None | No cross-round independent discoveries occurred in this run. |

Allowed richer full-report variant:

- `Source` may appear as `Sources` when the table cell lists multiple contributing round-local identifiers
