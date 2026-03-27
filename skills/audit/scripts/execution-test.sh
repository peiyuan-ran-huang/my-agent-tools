#!/usr/bin/env bash
# Audit skill — execution-level tests for script-layer dynamic behaviour
# Complements audit-self-check.sh (static checks) with runtime execution path tests.
# All tests use temporary directories; never modifies real configuration.
#
# Rule ID registry:
#   E001-E014  config-check.sh
#   E020-E028  config-optimize.sh
#   E030-E040  config-restore.sh
#   E050-E055  validate-report.sh
#   E060-E070  parse-audit-args.py
#
# Exit codes:
#   0 = all tests pass
#   1 = one or more tests fail
#   2 = test harness execution error

set -euo pipefail

on_error() {
  local line="$1"
  echo "ERROR: execution-test.sh failed at line $line" >&2
  exit 2
}
trap 'on_error $LINENO' ERR

die() {
  echo "ERROR: $*" >&2
  exit 2
}

# Restrict temp file permissions (match config-optimal-values.sh security posture)
umask 077

# ── Dependency checks ─────────────────────────────────────────────
for cmd in bash grep mktemp mkdir rm cp cat mv; do
  command -v "$cmd" >/dev/null 2>&1 || die "required command not found: $cmd"
done

# Resolve jq (optional — T1/T2/T3 require it, T4/T5 do not)
JQ_BIN=""
if command -v jq >/dev/null 2>&1; then
  JQ_BIN="$(command -v jq)"
elif command -v jq.exe >/dev/null 2>&1; then
  JQ_BIN="$(command -v jq.exe)"
fi

# Resolve python (optional — T5 requires it)
PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python3)"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="$(command -v python)"
fi

# ── Script paths ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_CHECK="$SCRIPT_DIR/config-check.sh"
CONFIG_OPTIMIZE="$SCRIPT_DIR/config-optimize.sh"
CONFIG_RESTORE="$SCRIPT_DIR/config-restore.sh"
VALIDATE_REPORT="$SCRIPT_DIR/validate-report.sh"
PARSE_ARGS="$SCRIPT_DIR/parse-audit-args.py"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
GOLDEN_DIR="$PACKAGE_ROOT/goldens"

for script in "$CONFIG_CHECK" "$CONFIG_OPTIMIZE" "$CONFIG_RESTORE" "$VALIDATE_REPORT" "$PARSE_ARGS"; do
  [[ -f "$script" ]] || die "script not found: $script"
done

# ── Temp directory with cleanup ───────────────────────────────────
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/audit-exec-test.XXXXXX")"
trap 'rm -rf "$TEST_TMP" 2>/dev/null || true' EXIT

# ── Counters and framework ────────────────────────────────────────
TOTAL_CHECKS=0
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
declare -a FINDINGS=()

record_pass() {
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  PASS_COUNT=$((PASS_COUNT + 1))
}

record_finding() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local message="$4"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  case "$severity" in
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    *) die "unsupported severity: $severity" ;;
  esac
  FINDINGS+=("$severity $rule $file $message")
}

# ── Helpers ───────────────────────────────────────────────────────

# Create a fake HOME with .claude/ and a settings.json
setup_fake_home() {
  local fake_home="$1"
  local settings_content="$2"
  mkdir -p "$fake_home/.claude"
  printf '%s\n' "$settings_content" > "$fake_home/.claude/settings.json"
}

# Run a script with overridden HOME; capture stdout, stderr, exit code.
# Results exported in global variables: RUN_STDOUT, RUN_STDERR, RUN_RC
run_with_home() {
  local fake_home="$1"
  local script="$2"
  shift 2
  local _out _err
  _out="$(mktemp "$TEST_TMP/stdout.XXXXXX")"
  _err="$(mktemp "$TEST_TMP/stderr.XXXXXX")"

  set +e
  HOME="$fake_home" bash "$script" "$@" >"$_out" 2>"$_err"
  RUN_RC=$?
  set -e

  RUN_STDOUT="$(cat "$_out" 2>/dev/null || true)"
  RUN_STDERR="$(cat "$_err" 2>/dev/null || true)"
  rm -f "$_out" "$_err"
}

# Run any command, capturing stdout/stderr/exit-code without triggering ERR trap.
# (Functions don't inherit ERR trap unless -E is set, so this is safe.)
# Results in: RUN_STDOUT, RUN_STDERR, RUN_RC
run_capturing() {
  local _out _err
  _out="$(mktemp "$TEST_TMP/stdout.XXXXXX")"
  _err="$(mktemp "$TEST_TMP/stderr.XXXXXX")"

  set +e
  "$@" >"$_out" 2>"$_err"
  RUN_RC=$?
  set -e

  RUN_STDOUT="$(cat "$_out" 2>/dev/null || true)"
  RUN_STDERR="$(cat "$_err" 2>/dev/null || true)"
  rm -f "$_out" "$_err"
}

# ═══════════════════════════════════════════════════════════════════
# T1: config-check.sh execution paths
# ═══════════════════════════════════════════════════════════════════

echo "── T1: config-check.sh ──"

if [[ -z "$JQ_BIN" ]]; then
  echo "SKIP: T1 (jq not available)"
else
  # E001-E003: OK status — all fields match optimal values
  t1_ok="$TEST_TMP/t1-ok"
  setup_fake_home "$t1_ok" '{"model":"claude-opus-4-6","effortLevel":"max","fastMode":false,"alwaysThinkingEnabled":true}'
  run_with_home "$t1_ok" "$CONFIG_CHECK"

  if [[ "$RUN_RC" -eq 0 ]]; then record_pass
  else record_finding FAIL E001 config-check.sh "OK scenario: expected exit 0, got $RUN_RC"; fi

  if echo "$RUN_STDOUT" | grep -Fq "STATUS: OK"; then record_pass
  else record_finding FAIL E002 config-check.sh "OK scenario: stdout missing 'STATUS: OK'"; fi

  match_count=$(echo "$RUN_STDOUT" | grep -c '^MATCH:' || true)
  if [[ "$match_count" -eq 4 ]]; then record_pass
  else record_finding FAIL E003 config-check.sh "OK scenario: expected 4 MATCH lines, got $match_count"; fi

  # E004-E007: MISMATCH status — all 4 fields differ
  t1_mis="$TEST_TMP/t1-mismatch"
  setup_fake_home "$t1_mis" '{"model":"claude-sonnet-4-6","effortLevel":"high","fastMode":true,"alwaysThinkingEnabled":false}'
  run_with_home "$t1_mis" "$CONFIG_CHECK"

  if [[ "$RUN_RC" -eq 0 ]]; then record_pass
  else record_finding FAIL E004 config-check.sh "MISMATCH scenario: expected exit 0 (status line distinguishes), got $RUN_RC"; fi

  if echo "$RUN_STDOUT" | grep -Fq "STATUS: MISMATCH"; then record_pass
  else record_finding FAIL E005 config-check.sh "MISMATCH scenario: stdout missing 'STATUS: MISMATCH'"; fi

  if echo "$RUN_STDOUT" | grep -Fq "DIFF_COUNT:"; then record_pass
  else record_finding FAIL E006 config-check.sh "MISMATCH scenario: stdout missing 'DIFF_COUNT:'"; fi

  diff_count=$(echo "$RUN_STDOUT" | grep -c '^DIFF:' || true)
  if [[ "$diff_count" -eq 4 ]]; then record_pass
  else record_finding FAIL E007 config-check.sh "MISMATCH scenario: expected 4 DIFF lines, got $diff_count"; fi

  # E008-E009: MODEL_MISMATCH flag (only model differs)
  t1_model="$TEST_TMP/t1-model"
  setup_fake_home "$t1_model" '{"model":"claude-sonnet-4-6","effortLevel":"max","fastMode":false,"alwaysThinkingEnabled":true}'
  run_with_home "$t1_model" "$CONFIG_CHECK"

  if echo "$RUN_STDOUT" | grep -Fq "MODEL_MISMATCH: true"; then record_pass
  else record_finding FAIL E008 config-check.sh "MODEL_MISMATCH flag absent when only model differs"; fi

  if echo "$RUN_STDOUT" | grep -Fq "DIFF_COUNT: 1"; then record_pass
  else record_finding FAIL E009 config-check.sh "MODEL_MISMATCH scenario: DIFF_COUNT should be 1"; fi

  # E010-E011: Missing settings file → exit 1 + ERROR on stderr
  t1_missing="$TEST_TMP/t1-missing"
  mkdir -p "$t1_missing/.claude"
  run_with_home "$t1_missing" "$CONFIG_CHECK"

  if [[ "$RUN_RC" -eq 1 ]]; then record_pass
  else record_finding FAIL E010 config-check.sh "missing settings: expected exit 1, got $RUN_RC"; fi

  if echo "$RUN_STDERR" | grep -Fq "ERROR"; then record_pass
  else record_finding FAIL E011 config-check.sh "missing settings: stderr should contain ERROR"; fi

  # E012: Invalid JSON → exit 1
  t1_invalid="$TEST_TMP/t1-invalid"
  setup_fake_home "$t1_invalid" 'not json at all {'
  run_with_home "$t1_invalid" "$CONFIG_CHECK"

  if [[ "$RUN_RC" -eq 1 ]]; then record_pass
  else record_finding FAIL E012 config-check.sh "invalid JSON: expected exit 1, got $RUN_RC"; fi

  # E013-E014: Empty JSON object (all fields UNSET)
  t1_empty="$TEST_TMP/t1-empty"
  setup_fake_home "$t1_empty" '{}'
  run_with_home "$t1_empty" "$CONFIG_CHECK"

  if echo "$RUN_STDOUT" | grep -Fq "STATUS: MISMATCH"; then record_pass
  else record_finding FAIL E013 config-check.sh "empty-object: expected STATUS: MISMATCH"; fi

  if echo "$RUN_STDOUT" | grep -Fq "current=UNSET"; then record_pass
  else record_finding FAIL E014 config-check.sh "empty-object: expected 'current=UNSET' in DIFF lines"; fi
fi

# ═══════════════════════════════════════════════════════════════════
# T2: config-optimize.sh execution paths
# ═══════════════════════════════════════════════════════════════════

echo "── T2: config-optimize.sh ──"

if [[ -z "$JQ_BIN" ]]; then
  echo "SKIP: T2 (jq not available)"
else
  # E020-E026: Normal optimization — backup created, settings modified, non-audit fields preserved
  t2_normal="$TEST_TMP/t2-normal"
  setup_fake_home "$t2_normal" '{"model":"claude-sonnet-4-6","effortLevel":"high","fastMode":true,"alwaysThinkingEnabled":false,"customField":"keep-me"}'
  run_with_home "$t2_normal" "$CONFIG_OPTIMIZE"

  if [[ "$RUN_RC" -eq 0 ]]; then record_pass
  else record_finding FAIL E020 config-optimize.sh "normal optimize: expected exit 0, got $RUN_RC"; fi

  if [[ -f "$t2_normal/.claude/settings.json.audit-backup" ]]; then record_pass
  else record_finding FAIL E021 config-optimize.sh "normal optimize: backup file not created"; fi

  if echo "$RUN_STDOUT" | grep -Fq "OPTIMIZED:"; then record_pass
  else record_finding FAIL E022 config-optimize.sh "normal optimize: stdout missing 'OPTIMIZED:'"; fi

  if echo "$RUN_STDOUT" | grep -Fq "BACKUP:"; then record_pass
  else record_finding FAIL E023 config-optimize.sh "normal optimize: stdout missing 'BACKUP:'"; fi

  # Post-optimize: config-check should report STATUS: OK
  run_with_home "$t2_normal" "$CONFIG_CHECK"
  if echo "$RUN_STDOUT" | grep -Fq "STATUS: OK"; then record_pass
  else record_finding FAIL E024 config-optimize.sh "post-optimize config-check should show STATUS: OK"; fi

  # Backup preserves original values
  orig_model=$("$JQ_BIN" -r '.model' "$t2_normal/.claude/settings.json.audit-backup" 2>/dev/null || echo "FAIL")
  if [[ "$orig_model" == "claude-sonnet-4-6" ]]; then record_pass
  else record_finding FAIL E025 config-optimize.sh "backup should preserve original model, got: $orig_model"; fi

  # Non-audit fields preserved in optimized settings
  custom_val=$("$JQ_BIN" -r '.customField' "$t2_normal/.claude/settings.json" 2>/dev/null || echo "FAIL")
  if [[ "$custom_val" == "keep-me" ]]; then record_pass
  else record_finding FAIL E026 config-optimize.sh "optimization should preserve non-audit fields, customField=$custom_val"; fi

  # E027-E028: Backup already exists → exit 1 + error message
  run_with_home "$t2_normal" "$CONFIG_OPTIMIZE"

  if [[ "$RUN_RC" -eq 1 ]]; then record_pass
  else record_finding FAIL E027 config-optimize.sh "backup-exists: expected exit 1, got $RUN_RC"; fi

  if echo "$RUN_STDERR" | grep -Fq "backup already exists"; then record_pass
  else record_finding FAIL E028 config-optimize.sh "backup-exists: stderr should mention 'backup already exists'"; fi
fi

# ═══════════════════════════════════════════════════════════════════
# T3: config-restore.sh execution paths
# ═══════════════════════════════════════════════════════════════════

echo "── T3: config-restore.sh ──"

if [[ -z "$JQ_BIN" ]]; then
  echo "SKIP: T3 (jq not available)"
else
  # E030-E031: No backup → SKIP, exit 0
  t3_nobackup="$TEST_TMP/t3-nobackup"
  setup_fake_home "$t3_nobackup" '{"model":"claude-opus-4-6"}'
  run_with_home "$t3_nobackup" "$CONFIG_RESTORE"

  if [[ "$RUN_RC" -eq 0 ]]; then record_pass
  else record_finding FAIL E030 config-restore.sh "no-backup: expected exit 0, got $RUN_RC"; fi

  if echo "$RUN_STDOUT" | grep -Fq "SKIP:"; then record_pass
  else record_finding FAIL E031 config-restore.sh "no-backup: stdout should contain 'SKIP:'"; fi

  # E032-E037: Field-level restore — only 4 audit fields reverted, user changes preserved
  t3_field="$TEST_TMP/t3-field"
  setup_fake_home "$t3_field" '{"model":"claude-sonnet-4-6","effortLevel":"high","fastMode":true,"alwaysThinkingEnabled":false}'
  run_with_home "$t3_field" "$CONFIG_OPTIMIZE"

  # Simulate user changes made during audit session
  "$JQ_BIN" -S '. + {"userAddedField": "during-audit"}' "$t3_field/.claude/settings.json" > "$t3_field/.claude/settings.json.tmp"
  mv "$t3_field/.claude/settings.json.tmp" "$t3_field/.claude/settings.json"

  run_with_home "$t3_field" "$CONFIG_RESTORE"

  if [[ "$RUN_RC" -eq 0 ]]; then record_pass
  else record_finding FAIL E032 config-restore.sh "field-restore: expected exit 0, got $RUN_RC"; fi

  if echo "$RUN_STDOUT" | grep -Fq "RESTORED:"; then record_pass
  else record_finding FAIL E033 config-restore.sh "field-restore: stdout should contain 'RESTORED:'"; fi

  # Audit fields reverted to pre-optimization values
  restored_model=$("$JQ_BIN" -r '.model' "$t3_field/.claude/settings.json" 2>/dev/null || echo "FAIL")
  if [[ "$restored_model" == "claude-sonnet-4-6" ]]; then record_pass
  else record_finding FAIL E034 config-restore.sh "field-restore: model should revert to claude-sonnet-4-6, got: $restored_model"; fi

  restored_effort=$("$JQ_BIN" -r '.effortLevel' "$t3_field/.claude/settings.json" 2>/dev/null || echo "FAIL")
  if [[ "$restored_effort" == "high" ]]; then record_pass
  else record_finding FAIL E035 config-restore.sh "field-restore: effortLevel should revert to high, got: $restored_effort"; fi

  # User changes made during audit preserved
  user_field=$("$JQ_BIN" -r '.userAddedField' "$t3_field/.claude/settings.json" 2>/dev/null || echo "FAIL")
  if [[ "$user_field" == "during-audit" ]]; then record_pass
  else record_finding FAIL E036 config-restore.sh "field-restore: userAddedField should survive restore, got: $user_field"; fi

  # Backup removed after successful restore
  if [[ ! -f "$t3_field/.claude/settings.json.audit-backup" ]]; then record_pass
  else record_finding FAIL E037 config-restore.sh "field-restore: backup should be removed after successful restore"; fi

  # E038: Corrupted backup → exit 1
  t3_corrupt="$TEST_TMP/t3-corrupt"
  setup_fake_home "$t3_corrupt" '{"model":"claude-opus-4-6"}'
  printf '%s\n' "not-json{{{" > "$t3_corrupt/.claude/settings.json.audit-backup"
  run_with_home "$t3_corrupt" "$CONFIG_RESTORE"

  if [[ "$RUN_RC" -eq 1 ]]; then record_pass
  else record_finding FAIL E038 config-restore.sh "corrupted-backup: expected exit 1, got $RUN_RC"; fi

  # E039-E040: Full round-trip — original → optimize → restore → values match
  t3_rt="$TEST_TMP/t3-roundtrip"
  setup_fake_home "$t3_rt" '{"model":"claude-haiku-4-5","effortLevel":"low","fastMode":true,"alwaysThinkingEnabled":false,"extraKey":"survives"}'
  cp "$t3_rt/.claude/settings.json" "$t3_rt/.claude/original.json"

  run_with_home "$t3_rt" "$CONFIG_OPTIMIZE"
  run_with_home "$t3_rt" "$CONFIG_RESTORE"

  for field in model effortLevel fastMode alwaysThinkingEnabled; do
    orig_val=$("$JQ_BIN" -r ".$field" "$t3_rt/.claude/original.json")
    rest_val=$("$JQ_BIN" -r ".$field" "$t3_rt/.claude/settings.json")
    if [[ "$orig_val" == "$rest_val" ]]; then record_pass
    else record_finding FAIL E039 config-restore.sh "round-trip: $field mismatch (original=$orig_val restored=$rest_val)"; fi
  done

  extra_val=$("$JQ_BIN" -r '.extraKey' "$t3_rt/.claude/settings.json" 2>/dev/null || echo "FAIL")
  if [[ "$extra_val" == "survives" ]]; then record_pass
  else record_finding FAIL E040 config-restore.sh "round-trip: extraKey should survive optimize→restore cycle"; fi
fi

# ═══════════════════════════════════════════════════════════════════
# T4: validate-report.sh execution paths
# ═══════════════════════════════════════════════════════════════════

echo "── T4: validate-report.sh ──"

# E050: All golden .md files must pass validation
if [[ -d "$GOLDEN_DIR" ]]; then
  for golden in "$GOLDEN_DIR"/*.md; do
    [[ -f "$golden" ]] || continue
    run_capturing bash "$VALIDATE_REPORT" "$golden"
    bn="$(basename "$golden")"
    if [[ $RUN_RC -eq 0 ]]; then record_pass
    else record_finding FAIL E050 validate-report.sh "golden $bn should pass but exited $RUN_RC"; fi
  done
else
  record_finding FAIL E050 validate-report.sh "goldens directory not found"
fi

# E051: Broken report (no recognised header) → exit 1
cat > "$TEST_TMP/broken.md" <<'EOF'
Some random text without a proper report header.

**Audit Target**: test.md
EOF
run_capturing bash "$VALIDATE_REPORT" "$TEST_TMP/broken.md"
if [[ $RUN_RC -eq 1 ]]; then record_pass
else record_finding FAIL E051 validate-report.sh "broken report: expected exit 1, got $RUN_RC"; fi

# E052: No argument → exit 2
run_capturing bash "$VALIDATE_REPORT"
if [[ $RUN_RC -eq 2 ]]; then record_pass
else record_finding FAIL E052 validate-report.sh "no-argument: expected exit 2, got $RUN_RC"; fi

# E053: Non-existent file → exit 2
run_capturing bash "$VALIDATE_REPORT" "$TEST_TMP/does-not-exist.md"
if [[ $RUN_RC -eq 2 ]]; then record_pass
else record_finding FAIL E053 validate-report.sh "missing-file: expected exit 2, got $RUN_RC"; fi

# E054: Partial report with forbidden normal sections → exit 1
cat > "$TEST_TMP/mixed-partial.md" <<'EOF'
# AUDIT Partial Report

**Audit Target**: manuscript.md
**Target Type**: Paper
**Completion Status**: Partial report due to degradation
**Completed Big Rounds**: R1
**Incomplete Big Rounds**: R2
**Retained Temp Files**: audit_R2_temp.md
**Interruption Note**: Test.

## Issue List

This section is forbidden in partial reports.
EOF
run_capturing bash "$VALIDATE_REPORT" "$TEST_TMP/mixed-partial.md"
if [[ $RUN_RC -eq 1 ]]; then record_pass
else record_finding FAIL E054 validate-report.sh "mixed-partial: expected exit 1, got $RUN_RC"; fi

# E055: All-zero report missing required fixed line → exit 1
cat > "$TEST_TMP/allzero-bad.md" <<'EOF'
# AUDIT Report

**Audit Target**: clean.md
**Target Type**: Paper
**Domain**: Epidemiology
**Audit Date**: 2026-03-21
**Audit Architecture**: Parallel
**Big Rounds Executed**: R1
**Total Issues**: 0 (Critical 0 / Major 0 / Minor 0)
**Cross-Round Independent Discoveries**: 0
**Tool Degradation**: None

## Summary Statistics

| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |
|-----------|-------|----------|-------|-------|------------|------------|
| R1 | Test | 0 | 0 | 0 | 1D | 1 |

## Overall Assessment

Clean.
EOF
run_capturing bash "$VALIDATE_REPORT" "$TEST_TMP/allzero-bad.md"
if [[ $RUN_RC -eq 1 ]]; then record_pass
else record_finding FAIL E055 validate-report.sh "all-zero missing fixed line: expected exit 1, got $RUN_RC"; fi

# ═══════════════════════════════════════════════════════════════════
# T5: parse-audit-args.py execution paths
# ═══════════════════════════════════════════════════════════════════

echo "── T5: parse-audit-args.py ──"

if [[ -z "$PYTHON_BIN" ]]; then
  echo "SKIP: T5 (python not available)"
else
  # E060-E061: Simple single argument
  run_capturing "$PYTHON_BIN" "$PARSE_ARGS" "manuscript.md"

  if echo "$RUN_STDOUT" | grep -Fq '"ok": true'; then record_pass
  else record_finding FAIL E060 parse-audit-args.py "simple arg: expected ok=true"; fi

  if echo "$RUN_STDOUT" | grep -Fq '"manuscript.md"'; then record_pass
  else record_finding FAIL E061 parse-audit-args.py "simple arg: expected 'manuscript.md' in args"; fi

  # E062-E063: Quoted argument with spaces + second arg
  run_capturing "$PYTHON_BIN" "$PARSE_ARGS" '"my file.md" --verbose'

  if [[ -n "$JQ_BIN" ]]; then
    if echo "$RUN_STDOUT" | "$JQ_BIN" -e '.args[0] == "my file.md"' >/dev/null 2>&1; then record_pass
    else record_finding FAIL E062 parse-audit-args.py "quoted arg: 'my file.md' not parsed as first arg"; fi

    if echo "$RUN_STDOUT" | "$JQ_BIN" -e '.args[1] == "--verbose"' >/dev/null 2>&1; then record_pass
    else record_finding FAIL E063 parse-audit-args.py "quoted arg: '--verbose' not parsed as second arg"; fi
  else
    echo "SKIP: E062-E063 (jq needed for JSON arg inspection)"
  fi

  # E064: Empty stdin → exit 2 (use a subshell to pipe empty input)
  run_capturing bash -c "printf '' | '$PYTHON_BIN' '$PARSE_ARGS'"
  if [[ "$RUN_RC" -eq 2 ]]; then record_pass
  else record_finding FAIL E064 parse-audit-args.py "empty stdin: expected exit 2, got $RUN_RC"; fi

  # E065: Too many positional arguments → exit 2
  run_capturing "$PYTHON_BIN" "$PARSE_ARGS" "arg1" "arg2"
  if [[ "$RUN_RC" -eq 2 ]]; then record_pass
  else record_finding FAIL E065 parse-audit-args.py "too-many-args: expected exit 2, got $RUN_RC"; fi

  # E066-E067: Unclosed quote → exit 1 + ok=false
  run_capturing "$PYTHON_BIN" "$PARSE_ARGS" '"unclosed'
  if [[ "$RUN_RC" -eq 1 ]]; then record_pass
  else record_finding FAIL E066 parse-audit-args.py "unclosed-quote: expected exit 1, got $RUN_RC"; fi

  if echo "$RUN_STDOUT" | grep -Fq '"ok": false'; then record_pass
  else record_finding FAIL E067 parse-audit-args.py "unclosed-quote: expected ok=false in output"; fi

  # E068-E069: BOM prefix handling
  bom_input=$'\xEF\xBB\xBFmanuscript.md'
  run_capturing "$PYTHON_BIN" "$PARSE_ARGS" "$bom_input"

  if echo "$RUN_STDOUT" | grep -Fq '"ok": true'; then record_pass
  else record_finding FAIL E068 parse-audit-args.py "BOM prefix: expected ok=true after stripping"; fi

  if echo "$RUN_STDOUT" | grep -Fq '"manuscript.md"'; then record_pass
  else record_finding FAIL E069 parse-audit-args.py "BOM prefix: 'manuscript.md' should appear without BOM"; fi

  # E070: Stdin pipe mode with multiple tokens
  run_capturing bash -c "printf 'file.md --loop\n' | '$PYTHON_BIN' '$PARSE_ARGS'"

  if [[ -n "$JQ_BIN" ]]; then
    if echo "$RUN_STDOUT" | "$JQ_BIN" -e '.args | length == 2' >/dev/null 2>&1; then record_pass
    else record_finding FAIL E070 parse-audit-args.py "stdin-pipe: expected 2 args from piped input"; fi
  else
    if echo "$RUN_STDOUT" | grep -Fq '"ok": true'; then record_pass
    else record_finding FAIL E070 parse-audit-args.py "stdin-pipe: expected ok=true"; fi
  fi
fi

# ═══════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Execution Test Summary"
echo "═══════════════════════════════════════════════════════════"
echo "- Package Path: $PACKAGE_ROOT"
echo "- Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
echo "- Total: $TOTAL_CHECKS | Pass: $PASS_COUNT | Fail: $FAIL_COUNT | Warn: $WARN_COUNT"
echo ""

if [[ ${#FINDINGS[@]} -gt 0 ]]; then
  echo "Findings"
  for f in "${FINDINGS[@]}"; do
    echo "- $f"
  done
  echo ""
fi

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
fi

exit 0
