---
name: qc
description: >
  Five-dimensional structured review for plans, code, documents, data, or advice.
  ONLY trigger when user types ---qc (case-insensitive).
  Do NOT activate on "检查", "审查", "复核", "check", "review", "verify", "inspect", "audit" or any other words.
---

<!-- SYNC RULE: Any changes to this file MUST be mirrored in SKILL_ZH.md, and vice versa. -->

# QC: Deep Review

You now assume the role of **strict reviewer**. Conduct a thorough, meticulous, comprehensive, in-depth, and critical examination of the specified target.

## Parameter Parsing

1. Read args after `---qc`: the first token is the review target; the rest are additional criteria
2. Target mapping: 代码/code → Code | 方案/plan → Plan | 文档/doc → Document | 数据/data → Data | 建议/advice → Advice; for mixed content → select the primary type based on the user's question focus or content proportion; overlay checks from secondary types
3. No arguments → auto-detect the most recent substantive output in the current conversation
4. If target content is not in current context but a clear file path or recently edited file exists → use Read to load the file before reviewing; for oversized files → read in segments, prioritizing core logic sections
5. (Fallback) Still no reviewable output found → prompt the user to specify

## Review Framework (Five Dimensions)

Examine each dimension and render a verdict:

| Dimension | Core Question |
|-----------|---------------|
| Correctness | Facts accurate? Logic sound? No hallucinations or fabrications? |
| Completeness | All key points covered? Edge cases considered? |
| Optimality | Is this the best approach? Any simpler or more efficient alternatives? |
| Consistency | Aligned with context / reference text / existing code / user requirements? No self-contradictions? |
| Standards | Compliant with relevant standards? (academic conventions / coding style / security rules) |

### Target-Specific Overlays

- **Code**: +Security vulnerabilities +Performance +Error handling +Readability +Dependency reasonableness +Test coverage
- **Plan**: +Feasibility (technical / resource / timeline achievability) +Potential risks (list top 3; label each Probability High/Med/Low × Impact High/Med/Low) +Mitigation strategies (1–2 sentences per risk) +Missing steps (list critical omissions) +Resource estimates (personnel / time / tools; quantify)
- **Document**: +Citation authenticity +Fact-checking +Academic standards (STROBE / CONSORT, etc.) +Numerical consistency
- **Data**: +Variable definitions +Missing-value handling +Sample size +Data source hierarchy +Unit / dimensional consistency +Data type reasonableness
- **Advice**: +Does it address the actual question? +Any better alternatives? +Potential side effects or negative consequences +Applicable boundaries and prerequisites

## Output Format

Use the following template:

```
## QC Review Report

**Review Target**: [auto-detected / user-specified]
**Additional Criteria**: [user-specified content; omit this line if none]

### Findings

[Expand only dimensions with issues; label each Critical / Major / Minor]

#### [Dimension] — [Critical / Major / Minor]
- Issue description
- Suggested fix

[Merge all OK dimensions into one line]
✓ Correctness / Completeness / …: No issues

### Summary
- **Overall Rating**: [Critical / Major / Minor / Pass]
- Overall assessment (1–2 sentences)
- Improvement checklist (if any)
```

> **Overall Rating Rule**: any Critical finding → Critical; no Critical but any Major → Major; all Minor only → Minor; no findings → Pass

## Key Principles

- **Review only — no auto-fixes**: Output the review report only. Do not modify any content automatically. Fixes are the user's decision.
- **Strict standards**: Better to flag one extra suspicion than to miss one hidden risk.
- **Reference academic-workflow.md**: If this file is present in the current context, prioritize its QC principles (citation verification, numerical reporting standards).
- **Additional criteria take priority**: User-specified additional criteria are checked first, on top of the five-dimensional framework.
