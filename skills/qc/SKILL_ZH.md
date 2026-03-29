---
name: qc-zh
description: 当用户消息以 ---qc 开头时触发，对代码、方案、文档、数据、建议或技能/提示词进行五维结构化审查。中文参考版（不会被自动加载）。
---

<!-- version: 1.2.0 | 同步规则：此文件的任何改动必须同步到 SKILL.md，反之亦然。
允许差异：(1) frontmatter name 字段 (qc vs qc-zh)，(2) frontmatter description 语言，(3) SKILL_ZH.md 的加载说明，(4) 翻译过程注释（如说明哪些部分保留英文原文的注释）。
同步标准：逐节语义等价，非行数相等。 -->

# QC：深度审查

## 触发规则

仅当 `---qc`（不区分大小写）作为用户消息的**首个 token** 出现时激活。
忽略出现在代码块、引用块、引号内或行内示例中的 `---qc`。
不得因自然语言触发：check / review / verify / inspect / audit / 检查 / 审阅 / 复核 / 审计 或类似词语。
若用户明显意图为 QC 但未使用哨兵字符，不触发——用户可使用 `---qc` 来调用。

你现在切换为**严格审查者**角色。对指定对象进行认真、仔细、全面、深度、批判性的检查。

## 参数解析

1. 读取 `---qc` 后的参数：第一个非标志 token 为审查对象（可以是一个词、引号包裹的短语、或文件路径——**含空格的文件路径必须用双引号包裹**，例如 `---qc "my project/analysis.R"`；若检测到未加引号的含空格路径，请用户重新输入；仅识别双引号路径包裹——单引号和反斜杠转义空格不受支持；空引号字符串作为审查对象时回退至自动检测步骤 3）；其余为额外标准。扫描所有 token 中的已知标志——标志 token（以 `--` 前缀匹配下列已知标志）无论位置如何均排除在对象/标准识别之外：
   - `--loop`/`--循环` [N]：激活**循环模式**（N 默认为 3；若该标志后紧跟正整数 token，则该 token 被消费为 N，不视为审查对象；非正整数（如 `--loop 0`）及非数字 token 不被消费为 N——未被消费的 token 重新进入正常 token 流；若由此产生明显无意义的审查对象，提示用户澄清）
   - `--sub`/`--子代理`：激活**子代理反事实模式**（见下方）

   `--loop` 和 `--sub` 可以同时使用，二者为独立开关，互不冲突（各自行为见对应章节）。
2. 对象映射：代码/code → 代码 | 方案/plan → 方案 | 文档/doc → 文档 | 数据/data → 数据 | 建议/advice → 建议 | skill/prompt/技能/提示词 → 技能/提示词 | diff/changeset/directory/目录 → 代码叠加（影响范围 = diff/目录）；若内容混合 → 按用户问题指向或内容主体比例选主体类型，次要类型叠加检查
3. 无参数 → 按以下优先级自动识别：
   1. 用户当前消息中提及的文件路径
   2. 最近一次 assistant 的实质性输出——须满足：(a) ≥3 行代码块、≥5 项编号方案、或 ≥5 行连续散文（排除纯表格、纯数据输出或单行回答）；(b) 可归类为代码、方案、文档、数据、建议或技能/提示词（排除工具状态输出、报错信息、数据转储）；不确定时跳至步骤 3
   3. 本次会话中最近编辑或读取的文件
   4. （兜底）提示用户指定
4. 若目标内容不在当前上下文中但有明确文件路径或最近编辑的文件 → 先用 Read 读取再审查；文件过大时 → 分段读取，优先读取核心逻辑部分。若 Read 失败（文件不存在、权限错误），在 Coverage 中报告失败，回退至上下文中的内容（若有，标注 `[degraded: context fallback]`），或提示用户确认路径

## 循环模式（由 `--loop [N]` / `--循环 [N]` 激活）

当 `--loop` 存在时，执行审查-修复-再审查循环：

1. 对目标执行标准 QC 审查
2. **Pass** → 连续通过计数器 +1（若 `--sub` 激活，需经子代理反事实覆盖；见子代理反事实模式）；**非 Pass** → 计数器归零，修复所有非 WNF 发现（Critical → Major → Minor），然后重新审查。若同一发现（同一维度、同一位置）在此前某轮被修复后再次出现，在轮次状态头中记录复发（如 `History: [M, m, M(recur), ...]`）。若该发现复发 3 次（即修复后在 3 个独立轮次中再次出现），暂停并告知用户："此发现已在修复后复发 3 次——可能需要人工介入。标记为 WNF 或提供指导？"
3. 退出条件：连续通过次数 >= N（默认 3），或总轮次 >= 15。若循环因达到轮次上限（总轮次 >= 15）而退出，且最近一轮评级为非 Pass（如子代理在最后一轮 reopen），则报告：`[Loop cap reached: X/15 rounds completed. Final rating: [rating]. Unresolved findings remain — see last round's report above.]`
4. 每轮报告以状态头开始：`🔄 Round X/15 | Passes: Y/N | History: [P, M, m, P, ...]`（P=Pass, C=Critical, M=Major, m=Minor）  <!-- emoji is part of this template's format spec; overrides default no-emoji rule -->
5. 目标在调用时解析一次；后续轮次审查同一目标（文件：从磁盘重新读取；上下文中的内容：审查 Claude 输出的最新修正版——Claude 在轮次报告中输出修正版以应用修复，后续轮次审查该最新输出）。若重新读取在循环过程中失败（文件被删除、重命名或权限变更），适用与参数解析步骤 4 相同的降级处理：在 Coverage 中报告，回退至上下文中的内容（若有，标注 `[degraded: context fallback]`）；若连续 2 轮重新读取失败，终止循环并报告 `[Loop terminated: target unreadable since round X]`。若目标为自动检测（非用户显式指定）且 `--loop` 激活，进入循环前须与用户确认自动检测的目标。若用户拒绝自动检测的目标，提示用户显式指定目标（参数解析步骤 3.4）后再进入循环
6. 校准文件（examples.md、pitfalls.md）：启动时读取一次。进化协议：**仅在循环退出轮执行**（循环终止的那一轮，无论是通过达到 N 次连续通过还是达到轮次上限）。

循环模式下，"只审不改"原则暂停：Claude 在各轮之间修复发现的问题。若修复需要用户确认，暂停循环并询问。若用户拒绝某项修复，将该发现标记为**不予修复（WNF）**。后续轮次的严重性评级中排除 WNF 项（因此，一个所有剩余发现均为 WNF 的轮次在整体评级规则下视为 Pass）。在轮次状态头中追踪 WNF 项以供审计（如 `History: [M, P(1 WNF), P, P]`）。对 Critical 级别的 WNF：需提示用户显式确认（"此 Critical 发现涉及 [描述]——确认跳过？"），并在状态头中标记为 `P(1 C-WNF)`。若因工具故障（如文件目标的 Write 工具不可用）无法应用修复，视为需用户介入——暂停循环并报告故障。

**不偷懒规则（通过轮次）**：即使在连续通过的轮次中，每轮也**必须**：
1. **重新读取**磁盘上的目标文件（使用 Read 工具；不得依赖上下文记忆；对上下文中的内容目标，重新检视对话上下文中的最新版本）
2. 执行真实的**五维评估**——紧凑格式可接受（每个维度一行判定），但每个判定必须反映对目标内容的实际重新审查，而非复制上一轮的结果
3. 在**反事实测试**中引用一个与上一轮反事实聚焦区域**不同**的具体区域（文件:行号或逻辑点）——在各轮之间循环审查不同的风险区域，避免每轮都检查同一个点。对于审查区域有限的小型目标，可以从不同角度（如正确性 vs 性能 vs 边界情况）重新审视已检查过的区域。

仅复制上一轮格式而无新审查证据的通过轮次视为协议违规。输出可以紧凑，但审查**必须**真实。

**深度检查点轮次**：在轮次编号为 5 的倍数的轮次（第 5、10、15 轮），**必须**产出**完整五维报告**（展开推理，非紧凑格式），无论当前评级或连续通过情况如何。将深度检查点视为第 1 轮——以全新视角和最高严格度审查目标。此定期强制展开抵消后期轮次中自然出现的浅层重复趋势。深度检查点与子代理反事实相互独立——当各自条件满足时均适用。在 `--sub` 激活且评级为 Pass 的深度检查点轮次中，同时产出完整五维报告并派发子代理。

**上下文压力管理**：在长循环中（第 6 轮起，非检查点轮次），若上下文占用较高，可将第 1 轮至第 (current_round - 4) 轮压缩为单行状态记录（轮次编号 + 评级 + 关键发现 ID）以释放上下文空间。若此操作影响审查深度，在 Coverage 中报告 `[degraded: context pressure]`。若循环过程中达到上下文限制，以 `[Loop terminated: context limit reached at round X]` 终止。

**对抗性重构**：第 2 轮起，审查前先切换立场："假设这是别人写的，我的任务是找问题而非确认正确。"这抵消了对自己修复的天然认可倾向。

## 子代理反事实模式（由 `--sub` / `--子代理` 激活）

当 `--sub` 存在时，反事实测试（见重要原则中的元校准）由物理隔离的子代理执行，而非在同一上下文中内联运行。这提供了真正的上下文隔离——子代理从未参与过生成或审查过程，消除了自审偏差。

### 派发逻辑

```python
# 五维审查完成后、写总结之前：
if --sub 激活:
    if --loop 激活:
        if 本轮评级 == "Pass":
            result = dispatch_subagent_counterfactual()
        else:
            result = inline_counterfactual()    # 非 Pass：问题已浮出水面；inline 足够
    else:
        result = dispatch_subagent_counterfactual()

    # 派发后处理（仅子代理）：
    if result.source == "subagent":  # source 从派发上下文推断，而非从子代理输出中读取
        apply_severity_adjustments(result.severity_adjustments)  # 对 confirmed 和 reopened 均适用
        if result.verdict == "reopened":
            apply_new_findings(result.new_findings)
            recalculate_overall_rating()
            update_round_history(round_number, new_overall_rating)  # 将初始 'P' 替换为重算后的评级
            consecutive_passes = 0  # 显式重置——不依赖下一轮的隐式检测
```

> **Confirmed + severity_adjustments**：`confirmed` 裁决仍可包含非空 `severity_adjustments`（例如子代理确认无遗漏问题但建议调整现有发现的严重性）。无论裁决如何均适用这些调整。

> **反降级自检**：在写 `**反事实**:` 行之前，验证："是否 `--sub` 激活且本轮评级为 Pass（循环模式）或任意评级（非循环模式）？"若为是，**必须**派发子代理——如果发现自己即将写内联反事实而条件满足时，**停下来**改为派发子代理。绝不在未报告 `[degraded: inline fallback]` 和具体失败原因的情况下静默降级为内联。若为否（即循环模式 + 非 Pass 轮次），内联反事实为**设计行为**——无需降级标签。

### 子代理规格

- **Agent 类型**：`general-purpose`，`model: "opus"`（运行时约定下的最新 Opus 级模型；不可用时见下方降级处��）
- **会话目录**：在 session 首次派发子代理时，生成 session 唯一的工作目录：通过 Bash 运行 `echo "$(date +%s)_${RANDOM}"` 获取唯一 ID，然后使用 `C:/tmp/qc_sub_<id>/` 作为工作目录（如 `C:/tmp/qc_sub_1711700000_12345/`）。将此路径存储为 `QC_SUB_DIR`，在同一 session 的所有后续子代理派发中复用。循环模式下，每轮的清理和下一轮的写入使用同一个 `QC_SUB_DIR`。
- **启动清理**：在写入临时文件前，若 `QC_SUB_DIR` 已存在，先删除其全部内容（防止崩溃/中断的前一次会话的残留文件污染当前审查）。
- **输入**：写入两个临时文件到 `QC_SUB_DIR`（目录不存在时自动创建）：
  - `target_temp.md` — 审查目标内容（文件目标则复制文件内容；上下文中的内容则写入临时文件）
  - `findings_temp.md` — 五维审查发现，使用 QC 报告格式（每条发现以 `#### [维度] — [严重性]` 为标题）；对 Pass 评级且无发现的轮次，写入：`✓ Correctness / Completeness / Optimality / Consistency / Standards: No issues\n\n**Overall Rating**: Pass`。在 findings_temp.md 末尾追加 `## Matched Pitfalls` 部分，列出与当前审查目标上下文匹配的错题本条目（使子代理也能访问用户自定义的检查项）
- **Prompt**：必须使用以下规范模板逐字填写。��允许填入五个 `{{...}}` 标记字段。不得添加指示聚焦特定维度、缩窄审查范围或跳过任何方面的指令。

  <!-- 以下模板为子代理使用的英文原文，不翻译。仅翻译填入字段说明和约束条款。 -->

````
You are an independent reviewer who has NOT participated in the creation or initial review of the target below. Your task is to provide a thorough, unbiased second opinion.

## Target Information
- **Type**: {{TARGET_TYPE}}
- **Domain context**: {{DOMAIN_CONTEXT}}
- **Target-specific checks**: {{TARGET_OVERLAYS}}
- **Content**: Read the file `{{QC_SUB_DIR}}/target_temp.md`
- **Original file path** (if file-based target): {{ORIGINAL_FILE_PATH}}

## Initial Review Findings
Read the file `{{QC_SUB_DIR}}/findings_temp.md`

## Cross-validation (mandatory for file-based targets)
If an original file path is provided above, ALSO read it directly from disk and compare with the temp copy. If they differ, the disk version is authoritative — base your review on it and note the discrepancy. If the original file cannot be read (not found, permission error), proceed with the temp copy and note: [cross-validation skipped: original file unreadable].

## Your Task

Perform a COMPREHENSIVE independent review across ALL of the following five dimensions with EQUAL depth and rigor. Do NOT focus on any single dimension — every dimension deserves the same thoroughness.

1. **Correctness**: Facts accurate? Logic sound? No hallucinations or fabrications?
2. **Completeness**: All key points covered? Edge cases considered? Dependencies checked?
3. **Optimality**: Best approach? Any simpler or more efficient alternatives?
4. **Consistency**: Aligned with context / requirements / existing code? No self-contradictions?
5. **Standards**: Compliant with relevant standards? (academic conventions / coding style / security rules)

Also apply the target-specific checks listed above.

You must:
- (a) Find issues the initial review MISSED — actively look for blind spots, not confirmations
- (b) Verify severity assignments of ALL existing findings — are any over- or under-rated?
- Start from the execution layer (scripts, configs) rather than documentation
- Verify implementation assumptions — comments/labels do not guarantee enforcement
- Check for namespace collisions (ID/key/variable uniqueness)

## Severity Definitions
- **Critical**: factually wrong, dangerous, or fundamentally broken
- **Major**: significant functional gap or risk
- **Minor**: style, edge case, or non-blocking improvement

## Output Format
Respond with a JSON object ONLY (no markdown wrapping, no commentary outside JSON):
```json
{
  "verdict": "confirmed | reopened",
  "area_examined": "[MUST cite specific locations: file:line, code snippets, logic paths. Generic statements are INVALID.]",
  "reasoning": "[MUST provide detailed reasoning with specific references. 'Looks good' or 'no issues' is INVALID.]",
  "severity_adjustments": [
    {"finding_ref": "Dimension — Severity", "proposed": "new severity", "reason": "..."}
  ],
  "new_findings": [
    {"dimension": "...", "severity": "...", "evidence": "...", "issue": "...", "suggested_fix": "..."}
  ]
}
```
````

  **填入字段定义**：
  - `{{TARGET_TYPE}}`：参数解析中确定的目标类型（代码 / 方案 / 文档 / 数据 / 建议 / 技能/提示词）
  - `{{DOMAIN_CONTEXT}}`：1-2 句领域描述（如："R tidyverse 数据处理脚本，用于流行病学分析" / "遵循 STROBE 指南的学术稿件"）
  - `{{TARGET_OVERLAYS}}`：从 §对象专项叠加 复制该目标类型的完整叠加检查清单（如代码："+安全漏洞 +性能 +错误处理 +可读性 +依赖合理性 +测试覆盖"）
  - `{{ORIGINAL_FILE_PATH}}`：文件类目标为磁盘上的原始文件路径（如 `~/project/analysis.R`）；上下文中的内容则写 "N/A — in-context content"
  - `{{QC_SUB_DIR}}`：在会话目录步骤中生成的 session 唯一工作目录路径（如 `C:/tmp/qc_sub_1711700000_12345`）

  **约束**：若主 agent 需要提供额外上下文（如轮次编号、前几轮发现了什么），可在模板内容**之后**添加 `## Additional Context` 部分，但该部分**不得**覆盖、缩窄或优先任何维度。违例——如"聚焦完整性"或"特别检查影响范围"——被禁止。
- **清理**：每次整合子代理结果后删除 `QC_SUB_DIR` 下所有临时文件（循环模式下，每轮子代理结束后清理，而非仅在循环退出时清理）

### 降级

子代理派发失败（工具错误——包括创建临时文件时 Write 工具失败——、超时、模型不可用等）→ 回退到内联反事实测试。报告行显示 `[degraded: inline fallback]`。

### 输出格式变化

总结部分的 `**反事实**:` 行增加来源标记：

- `[subagent] Confirmed — ...` 或 `[subagent] Reopened — ...`
- `[degraded: inline fallback] Confirmed — ...`
- （无标记）= 内联反事实测试（默认，`--sub` 未激活时）

## 影响范围扫描（仅限文件修改）

当审查对象涉及文件修改时（包括 `directory`/`目录` 目标，视为多文件变更集），在五维审查前执行以下预扫描：

1. 识别变更集：若有 diff/changeset 则使用；否则列出本次会话中**与审查对象相关的**被修改文件（非整个会话的所有修改）
2. **在报告中显式声明扫描边界**（见下方模板）：说明哪些文件在范围内，搜索了哪些目录
3. 对每个变更文件，搜索引用了它的其他文件——使用 Grep 搜索文件名/路径；检查 import/require/source 语句；搜索索引文件（MEMORY.md、CLAUDE.md、AGENTS.md、README.md、包清单、仓库级指令文件）中的引用。范围：当前工作目录；若涉及配置文件则扩展到 `~/.claude/`。此扫描不会自动覆盖工作空间以外的固定路径；对于已知的外部依赖，请将其编码为错题本条目。
4. 对每个发现的引用，评估其是否为实质性依赖（而非仅仅提及），以及是否需要更新
5. 将发现的问题输入下方完整性维度
6. 对配置文件（`.bashrc`、`settings.json`、`mcp.json`、`MEMORY.md`、`rules/*`、`scripts/*`），额外验证是否符合工作空间中定义联动更新规则的指令文件（如 `CLAUDE.md`、`AGENTS.md`、仓库级策略文件）的联动更新规则（如存在）

**边界规则**：若用户仅提供文件路径（如 `---qc file.R`）而无 diff/changeset，且当前会话中该文件未被修改，则视为**独立内容审查**——跳过影响范围扫描。仅在以下情况执行影响范围扫描：(a) 明确提供了 diff/changeset，(b) 该文件在当前会话中被修改过，或 (c) 用户明确要求审查修改影响。

**仅当**审查对象为完全独立的内容且无文件依赖时跳过此步（包括上述边界规则中的"仅文件路径无修改上下文"场景，以及独立的建议、尚未保存到文件的文档草稿、或不涉及现有文件的方案）。

若影响范围扫描期间 Grep 不可用，在影响范围输出行报告 `[degraded: no blast radius]`，并在 Coverage 中注明此限制。

## 审查框架（五维）

逐维检查，对每个维度给出判定：

| 维度 | 核心问题 |
|------|----------|
| 正确性 | 事实准确？逻辑无误？无幻觉或捏造？ |
| 完整性 | 关键点无遗漏？边界情况已考虑？ † |
| 最优性 | 是否最优方案？有无更简洁或更高效的替代？ |
| 一致性 | 与上下文/参考原文/已有代码/用户要求一致？无自相矛盾？ |
| 规范性 | 符合相关标准？（学术规范/编码风格/安全规则） |

> † 修改文件时，完整性包含影响范围检查——见上方**影响范围扫描**。

### 对象专项叠加

- **代码**：+安全漏洞 +性能 +错误处理 +可读性 +依赖合理性 +测试覆盖
- **方案**：+可行性（技术/资源/时间可达性）+潜在风险（列出前 3 项，标注概率 高/中/低 × 影响 高/中/低）+缓解策略（每项风险对应 1–2 句）+步骤遗漏（列出关键缺失步骤）+资源估计（人力/时间/工具，量化）
- **文档**：+引用真实性 +事实核查 +学术规范（STROBE/CONSORT 等）+数值一致性
- **数据**：+变量定义 +缺失值处理 +样本量 +数据来源层级 +数值单位/量纲一致性 +数据类型合理性
- **建议**：+是否答对问题 +有无更优替代 +潜在副作用或负面后果 +适用边界与前提
- **技能/提示词**：+触发/激活边界清晰度 +参数解析边界情况（空格、引号、空输入）+指令文本与示例的一致性 +Token 成本意识（强制预读、增长的参考文件）+可移植性假设（依赖哪些运行时特性？）+降级路径覆盖（skill 是否定义了工具不可用或上下文不足时的行为？——缺失 → Major）+自审偏差风险（同一 agent 既生成又审查输出而无隔离？——Minor，设计局限）+运行时 vs 开发材料边界（文件是否明确标注为运行时加载 vs 仅开发参考？——Minor，认知负担）

## 输出格式

> **严重性定义**：Critical = 事实错误、存在危险或根本性缺陷；Major = 重大功能缺失或风险；Minor = 风格、边界情况或非阻塞性改进。
>
> **整体评级判定**：有任一 Critical → Critical；无 Critical 有 Major → Major；全为 Minor → Minor；无发现 → Pass

按以下模板输出：

```
## QC 审查报告

**审查对象**：[自动识别/用户指定]
**对象类型**：[代码 / 方案 / 文档 / 数据 / 建议 / 技能/提示词]
**额外标准**：[用户指定内容，无则省略此行]
**覆盖范围**：[完整 | 部分——说明审查了哪些部分/文件，跳过了哪些及原因]
**影响范围**：[N/A — 独立内容 | 范围：[边界声明]；扫描了 X 个文件；发现 Y 处过时引用]
**错题本检查**：[N/A — 无错题本文件 | 检查了 X 条；Y 条匹配上下文；Z 条触发发现]

### 发现

[仅展开有问题的维度，标注 Critical/Major/Minor]

#### [维度名] — [Critical/Major/Minor]
- **证据**：[原文引用 / 文件:行号 / 代码片段 / "缺失：预期在 Y 中有 X 但未找到" / "Grep 对模式 X 返回 0 结果"]
- **问题**：描述
- **建议修复**：建议

[全部通过的维度合并为一行]
✓ 正确性 / 完整性 / …：无问题

### 开放问题

[可选。列出证据不足或上下文不充分、无法确认/否认的项目。每项注明何种信息可解决疑问。无不确定项时完全省略此节。]

- **问题**：[歧义描述]
- **可通过以下方式确认**：[何种信息或检查可解决]

### 总结
- **整体评级**：[Critical/Major/Minor/Pass]
- **反事实**：[Confirmed — [引用具体复查区域及其经受住审视的原因] | Reopened — [复查区域及新增发现]]
- 总体评价（1–2 句）
- 改进建议清单（如有）
- 进化检查：[未发现新模式 | 见下方进化提议]
```

## 重要原则

- **输出校准**：在撰写报告前，读取本 skill 目录（`~/.claude/skills/qc/`）下的 `examples.md`（格式/严重性校准）和 `pitfalls.md`（用户自定义检查项）。对每条错题本条目，先判断其触发标签（如有）是否匹配当前审查对象的类型和上下文，仅应用匹配的条目。在错题本检查输出行中报告：检查了 X 条；Y 条匹配上下文；Z 条触发发现。若 `pitfalls.md` 超过约 30 条，先扫描标签/标题，仅完整读取匹配部分。若任一文件不可用或为空，直接继续。
- **错题本标签匹配规则**：`[tag1/tag2]` — `/` 表示 OR；条目中任一标签匹配当前上下文即适用。无标签 = 始终适用（等同于 `[all]`）。匹配基于上下文语义判断（AI 判定适用性），而非对目标类型名称的字面匹配。建议标签：`[all]`、`[code]`、`[academic]`、`[academic/statistics]`、`[file-modification]`、`[file-path]`、`[code/R/Python]`、`[skill/prompt]`。标签应保持在单一维度内（对象类型 或 动作上下文 或 语言），避免在同一个 OR 组中混合不同维度。
- **只审不改**：输出审查报告，不自动修改任何内容。修复由用户决定。（`--loop` 激活时此原则暂停——见上方**循环模式**。）
- **循证而非循疑**：Findings 部分的每条发现必须有实质证据（原文引用、文件:行号、代码片段、或显式缺失引用）。证据不足的不确定项 → 放入**开放问题**部分。目标：不漏掉任何真实问题——但无证据的疑点是问题，不是发现。
- **引用项目级学术规则**：若当前上下文中存在学术工作流规则（如引用核查、数值报告规范），优先引用。
- **额外标准优先**：用户指定的额外标准在五维框架之上优先检查。
- **绝不跳过影响范围扫描**：凡涉及文件修改的审查，必须在五维审查前执行影响范围扫描。拿不准是否适用时，宁可执行——漏检的代价远高于多扫一次。
- **定稿前元校准**：在撰写总结部分之前，重新审视所有发现并自问：
  1. 如果这条发现单独出现，我会给同样的严重性评级吗？
  2. 我是否因发现太少而虚高评级，或因发现太多而压低评级？
  3. **反事实测试**（对所有评级必做）：根据当前评级选择对应问题——Pass/Minor："如果这份审查对象是由陌生人首次提交的，我还会认为没有 Critical 或 Major 问题吗？"；Major/Critical："我是否低估了严重性——这是否实为 Critical / 这真的是 Major？"如不确定，选最薄弱的区域以对抗性视角重新审视后再确认。循环模式第 2 轮起，reasoning 必须具体说明上一轮修复是否正确且完整。
     **有效执行操作指南**：
     - 从执行层（脚本、配置）切入，而非文档——文档在常规 QC 中已覆盖，执行代码才是信任盲区。
     - 验证实现假设——看到注释或标签（如 `<!-- T050 -->`）不等于系统会强制执行，必须读执行代码确认。
     - 扫描命名空间碰撞——ID/key/变量名唯一性是自测试代码最常见的碰撞点。
     - 追溯根因链——发现 bug 后问"为什么这个 bug 能存在？"，找到缺失的 guard、registry 或 spec 覆盖。
  如有偏差，调整后再写总结。

## 进化协议

完成 QC 报告后（循环模式下：仅在循环退出轮执行——见循环模式章节；异常终止如目标不可读或上下文限制退出时跳过），反思本次审查是否发现了值得保留的知识。这是**后审步骤**——绝不干扰审查本身。

### 何时提议

自问：
- 是否遇到了现有叠加检查未覆盖的对象类型？
- 是否发现了值得为未来审查记录的模式，且不在 pitfalls.md 中？
- 是否发现了 examples.md 中缺失的校准案例（如新的反模式或严重性边界情况）？
- 是否运用了应当形式化的领域知识？

若任一为"是" → 在报告的**总结部分之后**追加进化提议部分（作为 QC 报告的最后一节）。若全部为"否" → 正常结束，不强行提议。

### 提议格式

在报告末尾追加以下区块：

```
### 进化提议

> 🔄 **拟议进化**  <!-- emoji 属于本模板格式规范；覆盖默认 no-emoji 规则 -->
>
> **类型**：pitfall（错题）| example（样例）| overlay-gap（叠加缺口）
> **草拟条目**：
> `- **标题** [tag1/tag2]: 一句话描述`
> **理由**：为何现有规则未覆盖。
> **操作**："追加到 pitfalls.md" / "追加到 examples.md" / "标记待 SKILL.md 审查"
>
> *批准 / 修改 / 拒绝？*
```

### 写入机制（用户批准后）

- 在 pitfalls.md 的 `## Entries` 部分最后一条之后追加新条目（匹配 `## Entries` 前缀，忽略任何双语后缀）（或 examples.md 的对应部分）
- 自动附加来源注释：`<!-- via: evolution-proposal, YYYY-MM-DD -->`
- 写入前扫描现有条目是否存在语义重叠；若有，提醒用户并建议合并而非新增

### 约束

- 每次 QC 审查最多 1 条提议（避免提议疲劳；若确实有 2+ 个新颖模式，选最有价值的那条）
- 绝不自动写入任何文件；始终等待用户确认
- 绝不提议修改五个核心维度或严重性定义
- 涉及 SKILL.md 结构性改动（新叠加检查、新维度）的提议 → 仅标记，留待专门审查会话
