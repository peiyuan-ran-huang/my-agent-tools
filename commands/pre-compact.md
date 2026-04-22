---
description: "Preserve critical context-only content before running /compact"
allowed-tools: Read, Write, Bash, TaskList, Glob
---
<!-- version: 0.1.0 (2026-04-16) -->

# Pre-Compact Context Preservation

Extract and backup critical information that exists **only in conversation
context** (not yet persisted to files) before the user runs `/compact`, so it
can be recovered after context compression.

## Trigger

Activate only when invoked via `/pre-compact`. Do not activate on natural
language such as "save context", "backup before compact", or similar. Ignore
`/pre-compact` appearing inside code fences or blockquotes.

## Parameter Parsing

Syntax: `/pre-compact [topic hint]`

1. **No arguments**: auto-detect session topic from conversation context.
2. **With arguments**: all tokens are treated as a topic hint to focus
   extraction (e.g., `/pre-compact thesis corrections plan`).

There are no flags or options — any text after `/pre-compact` is a topic hint,
including tokens that resemble flags (e.g., `--help`).

## Workflow

### Phase 1: Scan & Classify

Scan the full conversation history and TaskList (if available — skip silently
if unavailable or empty; match task subjects against session topics).
Identify content meeting ALL three criteria:
- **Context-only**: NOT already saved to any file on disk
- **Forward-relevant**: likely needed for subsequent work in this session
- **Non-trivial to reconstruct**: would take significant effort to regenerate

Classify into these categories (include only non-empty categories):

| Category | What to look for | Priority |
|----------|-----------------|----------|
| **Plans & Decisions** | Approved execution plans, step progress, user-approved strategies, architectural decisions with rationale | Critical |
| **Pending Actions** | Decision points awaiting user input, options presented but not yet chosen, unresolved questions | Critical |
| **Investigation Results** | Debugging findings, root cause analysis, hypotheses tested, error patterns | High |
| **Intermediate Artifacts** | Draft content (text, code, configs) discussed but not written to files, computed values, inline analysis results | High |
| **Session State** | Current task, immediate next action, progress checkpoint (completed / remaining steps) | High |
| **Cross-references** | File paths, line numbers, URLs, or external resources referenced in discussion | Medium |

**Exclusion filter** (do NOT extract):
- Content already persisted to files (check recent Write/Edit operations in context)
- Git history (reconstructible via `git log`)
- General discussion, greetings, meta-conversation
- Information quickly re-derivable from reading existing files
- Verbatim file contents already on disk

### Phase 2: Extract & Structure

For each non-empty category, extract content following these guidelines:

- **Plans**: preserve the full structure (numbered steps, substeps) — truncating
  a plan makes it useless
- **Decisions**: preserve both the choice AND the rationale
- **Pending actions**: preserve exact options/questions with constraints
- **Artifacts**: preserve the content itself, not just a summary of it
- **State**: preserve enough for the agent to resume without asking "where were we?"
- **Cross-references**: preserve exact paths, line numbers, URLs

**Compression rule**: high information density. Summarize surrounding
discussion, but preserve exact details for actionable items (plan steps, code
snippets, file paths, numeric values).

### Phase 3: Write Backup File

1. Generate timestamp via Bash: `date +%Y%m%d-%H%M%S`

2. Write to `C:/tmp/pre-compact-{timestamp}.md` with this structure:

   **Frontmatter** (YAML, with `---` delimiters):
   ```
   ---
   type: pre-compact-context-backup
   created: {ISO 8601 with timezone, e.g. 2026-04-16T14:30:00+01:00}
   session_topic: "{topic}"
   status: active
   cleanup: |
     Temporary context backup. Safe to delete when:
     (1) status is "consumed", (2) owning session ended, or (3) >24h old.
     Any agent may delete under these conditions without user confirmation.
   ---
   ```

   **Body** — organized by category, each as a `##` section:
   ```
   # Pre-Compact Context Backup

   > Session: {topic} | Created: {human-readable time}
   > Recovery: Read this file to restore context compressed by /compact.

   ## Plans & Decisions
   [extracted content]

   ## Pending Actions
   [extracted content]

   ...remaining non-empty categories...
   ```

3. **Verify write**: Read back and confirm the file is non-empty and contains
   at least one content section. If write fails, retry once; if still failing,
   output content directly to conversation as fallback.

### Phase 4: Confirm & Recovery Hint

Present to the user:
1. Brief summary: which categories were preserved, approximate content size
2. The backup file path
3. "You can now run `/compact`."

**CRITICAL** — end the response with this recovery block (it survives in recent
messages after compaction and serves as the bridge for the agent to find the
backup):

```
──────────────────────────────────────────────────────
PRE-COMPACT BACKUP: C:/tmp/pre-compact-{timestamp}.md
If post-compact context feels incomplete, read this file.
──────────────────────────────────────────────────────
```

## Degradation Paths

| Failure | Behavior |
|---------|----------|
| No critical content found | Report "no context-only critical content found — safe to `/compact` directly" and skip file creation |
| Very short session (1-2 exchanges) | Same as above — minimal context to preserve |
| Context already compressed | Proceed, but prepend `[warning: context may already be partially compressed — backup may be incomplete]` |
| Write tool failure | Output extracted content directly to conversation; note `[degraded: file write failed — content in conversation only]` |
| Bash unavailable | Use day-level precision: `pre-compact-20260416.md` |
| C:/tmp/ not writable | Try `~/Desktop/_temp_md/` as fallback; if that fails, conversation output |
| Read verification failure | Report file path, note `[degraded: write unverified]`; do not block |
| Recovery block lost during compaction | Agent can discover backups via Glob pattern `C:/tmp/pre-compact-*.md`; user may also remind agent to check. Best practice: run `/compact` immediately after `/pre-compact` |
| TaskList unavailable | Skip task state; proceed with other sources |

<!-- The sections below are reference material for agents in future turns,
     not part of the /pre-compact execution workflow. -->

## Post-Compact Recovery (reference — not executed by this command)

This section is guidance for the agent — after compaction, the agent should:

1. If critical context seems missing, check for backups: glob `C:/tmp/pre-compact-*.md`
2. Read the most recent file with `status: active`
3. After consuming the content, update the frontmatter to `status: consumed`
4. Continue work with restored context

The backup file's frontmatter and header are self-documenting — even without
this command loaded, any agent encountering the file understands its purpose.

## Cleanup (reference)

Backup files are temporary and self-documenting for cleanup:
- The agent may delete files with `status: consumed` at any point
- Files older than 24 hours may be deleted regardless of status
- The frontmatter explicitly permits deletion under these conditions
- At session end, the agent is encouraged (but not required) to clean up
