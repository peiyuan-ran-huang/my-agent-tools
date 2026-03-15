# QC Examples / QC 示例

<!-- This file is read by Claude for output calibration. Keep it concise. -->

Use these examples to calibrate output format and severity judgement.
以下示例用于校准输出格式和严重性判定。

---

## Good Example / 正确示例

Reviewing a hypothetical deployment script (`deploy.sh`).
审查对象：一个假设的部署脚本（`deploy.sh`）。

```
## QC Review Report

**Review Target**: deploy.sh (Code)

### Findings

#### Standards — Minor
- **Evidence**: `rm -rf /tmp/build_*` (line 15)
- **Issue**: Glob pattern cleanup without confirming the directory exists first; silent failure on empty match.
- **Suggested fix**: Add `shopt -s nullglob` before the rm command, or guard with an existence check.

✓ Correctness / Completeness / Optimality / Consistency: No issues

### Summary
- **Overall Rating**: Minor
- One defensive coding gap; deployment logic is sound.
- [ ] Add nullglob or existence guard before rm glob
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

**4. Narrow scope miss (blast radius) / 范围过窄遗漏（影响范围）**
- ✗ Credentials moved from `.bashrc` to `.secrets` — QC checks only the three modified files and rates Pass. MEMORY.md still says "credentials in `.bashrc`"; changelog not updated.
- ✓ For file modifications, grep for references to modified files; flag stale references as Completeness issues.
- ✗ 凭据从 `.bashrc` 迁移到 `.secrets` — QC 只检查了三个被修改的文件，评为 Pass。MEMORY.md 仍写着"凭据在 `.bashrc`"；changelog 未更新。
- ✓ 修改文件时，搜索引用了被修改文件的其他文件，将过时引用标记为完整性问题。
