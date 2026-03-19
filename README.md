# personal-agentic-skills

Private repository for personal AI agent skills, synced across devices.

## Structure

```
skills/
  <skill-name>/
    SKILL.md      ← skill prompt template (EN, primary)
    SKILL_ZH.md   ← Chinese translation (reference only)
```

## First-time setup (new device)

```bash
git clone https://github.com/peiyuan-ran-huang/personal-agentic-skills.git ~/personal-agentic-skills
bash ~/personal-agentic-skills/sync.sh
```

## Update (existing device)

```bash
bash ~/personal-agentic-skills/sync.sh
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| qc | `---qc [object] [criteria]` | Five-dimensional QC review (correctness / completeness / optimality / consistency / standards). EN + ZH bilingual. |
