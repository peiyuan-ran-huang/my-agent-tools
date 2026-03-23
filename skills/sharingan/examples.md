# SHARINGAN Examples / 校准示例

<!-- 本文件供 Phase 6/8/9/10 校准使用。聚焦关键判断步骤。 -->

---

## Phase 2: Classification — 好示例

外部资料：一篇关于 Claude Code hooks 最佳实践的博客文章。

```
Classification: hooks (primary), settings (secondary)

理由：文章核心讨论 PreToolUse/PostToolUse hook 模式，主要影响 ~/.claude/hooks/*.sh；
同时涉及 settings.json 的 hooks 配置数组，故列为 secondary。
```

### Anti-pattern

```
Classification: global-instructions (primary)

错误：文章讨论的是具体的 hook 实现，不是全局行为规则。
将实现细节分类为 global-instructions 会导致在错误的文件中提出修改。
```

---

## Phase 3: Extract Insights — 好示例

外部资料推荐了 5 个 Claude Code tips，经过滤后：

```
### Extracted Insights

1. **Hook timeout 配置** — 设置 hook 执行超时防止卡死
   - Source: "Tip 3: Always set timeouts for hooks" (section 3, paragraph 2)
   - Applicability: 当前 hooks 未配置 timeout，Context Mode hook 平均 694ms，偶发卡顿
   - Priority: Medium

已过滤：
- Tip 1 ("Use zsh for better completion") — 不适用，用户平台为 Windows Git Bash
- Tip 2 ("Add --no-verify to speed up commits") — 与 security.md 冲突：禁止跳过 hooks
- Tip 4 ("Create a CLAUDE.md for each project") — 已实现：~/.claude/projects/ 下已存在多个项目级配置
- Tip 5 ("Use model aliases") — 已实现：settings.json 已配置 model: opus-4-6
```

### Anti-pattern: 未过滤，全盘接收

```
### Extracted Insights

1. **Use zsh** — 切换到 zsh
2. **Skip hooks** — 添加 --no-verify
3. **Hook timeout** — 设置超时
4. **Project CLAUDE.md** — 每个项目创建 CLAUDE.md
5. **Model aliases** — 使用模型别名

错误：5 个 tips 全部列出，没有基于当前环境过滤。
Tip 1 与平台不兼容，Tip 2 违反安全规则，Tip 4/5 已实现。
```

---

## Phase 5: Optimization Proposal — 好示例 (有变更)

```
**Target**: ~/.claude/hooks/block-dangerous.sh
**Category**: hooks
**Change Type**: Modify

Proposed Changes:
1. 在第 3 行 shebang 后添加 `HOOK_TIMEOUT=5` 变量
2. 用 `timeout $HOOK_TIMEOUT` 包裹主逻辑

Rationale: 防止 hook 在异常情况下无限等待，基于 context mode hook 平均 694ms 的观测，5s 超时既安全又有裕量。

Three-Check Impact:
- Within-file sync: 无其他需更新的部分
- MEMORY.md: hooks 条目中 block-dangerous 描述不受影响
- Dependent files: settings.json hooks 数组中引用此文件路径，不受影响

Risk Assessment:
- Regression risk: Low — 正常执行远低于 5s
- Conflict with existing: None
- Reversibility: Easy — 删除 timeout 包裹即可
```

## Phase 5: Optimization Proposal — 好示例 (No changes)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHARINGAN: No Changes Recommended
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source: "10 Essential Claude Code Tips" (blog post)
Insights extracted: 5
Insights filtered: 4 (1 platform incompatible, 1 security conflict, 2 already implemented)
Remaining insight: Hook timeout — 经 self-review 发现当前 hooks 执行均 <1s，
  且 PostToolUse backup hook 已提供文件恢复机制，无需额外 timeout 修改。
Current state assessment: 当前 hooks 执行时间短且有 backup 恢复机制，无改动空间。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

正确：经过批判性评估后诚实地得出"不需要改动"的结论，
而非为了产出改动而硬凑一个不必要的修改。
```

---

## Phase 6: Inline QC — 好示例

```
Inline QC Round 1
Target: Optimization Proposal (1 change to hooks/block-dangerous.sh)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: clean
  - [x] Optimality: clean
  - [x] Consistency: clean
  - [x] Standards: Proposal uses `timeout` command but does not check
        if it's available in Git Bash (it is, but noting for completeness).
        Not blocking; no fix needed. [Minor]
  - [x] Write-deny compliance: checked 1 file, 0 violations
Calibration: read pitfalls.md (N entries), examples.md (this file)
Counterfactual: Without the external source I would not propose HOOK_TIMEOUT — this is a source-specific insight. Change is source-justified.
Rating: Minor

Inline QC Round 2
Target: Optimization Proposal (1 change to hooks/block-dangerous.sh)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: clean
  - [x] Optimality: clean
  - [x] Consistency: clean
  - [x] Standards: clean
  - [x] Write-deny compliance: checked 1 file, 0 violations
Calibration: (re-calibration not required; < 3 rounds since last read)
Counterfactual: Source-based timeout change remains justified; no sunk-cost reasoning here.
Rating: Pass
```

### Additional example: Major finding (multi-file proposal)

```
Inline QC Round 1
Target: Optimization Proposal (3 changes to CLAUDE.md, rules/security.md)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: Proposed CLAUDE.md addition references "three-check protocol"
        but the proposal does not include the corresponding MEMORY.md update.
        Fix: Add MEMORY.md update to proposal. [Major]
  - [x] Optimality: clean
  - [x] Consistency: clean
  - [x] Standards: clean
  - [x] Write-deny compliance: checked 2 files, 0 violations
Calibration: read pitfalls.md (N entries), examples.md (this file)
Counterfactual: Source-derived CLAUDE.md rules; the MEMORY.md omission is an internal consistency gap independent of the source — would catch this regardless.
Rating: Major
```

### Anti-pattern: 硬凑 findings

```
Inline QC Round 1
Target: Optimization Proposal (1 change to hooks/block-dangerous.sh)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: clean
  - [x] Optimality: "Could consider using a more sophisticated timeout mechanism" [Major]
  - [x] Consistency: clean
  - [x] Standards: clean
  - [x] Write-deny compliance: checked 1 file, 0 violations
Rating: Major

错误：Optimality 维度没有具体证据说明当前方案不够好，纯属 suspicion-without-evidence。
按 qc 规范应放入 Open Questions 或省略。格式正确不等于内容正确。
```

---

## Phase 8: Execute Changes — 好示例

场景：修改 hooks/block-dangerous.sh 添加 timeout 包裹。

```
Phase 8: Execute Changes

Pre-execution safety:
- OneDrive: N/A (file not in OneDrive)
- File unchanged since proposal: confirmed via Read
- Write-deny list: block-dangerous.sh is NOT on deny list

Execution:
1. Modified hooks/block-dangerous.sh: added HOOK_TIMEOUT=5, wrapped main logic

Three-Check:
  #1 (within-file sync): shebang intact, no other sections affected
  #2 (MEMORY.md): hooks 条目中 block-dangerous 描述不引用 timeout，无需更新
  #3 (dependent files): settings.json hooks 数组引用此文件路径，路径未变，无需更新

changelog.md: added entry "hooks/block-dangerous.sh: added 5s timeout wrapper"
```

### Anti-pattern: 跳过 compare 步骤

```
Phase 8: Execute Changes

1. Modified hooks/block-dangerous.sh
2. Done.

错误：跳过了 Pre-execution safety（未确认文件自方案起未被修改），
跳过了 Three-Check 全部三步。"改完就算完成"是完成偏误的典型表现。
```

---

## Phase 9: Changes QC Loop — 好示例

场景：对 Phase 8 实际改动的文件执行 QC + Blast Radius Scan + MEMORY.md Numerical Audit。

```
Inline QC Round 1 (Changes)
Target: hooks/block-dangerous.sh (modified)
Dimensions:
  - [x] Correctness: clean — timeout 语法正确，变量引用正确
  - [x] Completeness: clean — 所有修改点均在方案范围内
  - [x] Optimality: clean — 5s 阈值基于实测 694ms 有合理裕量
  - [x] Consistency: clean — 与现有 hook 风格一致
  - [x] Standards: clean — shebang, 注释, 变量命名符合约定
  - [x] Write-deny compliance: checked 1 file, 0 violations
Calibration: read pitfalls.md (N entries), examples.md (this file)
Counterfactual: Timeout change correct for modified file; no sunk-cost reasoning — change stands independently on technical merit.
Rating: Pass

Inline QC Round 2 (Changes)
Target: hooks/block-dangerous.sh (modified)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: clean
  - [x] Optimality: clean
  - [x] Consistency: clean
  - [x] Standards: clean
  - [x] Write-deny compliance: checked 1 file, 0 violations
Calibration: (re-calibration not required; < 3 rounds since last read)
Counterfactual: Confirmed — same change, same assessment.
Rating: Pass

Blast Radius: scanned 3 references to [block-dangerous.sh]; 0 stale references found

MEMORY.md audit: 2 values checked; 0 stale
- hooks count: 4 (actual) vs 4 (MEMORY.md) — match
- block-dangerous description: no version/count referenced — N/A

changelog.md: new entry confirmed
```

### Anti-pattern: 遗漏跨文件引用

```
Inline QC Round 1 (Changes)
Target: settings.json (modified — added new deny rule)
Dimensions:
  - [x] Correctness: clean
  - [x] Completeness: clean
  - [x] Optimality: clean
  - [x] Consistency: clean
  - [x] Standards: clean
  - [x] Write-deny compliance: checked 1 file, 0 violations
Rating: Pass

Blast Radius: scanned 0 references; 0 stale

错误：Blast Radius 报告 0 references，但 settings.json 被 scripts/config-check.sh、
scripts/security-review.sh、MEMORY.md 等多处引用。扫描范围不足或 grep 未执行。
```

---

## Phase 10: Safety Verification — 好示例

场景：确认 hook 修改不引入回归、冲突或副作用。

```
Phase 10: Safety Verification

回归检查:
- 现有功能保留: block-dangerous.sh 仍拦截 git push --force 等命令 ✅
- 触发器正常: PreToolUse hook 链中 block-dangerous 仍在 settings.json hooks 数组 ✅
- Hook 链无冲突: 与 context-mode、hookify 等其他 hook 无执行顺序冲突 ✅

冲突检查:
- deny list 违规: 无（未修改 deny 数组）✅
- 文件内部矛盾: 无 ✅
- Hook 执行顺序: 无新冲突 ✅

副作用检查:
- 意外修改的文件: 无（仅修改 block-dangerous.sh + changelog.md）✅
- 新引入的不可用依赖: timeout 命令在 Git Bash 中可用 ✅
- Token overhead 变化: 无（hook 脚本不计入 session token）✅

Safety Verification: PASS
```

### Anti-pattern: 首轮就 pass（未做真正检查）

```
Phase 10: Safety Verification

All checks passed. No issues found.

Safety Verification: PASS

错误：没有列出具体检查了什么。"All checks passed" 是橡皮图章，
未展示回归/冲突/副作用三个维度的任何具体验证内容。
Phase 10 是最脆弱的 phase（TDD 发现完成偏误防御最薄弱），
必须展示每个检查项的具体结果才能 PASS。
```

---

## Reference Value Assessment — 好示例

场景：EXIT POINT 1 后评估外部资料的长期参考价值。

```
### Reference Value Assessment

**Proposed reference**: ref_autoresearch.md — Autonomous AI research loop pattern
**Key patterns**:
- Autonomous experiment loop: modify code → evaluate → keep/discard (git commit/reset)
- Single-file constraint: only one file editable, keeps scope manageable
- Fixed time budget: 5 min wall clock per experiment for fair comparison
- Simplicity criterion: complexity cost vs improvement magnitude
**When to reference**: Iterative analysis optimisation or automated code iteration workflows

Save as reference memory? (Y / N / custom title)

正确：轻量评估，2-4 bullets 概括核心模式，明确触发条件。
用户可快速判断是否值得保存。
```

### Anti-pattern: 硬凑 reference value

```
### Reference Value Assessment

**Proposed reference**: ref_bbc_recipes.md — Structured data schema patterns
**Key patterns**:
- Recipe format as structured data schema inspiration
- Ingredient list as key-value pair paradigm
- Step numbering as workflow sequencing model
**When to reference**: When designing any structured data format

错误：BBC 食谱网站与用户的流行病学研究/编程工作流无关。
三个 "patterns" 都是硬凑的抽象（食谱格式 → 数据模式？）。
这是 action bias 的典型表现——无 value 时应一行终止：
"No reference value identified."
```
