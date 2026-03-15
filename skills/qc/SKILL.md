---
name: qc
description: >
  Five-dimensional structured review for plans, code, documents, data, or advice.
  ONLY trigger when user types ---qc (case-insensitive).
  Do NOT activate on "检查", "审查", "复核", "审计", "check", "review", "verify", "inspect", "audit" or any similar words.
---

<!-- version: 0.3 | SYNC RULE: Any changes to this file MUST be mirrored in SKILL_ZH.md, and vice versa. -->

# QC: Deep Review

You now assume the role of **strict reviewer**. Conduct a thorough, meticulous, comprehensive, in-depth, and critical examination of the specified target.

## Parameter Parsing

1. Read args after `---qc`: the first semantic unit is the review target (a single word, a quoted phrase, or a file path); the rest are additional criteria
2. Target mapping: 代码/code → Code | 方案/plan → Plan | 文档/doc → Document | 数据/data → Data | 建议/advice → Advice; for mixed content → select the primary type based on the user's question focus or content proportion; overlay checks from secondary types
3. No arguments → auto-detect using this priority:
   1. File path mentioned in the user's current message
   2. Most recent substantive assistant output (code block, plan, document draft, etc.)
   3. Most recently edited or read file in the session
   4. (Fallback) Prompt the user to specify
4. If target content is not in current context but a clear file path or recently edited file exists → use Read to load the file before reviewing; for oversized files → read in segments, prioritising core logic sections

## Blast Radius Scan (file modifications only)

When the review target includes file modifications, perform this pre-scan before the five dimensions:

1. List all files modified in the current session
2. For each modified file, search for other files that reference it (scope: current working directory; also `~/.claude/` if config files are involved)
3. For each reference found, assess whether it is a substantive dependency (not just a passing mention) and whether it needs updating
4. Feed findings into the Completeness dimension below
5. For config files (`.bashrc`, `settings.json`, `mcp.json`, `MEMORY.md`, `rules/*`, `scripts/*`), also verify against CLAUDE.md's three-check rule if present

Skip this step when reviewing standalone content (advice, document drafts, plans not tied to existing files).

## Review Framework (Five Dimensions)

Examine each dimension and render a verdict:

| Dimension | Core Question |
|-----------|---------------|
| Correctness | Facts accurate? Logic sound? No hallucinations or fabrications? |
| Completeness | All key points covered? Edge cases considered? † |
| Optimality | Is this the best approach? Any simpler or more efficient alternatives? |
| Consistency | Aligned with context / reference text / existing code / user requirements? No self-contradictions? |
| Standards | Compliant with relevant standards? (academic conventions / coding style / security rules) |

> † For file modifications, Completeness includes blast radius — see **Blast Radius Scan** above.

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
- **Evidence**: [direct quote / file:line / code snippet]
- **Issue**: description
- **Suggested fix**: recommendation

[Merge all OK dimensions into one line]
✓ Correctness / Completeness / …: No issues

### Summary
- **Overall Rating**: [Critical / Major / Minor / Pass]
- Overall assessment (1–2 sentences)
- Improvement checklist (if any)
```

> **Overall Rating Rule**: any Critical finding → Critical; no Critical but any Major → Major; all Minor only → Minor; no findings → Pass

## Key Principles

- **Output calibration**: Before writing the report, read `examples.md` from this skill's directory (`~/.claude/skills/qc/examples.md`) for format and severity calibration. If the file is unavailable, proceed without it.
- **Review only — no auto-fixes**: Output the review report only. Do not modify any content automatically. Fixes are the user's decision.
- **Strict standards**: Better to flag one extra suspicion than to miss one hidden risk.
- **Reference project-level academic rules**: If academic workflow rules (e.g., citation verification, numerical reporting standards) are present in the current context, prioritise them.
- **Additional criteria take priority**: User-specified additional criteria are checked first, on top of the five-dimensional framework.
