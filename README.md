# my-agent-tools

Reusable tools (e.g., skills and commands) for AI agents (e.g., Claude Code), synced across devices.

## Structure

```
skills/
  <skill-name>/
    SKILL.md      ← skill prompt template (EN)

commands/
  work.md         ← slash command (/work)
  handoff.md      ← session handoff generator (/handoff)
  rus.md          ← lightweight self-review "r u sure?" (/rus)
  prompt.md       ← session continuation prompt (/prompt)
```

## First-time setup (new device)

```bash
git clone https://github.com/peiyuan-ran-huang/my-agent-tools.git ~/my-agent-tools
bash ~/my-agent-tools/sync.sh
```

## Update (existing device)

```bash
bash ~/my-agent-tools/sync.sh
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| qc | `---qc [target] [criteria] [--loop [N]] [--sub]` | Five-dimensional QC review (correctness / completeness / optimality / consistency / standards). Supports loop mode and subagent counterfactual. EN + ZH bilingual. |
| audit | `---audit [target] [--focus X] [--out path] [--lang zh/en] [--lite]` | Multi-round deep audit with parallel subagents across 3 phases: plan → dispatch → merge. Supports focus areas, output path, language override, and lite mode. EN + ZH bilingual. |
| sharingan | `---sharingan <source> [--target <category>] [--auto] [--dry-run] [--no-ref] [--explore] [--no-explore] [context...]` | Self-optimization via external resources. 10-phase workflow to extract insights from URLs, repos, or local files and apply them to Claude Code config. Dual EXIT POINTs, built-in QC, security preflight. EN + ZH bilingual. |

## Commands

Lightweight single-file tools that complement the skills above.

| Tool | Trigger | Description |
|------|---------|-------------|
| work | `/work` | Read-only session summary: completed, pending, remaining items |
| handoff | `/handoff [path]` | 4-phase session handoff document generator with QC review |
| rus | `/rus` | Lightweight critical self-review ("r u sure?") of last response (v1.2.0) |
| prompt | `/prompt [desc] [--file [path]]` | Session continuation prompt generator (v0.1.0) |
