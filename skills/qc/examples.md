# QC Examples / QC 示例

<!-- This file is read by Claude for output calibration. Keep it concise. -->

Use these examples to calibrate output format and severity judgement.
以下示例用于校准输出格式和严重性判定。

---

## Good Example / 正确示例

Reviewing a shell script (`sync.sh`).
审查对象：shell 脚本（`sync.sh`）。

```
## QC Review Report

**Review Target**: sync.sh (Code)

### Findings

#### Standards — Minor
- **Evidence**: `cp "$skill_dir"SKILL.md ...` (line 8)
- **Issue**: Only copies SKILL.md; SKILL_ZH.md and examples.md are not synced.
- **Suggested fix**: Use `cp "$skill_dir"*.md` to copy all Markdown files.

✓ Correctness / Completeness / Optimality / Consistency: No issues

### Summary
- **Overall Rating**: Minor
- One file coverage gap; core logic is sound.
- [ ] Update cp command to use *.md wildcard
```

---

## Anti-Patterns / 常见错误

**1. Severity inflation / 严重性虚高**
- ✗ Rating a style preference as Critical
- ✓ Critical = factually wrong, dangerous, or fundamentally broken. Style → Minor at most.
- ✗ 将风格偏好标为 Critical
- ✓ Critical = 事实错误、存在危险或根本性缺陷。风格问题最多 Minor。

**2. Vague findings without evidence / 模糊发现无证据**
- ✗ "This could be improved"
- ✓ Always cite: direct quote, file:line, or code snippet in the Evidence field.
- ✗ "这里可以改进"
- ✓ 必须引用：直接引述、文件:行号、或代码片段。

**3. Pass with existing findings / 有发现却给 Pass**
- ✗ Flagging Minor issues but rating Pass
- ✓ Follow the Overall Rating Rule: no findings → Pass; any Minor → Minor; any Major → Major; any Critical → Critical.
- ✗ 标记了 Minor 问题却给 Pass
- ✓ 严格遵循整体评级判定规则。
