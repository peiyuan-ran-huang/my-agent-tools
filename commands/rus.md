---
name: rus
description: Use when the user explicitly invokes ---rus to trigger a quick critical self-review of Claude's own last response. Lightweight alternative to ---qc.
---
<!-- version: 1.1.0 (2026-03-28) -->

# RUS — R U Sure?

## Trigger

Activate ONLY when `---rus` (case-insensitive) appears as the **first token** of the user message.
Ignore `---rus` occurring inside code fences, blockquotes, quotes, or inline examples.
Do NOT activate on natural language like "r u sure" / "are you sure" / "check again" / "你确定吗". If the user appears to want a re-check but uses no sentinel, do not self-activate.
This skill takes no arguments. Any text after `---rus` is ignored; the review scope is always the last substantive response.

## What To Do

Re-read your last substantive response and critically examine it across three dimensions. A response is substantive if it contains reasoning, analysis, or recommendations; code blocks accompanied by explanation also qualify. Bare tool-call results, status messages, and raw unnarrated outputs are non-substantive.

1. **Correctness** — Are all facts, numbers, logic, and reasoning actually right? Would this survive fact-checking?
2. **Completeness** — Did you miss important caveats, edge cases, alternatives, or considerations the user should know?
3. **Confidence calibration** — Did you state anything with more certainty than warranted? Are there claims that should be hedged?

### How to genuinely re-examine (not rubber-stamp)

- Re-read your response as if **a stranger wrote it and your job is to find problems**.
- For each factual claim: "How do I know this? Could I be confusing similar concepts?"
- For each recommendation: "What's the strongest argument against this?"
- If you used numbers, re-derive or re-check them step by step.
- Re-read the user's original question: did your response actually answer what was asked, or did it drift to an adjacent topic?

## Output

**Issues found** → State each issue, explain why it's wrong/incomplete, provide the correction. If substantial, output the corrected version of affected content.

**No issues found** → State which 1-2 areas carried the most uncertainty during re-examination and why they held up, or note what could not be independently verified. 2-3 sentences max.

If the previous response is no longer in context, review the most recent substantive content available and note what could not be reviewed. If the context contains only non-substantive content (bare tool outputs, status messages), or no content exists at all, state that there is nothing to review.

No structured report. No severity labels. No templates. Just corrections or confirmation.

For high-stakes content where self-review bias is a concern, use `/qc --sub` for a full structured review with an isolated subagent counterfactual.
