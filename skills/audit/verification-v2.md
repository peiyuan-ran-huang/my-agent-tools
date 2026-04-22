# Audit Verification V2

This document defines the faster maintenance verification workflow for the live `audit` skill package.

It is a maintenance process document, not a runtime authority.

If this document conflicts with a canonical runtime source, the canonical runtime source wins.

## Goal

Verification V2 keeps the current quality bar while reducing repeated whole-package re-review.

The key idea is:

- move checker-driven drift-prone literals into one structured contract source
- classify changes by risk zone instead of resetting every counter blindly
- split reviewers into fixed lanes
- require one full-package final sweep only after delta rounds are already clean

## Why V1 Stalls

The previous workflow was slow for structural reasons:

- the same rule often had to stay aligned across runtime docs, README, spec, checklist, fixture, and checker
- any new finding, even in maintenance prose, reset the whole clean-count sequence
- reviewers repeatedly re-scanned the full package even when only a small maintenance surface changed

V2 reduces that waste without weakening the standard.

## Core Assets

- [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv)
  Structured source for checker-driven canonical-source rows, coverage-checklist items, scenario-heading families, expected example headings, example-order invariants, and verification-ledger header / Severity / Status schema families.
- [verification-issue-ledger.md](verification-issue-ledger.md)
  Stable ledger for open/resolved verification findings so the same issue is not repeatedly treated as “new”.
- [scripts/audit-self-check.sh](scripts/audit-self-check.sh)
  Deterministic gate that should catch contract-backed drift before reviewers spend time on it.
- [release-checklist.md](release-checklist.md)
  Human release gate.

## Risk Zones

### Red Zone

Runtime authority changed.

Default members:

- [SKILL.md](SKILL.md)
- any file under [references](references)
- any file under [templates](templates)
- runtime config scripts under [scripts](scripts) except [audit-self-check.sh](scripts/audit-self-check.sh)

### Yellow Zone

Maintenance authority changed.

Default members:

- [README.md](README.md)
- [release-checklist.md](release-checklist.md)
- [audit-self-check-spec.md](audit-self-check-spec.md)
- [scripts/audit-self-check.sh](scripts/audit-self-check.sh)
- [scripts/check-smoke-evidence.sh](scripts/check-smoke-evidence.sh)
- [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv)
- [verification-v2.md](verification-v2.md)
- [verification-issue-ledger.md](verification-issue-ledger.md)

### Green Zone

Calibration-only assets changed.

Default members:

- [examples.md](examples.md)
- [test-scenarios.md](test-scenarios.md)
- purely explanatory changelog-style edits inside maintenance docs that do not alter gates

## Review Lanes

### Lane A: Entry / Canonical

Scope:

- entry files
- canonical source map
- bilingual parity

### Lane B: Runtime Boundaries

Scope:

- degradation rules
- config/helper-script boundaries
- success-vs-degraded output contracts

### Lane C: Calibration / Fixtures

Scope:

- examples
- scenario fixtures
- report-shape calibration
- target-family route preservation

### Lane D: Maintenance System

Scope:

- `verification-v2.md`
- checker
- checker spec
- release checklist
- contract file
- issue ledger

## Reset Rules

### Green-only changes

Required:

1. local checker clean
2. one delta-lane clean round
3. one whole-package final clean round

Do not reset the main runtime clean count.

### Yellow present, no Red

Required:

1. local checker clean
2. two delta-lane clean rounds
3. one whole-package final clean round

Reset maintenance clean count, not runtime clean count.

### Any Red present

Required:

1. local checker clean
2. two delta-lane clean rounds
3. one whole-package final clean round
4. manual smoke-test plan review remains mandatory

Reset whole-package clean count.

## Delta-First Execution Protocol

1. Determine changed files.
2. Classify them into Red / Yellow / Green.
3. Run [scripts/audit-self-check.sh](scripts/audit-self-check.sh).
4. Open or update [verification-issue-ledger.md](verification-issue-ledger.md).
5. Run only the affected lanes first.
6. If a concrete finding appears, fix it and update the ledger before restarting the relevant clean count.
7. Once the required delta rounds are clean, run one whole-package final sweep.
8. Close only when the final sweep is clean and no open `blocker`-severity row remains in the ledger.

## Issue Ledger Rules

- Every concrete finding gets a stable ledger ID.
- Every ledger row must carry a severity so the close condition can distinguish blockers from lower-priority maintenance findings.
- The self-check must fail if the ledger loses the canonical `Severity` / `Status` header shape or the allowed severity/status value families.
- The self-check must also fail if ledger IDs become blank or duplicated; reviewers still judge whether an existing issue should have reused its prior ID instead of getting a new one.
- Re-checking an already logged issue does not count as a “new” finding.
- A clean round resets only when:
  - a truly new concrete issue appears, or
  - a previous fix introduces a new regression
- Pure rewording of an already logged issue should update the existing ledger row, not create a new one.

## First-Pass Contract Coverage

The first implementation of V2 uses [contracts/maintenance-contracts.tsv](contracts/maintenance-contracts.tsv) for:

- canonical source map rows
- coverage-checklist literal items
- coverage-checklist regex-backed items
- required scenario-heading families
- expected example headings
- the Example 1 ordered separator invariant
- verification-ledger header plus allowed severity/status value families

These were chosen first because they created repeated maintenance drift with low runtime risk but high review churn.

## Future Contract Expansion

Candidate next extractions:

- support-file load-order literals
- fixed final-summary labels
- degraded-output warning scaffold
- helper-script conditional boundary literals
- selected cross-file anchor families now still hardcoded in the checker

## Non-Goals

V2 does not:

- replace runtime smoke tests
- weaken manual heavyweight-strength review
- make README or the contract file a runtime authority
- eliminate whole-package review entirely

## Practical Stop Condition

V2 is working as intended when:

- the checker catches most maintenance drift before reviewers do
- reviewers spend most time on genuinely new issues
- whole-package final review becomes the confirmation step, not the discovery step
