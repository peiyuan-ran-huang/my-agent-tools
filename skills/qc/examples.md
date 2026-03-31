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

**Review Target**: deploy.sh
**Target Type**: Code
**Coverage**: Full — all 45 lines reviewed
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 1 matched context; 0 triggered findings

### Findings

#### Standards — Minor
- **Evidence**: `rm -rf /tmp/build_*` (line 15)
- **Issue**: Glob pattern cleanup without confirming the directory exists first; silent failure on empty match.
- **Suggested fix**: Add `shopt -s nullglob` before the rm command, or guard with an existence check.

✓ Correctness / Completeness / Optimality / Consistency: No issues

### Summary
- **Overall Rating**: Minor
- **Counterfactual**: Confirmed — re-examined the deployment target path construction at lines 8-12 (most likely source of a silent-but-dangerous error); path is built from validated env vars with fallback defaults. A fresh reviewer would agree this is sound.
- One defensive coding gap; deployment logic is sound.
- [ ] Add nullglob or existence guard before rm glob
- Evolution check: no new patterns discovered
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
- ✗ Blast Radius says "scanned 3 files" but doesn't declare scope — reader can't tell if key files were missed. MEMORY.md still says "credentials in `.bashrc`" after migration to `.secrets`.
- ✓ Declare scope explicitly: "Scope: 3 files in diff + imports/refs in cwd and ~/.claude/". Flag stale references as Completeness issues.
- ✗ 影响范围写"扫描了 3 个文件"但未声明范围——读者无法判断是否遗漏了关键文件。MEMORY.md 仍写着"凭据在 `.bashrc`"。
- ✓ 显式声明范围："范围：diff 中 3 个文件 + cwd 和 ~/.claude/ 的引用搜索"。将过时引用标记为完整性问题。

**5. Suspicion without evidence as finding / 无证据疑点列为发现**
- ✗ "This function might have a race condition" listed as Major under Correctness, with no evidence of concurrent access
- ✓ If evidence is ambiguous, place in Open Questions with a "Would resolve if" criterion. Findings require concrete evidence.
- ✗ 将"这个函数可能有竞态条件"列为 Correctness 下的 Major，但无并发访问的证据
- ✓ 证据不足时放入 Open Questions 并注明"可通过以下方式确认"。Findings 必须有实证。

---

## Major Example — Omission Evidence / Major 示例 — 缺失型证据

Reviewing a hypothetical MR analysis script (`mr_analysis.R`).
审查对象：一个假设的 MR 分析脚本（`mr_analysis.R`）。

```
## QC Review Report

**Review Target**: mr_analysis.R
**Target Type**: Code
**Coverage**: Full — all 85 lines reviewed
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 3 matched context; 1 triggered finding

### Findings

#### Completeness — Major
- **Evidence**: absent: expected `set.seed()` call before `sample()` on line 42, but not found in file
- **Issue**: Random sampling without seed compromises reproducibility
- **Suggested fix**: Add `set.seed(7)` before line 42
<!-- Note: examples use 7 as a generic seed for distribution safety (personal seed removed per v0.6). In actual reviews, apply the project-specific seed from pitfalls.md / academic-workflow.md. -->

#### Standards — Major
- **Evidence**: `p_value < 0.05` (line 67) used to label results as "significant"
- **Issue**: Binary significance framing; should report effect size with 95% CI
- **Suggested fix**: Replace with: "beta = X.XX (95% CI: X.XX, X.XX), P = 0.XXX"

✓ Correctness / Optimality / Consistency: No issues

### Summary
- **Overall Rating**: Major
- **Counterfactual**: Confirmed — re-examined the IVW estimation logic at lines 30-40 (core MR calculation); instrument selection and F-statistic filtering are correctly applied. The Major findings are in reporting format, not analytical correctness.
- Two standards/completeness gaps in statistical reporting and reproducibility.
- [ ] Add set.seed(7) before random operations
- [ ] Replace significance labels with effect sizes and CIs
- Evolution check: no new patterns discovered
```

---

## Critical Example / Critical 示例

Reviewing a hypothetical data processing script (`clean_data.R`).
审查对象：一个假设的数据清洗脚本（`clean_data.R`）。

```
## QC Review Report

**Review Target**: clean_data.R
**Target Type**: Code
**Coverage**: Full — all 120 lines reviewed
**Blast Radius**: Scope: cwd; scanned 4 files; 0 stale references
**Pitfalls Check**: checked N entries; 2 matched context; 0 triggered findings

### Findings

#### Correctness — Critical
- **Evidence**: `bmi <- weight / height` (line 34)
- **Issue**: BMI formula requires height squared (kg/m²); current code divides by height, not height²
- **Suggested fix**: Change to `bmi <- weight / height^2`

✓ Completeness / Optimality / Consistency / Standards: No issues

### Summary
- **Overall Rating**: Critical
- **Counterfactual**: Confirmed — re-examined lines 30-36 (the data transformation block containing the BMI error); no additional Critical issues beyond the formula error. The merge logic and unit conversions above are correct.
- Incorrect BMI calculation produces wrong values for all records.
- [ ] Fix BMI formula to use height squared
- Evolution check: no new patterns discovered
```

---

## Skill/Prompt Example / 技能/提示词示例

Reviewing a hypothetical agent skill (`summarize.md`).
审查对象：一个假设的 agent skill（`summarize.md`）。

```
## QC Review Report

**Review Target**: summarize.md
**Target Type**: Skill/Prompt
**Coverage**: Full — all 40 lines reviewed
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 1 matched context; 0 triggered findings

### Findings

#### Consistency — Minor
- **Evidence**: Frontmatter `description` says "triggered by /summarize or 'please summarize'" but body § Trigger says "only activate on /summarize"
- **Issue**: Natural-language trigger claim in description contradicts the explicit-only rule in body
- **Suggested fix**: Remove "or 'please summarize'" from description to match body

✓ Correctness / Completeness / Optimality / Standards: No issues

### Summary
- **Overall Rating**: Minor
- **Counterfactual**: Confirmed — re-examined the parameter parsing section (lines 15-25) for edge cases with quoted paths and empty input; parsing rules are complete and unambiguous. The finding is limited to the frontmatter/body mismatch.
- One trigger-boundary inconsistency between frontmatter and body.
- [ ] Align description with body trigger rule
- Evolution check: no new patterns discovered
```

---

## Open Questions Example / 开放问题示例

Demonstrating how to handle ambiguous findings.
展示如何处理证据不足的疑点。

```
### Open Questions

- **Question**: Line 15 hardcodes `n_bootstrap = 100`; this may be insufficient for stable CI estimation, but adequacy depends on the data distribution
- **Would resolve if**: Run convergence diagnostic or cite a power analysis justifying 100 iterations

- **问题**：第 15 行硬编码 `n_bootstrap = 100`；可能不足以得到稳定的 CI 估计，但充分性取决于数据分布
- **可通过以下方式确认**：运行收敛诊断或引用证明 100 次迭代足够的 power analysis
```

---

## Evolution Proposal Example / 进化提议示例

Demonstrating a well-formed proposal appended after the Summary section.
展示一个格式正确的进化提议，附加在总结部分之后。

```
### Evolution Proposal

> 🔄 **Proposed Evolution**  <!-- emoji is part of this template's format spec; overrides default no-emoji rule -->
>
> **Type**: pitfall
> **Draft entry**:
> `- **同文件内多处引用同一数值** [file-modification]: 文档中同一数值（行数、版本号、文件数等）出现在多处时，修改一处必须全文搜索其他引用点。`
> **Rationale**: Existing pitfall "多文件版本号一致性" covers version numbers across files, but not repeated numerical claims within a single document (e.g., "~30 lines" stated in 3 places).
> **Action**: "Add to pitfalls.md"
>
> *Approve / modify / reject?*
```

**Anti-pattern / 反模式**: proposing something already covered.
反模式：提议已有覆盖的内容。

```
### Evolution Proposal

> 🔄 **Proposed Evolution**
>
> **Type**: pitfall
> **Draft entry**:
> `- **版本号要统一** [file-modification]: 多个文件的版本号必须一致。`
> **Rationale**: Version numbers are sometimes inconsistent.
> **Action**: "Add to pitfalls.md"
>
> *Approve / modify / reject?*
```

✗ This duplicates existing pitfall "多文件版本号一致性". Write Mechanics requires scanning for semantic overlap before proposing — this should have been caught and merged instead.
✗ 与现有条目"多文件版本号一致性"语义重叠。写入机制要求提议前扫描重叠——应识别后建议合并而非新增。

---

## Loop Mode Example / 循环模式示例

Demonstrating a `--loop --sub` review-fix cycle on a hypothetical script.
展示对一个假设脚本的 `--loop --sub` 审查-修复循环。

```
🔄 Round 1/15 | Passes: 0/3 | History: []  <!-- emoji is part of this template's format spec; overrides default no-emoji rule -->

## QC Review Report
**Review Target**: preprocess.R
**Target Type**: Code
...
#### Completeness — Minor
- **Evidence**: absent: no `set.seed()` before `sample()` on line 22
- **Issue**: Random sampling without seed
- **Suggested fix**: Add `set.seed(7)` before line 22
### Summary
- **Overall Rating**: Minor

--- [Claude fixes: adds set.seed(7)] ---

🔄 Round 2/15 | Passes: 0/3 | History: [m]
✓ Correctness: re-read lines 1-30; data loading and transformation logic correct
✓ Completeness: set.seed(7) now present at line 21, immediately before sample() at line 22
✓ Optimality: no simpler alternative identified
✓ Consistency: seed value matches project convention
✓ Standards: reproducibility requirement satisfied
**Overall Rating**: Pass
**Counterfactual**: [subagent] Confirmed — re-examined the set.seed(7) fix at line 21: seed is placed immediately before sample(), and no other random operations exist between seed and usage. Also verified no stochastic calls elsewhere in the script. The fix is correct and complete.

🔄 Round 3/15 | Passes: 1/3 | History: [m, P]
✓ Correctness: re-read lines 30-50; filtering logic and output format correct
✓ Completeness: all edge cases (empty input, NA values) handled at lines 5-8
✓ Optimality: vectorised operations used throughout; no unnecessary loops
✓ Consistency: variable naming follows snake_case throughout
✓ Standards: seed present; no hardcoded paths
**Overall Rating**: Pass
**Counterfactual**: [subagent] Confirmed — re-examined the NA handling at lines 5-8 (different area from round 2); na.rm = TRUE consistently applied in aggregation, and the initial filter removes rows with missing key variables. Sound.

🔄 Round 4/15 | Passes: 2/3 | History: [m, P, P]
✓ Correctness: re-read lines 50-65; output write logic and path construction correct
✓ Completeness: directory existence verified at line 58 before write
✓ Optimality: write_csv appropriate for this data size
✓ Consistency: output filename pattern matches input convention
✓ Standards: no hardcoded absolute paths; relative paths used
**Overall Rating**: Pass
**Counterfactual**: [subagent] Confirmed — re-examined the output path construction at lines 58-62 (different area from rounds 2-3); paste0() correctly joins directory and filename, and dir.exists() guard prevents silent failure. No issues.

[Loop complete: 3/3 consecutive passes achieved in 4 rounds]
```

---

## Depth Checkpoint Round Example / 深度检查点轮次示例

Demonstrating a depth checkpoint round (every 5th round: rounds 5, 10, 15) that requires a full expanded report regardless of pass streak.
展示深度检查点轮次（每 5 轮触发：第 5、10、15 轮），无论连续 pass 状态如何，均要求完整展开报告。

```
🔄 Round 5/15 | Passes: 2/3 | History: [M, m, P, P, ...]  <!-- depth checkpoint: full report required -->

## QC Review Report
**Review Target**: preprocess.R
**Target Type**: Code
**Coverage**: Full — all 65 lines re-read from disk
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 2 matched context; 0 triggered findings

### Findings

✓ Correctness / Completeness / Optimality / Consistency / Standards: No issues

### Summary
- **Overall Rating**: Pass
- **Counterfactual**: [subagent] Confirmed — re-examined the data type coercion at line 35 (as.numeric on character column); input data codebook confirms column is always numeric-as-string with no non-numeric entries. Also verified the join key at line 40 is character type on both sides. No issues found.
- All dimensions clean on full re-examination.
- Evolution check: no new patterns discovered
```

---

## Meta-calibration: Counterfactual — 好示例

场景：审查一个 R 脚本，五维审查未发现 Critical/Major，整体评级 Minor。

```
### Summary
- **Overall Rating**: Minor
- **Counterfactual**: Confirmed — re-examined the join logic at lines 42-58 (most complex path with potential for silent row duplication); left_join keys are unique on both sides (verified via distinct check at line 38), and the downstream filter at line 60 would catch any unexpected expansion. A fresh reviewer would likely agree this is clean.
- Overall assessment: Minor style issues only. Core logic is sound.
- Improvement checklist: use explicit `.by` in joins for clarity
- Evolution check: no new patterns discovered
```

### Anti-pattern: 橡皮章 Counterfactual

```
### Summary
- **Overall Rating**: Pass
- **Counterfactual**: Confirmed — looks good, no issues found
- Overall assessment: Clean code, well structured.

错误：Counterfactual reasoning 没有引用任何具体审查区域，
等同于橡皮图章。有效的 counterfactual 必须指向至少一个
具体区域并说明为何经得起审视。对照 pitfalls.md 条目：
"若 reasoning 不含具体文件/行号/逻辑点引用，视为未执行"。
```

---

## Loop Mode Counterfactual — 好示例

场景：Loop Mode 第 3 轮，上一轮修复了 line 42 的 off-by-one error，本轮审查整体评级 Minor。

```
🔄 Round 3/15 | Passes: 0/3 | History: [M, m, ...]

### Summary
- **Overall Rating**: Minor
- **Counterfactual**: Confirmed — re-examined the off-by-one fix at line 42 (changed `<` to `<=`): the loop bound now matches the array length, and the downstream assertion at line 48 validates the boundary. Also checked whether the fix introduced any new edge case for empty arrays — the guard at line 40 handles this. A fresh reviewer would agree the fix is correct and complete.
- Overall assessment: Previous fix is sound. Remaining Minor: variable naming at line 55.
```

### Anti-pattern: Loop Mode 橡皮章

```
🔄 Round 3/15 | Passes: 0/3 | History: [M, m, ...]

### Summary
- **Overall Rating**: Pass
- **Counterfactual**: Confirmed — fix looks correct
- Overall assessment: All issues resolved.

错误：(1) 未引用上一轮具体修复位置（line 42 的 off-by-one）。
(2) 未验证修复是否引入新问题。Loop Mode 下 counterfactual 必须
具体指向上一轮修复并说明其正确性和完整性。
```

---

## Subagent Counterfactual (`--sub`) — 好示例

场景：审查一个 R 脚本，`---qc --sub`，五维审查评级 Minor。子代理独立审查后确认。

```
### Summary
- **Overall Rating**: Minor
- **Counterfactual**: [subagent] Confirmed — independent reviewer re-examined the data merge logic at lines 30-45 (most complex path with potential for silent row loss); left_join keys match on both sides, and the assertion at line 47 validates row count post-merge. Also checked whether the filtering at line 52 could silently drop valid records — the condition is correct per the codebook. No new findings. No severity adjustments.
- One reproducibility gap (missing set.seed); core analysis logic is sound.
- [ ] Add set.seed(7) before line 22
- Evolution check: no new patterns discovered
```

### Anti-pattern: 子代理 prompt 不自包含

```
### Summary
- **Overall Rating**: Pass
- **Counterfactual**: [subagent] Confirmed — subagent agreed with the review

错误：(1) 子代理结果缺少具体审查区域引用（area_examined 为空或泛化）。
(2) 有效的子代理 counterfactual 必须引用子代理独立审查的具体位置和推理，
而非仅仅"agreed"。子代理的价值在于独立视角——如果结果与内联无异，
说明 prompt 不够自包含或子代理未真正独立审查。
```

### Subagent WNF-aware 示例 / WNF 感知示例

场景：循环模式第 5 轮，存在 2 项 WNF。子代理重新识别了 WNF 项但未发现新问题。
Scenario: Loop mode round 5, 2 WNF items exist. Subagent re-identifies WNF items but finds no new issues.

```
🔄 Round 5/15 | Passes: 2/3 | History: [M, m, P(2 WNF), P, ...]  <!-- depth checkpoint: full report required -->

## QC Review Report
**Review Target**: analysis.R
**Target Type**: Code
**Coverage**: Full — all 85 lines re-read from disk
**Blast Radius**: N/A — standalone content
**Pitfalls Check**: checked N entries; 3 matched context; 0 triggered findings

### Findings

✓ Correctness / Completeness / Optimality / Consistency / Standards: No issues

### Summary
- **Overall Rating**: Pass
- **Counterfactual**: [subagent] Confirmed — independent reviewer re-identified 2 WNF items (WNF-1: missing set.seed, WNF-2: hardcoded output path) but found no genuinely new issues. Re-examined the data merge logic at lines 42-55 (most complex path); left_join keys are unique and the downstream assertion validates row count. wnf_reidentified: 2 items logged for audit trail. No new findings. No severity adjustments.
- All dimensions clean; 2 WNF items remain as user-accepted.
- Evolution check: no new patterns discovered
```

**关键机制 / Key mechanism**：子代理通过 `findings_temp.md` 中的 `## WNF Register` 获知 WNF 项，将重新识别的问题报告在 `wnf_reidentified`（而非 `new_findings`）中。主代理的派发后交叉检查确认无真正新发现，`consecutive_passes` 不重置。The subagent learns WNF items via the `## WNF Register` in `findings_temp.md`, reports re-identifications under `wnf_reidentified` (not `new_findings`). The main agent's post-dispatch cross-check confirms no genuinely new findings, so `consecutive_passes` is not reset.

---

### Subagent Reopened 示例

场景：子代理发现了初审遗漏的问题。

```
### Summary
- **Overall Rating**: Major (upgraded from Minor after subagent review)
- **Counterfactual**: [subagent] Reopened — independent reviewer identified silent type coercion at line 55: character join key "001" matches numeric 1 in R's left_join, causing unexpected row duplication. New finding added to Correctness above. Severity of existing Completeness finding unchanged.
- Subagent-discovered type coercion bug elevates rating to Major.
- [ ] Convert join key to consistent type before merge (line 54)
- [ ] Add set.seed(7) before line 22
- Evolution check: no new patterns discovered
```
