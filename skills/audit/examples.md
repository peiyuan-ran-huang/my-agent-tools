# Examples

This file is for output calibration and maintenance training.

It is **not** a canonical rule file.

- Final report structure is defined by `templates/report-template.md`.
- Merge behavior is defined by `references/phase-2-merge.md`.
- Failure and degradation behavior is defined by `references/degradation-and-limitations.md`.

Use this file selectively when calibrating output quality or reviewing whether a change has made the audit style too loose or too aggressive.

---

## Example 1: Good Report Excerpt

What “good” looks like:

- complete header
- precise locator
- verification source grounded in actual evidence
- actionable suggestion
- severity proportionate to impact

```markdown
# AUDIT Report

**Audit Target**: analysis/manuscript.md
**Target Type**: Paper
**Domain**: Epidemiology
**Audit Date**: 2026-03-20
**Audit Architecture**: Parallel subagent mode | 1 batches 3 subagents
**Big Rounds Executed**: R1–R3 (3 rounds total)
**Total Issues**: 2 (Critical 0 / Major 1 / Minor 1)
**Cross-Round Independent Discoveries**: 0 ⭐
**Model**: claude-opus-4-6 | Extended thinking: ON
**Tool Degradation**: None

---

## Issue List

### R2 · Citation and Literature Verification

---

**P-1**: PMID mismatch

| Field | Content |
|-------|---------|
| Category | R2 · Citation and Literature Verification |
| Severity | 🟡 Major |
| Location | Methods, paragraph opening “We followed Smith et al. (2021)…” |
| Issue Description | The cited article metadata does not match the study design claimed in text. The PMID linked in the references points to a review, not the cohort study described here. |
| Verification Source | PubMed search for title + first author + year returned PMID 12345678 as a review article; manuscript claim requires an original cohort study. |
| Related Issues | None |
| Potential Impact | Readers cannot verify the methodological precedent, and the methods section may appear to overstate evidential grounding. |
| AI Preliminary Suggestion | Re-check the cited PMID and replace it with the original cohort-study source, then update the in-text claim to match that source exactly. |
| User Response | _(to be filled)_ |
```

Why this is good:

- `Location` is exact enough to find immediately.
- `Verification Source` states what was checked and what was found.
- `Potential Impact` explains why the issue matters.
- The suggestion is concrete, not generic.

---

## Example 2: Over-Reporting Anti-Pattern

This is the kind of output the skill should avoid.

### Bad

```markdown
**P-4**: Weak wording

| Field | Content |
|-------|---------|
| Category | R5 · Writing Quality |
| Severity | 🟡 Major |
| Location | Discussion |
| Issue Description | The writing feels a bit flat and could be more elegant. |
| Verification Source | Verified. |
| Related Issues | None |
| Potential Impact | The paper quality is seriously compromised. |
| AI Preliminary Suggestion | Improve the writing. |
| User Response | _(to be filled)_ |
```

Why this is bad:

- stylistic preference is inflated to `Major`
- `Location` is too vague
- `Verification Source` is content-free
- `Potential Impact` is exaggerated
- suggestion is non-actionable

### Better handling

```markdown
Omit entirely unless the wording causes a real interpretive problem.
If retained, downgrade to Minor and tie it to a specific sentence-level ambiguity.
```

Calibration rule:

- Do not elevate mere style preference into Major or Critical.
- Do not claim a check was “verified” unless the verification path is actually described.

---

## Example 3: Cross-Round Dedup With Star

This example shows what happens when two independent big rounds discover the same issue.

### Before merge

```markdown
R1-2:
- Location: Results Table 2, row “Adjusted HR”
- Issue: confidence interval excludes the reported point estimate

R3-1:
- Location: Results Table 2, adjusted hazard ratio row
- Issue: numeric inconsistency between HR and 95% CI
```

### After merge

```markdown
**P-3**: HR-CI mismatch ⭐

| Field | Content |
|-------|---------|
| Category | R1 · Numerical Internal Consistency |
| Severity | 🟡 Major |
| Location | Results Table 2, row “Adjusted HR” |
| Issue Description | The reported hazard ratio falls outside its own 95% confidence interval. Two independent big rounds identified the same numeric inconsistency. |
| Verification Source | Table value cross-check; R1-2 and R3-1 independently discovered across big rounds (confidence: very high). |
| Related Issues | None |
| Potential Impact | This undermines trust in the reported effect estimate and may indicate a table transcription or computation error. |
| AI Preliminary Suggestion | Recompute the adjusted HR and CI from the analysis output, then update Table 2 and any downstream text that cites the value. |
| User Response | _(to be filled)_ |
```

### Number Mapping Table row

```markdown
| Final Number | Original Number | Big Round Theme |
|--------------|-----------------|-----------------|
| P-3 ⭐       | R1-2 + R3-1     | Cross-round merge |
```

Also acceptable as a richer full-report variant:

```markdown
| Final Number | Original Number(s) | Big Round Theme | Notes |
|--------------|--------------------|-----------------|-------|
| P-3 ⭐       | R1-2 + R3-1        | Cross-round merge | Numeric inconsistency retained from the more detailed copy |
```

Calibration rule:

- only add `⭐` when the same substantive issue was independently found across big rounds
- do not use `⭐` for duplicates found only within one big round
- richer appendix tables are acceptable only when they preserve the same canonical appendix sections and core meaning
- richer header metadata is acceptable only in the documented bundle: `**Total Issues (post-dedup)**:` plus both `**Pre-dedup Total**:` and `**Cross-Round Dedup Merges**:`; ad hoc extra header fields are not part of the accepted contract

---

## Example 4: no-MCP Supplement

This example shows correct provenance when subagents could not verify something because MCP was unavailable.

### Subagent-side issue

```markdown
| Verification Source | could not verify (MCP unavailable during subagent execution) |
```

### Orchestrator supplement during merge

```markdown
| Verification Source | Brave Search result for package release notes confirms the cited version was never published as claimed. [orchestrator-supplemented] |
```

If the supplement remains inconclusive:

```markdown
| Verification Source | Unverified (MCP unavailable, orchestrator supplement inconclusive) |
```

Calibration rule:

- do not silently replace the provenance trail
- retain the issue if it still cannot be verified
- do not fabricate certainty just because the orchestrator attempted a supplement

---

## Example 5: Zero-Issue Big Round

This example exists because a successful zero-issue round must not be mistaken for a failed round.

### Temp report excerpt

```markdown
### R2 · Formatting and Typesetting

No issues found.
```

### Correct interpretation during merge

- the temp file exists
- the round completed normally
- the issue count for that round is `0`
- this is not a crash, timeout, or incomplete audit

### If all big rounds are zero-issue and complete

The orchestrator may use the simplified all-zero report path:

```markdown
# AUDIT Report

**Audit Target**: manuscript.md
**Target Type**: Paper
**Domain**: Epidemiology
**Audit Date**: 2026-03-20
**Audit Architecture**: Parallel subagent mode | 1 batches 3 subagents
**Big Rounds Executed**: R1–R3 (3 rounds total)
**Total Issues**: 0 (Critical 0 / Major 0 / Minor 0)
**Cross-Round Independent Discoveries**: 0 ⭐
**Tool Degradation**: None

## Summary Statistics

| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |
|-----------|-------|----------|-------|-------|------------|------------|
| R1        | Scientific Accuracy | 0 | 0 | 0 | 2D+0V | 4 |
| R2        | Formatting and Typesetting | 0 | 0 | 0 | 2D+0V | 1 |
| R3        | Citation Verification | 0 | 0 | 0 | 2D+0V | 6 |
| Total     |       | 0 | 0 | 0 |      | 11 |

Audit complete, no issues found.

## Overall Assessment

The audit target showed no issues requiring remediation across 3 audit dimensions.
```

Calibration rule:

- zero issues is a valid outcome
- zero-issue temp files must still be written
- the simplified all-zero path is only valid when all big rounds completed successfully

---

## Example 6: D/V Cycle — Discovery vs Verification

This example shows the difference between genuine tool-backed verification and restating discovery as verification.

### Bad (discovery repeated as verification)

```text
D1 draft:
  D1-1: Missing sample size in Table 1 | Location: Results, Table 1, row 3 | Severity: Major

V1:
  D1-1: Confirmed — I re-read Table 1 and the sample size is indeed missing.
  Verification Source: Code inspection
```

Why this is bad:

- "I re-read it" is the same action as discovery, not independent verification
- `Verification Source: Code inspection` is content-free

### Good (tool-backed verification)

```text
D1 draft:
  D1-1: Missing sample size in Table 1 | Location: Results, Table 1, row 3 | Severity: Major

V1:
  D1-1: Confirmed — Grep for "N=" and "sample" in the target file returned no matches in the Table 1 section. Cross-checked against Methods section which states N=1,247 but this value does not appear in the table.
  Verification Source: Grep("N=", target.md) + Grep("sample", target.md) — zero hits in Table 1 block
```

Why this is good:

- verification uses a different tool (Grep) than the original discovery (Read)
- the verification source describes what was checked and what was found
- the cross-reference to Methods adds triangulation

Calibration rule:

- "I re-read the same text" is discovery, not verification
- verification requires a different tool, a different source, or a cross-reference to a different section
- `Verification Source` must describe what was actually checked, not just say "verified" or "code inspection"
