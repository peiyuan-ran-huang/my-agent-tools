---
description: "Summarize current session work: completed, pending, and remaining items"
allowed-tools: Read, Grep, Glob, TaskList, Bash(git:*)
---

# Session Work Summary

Review the entire conversation history of this session and produce a structured work summary report. Use the following information sources and output format.

## Information Gathering

Collect information from these sources in order:

1. **Conversation context** (primary) — scan the full conversation for all work performed, decisions made, files touched, and tasks discussed
2. **TaskList** — call the TaskList tool to check for tracked tasks and their statuses. If no tasks exist in this session, skip silently
3. **Git status/diff** (optional) — if working inside a git repository, run `git status` and `git diff --stat` to cross-validate file changes. Skip if not in a git repo
4. **File operation records** — from conversation context, compile a list of all files that were Read, Edited, or Written during this session

## Output Format

Produce the report in the following structure. **Omit any section that would be empty.** Use the same language as the conversation (Chinese if the session was in Chinese, English if in English), including section headers.

If this is a very short session (1-2 exchanges only), output a brief one-paragraph summary instead of the full template.

If the session was long and context has been compressed, note at the top: "[Note: this session was long and earlier context may have been compressed — coverage may be incomplete]"

```
## Completed Work
- [one-sentence description] (`relevant file path`)

## Incomplete Work
- [one-sentence description] — [reason / blocker]

## Remaining Items
### [Object category: Skills / Config / Code / Files / Project ...]
- [specific remaining item] (`file path`)
(empty categories omitted)
```

## Classification Rules

Apply these rules to decide which section each item belongs to:

- **Completed** = work explicitly finished in this session (user confirmed, file written, task marked completed)
- **Incomplete** = work explicitly started but not finished in this session (task-oriented — focuses on "what was started but not done")
- **Remaining Items** = follow-up work for each object handled in this session, including work not attempted but surfaced by the current session's operations (object-oriented — focuses on "what does this thing still need")
- **Overlap rule**: if an item fits both Incomplete and Remaining, put it in Incomplete (active session task takes priority). Remaining Items may cross-reference it but should not repeat the description

## Formatting Rules

- Each item: one sentence + key file path in backticks
- File paths: preserve the format used in the session (including full OneDrive paths where applicable)
- Do not modify any files — this is a read-only report
- Do not update memory or task tracking — just report
