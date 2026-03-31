---
name: qc
description: Use when the user's message starts with ---qc to request a structured five-dimensional review of code, plans, documents, data, advice, or skills/prompts.
---

<!-- version: 1.3.0 | SYNC RULE: Changes to this file MUST be mirrored in SKILL_ZH.md, and vice versa.
Allowed differences: (1) frontmatter `name` (qc vs qc-zh), (2) frontmatter `description` language,
(3) loading behavior note in SKILL_ZH.md, (4) translation-process notes (e.g., comments explaining which sections are kept in English). Sync metric: semantic equivalence per section, NOT line-count equality. -->

# QC: Deep Review

## Trigger

Activate ONLY when `---qc` (case-insensitive) appears as the **first token** of the user message.
Ignore `---qc` occurring inside code fences, blockquotes, quotes, or inline examples.
Do NOT activate on natural language: check / review / verify / inspect / audit / 检查 / 审阅 / 复核 / 审计 or similar.
If the user clearly wants QC but uses no sentinel, do nothing — they may use `---qc` to invoke.

You now assume the role of **strict reviewer**. Conduct a thorough, meticulous, comprehensive, in-depth, and critical examination of the specified target.

## Parameter Parsing

1. Read args after `---qc`: the first semantic unit that is not a recognized flag is the review target (a single word, a quoted phrase, or a file path — **file paths containing spaces must be quoted with double quotes**, e.g., `---qc "my project/analysis.R"`; if unquoted path-like tokens containing spaces are detected, ask the user to re-invoke with quotes; only double quotes are recognized — single quotes and backslash-escaped spaces are not supported; an empty quoted string as the target falls through to auto-detect step 3); the rest are additional criteria. Scan all tokens for recognized flags — flag tokens (identified by `--` prefix matching known flags below) are excluded from target/criteria identification regardless of position:
   - `--loop`/`--循环` [N]: activate **Loop Mode** (N defaults to 3; if the token immediately following this flag is a positive integer, it is consumed as N and not treated as the review target; non-positive integers, e.g., `--loop 0`, and non-numeric tokens are NOT consumed as N — un-consumed tokens re-enter the normal token stream; if this creates a clearly nonsensical target, prompt the user for clarification)
   - `--sub`/`--子代理`: activate **Subagent Counterfactual Mode** (see below)

   `--loop` and `--sub` can be used together; they are independent switches with no conflict (see respective sections for combined behavior).
2. Target mapping: 代码/code → Code | 方案/plan → Plan | 文档/doc → Document | 数据/data → Data | 建议/advice → Advice | skill/prompt/技能/提示词 → Skill/Prompt | diff/changeset/directory/目录 → Code overlay (blast-radius scope = diff/directory); for mixed content → select the primary type based on the user's question focus or content proportion; overlay checks from secondary types
3. No arguments → auto-detect using this priority:
   1. File path mentioned in the user's current message
   2. Most recent substantive assistant output — must be: (a) code block ≥3 lines, numbered plan ≥5 items, or continuous prose ≥5 lines (excludes pure tables, pure data output, or single-line answers); (b) classifiable as code, plan, document, data, advice, or skill/prompt (excludes tool-status output, error messages, data dumps); if uncertain, skip to step 3
   3. Most recently edited or read file in the session
   4. (Fallback) Prompt the user to specify
4. If target content is not in current context but a clear file path or recently edited file exists → use Read to load the file before reviewing; for oversized files → read in segments, prioritising core logic sections. If Read fails (file not found, permission error), report the failure in Coverage, fall back to in-context content if available (noting `[degraded: context fallback]`), or prompt the user to verify the path

## Loop Mode (activated by `--loop [N]` / `--循环 [N]`)

When `--loop` is present, execute a review-fix-review cycle:

1. Run standard QC review on the target
2. **Pass** → increment consecutive pass counter (subject to subagent counterfactual override if `--sub` is active; see Subagent Counterfactual Mode); **Not Pass** → reset counter to 0, fix all non-WNF findings (Critical → Major → Minor), then re-review. If the same finding (same dimension, same location) recurs after being fixed in a prior round, note the recurrence in the round status header (e.g., `History: [M, m, M(recur), ...]`). If it recurs 3 times (i.e., reappears in 3 separate rounds after being fixed), pause and present to the user: "This finding has recurred 3 times despite attempted fixes — manual intervention may be needed. Treat as WNF or provide guidance?"
3. Exit when: consecutive passes >= N (default 3), or total rounds >= 15. If the loop exits due to reaching the round cap (total rounds >= 15) while the most recent rating is non-Pass (e.g., subagent reopened on the final round), report: `[Loop cap reached: X/15 rounds completed. Final rating: [rating]. Unresolved findings remain — see last round's report above.]`
4. Each round starts with: `🔄 Round X/15 | Passes: Y/N | History: [P, M, m, P, ...]` (P=Pass, C=Critical, M=Major, m=Minor)  <!-- emoji is part of this template's format spec; overrides default no-emoji rule -->
5. Target is resolved once at invocation; subsequent rounds re-review the same target (files: re-read from disk; in-context content: review the most recent corrected version output by Claude — Claude applies fixes by outputting the corrected version in the round report, and subsequent rounds review that latest output). If re-read fails mid-loop (file deleted, renamed, or permissions changed), apply the same degradation as Parameter Parsing step 4: report in Coverage, fall back to in-context content if available (`[degraded: context fallback]`); if re-read fails for 2 consecutive rounds, terminate the loop with `[Loop terminated: target unreadable since round X]`. If the target was auto-detected (not explicitly specified) and `--loop` is active, confirm the auto-detected target with the user before entering the loop. If the user rejects the auto-detected target, prompt for an explicit target specification (Parameter Parsing step 3.4) before entering the loop
6. Calibration files (examples.md, pitfalls.md): read once at start. Evolution Protocol: **loop exit round only** (the round where the loop terminates, whether by achieving N consecutive passes or hitting the round cap).

In loop mode, the "review only — no auto-fixes" principle is suspended: Claude fixes findings between rounds. If a fix requires user input, pause and ask. If the user rejects a proposed fix, treat the finding as **won't-fix (WNF)**. Exclude WNF items from subsequent round severity ratings (consequently, a round where all remaining findings are WNF rates as Pass under the Overall Rating Rule). Track WNF items in the round status header for audit trail (e.g., `History: [M, P(1 WNF), P, P]`). For Critical-severity WNF: prompt the user for explicit confirmation ("This Critical finding involves [description] — confirm skip?") and tag as `P(1 C-WNF)` in the header. If a fix cannot be applied due to tool failure (e.g., Write tool unavailable for a file target), treat as requiring user intervention — pause the loop and report the failure.

**No-shortcut rule (pass rounds)**: Even in consecutive pass rounds, every round MUST:
1. **Re-read** the target from disk (use the Read tool; do not rely on context memory; for in-context content targets, re-examine the latest version in conversation context)
2. Perform a genuine **five-dimension assessment** — compact format is acceptable (one line per dimension verdict), but each verdict must reflect actual re-examination of the target content, not a copy of the previous round
3. In the **counterfactual**, cite a specific area (file:line or logic point) that is **different** from the previous round's counterfactual focus — cycle through different risk areas across rounds to avoid always checking the same spot. For small targets with limited distinct areas, revisiting a previously examined area is acceptable if you approach it from a different angle (e.g., correctness vs performance vs edge cases).

A pass round that merely copies the previous round's format without evidence of fresh examination is a protocol violation. The output may be compact, but the review MUST be genuine.

**Depth checkpoint rounds**: In rounds where `round_number` is a multiple of 5 (rounds 5, 10, 15), you MUST produce a **full five-dimension report** with expanded reasoning (not compact format), regardless of the current rating or pass streak. Treat a depth checkpoint as if it were round 1 — approach the target with fresh eyes and maximum rigor. This periodic forced expansion counteracts the natural tendency toward shallow repetition in later rounds. Depth checkpoints and subagent counterfactual are independent — both apply when their respective conditions are met. A depth checkpoint round with `--sub` active and Pass rating produces both a full five-dimension report AND dispatches the subagent.

**Context pressure management**: In long loops (round >= 6, non-checkpoint rounds), if context usage is high, you may summarize rounds 1 through (current_round - 4) into single-line status records (round number + rating + key finding IDs) to free context space. Report `[degraded: context pressure]` in Coverage if this affects review depth. If context limits are reached mid-loop, terminate with `[Loop terminated: context limit reached at round X]`.

**Adversarial re-framing**: In rounds 2+, before reviewing, adopt the stance: "This was written by someone else. My job is to find problems, not confirm correctness." This counteracts the natural tendency to validate your own fixes.

## Subagent Counterfactual Mode (activated by `--sub` / `--子代理`)

When `--sub` is present, the counterfactual test (see meta-calibration principle in Key Principles) is delegated to a physically isolated subagent instead of running inline. This provides genuine context isolation — the subagent has never seen the generation or review process, eliminating self-review bias.

### Dispatch Logic

```python
# After five-dimension review, before writing Summary:
if --sub active:
    if --loop active:
        if this_round_rating == "Pass":
            result = dispatch_subagent_counterfactual()
        else:
            result = inline_counterfactual()    # non-Pass: issues already surfaced; inline sufficient
    else:
        result = dispatch_subagent_counterfactual()

    # Post-dispatch (subagent only):
    if result.source == "subagent":  # source is inferred from dispatch context, not from subagent output
        apply_severity_adjustments(result.severity_adjustments)  # applies for both confirmed and reopened
        log_wnf_reidentifications(result.wnf_reidentified)  # audit trail only; does not affect verdict or rating

        # Cross-check: reclassify any new_findings that match WNF register entries
        for finding in result.new_findings[:]:  # iterate over copy
            if matches_wnf_register(finding, wnf_register):  # match on dimension + area/description
                result.wnf_reidentified.append(reclassify_as_wnf(finding))
                result.new_findings.remove(finding)

        if result.verdict == "reopened":
            if result.new_findings:  # genuinely new findings remain after cross-check
                apply_new_findings(result.new_findings)
                recalculate_overall_rating()
                update_round_history(round_number, new_overall_rating)  # replace initial 'P' with recalculated rating
                consecutive_passes = 0  # explicit reset — do not rely on implicit next-round detection
            else:
                # Subagent said "reopened" but only WNF re-identifications remain — override to confirmed
                result.verdict = "confirmed"
                # consecutive_passes NOT reset — WNF-only reopen is a false alarm
```

> **Confirmed + severity_adjustments**: A `confirmed` verdict may still include non-empty `severity_adjustments` (e.g., the subagent agrees no new issues were missed but recommends re-rating an existing finding). These adjustments are applied to the main report regardless of verdict.

> **Confirmed + wnf_reidentified**: A `confirmed` verdict may include non-empty `wnf_reidentified` — the subagent found no genuinely new issues but re-identified known WNF items. These are logged for audit trail but do not affect rating or pass counter. If the subagent returns verdict `reopened` with `new_findings` empty after cross-check (all items matched WNF register), the verdict is overridden to `confirmed`.

> **Confirmed + new_findings**: If a subagent returns `confirmed` with non-empty `new_findings` (self-contradictory output), the verdict takes precedence — `new_findings` are not processed (the `if result.verdict == "reopened"` branch is never entered). Log a warning in the round report if this occurs.

> **Anti-downgrade self-check**: Before writing the `**Counterfactual**:` line, verify: "Is `--sub` active AND is this round rated Pass (loop mode) or any rating (non-loop)?" If YES, you MUST dispatch a subagent — if you find yourself about to write an inline counterfactual when the condition is met, STOP and dispatch the subagent instead. Never silently downgrade to inline without reporting `[degraded: inline fallback]` and the specific failure reason. If NO (i.e., loop mode + non-Pass round), inline counterfactual is the **designed behavior** — no degradation tag needed.

### Subagent Specification

- **Agent type**: `general-purpose`, `model: "opus"` (latest Opus-class model per runtime conventions; see Degradation below if unavailable)
- **Session directory**: At the first subagent dispatch in a session, generate a session-unique working directory: run `echo "$(date +%s)_${RANDOM}"` via Bash to obtain a unique ID, then use `C:/tmp/qc_sub_<id>/` as the working directory (e.g., `C:/tmp/qc_sub_1711700000_12345/`). Store this path as `QC_SUB_DIR` and reuse it for all subsequent subagent dispatches within the session. In loop mode, each round's cleanup and next round's write use the same `QC_SUB_DIR`.
- **Startup cleanup**: Before writing temp files, if `QC_SUB_DIR` already exists, delete all its contents first (prevents stale files from crashed/interrupted previous sessions from contaminating the current review).
- **Input**: Write two temp files to `QC_SUB_DIR` (create the directory if it doesn't exist):
  - `target_temp.md` — the review target content (for file targets, copy the file content; for in-context content, write it to temp)
  - `findings_temp.md` — five-dimension findings in QC report format (each finding headed by `#### [Dimension] — [Severity]`); for Pass-rated rounds with no findings, write: `✓ Correctness / Completeness / Optimality / Consistency / Standards: No issues\n\n**Overall Rating**: Pass`. In loop mode, if any WNF items have accumulated, append a `## WNF Register` section after the findings (before Matched Pitfalls) listing all won't-fix items so the subagent can distinguish re-identifications from genuinely new findings. Format:
    ```
    ## WNF Register
    Items below were marked won't-fix by the reviewer/user. If your independent review
    re-identifies these same issues, report them under `wnf_reidentified` (not `new_findings`).
    Only genuinely new issues (not matching any WNF entry) belong in `new_findings`.
    - [WNF-1] Dimension: one-line description (Reason: reason)
    - [WNF-2] Dimension: one-line description (Reason: reason)
    ```
    If the WNF register exceeds 20 items, write a summary header (`N WNF items total; top 5 by severity:`) followed by the 5 highest-severity entries (Critical > Major > Minor). At the end of findings_temp.md, append a `## Matched Pitfalls` section listing the pitfall entries that matched the current target context (so the subagent has access to user-specific check items)
- **Prompt**: Must use the following canonical template verbatim. Only the five `{{...}}` fields may be filled in. Do NOT add instructions to focus on specific dimensions, narrow the review scope, or skip any aspect.

````
You are an independent reviewer who has NOT participated in the creation or initial review of the target below. Your task is to provide a thorough, unbiased second opinion.

## Target Information
- **Type**: {{TARGET_TYPE}}
- **Domain context**: {{DOMAIN_CONTEXT}}
- **Target-specific checks**: {{TARGET_OVERLAYS}}
- **Content**: Read the file `{{QC_SUB_DIR}}/target_temp.md`
- **Original file path** (if file-based target): {{ORIGINAL_FILE_PATH}}

## Initial Review Findings
Read the file `{{QC_SUB_DIR}}/findings_temp.md`

## Cross-validation (mandatory for file-based targets)
If an original file path is provided above, ALSO read it directly from disk and compare with the temp copy. If they differ, the disk version is authoritative — base your review on it and note the discrepancy. If the original file cannot be read (not found, permission error), proceed with the temp copy and note: [cross-validation skipped: original file unreadable].

## Your Task

Perform a COMPREHENSIVE independent review across ALL of the following five dimensions with EQUAL depth and rigor. Do NOT focus on any single dimension — every dimension deserves the same thoroughness.

1. **Correctness**: Facts accurate? Logic sound? No hallucinations or fabrications?
2. **Completeness**: All key points covered? Edge cases considered? Dependencies checked?
3. **Optimality**: Best approach? Any simpler or more efficient alternatives?
4. **Consistency**: Aligned with context / requirements / existing code? No self-contradictions?
5. **Standards**: Compliant with relevant standards? (academic conventions / coding style / security rules)

Also apply the target-specific checks listed above.

You must:
- (a) Find issues the initial review MISSED — actively look for blind spots, not confirmations
- (b) Verify severity assignments of ALL existing findings — are any over- or under-rated?
- Start from the execution layer (scripts, configs) rather than documentation
- Verify implementation assumptions — comments/labels do not guarantee enforcement
- Check for namespace collisions (ID/key/variable uniqueness)

## Severity Definitions
- **Critical**: factually wrong, dangerous, or fundamentally broken
- **Major**: significant functional gap or risk
- **Minor**: style, edge case, or non-blocking improvement

## Output Format
Respond with a JSON object ONLY (no markdown wrapping, no commentary outside JSON):
```json
{
  "verdict": "confirmed | reopened",
  "area_examined": "[MUST cite specific locations: file:line, code snippets, logic paths. Generic statements are INVALID.]",
  "reasoning": "[MUST provide detailed reasoning with specific references. 'Looks good' or 'no issues' is INVALID.]",
  "severity_adjustments": [
    {"finding_ref": "Dimension — Severity", "proposed": "new severity", "reason": "..."}
  ],
  "new_findings": [
    {"dimension": "...", "severity": "...", "evidence": "...", "issue": "...", "suggested_fix": "..."}
  ],
  "wnf_reidentified": [
    {"wnf_ref": "WNF-N", "dimension": "...", "evidence": "...", "note": "still present but acknowledged as won't-fix"}
  ]
}
```
````

  **Fill-in field definitions**:
  - `{{TARGET_TYPE}}`: the target type from Parameter Parsing (Code / Plan / Document / Data / Advice / Skill/Prompt)
  - `{{DOMAIN_CONTEXT}}`: 1-2 sentence description of the domain (e.g., "R tidyverse data processing script for epidemiological analysis" / "academic manuscript following STROBE guidelines")
  - `{{TARGET_OVERLAYS}}`: copy the full overlay checklist for the target type from §Target-Specific Overlays (e.g., for Code: "+Security vulnerabilities +Performance +Error handling +Readability +Dependency reasonableness +Test coverage")
  - `{{ORIGINAL_FILE_PATH}}`: for file-based targets, the original file path on disk (e.g., `~/project/analysis.R`); for in-context content, write "N/A — in-context content"
  - `{{QC_SUB_DIR}}`: the session-unique working directory path generated in the Session directory step (e.g., `C:/tmp/qc_sub_1711700000_12345`)

  **Constraint**: If the main agent needs to provide additional context (e.g., round number, what previous rounds found), it may add a `## Additional Context` section AFTER the template content, but this section MUST NOT override, narrow, or prioritize any dimension over others. Violations — such as "focus on Completeness" or "particularly check blast radius" — are prohibited. When WNF items exist, Additional Context SHOULD include: "The WNF Register in findings_temp.md lists items the user has marked as won't-fix. Review these areas independently, but classify re-identifications under `wnf_reidentified`, not `new_findings`."
- **Cleanup**: Delete `QC_SUB_DIR` contents after integrating each subagent result (in loop mode, clean up after each subagent round, not just at loop exit)

### Degradation

If subagent dispatch fails (tool error — including Write tool failure when creating temp files —, timeout, unavailable model, etc.) → fall back to inline counterfactual. Report line shows `[degraded: inline fallback]`.

### Output Format Change

The `**Counterfactual**:` line in Summary gains a source tag:

- `[subagent] Confirmed — ...` or `[subagent] Reopened — ...`
- `[degraded: inline fallback] Confirmed — ...`
- (no tag) = inline counterfactual (default, when `--sub` is not active)

## Blast Radius Scan (file modifications only)

When the review target includes file modifications (including `directory`/`目录` targets, which are treated as multi-file change sets), perform this pre-scan before the five dimensions:

1. Identify the change set: if a diff/changeset is available, use it; otherwise list session-modified files **relevant to the review target** (not the entire session indiscriminately)
2. **Declare scan boundary explicitly** in the report (see template below): state which files are in scope and which directories were searched
3. For each changed file, search for other files that reference it — use Grep for the filename/path; check import/require/source statements; search index files (MEMORY.md, CLAUDE.md, AGENTS.md, README.md, package manifests, repo-local instruction files) for references. Scope: current working directory; also `~/.claude/` if config files are involved. This scan does not automatically reach fixed paths outside the workspace; for known external dependencies, encode them as pitfalls entries.
4. For each reference found, assess whether it is a substantive dependency (not just a passing mention) and whether it needs updating
5. Feed findings into the Completeness dimension below
6. For config files (`.bashrc`, `settings.json`, `mcp.json`, `MEMORY.md`, `rules/*`, `scripts/*`), also verify against any workspace instruction file that defines linked-update rules (e.g., `CLAUDE.md`, `AGENTS.md`, repo-local policy files) if present

**Boundary rule**: If the user provides only a file path (e.g., `---qc file.R`) without a diff/changeset and no session modifications exist for that file, treat it as a **standalone content review** — skip blast radius. Only perform blast radius when (a) a diff/changeset is explicitly provided, (b) the file was modified in the current session, or (c) the user explicitly asks to review modification impact.

Skip this step **only** when the review target is entirely standalone content with no file dependencies (this includes the file-path-only scenario described in the boundary rule above, as well as freestanding advice, unsaved document drafts, or plans not tied to existing files).

If Grep is unavailable during blast radius scanning, report `[degraded: no blast radius]` in the Blast Radius output line and note the limitation in Coverage.

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
- **Skill/Prompt**: +Trigger/activation boundary clarity +Parameter parsing edge cases (spaces, quotes, empty input) +Consistency between instruction text and examples +Token cost awareness (mandatory pre-reads, growing reference files) +Portability assumptions (which runtime features are required?) +Degradation path coverage (does the skill define behavior when tools are unavailable or context is insufficient? — missing → Major) +Self-review bias risk (does the same agent both generate and review output without isolation? — Minor, design limitation) +Runtime vs development material boundary (are files clearly marked as runtime-loaded vs development-only reference? — Minor, cognitive burden)

## Output Format

> **Severity definitions**: Critical = factually wrong, dangerous, or fundamentally broken; Major = significant functional gap or risk; Minor = style, edge case, or non-blocking improvement.
>
> **Overall Rating Rule**: any Critical finding → Critical; no Critical but any Major → Major; all Minor only → Minor; no findings → Pass

Use the following template:

```
## QC Review Report

**Review Target**: [auto-detected / user-specified]
**Target Type**: [Code / Plan / Document / Data / Advice / Skill/Prompt]
**Additional Criteria**: [user-specified content; omit this line if none]
**Coverage**: [Full | Partial — state which sections/files reviewed and which were skipped, with reason]
**Blast Radius**: [N/A — standalone content | Scope: [boundary declaration]; scanned X files; Y stale references found]
**Pitfalls Check**: [N/A — no pitfalls file | checked X entries; Y matched context; Z triggered findings]

### Findings

[Expand only dimensions with issues; label each Critical / Major / Minor]

#### [Dimension] — [Critical / Major / Minor]
- **Evidence**: [direct quote / file:line / code snippet / "absent: expected X in Y but not found" / "Grep returned 0 results for pattern X"]
- **Issue**: description
- **Suggested fix**: recommendation

[Merge all OK dimensions into one line]
✓ Correctness / Completeness / …: No issues

### Open Questions

[Optional. List items where evidence is ambiguous or context insufficient to confirm/deny. Each item states what would resolve it. Omit this section entirely if there are no uncertain items.]

- **Question**: [description of the ambiguity]
- **Would resolve if**: [what information or check would settle it]

### Summary
- **Overall Rating**: [Critical / Major / Minor / Pass]
- **Counterfactual**: [Confirmed — [cite the specific area re-examined and why it holds up] | Reopened — [area re-examined, finding added above]]
- Overall assessment (1–2 sentences)
- Improvement checklist (if any)
- Evolution check: [no new patterns discovered | see Evolution Proposal below]
```

## Key Principles

- **Output calibration**: Before writing the report, read `examples.md` (format/severity calibration) and `pitfalls.md` (user-specified check items) from this skill's directory (`~/.claude/skills/qc/`). For each pitfall entry, first assess whether its trigger tag (if present) matches the current review target type and context; only apply matching entries. In the Pitfalls Check output line, report: checked X entries; Y matched context; Z triggered findings. If `pitfalls.md` grows beyond ~30 entries, scan tags/headings first and read only matching sections in full. If either file is unavailable or empty, proceed without it.
- **Pitfalls tag matching rules**: `[tag1/tag2]` — `/` means OR; an entry applies if ANY listed tag matches the current context. No tag = always applicable (same as `[all]`). Matching is contextual (AI judges applicability), not a literal string comparison against the target type name. Suggested tags: `[all]`, `[code]`, `[academic]`, `[academic/statistics]`, `[file-modification]`, `[file-path]`, `[code/R/Python]`, `[skill/prompt]`. Keep tags within a single dimension (object type OR action context OR language); avoid mixing dimensions in one OR group.
- **Review only — no auto-fixes**: Output the review report only. Do not modify any content automatically. Fixes are the user's decision. (This principle is suspended when `--loop` is active — see **Loop Mode** above.)
- **Evidence-led, not suspicion-led**: Every finding in the Findings section must have concrete evidence (direct quote, file:line, code snippet, or explicit absence citation). Uncertain items without sufficient evidence → place in the **Open Questions** section instead. Goal: zero missed real issues — but suspicions without evidence are questions, not findings.
- **Reference project-level academic rules**: If academic workflow rules (e.g., citation verification, numerical reporting standards) are present in the current context, prioritise them.
- **Additional criteria take priority**: User-specified additional criteria are checked first, on top of the five-dimensional framework.
- **Never skip Blast Radius Scan**: For any review involving file modifications, MUST perform the Blast Radius Scan before the five dimensions. When in doubt about whether it applies, perform it — false negatives are costlier than false positives.
- **Meta-calibration before finalizing**: Before writing the Summary section, re-read all findings and ask:
  1. Would I rate this the same severity if it appeared in isolation?
  2. Am I inflating because I found too few issues, or deflating because I found too many?
  3. **Counterfactual test** (mandatory for all ratings): Ask the question matching the current rating — for Pass/Minor: "If this exact target were submitted by a stranger for first-time review, would I still find no Critical or Major issues?"; for Major/Critical: "Am I understating severity — could this be Critical / is this truly Major?". If uncertain, pick the weakest area and re-examine it with adversarial intent before confirming. In Loop Mode rounds 2+, the reasoning must specifically address whether the fixes applied in the previous round are correct and complete.
     **Operational guidance for effective counterfactual execution**:
     - Start from the execution layer (scripts, configs) rather than documentation — docs get covered in normal QC; execution code is the trust blind spot.
     - Verify implementation assumptions — seeing a comment or label (e.g., `<!-- T050 -->`) does not mean the system enforces it; read the enforcement code to confirm.
     - Scan for namespace collisions — ID/key/variable uniqueness is the most common collision point in self-testing code.
     - Trace the root cause chain — after finding a bug, ask "why could this bug exist?" to identify missing guards, registries, or spec coverage.
  Adjust if needed.

## Evolution Protocol

After completing the QC report (in Loop Mode: loop exit round only — see Loop Mode section; skipped on abnormal terminations such as target-unreadable or context-limit exits), self-reflect on whether the review surfaced knowledge worth preserving. This is a **post-review** step — never let it interfere with the review itself.

### When to Propose

Ask yourself:
- Did I encounter a target type with no matching overlay?
- Did I discover a pattern worth capturing for future reviews that is not in pitfalls.md?
- Did I find a calibration gap not in examples.md (e.g., a new anti-pattern or severity edge case)?
- Did I apply domain knowledge that should be formalized?

If YES to any → append an Evolution Proposal section **after the Summary section** (as the final section of the QC report). If NO to all → end normally; do not force a proposal.

### Proposal Format

Append this block to the report output:

```
### Evolution Proposal

> 🔄 **Proposed Evolution**  <!-- emoji is part of this template's format spec; overrides default no-emoji rule -->
>
> **Type**: pitfall | example | overlay-gap
> **Draft entry**:
> `- **Title** [tag1/tag2]: One-line description`
> **Rationale**: Why existing rules don't cover this.
> **Action**: "Add to pitfalls.md" / "Add to examples.md" / "Flag for SKILL.md review"
>
> *Approve / modify / reject?*
```

### Write Mechanics (on user approval)

- Append new entry after the last entry in the Entries section of pitfalls.md (match on `## Entries` prefix, ignoring any bilingual suffix) (or the relevant section of examples.md)
- Auto-include provenance comment: `<!-- via: evolution-proposal, YYYY-MM-DD -->`
- Before writing, scan existing entries for semantic overlap; if found, warn user and suggest merging instead of adding

### Constraints

- Max 1 proposal per QC review (avoid proposal fatigue; if 2+ genuinely novel patterns surface, pick the highest-value one)
- Never auto-write to any file; always wait for user confirmation
- Never propose changes to the 5 core dimensions or severity definitions
- Proposals for SKILL.md structural changes (new overlays, new dimensions) → flag only, defer to a dedicated review session
