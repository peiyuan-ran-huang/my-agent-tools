---
description: "Critical necessity review of Claude's own proposals — 5-gate filter against action bias + drilldown trap"
allowed-tools: ""
---
<!-- version: 1.1.0 (2026-04-21) — 5 gates + 五问 mantra hard-gate (cond on Gate 2) + negative-assertion scope check (cond on RETRACT/REFINE) + --N counterfactual iteration + no-majority-vote aggregation -->

# /necess — Is this actually necessary?

## Arguments

- `/necess` — single-pass review (default)
- `/necess --N` where N ∈ {2, 3, 4, 5} — run N independent counterfactual passes, then aggregate
- `/necess --1` — equivalent to bare `/necess` (single-pass; does not fire the counterfactual self-deception prompt)
- `/necess --0` or `--6+` or `--abc` or other malformed — print this syntax block and refuse to execute; for N>5 suggest upgrading to `---qc --loop --sub`
- **Arg format rule**: only `--<digit>` (e.g., `--3`) is accepted; positional `3` / single-dash `-3` / equals-form `--N=3` are malformed. Text following a valid `--N` (e.g., `/necess --3 side note`) is ignored as user annotation.

## What To Do

Re-examine every **proposal / suggestion / recommended change** Claude made in the most recent substantive Claude response (default scope; user may widen explicitly for multi-turn review). Include proposals about meta-tools and self-workflow — do not exempt the command's own design. A "proposal" means any Claude-initiated recommendation to add/modify/remove code, config, docs, scope, or approach. Pure tool outputs, status messages, and direct-answer content are out of scope.

For **each** proposal, run it through the following 5 gates in order:

1. **Necessity** — Is the status quo genuinely broken, or am I proposing because proposing feels like progress? Does the "Null option" (do nothing) fail the user's actual need?
2. **Mechanism** — By what concrete mechanism does this take effect? Who executes it? When does it fire? Is it a hard mechanism (env var / hook / config key) or a soft one (text reminder)? Is the soft→hard gap acceptable? (If the proposal contains factual attribution of the types listed below — PMID/DOI, feature/config-key attribution, historical/empirical claim, negative assertion — run the **Factual-assertion hard-gate** as part of this gate's evaluation.)
3. **Proportionality** — Does solution complexity match problem complexity? Does an 80%-effect simpler version exist? Is any layer of the proposal complexity theater rather than genuine need?
4. **Counterfactual** — Strip drilldown momentum: if I weren't already in "how to implement X" mode, would I still recommend X now? Is this sunk-cost reasoning?
5. **Reversibility / Blast Radius** — If this turns out wrong, how hard to undo? What's the damage scope? Is my confidence calibrated to the stakes (L0-L4 ladder)?

### Factual-assertion hard-gate (Gate 2 conditional)

<!-- mirrors CLAUDE.md §Workflow five-question mantra; re-sync on CLAUDE.md changes -->

**Trigger**: the proposal contains a factual assertion of any of these types — PMID/DOI/citation claim; product / feature / config-key attribution ("this comes from X", "feature Y is provided by Z"); historical/empirical claim; negative assertion ("X is not Y", "feature F was never shipped").

**Run the five-question mantra** (operationalizing CLAUDE.md §Workflow factual-attribution hard gate — 候选 / 权威 / 便宜 / 独立 / 置信):

1. **候选** (candidates): What alternative answers exist besides the one claimed?
2. **权威** (authority): What is the first-party canonical source — Anthropic docs / PubMed / DOI / WHO ATC / target tool's official docs?
3. **便宜** (cheap check): What is the lowest-cost verification available right now (a single grep, a WebFetch, a single doc page)?
4. **独立** (independence): Is my verification path independent of the claim's own source?
5. **置信** (confidence): After the check, what is my calibrated confidence — and am I hedging appropriately?

If any of the five questions lacks a clean answer → **Gate 2 fails on that proposal**; the verdict must reflect that the mechanism claim is not independently verified (downgrade KEEP → REFINE, or REFINE stays REFINE with stronger hedge wording). If the claim cannot be quickly verified at all → flag the proposal for user adjudication rather than asserting the mechanism holds.

### Verdict per proposal

- **Pass all 5** → `KEEP` (may refine wording, but substance stands)
- **Fail 1-2 gates** → `REFINE` (output a simpler / narrower / more-justified version)
- **Fail 3+ gates** → `RETRACT` (recommend Null option — first-class outcome, not a retreat)

**Anti over-retract guard**: if the reason for RETRACT is "pure conservatism" rather than a specific gate failure → downgrade to REFINE. Null option stands equal with KEEP/REFINE — never labeled as "backing off".

Before finalizing RETRACT or REFINE, if the verdict reasoning contains a confident negative assertion (no hedging words like "appears", "seems", "likely"), run the **Negative-assertion scope-evidence check** below.

### Negative-assertion scope-evidence check (RETRACT/REFINE conditional)

<!-- mirrors CLAUDE.md §Workflow highest-risk combination — negative + confident tone; re-sync on CLAUDE.md changes -->

**Trigger**: verdict is RETRACT or REFINE AND the reasoning contains a negative assertion in confident tone (no hedging words like "appears", "seems", "likely", "as far as I can tell"). Per `ref_real_time_attribution_detection.md`, negative + confident is the highest-risk combination.

Before finalizing such a verdict:

- Was my search space complete? (grep empty ≠ doesn't exist; file missing ≠ feature absent; "branch never runs" ≠ all code paths audited)
- Did I distinguish absence-of-evidence from evidence-of-absence?
- Is there a broader scope (other directories, other branches, other versions, other tools) I didn't check before concluding "mechanism absent" / "status quo is not broken" / "Null option suffices"?
- Am I confusing the current state with the permanent state?

If any scope concern is unresolved → downgrade verdict reasoning to hedged wording ("we didn't find a mechanism in X" instead of "no mechanism exists"). RETRACT downgrades to REFINE when the negative claim hinges on incomplete search; KEEP is unaffected by this check.

### Genuine re-examination (not rubber-stamp)

- Re-read each proposal as if **a stranger wrote it and your job is to find reasons not to do it**.
- For each gate failure, cite the specific evidence (which claim? which mechanism gap? which complexity layer?).
- Do not exempt meta / self-workflow proposals — the command applies to **any proposal Claude made, including proposals about /necess itself**.

## Multi-pass Mode (`--N`)

When `--N` is present, execute N independent passes before aggregating:

**Each pass begins with this counterfactual self-deception prompt** (internal, not output):

> "This is Pass {k}/{N}. Pretend you have never seen Pass 1..{k-1}. Re-read the original Claude proposals from scratch, ignore prior verdicts, run the 5 gates + 五问 mantra (if Gate 2 trigger fires) + negative-assertion scope check (if verdict ∈ RETRACT/REFINE with confident negative reasoning) again from the user's original question. Do not reference prior conclusions; do not intentionally agree or disagree with them."

Each pass independently decides whether conditional triggers fire based on its own fresh read of the target — do not carry forward Pass (k-1)'s trigger-firing state into Pass k.

Pass k receives only: the original user question + the Claude proposal text. Do **not** feed prior-pass verdicts into later passes. Aggregation happens only after all N passes complete.

**Independence is approximated, not enforced**: passes share Claude's context (prior passes are visible despite the "pretend unseen" instruction); effectiveness degrades with higher N. For genuine context isolation, see §Escalation (`---qc --loop --sub`).

### Aggregation rules (Strategy A — strict conservative, no auto-majority-vote)

| N-pass outcome | Output |
|----------------|--------|
| All RETRACT | "RETRACT, N/N converged" + Null-option alternative |
| All KEEP | "KEEP, N/N converged" + integrated refinement notes from across passes |
| All REFINE (identical wording) | "REFINE, N/N converged" + the single unified refined version |
| All REFINE (wording differs) | Show all N refined versions side-by-side; user picks |
| Any mixed verdict (including 2-vs-1 near-unanimous) | **Show all N verdicts + each gate-failure reasoning in full — do not vote, do not pick majority, do not synthesize an "average" opinion.** Divergence itself is the signal — this proposal sits in the unstable-judgment zone and requires user adjudication (HITL). |

**Tiebreaker — near-identical REFINE**: if REFINE versions across passes are near-identical but not strictly equivalent (paraphrasing, word-order, minor scope variance), default to the "wording differs" row. Err toward showing the user more options, not fewer — collapsing genuine nuance is harder to detect than over-showing.

**Why forbidden to majority-vote**: 3 "independent" passes aggregated as majority gives a false sense of objectivity. The divergence is the finding — tell the user, let them decide.

## Output

### Single-pass (`/necess`)

- **If any proposal failed a gate** →
  1. List each failing proposal: which gate(s) it failed + one-line reason.
  2. Then output the **complete revised response** that replaces the previous one (may include explicit "retract: do nothing" for fully-retracted items). The user should read this single block as the final answer without consulting the original.

- **If all proposals pass all gates** → 2-3 sentences naming which gate came closest to failing and why it held up (not a vacuous "looks good").

### Multi-pass (`/necess --N`)

```
## /necess --N Review

*Per-pass reasoning surfaces 五问 findings inline within the gate-failure reason when Gate 2 deep-check fires; scope-check findings surface inline within the RETRACT/REFINE reason when the scope conditional triggers.*

### Pass 1 Verdict
- Proposal A: RETRACT — fails Necessity + Proportionality (one-line reason each)
- Proposal B: KEEP — passes all 5
- Proposal C: REFINE — fails Counterfactual

### Pass 2 Verdict
- ...

### Pass 3 Verdict
- ...

### Convergence Analysis
- Proposal A: 3/3 RETRACT → strong signal; retract confirmed
- Proposal B: 2 KEEP + 1 REFINE → divergence; all 3 shown below with gate reasoning; user decides (no majority vote per rule above)
- Proposal C: 1 KEEP + 1 RETRACT + 1 REFINE → full divergence; 3 verdicts with full reasoning follow

### Integrated Revised Response
[Block that replaces the original, built per aggregation rules above. Full shown-divergence sections expanded for proposals in the mixed rows.]
```

## Escalation

For high-stakes proposals, meta-tool proposals (including /necess's own design), or persistent divergence → use `---qc --loop --sub` for a truly-isolated subagent counterfactual. `/necess --N` runs N passes in the same context (counterfactual-prompt approximation); `---qc --sub` provides actual context isolation.

If the previous response contains no proposals (pure fact-recall, direct answer, bare tool output) → state "no proposals to evaluate, skipping" and exit. If context has been cleared or compacted, review whatever substantive content remains and note the scope limitation.

No structured report. No severity labels. No templates. Just verdicts + reasoning + revised response.
