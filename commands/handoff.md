---
name: handoff
description: >
  Generate a comprehensive session handoff document for seamless work continuity
  across Claude Code sessions. This skill should be used when the user wants to
  preserve session context, decisions, and progress before ending a session.
  Produces a structured Markdown document and runs QC review on it.
argument-hint: [output path]
---

# Session Handoff

Generate a thorough, accurate, and well-structured handoff document that enables
a new session to seamlessly continue the current session's work.

## Trigger

Activate only when invoked via `/handoff`. Do not activate on natural language
such as "summarize session", "create handoff", "write a handoff document", or
similar phrases. Ignore `/handoff` appearing inside code fences or blockquotes.

## Parameter Parsing

Syntax: `/handoff [output path]`

1. **No arguments**: output to default path:
   `~/Desktop/_temp_md/handoff_<timestamp>.md`
   Generate `<timestamp>` via Bash: `date +%Y-%m-%d_%H%M%S`
   <!-- Note: ~/Desktop/ may not exist on headless Linux/WSL. Users can override via /handoff [path]. -->

2. **With arguments**: the argument is the output path.
   - Paths containing spaces **must be double-quoted**
     (e.g., `/handoff "D:/My Projects/notes/"`)
   - **Path type detection**:
     - Path exists on disk: use its actual type (file or directory)
     - Path does not exist: trailing `/` or no file extension → directory;
       `.md` extension → file; other extensions → prompt for clarification
   - Directory path → generate `handoff_<timestamp>.md` inside it
   - File path (`.md`) → use directly
   - Unquoted multi-token path detected → prompt to re-enter with double quotes

3. **Degradation**: if Bash is unavailable for timestamp generation, use the
   current date at day-level precision (e.g., `handoff_2026-03-26.md`) and
   prompt the user to confirm the output directory exists.

## Workflow

Execute these four phases in order.

### Phase 1: Collect Context

Gather session information from the following sources:

| # | Source | Tool | Condition |
|---|--------|------|-----------|
| 1 | Conversation context | Context window | Always (primary source) |
| 2 | Task states | TaskList | Always attempt; skip if unavailable, empty, or errored. Include tasks with status `in_progress` or `completed`; match subjects against session topics. Note: TaskList lacks timestamps — session scope is inferred heuristically from status and subject. |
| 3 | File changes | Bash: `git status`, `git diff --stat` | Only if current directory is a git repository |
| 4 | Recent commits | Bash: `git log --oneline -10` | Only if current directory is a git repository |

### Phase 2: Generate Document

Produce a Markdown document with the following 7 sections. Write in the
**session's conversation language** (if the session was in Chinese, write in
Chinese; if English, write in English). For mixed-language sessions, use the
language of the majority of substantive discussion; if roughly equal, default
to English.

```markdown
# Session Handoff — <date>

## 1. Session Overview
- Date and estimated session duration
- Main objectives for this session
- Overall outcome summary (completed / partially completed / blocked)

## 2. Completed Work
For each completed task:
- What was done (concise description)
- Which files were created, modified, or deleted
- Key decisions made and their rationale
Order by importance, not chronology.

## 3. Incomplete / In-Progress Work
For each unfinished item:
- Current status and what has been done so far
- What is blocking progress (if anything)
- Suggested next steps
- Priority label (High / Medium / Low)

## 4. Key Decisions & Context
- Important trade-off decisions (why option A was chosen over B)
- User instructions or constraints that shaped the work
- Assumptions made that the next session should be aware of

## 5. File Change Log
| File Path | Operation | Description |
|-----------|-----------|-------------|
| path/to/file | Added / Modified / Deleted | Brief description |

Source from git diff --stat when available; otherwise from conversation records.

## 6. Known Issues & Risks
- Potential pitfalls or edge cases discovered
- Things that could go wrong if not handled carefully
- Technical debt introduced (if any)

## 7. Action Items for Next Session
Prioritized TODO list for the inheriting session:
- [ ] High priority items first
- [ ] Medium priority items
- [ ] Low priority / nice-to-have items
Suggest what the next session should do first.
```

Ensure every section is substantive. If the session had very little work, still
generate all sections but note "minimal activity" in the overview and simplify
content accordingly.

### Phase 3: Write File

1. Ensure the output directory exists: `mkdir -p <directory>`
2. Write the document using the Write tool
3. **Verify the write**: Read the file back and confirm:
   - File is non-empty
   - All 7 section headings (`## 1` through `## 7`) are present
   - If content appears truncated → retry Write once
   - If still failing → report `[degraded: write verification mismatch]`
     and proceed to Phase 4

### Phase 4: QC Review

Invoke the qc skill for rigorous review of the handoff document:

```
Skill(qc, "--loop --sub \"<generated file path>\"")
```

The Skill tool loads qc by name, bypassing the `---qc` sentinel trigger (which
is a user-message guard). Arguments are parsed by qc's Parameter Parsing rules.

**Safety fallback**: if qc does not activate with the above invocation, retry
with `---qc` prepended to the args. If path parsing fails due to nested quotes,
qc's auto-detect mechanism will find the most recently written file (which is
the handoff document) — this is acceptable.

After QC completes, report to the user:
- Final QC rating
- File location (full path)
- Any degradation notes

**Self-review bias note**: QC is performed by the same agent that generated the
document. The `--sub` flag (subagent counterfactual) partially mitigates this
by introducing an independent reviewer.

## Degradation Paths

| Failure | Behavior |
|---------|----------|
| qc skill unavailable | Perform inline lightweight checks: (1) verify all 7 sections are non-empty and correspond to session content, (2) Read-verify all file paths mentioned in the document, (3) compare against TaskList and conversation records for omissions. Report `[degraded: inline QC fallback]` |
| Skill tool unavailable | Same as "qc skill unavailable" above |
| Write tool failure | Report the error with the attempted path; suggest the user create the file manually or specify an alternative path |
| Bash unavailable | Use day-level timestamp from known date; skip `mkdir -p` and prompt the user to confirm the directory exists |
| Read verification failure | Warn but do not block; note `[degraded: write unverified]` |
| Write verification mismatch | Retry Write once; if still failing, report `[degraded: write verification mismatch]` |
| OneDrive file lock | Retry once; if still failing, suggest `C:/tmp/` as an alternative output location |
| Insufficient context (long session after compaction) | Generate a simplified document covering available context; note `[degraded: partial context — some early session details may be missing]` |
