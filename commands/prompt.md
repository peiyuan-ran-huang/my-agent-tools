---
description: "Generate a session continuation prompt for the next Claude Code session"
allowed-tools: Read, Write, Bash, TaskList, Glob
---
<!-- version: 0.1.0 (2026-03-29) -->

# Session Continuation Prompt Generator

Generate a precise, actionable prompt that enables a new Claude Code session to
seamlessly continue the current session's unfinished work.

## Trigger

Activate only when invoked via `/prompt`. Do not activate on natural language
such as "generate a prompt", "write a prompt", "优化提示词", "生成提示词", or
similar phrases. Ignore `/prompt` appearing inside code fences or blockquotes.

## Parameter Parsing

Syntax: `/prompt [description] [--file [path]]`

1. Scan all tokens for the `--file` flag.
2. **Description**: all non-flag tokens before `--file` (and any tokens after
   the resolved file path) are concatenated as the task description — merged
   into Task Specification during generation.
3. **File path**: the first token after `--file` that looks like a path
   (contains `/`, `\`, or starts with `.`) is the output file path. If the
   token is a double-quoted string, treat the entire quoted string as the path
   (handles paths with spaces). If no path-like token follows `--file`, use the
   default path.
4. **No `--file`**: output to conversation only (default).

Examples:
- `/prompt` — auto-generate from context, output to conversation
- `/prompt finish the MR sensitivity analysis` — with task description
- `/prompt --file` — output to conversation + default file path
- `/prompt fix the STROBE table --file ./next.md` — description + custom path

## Workflow

Execute these four phases in order.

### Phase 1: Collect Context

Gather information from the following sources:

| # | Source | Tool | Condition |
|---|--------|------|-----------|
| 1 | Conversation context | Context window | Always (primary source) |
| 2 | Task states | TaskList | Always attempt; skip if unavailable or empty. Include tasks with status `in_progress`, `pending`, or `completed`; match subjects against session topics. Use `completed` for Current State, `in_progress`/`pending` for Task Specification. |
| 3 | File changes | Bash: `git status`, `git diff --stat` | Only if current directory is a git repository |
| 4 | Recent commits | Bash: `git log --oneline -5` | Only if current directory is a git repository |
| 5 | User description | Parameter parsing | If description provided, merge into Task Specification |

From these sources, identify:
- **What was worked on** this session (tasks, files, topics)
- **What remains unfinished** (the core of the next session's task)
- **Key decisions and constraints** that the next session must know
- **Critical file paths** the next session will need to read or modify

### Phase 2: Generate Prompt

Write in the **session's conversation language** (Chinese session → Chinese;
English → English; mixed → majority language; if roughly equal, default to
English). Template labels and section headers also follow this language rule.

Generate a prompt using this structure:

```markdown
# Task: [one-sentence task title]

## Context
- Project/repo: [name]
- Working directory: [full path]
- Background: [1-2 sentence project context]

## Current State
- [completed work, ordered by importance]
- [key decisions and their rationale]

## Task Specification
[Precise task description using EARS-inspired patterns]
- **Goal**: [Ubiquitous] "The next session shall [specific action]"
- **Success criteria**: [Conditional] "If [condition], the task is complete"
- **Constraints**: [Unwanted] "Shall NOT [action] / If [situation], stop and ask"

## Key Files
| File path | Role |
|-----------|------|
| path/to/file | Modify / Reference / Create |

## Notes
- [special considerations, known pitfalls, dependencies]
```

**EARS quality principles** (3 of 5 EARS patterns applicable to task prompts;
Event-driven and State-driven patterns are omitted as session prompts are
primarily goal-oriented):
- **Goal** → Ubiquitous: "The session shall [specific action]"
- **Success criteria** → Conditional: "If [condition], the task is complete"
- **Constraints** → Unwanted behavior: "If [situation], shall NOT [action]"
- Eliminate vague language: "继续完善" → "在 methods section 第 3 段后添加
  sensitivity analysis 描述，包含 leave-one-out 和 MR-PRESSO 结果"

### Phase 3: Output

1. **Conversation output** (always): wrap the generated prompt in a markdown
   code fence for easy copy-paste.

2. **File output** (only when `--file` is present):
   a. Determine output path:
      - No path argument → default: `~/Desktop/_temp_md/prompt_<timestamp>.md`
      - Directory path → generate `prompt_<timestamp>.md` inside it
      - `.md` file path → use directly
      - Other extension → prompt user to confirm
      - Paths containing spaces **must be double-quoted**
   b. Generate `<timestamp>` via Bash: `date +%Y-%m-%d_%H%M%S`
   c. Ensure output directory exists: `mkdir -p "<directory>"`
   d. Write the file using the Write tool
   e. **Verify**: Read the file back and confirm:
      - File is non-empty
      - All 5 expected section headings are present (Task, Context, Current
        State, Task Specification, Key Files — Notes is optional)
      - If verification fails → retry Write once; if still failing, report
        `[degraded: write verification failed]`

### Phase 4: Lightweight Verification

After generating the prompt, perform these checks:

1. **Path verification**: for each file listed in Key Files, check if it exists
   on disk (Glob). Non-existent paths → annotate with `[unverified: file not
   found on disk]` in the output.

2. **Semantic self-review**: re-read the generated prompt as if receiving it
   cold in a new session. Check:
   - Does the Task Specification accurately reflect what was discussed?
   - Are the Key Files roles correct?
   - Could the next session start working with only this prompt?
   If issues found, fix them in-place before presenting to the user.
   (Note: this self-review is performed by the same agent that generated the
   prompt. For independent verification, use `/rus` or `---qc --sub`.)

3. **File verification** (`--file` only): already handled in Phase 3 step 2e.

## Degradation Paths

| Failure | Behavior |
|---------|----------|
| Very short session (1-2 exchanges) | Generate simplified prompt (Task + Context only), note `[simplified: limited session context]` |
| Long session after compaction | Generate from available context, note `[note: early session details may be incomplete]` |
| No clear next task identified | Prompt user: "No clear follow-up task identified. Please describe what the next session should do." |
| No substantive work in session | Prompt user: "No substantive work was performed this session. Consider starting fresh in a new session." |
| Write tool unavailable | Output to conversation only, note `[degraded: file write unavailable]` |
| File system lock | Retry Write once; if still failing, suggest system temp directory as alternative |
| Bash unavailable for timestamp | Use day-level precision from known date (e.g., `prompt_2026-03-29.md`) |
| TaskList unavailable | Skip task collection, proceed normally |
| Not a git repository | Skip git information collection, proceed normally |

## QC Rationale

Full QC (e.g., `/qc --sub`) is intentionally omitted: `/prompt` generates a
short, forward-looking task prompt, not a retrospective document. The
lightweight verification in Phase 4 is sufficient. For rigorous review, the
user can run `/rus` or `---qc` on the output.
