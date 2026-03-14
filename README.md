# claude-personal-skills

Private repository for personal Claude Code skills, synced across devices.

## Structure

```
skills/
  <skill-name>/
    SKILL.md    ← skill prompt template
```

## First-time setup (new device)

```bash
git clone https://github.com/peiyuan-ran-huang/claude-personal-skills.git ~/claude-personal-skills
bash ~/claude-personal-skills/sync.sh
```

## Update (existing device)

```bash
bash ~/claude-personal-skills/sync.sh
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| qc | `---qc [object] [criteria]` | Five-dimensional QC review (correctness / completeness / optimality / consistency / standards) |
