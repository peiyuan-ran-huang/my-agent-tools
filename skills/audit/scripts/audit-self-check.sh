#!/usr/bin/env bash
# Audit skill — maintenance checker for package integrity and drift-prone contracts
# Output (stdout): Summary / Findings / Manual Follow-Ups
# Exit codes:
#   0 = no FAIL findings
#   1 = one or more FAIL findings
#   2 = checker execution error

set -euo pipefail

on_error() {
  local line="$1"
  echo "ERROR: audit-self-check.sh failed at line $line" >&2
  exit 2
}
trap 'on_error $LINENO' ERR

usage() {
  cat <<'EOF'
Usage:
  audit-self-check.sh [PACKAGE_ROOT]

If PACKAGE_ROOT is omitted, the checker uses the parent directory of this script.
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 2
}

for cmd in awk bash grep sed wc tr mktemp cp rm mkdir cat head; do
  command -v "$cmd" >/dev/null 2>&1 || die "required command not found in PATH: $cmd"
done

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PACKAGE_ROOT_DEFAULT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
PACKAGE_ROOT_INPUT="${1:-$PACKAGE_ROOT_DEFAULT}"
PACKAGE_ROOT="$(cd "$PACKAGE_ROOT_INPUT" 2>/dev/null && pwd -P)" || die "package root not found or unreadable: $PACKAGE_ROOT_INPUT"

README_FILE="$PACKAGE_ROOT/README.md"
SKILL_EN="$PACKAGE_ROOT/SKILL.md"
SKILL_ZH="$PACKAGE_ROOT/SKILL_ZH.md"
TEST_SCENARIOS="$PACKAGE_ROOT/test-scenarios.md"
EXAMPLES_FILE="$PACKAGE_ROOT/examples.md"
CONTRACTS_FILE="$PACKAGE_ROOT/contracts/maintenance-contracts.tsv"
LEDGER_FILE="$PACKAGE_ROOT/verification-issue-ledger.md"
GOLDEN_DIR="$PACKAGE_ROOT/goldens"

declare -a FINDINGS=()
declare -a MANUALS=(
  "M001 Review semantic parity between SKILL.md and SKILL_ZH.md."
  "M002 Review whether the skill still feels heavyweight, explicit, isolated, and exhaustive."
  "M003 Review whether examples still calibrate maintainers toward the correct report shape."
  "M004 Run fresh-session smoke tests for paper/code/plan/data/mixed plus at least one degraded-path drill from the documented release-gate set ('MCP unavailable', 'sequential fallback', 'merge interruption / partial-output salvage', 'config-check anomaly or failure path', or the incompatible Windows bash case). If Claude Code CLI is used for those smoke attempts, first require 'claude auth status' to show 'loggedIn: true', and if the non-interactive prompt begins with '---audit', deliver it through stdin or another non-argv input path instead of a bare prompt argument. If archived markdown smoke reports are cited as report-shape evidence, first revalidate them against the current 'scripts/validate-report.sh' shape validator; otherwise mark them stale and do not count them toward release acceptance. Non-markdown or in-thread smoke evidence must be reviewed against its own canonical source or fixture instead of being treated as something 'scripts/validate-report.sh' can prove. If a CLI smoke attempt fails before the session starts because Claude Code was unauthenticated or a leading '---audit' prompt was misparsed as an option, record that as an operator / harness prerequisite failure rather than as an 'audit' runtime regression. If the direct fresh-session 'paper' smoke on a quoted OneDrive absolute path with spaces collapses to a prefix directory, record it as the documented platform limitation and also run one mitigated 'paper' smoke via a staged no-space path or 'audit_object_temp.md'."
  "M005 If Claude Code CLI is the intended release-acceptance path, verify it is actually authenticated, then verify MCP, LSP, Context Mode MCP, Bash, and jq availability in the intended environment."
  "M006 Review whether this change blurs or silently reassigns canonical source ownership."
  "M007 Review whether this change introduces behaviour that lacks fixture coverage or an explicit smoke-test decision."
)

TOTAL_CHECKS=0
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

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

check_expected_count() {
  local rule="$1"
  local file="$2"
  local label="$3"
  local actual="$4"
  local expected="$5"
  if [[ "$actual" -eq "$expected" ]]; then
    record_pass
  else
    record_finding FAIL "$rule" "$file" "$label count drifted: expected $expected, found $actual"
  fi
}

check_file_exists() {
  local rule="$1"
  local path="$2"
  local message="$3"
  if [[ -f "$path" ]]; then
    record_pass
  else
    record_finding FAIL "$rule" "$path" "$message"
  fi
}

check_file_nonempty() {
  local rule="$1"
  local path="$2"
  local message="$3"
  if [[ -s "$path" ]]; then
    record_pass
  else
    record_finding FAIL "$rule" "$path" "$message"
  fi
}

ensure_readable() {
  local path="$1"
  [[ -r "$path" ]] || die "required input file is not readable: $path"
}

has_literal() {
  local file="$1"
  local needle="$2"
  grep -Fq -- "$needle" "$file"
}

check_literal() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local needle="$4"
  local message="$5"
  if has_literal "$file" "$needle"; then
    record_pass
  else
    record_finding "$severity" "$rule" "$file" "$message"
  fi
}

check_regex() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local pattern="$4"
  local message="$5"
  if grep -Eq -- "$pattern" "$file"; then
    record_pass
  else
    record_finding "$severity" "$rule" "$file" "$message"
  fi
}

contract_rest_lines() {
  local type="$1"
  [[ -r "$CONTRACTS_FILE" ]] || return 0
  awk -F '\t' -v t="$type" '
    BEGIN { OFS = "\t" }
    $0 ~ /^#/ { next }
    $1 == t {
      $1 = ""
      sub(/^\t/, "")
      print
    }
  ' "$CONTRACTS_FILE"
}

check_literal_order() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  shift 3
  local prev=0
  local needle
  local line
  for needle in "$@"; do
    line="$(grep -Fn -- "$needle" "$file" | head -n 1 | cut -d: -f1 || true)"
    if [[ -z "$line" ]]; then
      record_finding "$severity" "$rule" "$file" "cannot verify ordered literal sequence because this literal is missing: $needle"
      return
    fi
    if (( line <= prev )); then
      record_finding "$severity" "$rule" "$file" "ordered literal sequence violated at: $needle"
      return
    fi
    prev=$line
  done
  record_pass
}

check_section_literal_order() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local section_heading="$4"
  shift 4
  local section_text
  local prev=0
  local needle
  local line
  section_text="$(awk -v start="$section_heading" '
    $0 == start { in_section = 1; print; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$file")"
  if [[ -z "$section_text" ]]; then
    record_finding "$severity" "$rule" "$file" "missing required section for ordered literal verification: $section_heading"
    return
  fi
  for needle in "$@"; do
    line="$(printf '%s\n' "$section_text" | grep -Fn -- "$needle" | head -n 1 | cut -d: -f1 || true)"
    if [[ -z "$line" ]]; then
      record_finding "$severity" "$rule" "$file" "section-scoped ordered literal verification is missing: $needle"
      return
    fi
    if (( line <= prev )); then
      record_finding "$severity" "$rule" "$file" "section-scoped ordered literal sequence violated at: $needle"
      return
    fi
    prev=$line
  done
  record_pass
}

check_section_literal() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local section_heading="$4"
  local needle="$5"
  local message="$6"
  local section_text
  section_text="$(awk -v start="$section_heading" '
    $0 == start { in_section = 1; print; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$file")"
  if [[ -z "$section_text" ]]; then
    record_finding "$severity" "$rule" "$file" "missing required section for scoped literal verification: $section_heading"
    return
  fi
  if printf '%s\n' "$section_text" | grep -Fq -- "$needle"; then
    record_pass
  else
    record_finding "$severity" "$rule" "$file" "$message"
  fi
}

check_section_regex() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local section_heading="$4"
  local pattern="$5"
  local message="$6"
  local section_text
  section_text="$(awk -v start="$section_heading" '
    $0 == start { in_section = 1; print; next }
    in_section && /^## / { exit }
    in_section { print }
  ' "$file")"
  if [[ -z "$section_text" ]]; then
    record_finding "$severity" "$rule" "$file" "missing required section for scoped regex verification: $section_heading"
    return
  fi
  if printf '%s\n' "$section_text" | grep -Eq -- "$pattern"; then
    record_pass
  else
    record_finding "$severity" "$rule" "$file" "$message"
  fi
}

check_markdown_table_enum_column_after_header() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local header_literal="$4"
  local column_index="$5"
  local label="$6"
  shift 6
  local allowed_values=("$@")
  local alternation
  local found=0
  local line_no
  local value
  local row_id

  alternation="$(printf '%s|' "${allowed_values[@]}")"
  alternation="${alternation%|}"

  while IFS=$'\t' read -r line_no value row_id; do
    [[ -n "$line_no" ]] || continue
    found=1
    if [[ "$value" =~ ^($alternation)$ ]]; then
      record_pass
    else
      record_finding "$severity" "$rule" "$file" "$label contains invalid value '$value' in row $row_id at line $line_no; allowed values: ${allowed_values[*]}"
    fi
  done < <(
    awk -F'|' -v header="$header_literal" -v col="$column_index" '
      $0 == header { in_table = 1; next }
      in_table && $0 ~ /^\|/ && $0 !~ /[[:alnum:]]/ { next }
      in_table && $0 ~ /^\|/ {
        value = $col
        row_id = $2
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        gsub(/^[ \t]+|[ \t]+$/, "", row_id)
        print NR "\t" value "\t" row_id
        next
      }
      in_table && $0 !~ /^\|/ { exit }
    ' "$file"
  )

  if [[ "$found" -eq 0 ]]; then
    record_finding "$severity" "$rule" "$file" "cannot verify $label because no matching ledger rows were found"
  fi
}

check_markdown_table_unique_id_after_header() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local header_literal="$4"
  local label="$5"
  local found=0
  local line_no
  local row_id
  declare -A seen_ids=()

  while IFS=$'\t' read -r line_no row_id; do
    [[ -n "$line_no" ]] || continue
    found=1
    if [[ -z "$row_id" ]]; then
      record_finding "$severity" "$rule" "$file" "$label is blank at line $line_no"
    elif [[ -n "${seen_ids[$row_id]+x}" ]]; then
      record_finding "$severity" "$rule" "$file" "$label '$row_id' is duplicated at line $line_no; first seen at line ${seen_ids[$row_id]}"
    else
      seen_ids["$row_id"]="$line_no"
      record_pass
    fi
  done < <(
    awk -F'|' -v header="$header_literal" '
      $0 == header { in_table = 1; next }
      in_table && $0 ~ /^\|/ && $0 !~ /[[:alnum:]]/ { next }
      in_table && $0 ~ /^\|/ {
        row_id = $2
        gsub(/^[ \t]+|[ \t]+$/, "", row_id)
        print NR "\t" row_id
        next
      }
      in_table && $0 !~ /^\|/ { exit }
    ' "$file"
  )

  if [[ "$found" -eq 0 ]]; then
    record_finding "$severity" "$rule" "$file" "cannot verify $label because no matching ledger rows were found"
  fi
}

check_between_headings_literal_order() {
  local severity="$1"
  local rule="$2"
  local file="$3"
  local start_heading="$4"
  local end_heading="$5"
  shift 5
  local section_text
  local prev=0
  local needle
  local line
  if ! grep -Fxq -- "$start_heading" "$file"; then
    record_finding "$severity" "$rule" "$file" "missing required start heading for ordered literal verification: $start_heading"
    return
  fi
  if ! grep -Fxq -- "$end_heading" "$file"; then
    record_finding "$severity" "$rule" "$file" "missing required end heading for ordered literal verification: $end_heading"
    return
  fi
  section_text="$(awk -v start="$start_heading" -v stop="$end_heading" '
    $0 == start { in_section = 1 }
    in_section {
      if ($0 == stop) exit
      print
    }
  ' "$file")"
  if [[ -z "$section_text" ]]; then
    record_finding "$severity" "$rule" "$file" "missing required heading-bounded block for ordered literal verification: $start_heading"
    return
  fi
  for needle in "$@"; do
    line="$(printf '%s\n' "$section_text" | grep -Fn -- "$needle" | head -n 1 | cut -d: -f1 || true)"
    if [[ -z "$line" ]]; then
      record_finding "$severity" "$rule" "$file" "heading-bounded ordered literal verification is missing: $needle"
      return
    fi
    if (( line <= prev )); then
      record_finding "$severity" "$rule" "$file" "heading-bounded ordered literal sequence violated at: $needle"
      return
    fi
    prev=$line
  done
  record_pass
}

check_shared_source_binding() {
  local rule="$1"
  local file="$2"
  shift 2
  local required_entries=("$@")
  local missing_labels=()
  local entry
  local label
  local pattern

  if ! grep -Eq '^[[:space:]]*_shared=.*config-optimal-values\.sh' "$file"; then
    record_finding FAIL "$rule" "$file" "script no longer binds _shared to config-optimal-values.sh: $(basename "$file")"
    return
  fi

  if ! grep -Eq '^[[:space:]]*source[[:space:]]+"\$_shared"' "$file"; then
    record_finding FAIL "$rule" "$file" "script no longer sources shared config values via \$_shared: $(basename "$file")"
    return
  fi

  for entry in "${required_entries[@]}"; do
    label="${entry%%::*}"
    pattern="${entry#*::}"
    if ! grep -Eq -- "$pattern" "$file"; then
      missing_labels+=("$label")
    fi
  done

  if [[ ${#missing_labels[@]} -gt 0 ]]; then
    record_finding FAIL "$rule" "$file" "script no longer preserves expected live shared-source patterns from config-optimal-values.sh: $(printf '%s ' "${missing_labels[@]}" | sed 's/[[:space:]]$//')"
  else
    record_pass
  fi
}

check_no_post_source_override() {
  local rule="$1"
  local file="$2"
  shift 2
  local protected_vars=("$@")
  local source_line
  local protected_union
  local override_hit

  source_line="$(awk '/^[[:space:]]*source[[:space:]]+"\$_shared"/ { print NR; exit }' "$file")"
  if [[ -z "$source_line" ]]; then
    record_finding FAIL "$rule" "$file" "cannot verify post-source overrides because source \"\$_shared\" was not found"
    return
  fi

  protected_union="$(printf '%s|' "${protected_vars[@]}")"
  protected_union="${protected_union%|}"
  override_hit="$(
    awk -v start="$source_line" -v union="$protected_union" '
      NR > start && $0 !~ /^[[:space:]]*#/ && $0 ~ ("^[[:space:]]*(((export|readonly|typeset|declare)([[:space:]]+-[[:alpha:]]+)*)[[:space:]]+)?(" union ")=") {
        print NR ":" $0
        exit
      }
    ' "$file"
  )"

  if [[ -n "$override_hit" ]]; then
    record_finding FAIL "$rule" "$file" "script overrides shared variable after sourcing config-optimal-values.sh: $override_hit"
  else
    record_pass
  fi
}

run_self_probe() {
  local target_root="$1"
  local output_file="$2"
  local exit_code_file="$3"
  local rc

  set +e
  AUDIT_SELF_CHECK_SELFTEST_DEPTH=1 "$AUDIT_SELF_CHECK" "$target_root" >"$output_file" 2>&1
  rc=$?
  set -e
  printf '%s' "$rc" >"$exit_code_file"
}

frontmatter_keys() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm { print }
  ' "$file" | sed -n 's/^\([A-Za-z][A-Za-z0-9_-]*\):.*/\1/p'
}

frontmatter_content() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm { print }
  ' "$file"
}

frontmatter_has_closing_delimiter() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$file"
}

check_frontmatter_shape() {
  local file="$1"
  local rule_prefix="$2"
  local label="$3"
  local first_line
  first_line="$(head -n 1 "$file" || true)"
  if [[ "$first_line" != "---" ]]; then
    record_finding FAIL "${rule_prefix}01" "$file" "$label frontmatter must start with ---"
    return
  fi

  if ! frontmatter_has_closing_delimiter "$file"; then
    record_finding FAIL "${rule_prefix}02" "$file" "$label frontmatter must end with a closing --- delimiter"
    return
  fi

  local keys_raw
  local content_raw
  keys_raw="$(frontmatter_keys "$file" || true)"
  content_raw="$(frontmatter_content "$file" || true)"
  if [[ -z "$keys_raw" ]]; then
    record_finding FAIL "${rule_prefix}03" "$file" "$label frontmatter keys could not be parsed"
    return
  fi

  mapfile -t keys < <(printf '%s\n' "$keys_raw")
  declare -A seen=()
  local key
  for key in "${keys[@]}"; do
    seen["$key"]=1
  done
  if [[ ${#keys[@]} -ne 2 ]]; then
    record_finding FAIL "${rule_prefix}04" "$file" "$label frontmatter must contain exactly two keys"
  elif [[ -z "${seen[name]+x}" || -z "${seen[description]+x}" || ${#seen[@]} -ne 2 ]]; then
    record_finding FAIL "${rule_prefix}05" "$file" "$label frontmatter keys must be exactly name and description"
  else
    record_pass
  fi

  local description_block
  local description_value
  local description_token
  local description_core
  description_block="$(
    printf '%s\n' "$content_raw" | awk '
      /^description:/ {
        capture = 1
        sub(/^description:[[:space:]]*/, "", $0)
        print
        next
      }
      capture && /^[[:space:]]+/ { print; next }
      capture { exit }
    '
  )"
  description_value="$(printf '%s\n' "$description_block" | head -n 1)"
  description_value="$(printf '%s' "$description_value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  description_token="$(printf '%s' "$description_value" | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]+$//')"
  description_core="$description_value"
  if printf '%s\n' "$description_token" | grep -Eq '^[|>][1-9+-]{0,2}$'; then
    description_core="$(printf '%s\n' "$description_block" | sed '1d' | sed -E 's/^[[:space:]]+//')"
  elif [[ "$description_value" =~ ^\"(.*)\"([[:space:]]*#.*)?$ ]]; then
    description_core="${BASH_REMATCH[1]}"
  elif [[ "$description_value" =~ ^\'(.*)\'([[:space:]]*#.*)?$ ]]; then
    description_core="${BASH_REMATCH[1]}"
  else
    description_core="$(printf '%s' "$description_core" | sed -E 's/^#.*$//; s/[[:space:]]+#.*$//')"
  fi
  description_core="$(printf '%s' "$description_core" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  if [[ -z "$description_core" ]]; then
    record_finding FAIL "${rule_prefix}06" "$file" "$label description must be present and non-empty"
  else
    record_pass
  fi
}

print_summary() {
  local manual_count
  manual_count="${#MANUALS[@]}"
  echo "Summary"
  echo "- Package Path: $PACKAGE_ROOT"
  echo "- Total Checks: $TOTAL_CHECKS"
  echo "- Pass Count: $PASS_COUNT"
  echo "- Fail Count: $FAIL_COUNT"
  echo "- Warn Count: $WARN_COUNT"
  echo "- Manual Count: $manual_count"
}

print_findings() {
  echo
  echo "Findings"
  if [[ ${#FINDINGS[@]} -eq 0 ]]; then
    echo "- None"
    return
  fi
  local finding
  for finding in "${FINDINGS[@]}"; do
    echo "- $finding"
  done
}

print_manuals() {
  echo
  echo "Manual Follow-Ups"
  local item
  for item in "${MANUALS[@]}"; do
    echo "- $item"
  done
}

# M1. File layout
ROOT_FILES=(
  "$SKILL_EN"
  "$SKILL_ZH"
  "$README_FILE"
  "$PACKAGE_ROOT/pitfalls.md"
  "$PACKAGE_ROOT/release-checklist.md"
  "$PACKAGE_ROOT/audit-self-check-spec.md"
  "$PACKAGE_ROOT/verification-v2.md"
  "$PACKAGE_ROOT/verification-issue-ledger.md"
  "$EXAMPLES_FILE"
  "$TEST_SCENARIOS"
)
REFERENCE_FILES=(
  "$PACKAGE_ROOT/references/phase-0-planning.md"
  "$PACKAGE_ROOT/references/phase-1-dispatch.md"
  "$PACKAGE_ROOT/references/phase-2-merge.md"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md"
)
TEMPLATE_FILES=(
  "$PACKAGE_ROOT/templates/subagent-template.md"
  "$PACKAGE_ROOT/templates/report-template.md"
)
SCRIPT_FILES=(
  "$PACKAGE_ROOT/scripts/config-check.sh"
  "$PACKAGE_ROOT/scripts/config-optimal-values.sh"
  "$PACKAGE_ROOT/scripts/config-optimize.sh"
  "$PACKAGE_ROOT/scripts/config-restore.sh"
  "$PACKAGE_ROOT/scripts/audit-self-check.sh"
  "$PACKAGE_ROOT/scripts/check-smoke-evidence.sh"
  "$PACKAGE_ROOT/scripts/validate-report.sh"
  "$PACKAGE_ROOT/scripts/test-golden.sh"
  "$PACKAGE_ROOT/scripts/parse-audit-args.py"
)
GOLDEN_FILES=(
  "$GOLDEN_DIR/normal-report.md"
  "$GOLDEN_DIR/richer-normal-report.md"
  "$GOLDEN_DIR/all-zero-report.md"
  "$GOLDEN_DIR/partial-report.md"
  "$GOLDEN_DIR/output-verification-warning.txt"
)

for file in "${ROOT_FILES[@]}"; do
  check_file_exists L001 "$file" "required root file is missing"
  check_file_nonempty L002 "$file" "required root file is empty"
  [[ -f "$file" ]] && ensure_readable "$file"
done
for file in "${REFERENCE_FILES[@]}"; do
  check_file_exists L003 "$file" "required reference file is missing"
  check_file_nonempty L004 "$file" "required reference file is empty"
  [[ -f "$file" ]] && ensure_readable "$file"
done
for file in "${TEMPLATE_FILES[@]}"; do
  check_file_exists L005 "$file" "required template file is missing"
  check_file_nonempty L006 "$file" "required template file is empty"
  [[ -f "$file" ]] && ensure_readable "$file"
done
for file in "${SCRIPT_FILES[@]}"; do
  check_file_exists L007 "$file" "required script file is missing"
  check_file_nonempty L008 "$file" "required script file is empty"
  [[ -f "$file" ]] && ensure_readable "$file"
done
for file in "${GOLDEN_FILES[@]}"; do
  check_file_exists L090 "$file" "required golden file is missing"
  check_file_nonempty L091 "$file" "required golden file is empty"
  [[ -f "$file" ]] && ensure_readable "$file"
done

mapfile -t LEDGER_HEADER_ROWS < <(contract_rest_lines ledger_header)
if [[ ${#LEDGER_HEADER_ROWS[@]} -eq 0 ]]; then
  record_finding FAIL L009 "$CONTRACTS_FILE" "maintenance contracts file does not define any ledger_header entries"
fi
check_expected_count L010 "$CONTRACTS_FILE" "ledger_header" "${#LEDGER_HEADER_ROWS[@]}" 1
LEDGER_HEADER_CANONICAL="${LEDGER_HEADER_ROWS[0]:-}"
for row in "${LEDGER_HEADER_ROWS[@]}"; do
  check_literal FAIL L011 "$LEDGER_FILE" "$row" "verification issue ledger is missing the canonical schema header row"
done

mapfile -t LEDGER_SEVERITIES < <(contract_rest_lines ledger_severity)
if [[ ${#LEDGER_SEVERITIES[@]} -eq 0 ]]; then
  record_finding FAIL L012 "$CONTRACTS_FILE" "maintenance contracts file does not define any ledger_severity entries"
fi
check_expected_count L013 "$CONTRACTS_FILE" "ledger_severity" "${#LEDGER_SEVERITIES[@]}" 3

mapfile -t LEDGER_STATUSES < <(contract_rest_lines ledger_status)
if [[ ${#LEDGER_STATUSES[@]} -eq 0 ]]; then
  record_finding FAIL L014 "$CONTRACTS_FILE" "maintenance contracts file does not define any ledger_status entries"
fi
check_expected_count L015 "$CONTRACTS_FILE" "ledger_status" "${#LEDGER_STATUSES[@]}" 4
if [[ -n "$LEDGER_HEADER_CANONICAL" ]]; then
  check_markdown_table_enum_column_after_header FAIL L016 "$LEDGER_FILE" "$LEDGER_HEADER_CANONICAL" 3 "ledger severity column" "${LEDGER_SEVERITIES[@]}"
  check_markdown_table_enum_column_after_header FAIL L017 "$LEDGER_FILE" "$LEDGER_HEADER_CANONICAL" 4 "ledger status column" "${LEDGER_STATUSES[@]}"
  check_markdown_table_unique_id_after_header FAIL L018 "$LEDGER_FILE" "$LEDGER_HEADER_CANONICAL" "ledger ID column"
else
  record_finding FAIL L016 "$CONTRACTS_FILE" "cannot verify ledger severity column because no canonical ledger_header contract is defined"
  record_finding FAIL L017 "$CONTRACTS_FILE" "cannot verify ledger status column because no canonical ledger_header contract is defined"
  record_finding FAIL L018 "$CONTRACTS_FILE" "cannot verify ledger ID column because no canonical ledger_header contract is defined"
fi

# M2. Frontmatter
check_frontmatter_shape "$SKILL_EN" "FEN" "English entry"
check_frontmatter_shape "$SKILL_ZH" "FZH" "Chinese entry"

# M3. Entry boundary anchors
EN_ANCHORS=(
  'Activate only when the user explicitly invokes `---audit` in any letter case.'
  'First capture arguments with quote-aware grouping. Any substring enclosed in matching quotes is one raw argument before further interpretation.'
  'When quoted arguments are present or path parsing is ambiguous, you must feed the raw args after `---audit` to `python scripts/parse-audit-args.py` via stdin or a single string argument, then treat its JSON output as the canonical parse before further heuristics.'
  '- `paper` / `论文`'
  '- `code` / `代码`'
  '- `plan` / `方案`'
  '- `data` / `数据`'
  '- `mixed` / `混合`'
  '- If no argument is provided, identify the most recent substantive deliverable in the current conversation.'
  '- Quoted target paths that contain spaces must remain a single path argument during target identification.'
  '- If a type keyword is followed by a quoted path, strip only the outer quotes and validate the full path string; do not probe internal fragments such as `C:/Users/jdoe/OneDrive` as standalone targets.'
  '- The exact raw substring inside those quotes is the authoritative target path; do not rewrite it to a shorter existing prefix directory during validation.'
  '- For any quoted target or output path containing spaces, emit a short parse preflight line before target validation, for example: `Parsed Args: type=paper | target=C:/.../paper_target.md | out=C:/.../paper_report.md`.'
  '- If that parse preflight does not preserve the exact quoted target substring, stop and re-parse instead of diagnosing path fragments.'
  '- `--focus [theme]` adds one focus topic at a time and may be repeated.'
  '- `--out [path]` sets the report path.'
  '- `--lang [zh/en]` forces report language.'
  '- `--lite` reduces round limits but must not skip critical verification:'
  '- If no audit target can be identified, stop and prompt the user to specify one.'
  'When any normal-path assumption breaks, follow `references/degradation-and-limitations.md`.'
  'If big rounds are `>=6` or the target is large, merge-phase context pressure is likely; prefer Context Mode MCP when available.'
  'Any degraded path must be declared explicitly and must not be presented as equivalent to normal parallel isolated execution.'
  'Sequential fallback lowers the independence guarantee and must be reported as such.'
  '- platform limitations'
)
ZH_ANCHORS=(
  '仅在用户以任意大小写形式显式输入 `---audit` 时激活。'
  '首先按引号感知方式捕获参数。任何被成对引号包住的子串，在进一步解释前都算一个原始参数。'
  '当存在带引号参数、或路径解析有歧义时，必须把 `---audit` 后面的原始参数串通过 stdin 或单个字符串参数喂给 `python scripts/parse-audit-args.py`，并把它输出的 JSON 结果当作后续启发式之前的 canonical parse。'
  '- `paper` / `论文`'
  '- `code` / `代码`'
  '- `plan` / `方案`'
  '- `data` / `数据`'
  '- `mixed` / `混合`'
  '- 如果没有提供参数，识别当前对话中最近的 substantive deliverable。'
  '- 带空格的加引号 target 路径必须保留为单个路径参数，不得在目标识别阶段被拆成多个 token。'
  '- 如果类型关键字后面跟着带引号的路径，只能去掉最外层引号并校验完整路径字符串；不得把 `C:/Users/jdoe/OneDrive` 之类的内部片段当成独立 target 去探测。'
  '- 引号内部的完整原始子串才是 authoritative target path；在校验时不得把它重写成一个更短、但恰好存在的前缀目录。'
  '- 只要 target 或 output 路径带引号且含空格，就要在真正校验前先显式输出一行 parse preflight，例如：`Parsed Args: type=paper | target=C:/.../paper_target.md | out=C:/.../paper_report.md`。'
  '- 如果这行 parse preflight 没能保留完整的引号 target 子串，就必须停止并重新解析，而不是继续诊断路径片段。'
  '- `--focus [theme]` 每次添加一个重点主题，可重复使用。'
  '- `--out [path]` 设置报告路径。若省略，则使用默认相对报告路径；若路径已存在，则自动追加 `_2`、`_3` 等后缀。'
  '- `--lang [zh/en]` 强制指定报告语言；否则按审计对象语言自动匹配。'
  '- `--lite` 会缩减轮次上限，但不得跳过关键验证：'
  '- 如果无法识别审计对象，停止并提示用户明确指定。'
  '当正常路径的任一前提失效时，遵循 `references/degradation-and-limitations.md`。'
  '如果 big rounds `>=6` 或审计对象很大，merge 阶段更容易出现 context pressure；若可用，优先启用 Context Mode MCP。'
  '任何降级路径都必须显式声明，不得伪装成与正常并行隔离执行等价。'
  '顺序 fallback 会降低独立性保证，必须明确告知这一点。'
  '- platform limitations'
)
for needle in "${EN_ANCHORS[@]}"; do
  check_literal FAIL E001 "$SKILL_EN" "$needle" "missing required English entry anchor: $needle"
done
for needle in "${ZH_ANCHORS[@]}"; do
  check_literal FAIL E002 "$SKILL_ZH" "$needle" "missing required Chinese entry anchor: $needle"
done

# M4. Canonical source map
check_literal FAIL C001 "$README_FILE" '## Canonical Source Map' "README is missing the Canonical Source Map section"
check_literal FAIL C002 "$README_FILE" 'This README is a maintenance and orientation document. It is **not** the canonical runtime authority for execution rules.' "README is missing the non-authority guardrail line"
check_file_exists C006 "$CONTRACTS_FILE" "maintenance contracts file is missing"
check_file_nonempty C007 "$CONTRACTS_FILE" "maintenance contracts file is empty"
mapfile -t CANONICAL_MAP_LITERAL_ROWS < <(contract_rest_lines canonical_map_row)
if [[ ${#CANONICAL_MAP_LITERAL_ROWS[@]} -eq 0 ]]; then
  record_finding FAIL C008 "$CONTRACTS_FILE" "maintenance contracts file does not define any canonical_map_row entries"
fi
check_expected_count C009 "$CONTRACTS_FILE" "canonical_map_row" "${#CANONICAL_MAP_LITERAL_ROWS[@]}" 13
for row in "${CANONICAL_MAP_LITERAL_ROWS[@]}"; do
  check_literal FAIL C003 "$README_FILE" "$row" "README canonical source map is missing or drifting from expected responsibility row: $row"
done
mapfile -t CANONICAL_MAP_PATHS < <(
  awk -F'`' '
    /^## Canonical Source Map/ { in_map = 1; next }
    in_map && /^## / { exit }
    in_map && /^\| `[^`]+` \|/ { print $2 }
  ' "$README_FILE"
)
if [[ ${#CANONICAL_MAP_PATHS[@]} -eq 0 ]]; then
  record_finding FAIL C004 "$README_FILE" "README canonical source map did not yield any parseable file rows"
else
  record_pass
fi
for rel_path in "${CANONICAL_MAP_PATHS[@]}"; do
  mapped_file="$PACKAGE_ROOT/$rel_path"
  if [[ -f "$mapped_file" ]]; then
    record_pass
  else
    record_finding FAIL C005 "$README_FILE" "README canonical source map points to missing file: $rel_path"
  fi
done

# M5. Script contracts
CONFIG_VALUES="$PACKAGE_ROOT/scripts/config-optimal-values.sh"
CONFIG_CHECK="$PACKAGE_ROOT/scripts/config-check.sh"
CONFIG_OPTIMIZE="$PACKAGE_ROOT/scripts/config-optimize.sh"
CONFIG_RESTORE="$PACKAGE_ROOT/scripts/config-restore.sh"
AUDIT_SELF_CHECK="$PACKAGE_ROOT/scripts/audit-self-check.sh"
CHECK_SMOKE_EVIDENCE="$PACKAGE_ROOT/scripts/check-smoke-evidence.sh"
VALIDATE_REPORT="$PACKAGE_ROOT/scripts/validate-report.sh"
TEST_GOLDEN="$PACKAGE_ROOT/scripts/test-golden.sh"
PARSE_AUDIT_ARGS="$PACKAGE_ROOT/scripts/parse-audit-args.py"

for symbol in OPTIMAL_MODEL OPTIMAL_EFFORT OPTIMAL_FAST OPTIMAL_THINKING SETTINGS_FILE BACKUP_FILE JQ_BIN; do
  check_literal FAIL S001 "$CONFIG_VALUES" "$symbol=" "shared config symbol is missing from config-optimal-values.sh: $symbol"
done
check_literal FAIL S104 "$CONFIG_VALUES" 'command -v jq.exe' "config-optimal-values.sh no longer preserves the jq.exe discovery branch"
check_literal FAIL S105 "$CONFIG_VALUES" 'command -v where.exe' "config-optimal-values.sh no longer preserves the where.exe fallback branch"
check_literal FAIL S106 "$CONFIG_VALUES" 'where.exe jq' "config-optimal-values.sh no longer preserves the WinGet jq discovery call"

check_literal FAIL S002 "$CONFIG_CHECK" 'STATUS: OK' "config-check.sh is missing STATUS: OK"
check_literal FAIL S003 "$CONFIG_CHECK" 'STATUS: MISMATCH' "config-check.sh is missing STATUS: MISMATCH"
check_literal FAIL S004 "$CONFIG_CHECK" 'MODEL_MISMATCH: true' "config-check.sh is missing MODEL_MISMATCH: true"
check_literal FAIL S005 "$CONFIG_CHECK" 'DIFF:' "config-check.sh is missing DIFF:"
check_literal FAIL S006 "$CONFIG_CHECK" 'MATCH:' "config-check.sh is missing MATCH:"

check_shared_source_binding S007 "$CONFIG_CHECK" \
  'settings-path-check::^[[:space:]]*if \[\[ ! -f "\$SETTINGS_FILE" \]\]' \
  'model-compare::^[[:space:]]*if \[\[ "\$cur_model" != "\$OPTIMAL_MODEL" \]\]' \
  'effort-compare::^[[:space:]]*if \[\[ "\$cur_effort" != "\$OPTIMAL_EFFORT" \]\]' \
  'fast-compare::^[[:space:]]*if \[\[ "\$cur_fast" != "\$OPTIMAL_FAST" \]\]' \
  'thinking-compare::^[[:space:]]*if \[\[ "\$cur_thinking" != "\$OPTIMAL_THINKING" \]\]'
check_no_post_source_override S036 "$CONFIG_CHECK" OPTIMAL_MODEL OPTIMAL_EFFORT OPTIMAL_FAST OPTIMAL_THINKING SETTINGS_FILE JQ_BIN
check_shared_source_binding S008 "$CONFIG_OPTIMIZE" \
  'settings-path-check::^[[:space:]]*if \[\[ ! -f "\$SETTINGS_FILE" \]\]' \
  'backup-path-check::^[[:space:]]*if \[\[ -f "\$BACKUP_FILE" \]\]' \
  'model-jq-arg::^[[:space:]]*"\$JQ_BIN" -S --arg m "\$OPTIMAL_MODEL"[[:space:]]*\\$' \
  'effort-jq-arg::^[[:space:]]*--arg e "\$OPTIMAL_EFFORT"[[:space:]]*\\$' \
  'fast-jq-arg::^[[:space:]]*--argjson f "\$OPTIMAL_FAST"[[:space:]]*\\$' \
  'thinking-jq-arg::^[[:space:]]*--argjson t "\$OPTIMAL_THINKING"[[:space:]]*\\$'
check_no_post_source_override S037 "$CONFIG_OPTIMIZE" OPTIMAL_MODEL OPTIMAL_EFFORT OPTIMAL_FAST OPTIMAL_THINKING SETTINGS_FILE BACKUP_FILE JQ_BIN
check_shared_source_binding S009 "$CONFIG_RESTORE" \
  'backup-path-check::^[[:space:]]*if \[\[ ! -f "\$BACKUP_FILE" \]\]' \
  'copy-restore::^[[:space:]]*if ! cp "\$BACKUP_FILE" "\$SETTINGS_FILE"; then' \
  'current-settings-check::^[[:space:]]*if \[\[ ! -f "\$SETTINGS_FILE" \]\] \|\| ! "\$JQ_BIN" empty "\$SETTINGS_FILE"' \
  'slurp-backup::^[[:space:]]*"\$JQ_BIN" -S --slurpfile backup "\$BACKUP_FILE"[[:space:]]'
check_no_post_source_override S038 "$CONFIG_RESTORE" SETTINGS_FILE BACKUP_FILE JQ_BIN

check_literal FAIL S010 "$CONFIG_OPTIMIZE" 'OPTIMIZED:' "config-optimize.sh is missing OPTIMIZED:"
check_literal FAIL S011 "$CONFIG_OPTIMIZE" 'BACKUP:' "config-optimize.sh is missing BACKUP:"
check_literal FAIL S012 "$CONFIG_OPTIMIZE" 'backup already exists' "config-optimize.sh is missing backup-exists refusal marker"
check_literal FAIL S013 "$CONFIG_OPTIMIZE" 'Generate modified JSON to temp file FIRST' "config-optimize.sh is missing generate-before-commit marker"
check_literal FAIL S014 "$CONFIG_OPTIMIZE" 'Only create backup AFTER jq succeeds' "config-optimize.sh is missing create-backup-after-generation marker"

check_literal FAIL S015 "$CONFIG_RESTORE" 'RESTORED:' "config-restore.sh is missing RESTORED:"
check_literal FAIL S016 "$CONFIG_RESTORE" 'SKIP:' "config-restore.sh is missing SKIP:"
check_literal FAIL S017 "$CONFIG_RESTORE" 'jq not found, falling back to full file restore' "config-restore.sh is missing jq-unavailable fallback marker"
check_literal FAIL S018 "$CONFIG_RESTORE" 'current settings.json is missing or corrupted, falling back to full file restore from backup' "config-restore.sh is missing missing/corrupted-settings fallback marker"

check_literal FAIL S019 "$AUDIT_SELF_CHECK" 'Summary' "audit-self-check.sh is missing the Summary output section marker"
check_literal FAIL S020 "$AUDIT_SELF_CHECK" 'Findings' "audit-self-check.sh is missing the Findings output section marker"
check_literal FAIL S021 "$AUDIT_SELF_CHECK" 'Manual Follow-Ups' "audit-self-check.sh is missing the Manual Follow-Ups output section marker"
check_literal FAIL S022 "$AUDIT_SELF_CHECK" '0 = no FAIL findings' "audit-self-check.sh is missing the exit-0 contract marker"
check_literal FAIL S023 "$AUDIT_SELF_CHECK" '1 = one or more FAIL findings' "audit-self-check.sh is missing the exit-1 contract marker"
check_literal FAIL S024 "$AUDIT_SELF_CHECK" '2 = checker execution error' "audit-self-check.sh is missing the exit-2 contract marker"
check_literal FAIL S088 "$VALIDATE_REPORT" 'validate-report.sh <report-path>' "validate-report.sh is missing its usage contract"
check_literal FAIL S089 "$VALIDATE_REPORT" 'Audit complete, no issues found.' "validate-report.sh no longer protects the all-zero completion line"
check_literal FAIL S090 "$VALIDATE_REPORT" '# AUDIT Partial Report' "validate-report.sh no longer protects the degraded partial-report heading"
check_literal FAIL S091 "$VALIDATE_REPORT" 'unsupported report shape: missing canonical report header' "validate-report.sh no longer rejects unsupported report shapes explicitly"
check_literal FAIL S092 "$CHECK_SMOKE_EVIDENCE" 'check-smoke-evidence.sh <SMOKE_ROOT> [<SMOKE_ROOT> ...]' "check-smoke-evidence.sh is missing its usage contract"
check_literal FAIL S093 "$CHECK_SMOKE_EVIDENCE" 'archived markdown smoke report is stale under the current validator:' "check-smoke-evidence.sh no longer surfaces the stale-evidence finding contract"
check_literal FAIL S094 "$CHECK_SMOKE_EVIDENCE" 'scripts/validate-report.sh' "check-smoke-evidence.sh no longer declares its dependency on the current validator"
check_literal FAIL S095 "$TEST_GOLDEN" 'test-golden.sh [PACKAGE_ROOT]' "test-golden.sh is missing its usage contract"
check_literal FAIL S096 "$TEST_GOLDEN" 'normal-report.md' "test-golden.sh no longer checks the normal-report golden"
check_literal FAIL S097 "$TEST_GOLDEN" 'richer-normal-report.md' "test-golden.sh no longer checks the richer-normal-report golden"
check_literal FAIL S098 "$TEST_GOLDEN" 'all-zero-report.md' "test-golden.sh no longer checks the all-zero golden"
check_literal FAIL S099 "$TEST_GOLDEN" 'partial-report.md' "test-golden.sh no longer checks the partial-report golden"
check_literal FAIL S100 "$TEST_GOLDEN" 'output-verification-warning.txt' "test-golden.sh no longer checks the output-verification-warning golden"
check_literal FAIL S125 "$PARSE_AUDIT_ARGS" 'print(json.dumps({"ok": True, "raw": raw, "args": args}, ensure_ascii=False))' "parse-audit-args.py is missing the canonical JSON stdout contract"
if bash -n "$VALIDATE_REPORT"; then
  record_pass
else
  record_finding FAIL S101 "$VALIDATE_REPORT" "validate-report.sh failed bash -n syntax validation"
fi
if bash -n "$CHECK_SMOKE_EVIDENCE"; then
  record_pass
else
  record_finding FAIL S102 "$CHECK_SMOKE_EVIDENCE" "check-smoke-evidence.sh failed bash -n syntax validation"
fi
if bash -n "$TEST_GOLDEN"; then
  record_pass
else
  record_finding FAIL S103 "$TEST_GOLDEN" "test-golden.sh failed bash -n syntax validation"
fi
# ── Rule ID Registry ──────────────────────────────────────────────
# Static checks:  L001-L091, S001-S106 (excl. S025-S033 reserved for self-probes), S125   (file existence, literals, contracts)
# Self-probes:    S025-S033 (checker), S130-S133 (golden), S134 (smoke-bad-root)
# Smoke probes:   S120-S124, S126                   (smoke-evidence)
# Fixtures:       T001-T050                          (test-scenarios fixed-line)
# Anchors:        R001-R022                          (reference/template section headings)
# Coverage:       A001+, A015-A018                   (checklist, regex, scenario, example)
# Execution tests (scripts/execution-test.sh — separate checker, listed here for cross-reference):
#                 E001-E014 (config-check), E020-E028 (config-optimize),
#                 E030-E040 (config-restore), E050-E055 (validate-report),
#                 E060-E070 (parse-audit-args)
# Note: check-smoke-evidence.sh also uses E001-E002 in its own context (separate output)
# ──────────────────────────────────────────────────────────────────

# Run nested self-probes only for the live package that this script belongs to.
# An explicit PACKAGE_ROOT still qualifies if it canonicalizes to PACKAGE_ROOT_DEFAULT.
if [[ "${AUDIT_SELF_CHECK_SELFTEST_DEPTH:-0}" == "0" && "$PACKAGE_ROOT" == "$PACKAGE_ROOT_DEFAULT" ]]; then
  self_tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/audit-self-check.XXXXXX")"
  self_ok_out="$self_tmp_dir/ok.txt"
  self_ok_rc="$self_tmp_dir/ok.rc"
  self_fail_out="$self_tmp_dir/fail.txt"
  self_fail_rc="$self_tmp_dir/fail.rc"
  self_error_out="$self_tmp_dir/error.txt"
  self_error_rc="$self_tmp_dir/error.rc"
  self_broken_pkg="$self_tmp_dir/broken-package"
  self_golden_ok_out="$self_tmp_dir/golden-ok.txt"
  self_golden_ok_rc="$self_tmp_dir/golden-ok.rc"
  self_golden_fail_out="$self_tmp_dir/golden-fail.txt"
  self_golden_fail_rc="$self_tmp_dir/golden-fail.rc"
  self_golden_broken_pkg="$self_tmp_dir/broken-golden-package"
  self_golden_tmp="$self_tmp_dir/all-zero-report.tmp"
  self_smoke_ok_dir="$self_tmp_dir/smoke-ok"
  self_smoke_stale_dir="$self_tmp_dir/smoke-stale"
  self_smoke_ok_out="$self_tmp_dir/smoke-ok.txt"
  self_smoke_stale_out="$self_tmp_dir/smoke-stale.txt"
  self_smoke_error_out="$self_tmp_dir/smoke-error.txt"

  run_self_probe "$PACKAGE_ROOT" "$self_ok_out" "$self_ok_rc"
  if [[ "$(cat "$self_ok_rc")" == "0" ]]; then
    record_pass
  else
    record_finding FAIL S025 "$AUDIT_SELF_CHECK" "clean self-probe exited with non-zero status: $(cat "$self_ok_rc")"
  fi
  check_literal FAIL S026 "$self_ok_out" 'Summary' "clean self-probe output is missing Summary"
  check_literal FAIL S027 "$self_ok_out" 'Findings' "clean self-probe output is missing Findings"
  check_literal FAIL S028 "$self_ok_out" 'Manual Follow-Ups' "clean self-probe output is missing Manual Follow-Ups"
  if grep -Eq '^- FAIL ' "$self_ok_out"; then
    record_finding FAIL S029 "$self_ok_out" "clean self-probe output must not contain FAIL findings when it exits 0"
  else
    record_pass
  fi

  mkdir -p "$self_broken_pkg"
  cp -R "$PACKAGE_ROOT/." "$self_broken_pkg/"
  rm -f "$self_broken_pkg/examples.md"
  run_self_probe "$self_broken_pkg" "$self_fail_out" "$self_fail_rc"
  if [[ "$(cat "$self_fail_rc")" == "1" ]]; then
    record_pass
  else
    record_finding FAIL S030 "$AUDIT_SELF_CHECK" "broken-package self-probe should exit 1 but returned $(cat "$self_fail_rc"); see $self_fail_out"
  fi
  check_regex FAIL S031 "$self_fail_out" '^- FAIL ' "broken-package self-probe should emit at least one FAIL finding"

  run_self_probe "$self_tmp_dir/does-not-exist" "$self_error_out" "$self_error_rc"
  if [[ "$(cat "$self_error_rc")" == "2" ]]; then
    record_pass
  else
    record_finding FAIL S032 "$AUDIT_SELF_CHECK" "bad-root self-probe should exit 2 but returned $(cat "$self_error_rc"); see $self_error_out"
  fi
  check_literal FAIL S033 "$self_error_out" 'ERROR: package root not found or unreadable:' "bad-root self-probe should surface the invocation error message"

  if bash "$TEST_GOLDEN" "$PACKAGE_ROOT" >"$self_golden_ok_out" 2>&1; then
    record_pass
  else
    record_finding FAIL S130 "$TEST_GOLDEN" "live golden harness should exit 0 but failed; see $self_golden_ok_out"
  fi
  check_literal FAIL S131 "$self_golden_ok_out" 'Fail Count: 0' "live golden harness should report zero failed checks"

  mkdir -p "$self_golden_broken_pkg"
  cp -R "$PACKAGE_ROOT/." "$self_golden_broken_pkg/"
  awk '$0 != "## Summary Statistics"' "$self_golden_broken_pkg/goldens/all-zero-report.md" > "$self_golden_tmp"
  cp "$self_golden_tmp" "$self_golden_broken_pkg/goldens/all-zero-report.md"
  rm -f "$self_golden_tmp"
  if bash "$self_golden_broken_pkg/scripts/test-golden.sh" "$self_golden_broken_pkg" >"$self_golden_fail_out" 2>&1; then
    golden_rc=0
  else
    golden_rc=$?
  fi
  printf '%s' "$golden_rc" > "$self_golden_fail_rc"
  if [[ "$(cat "$self_golden_fail_rc")" == "1" ]]; then
    record_pass
  else
    record_finding FAIL S132 "$TEST_GOLDEN" "broken-golden harness should exit 1 but returned $(cat "$self_golden_fail_rc"); see $self_golden_fail_out"
  fi
  check_regex FAIL S133 "$self_golden_fail_out" 'FAIL:' "broken-golden harness should emit at least one FAIL line"

  mkdir -p "$self_smoke_ok_dir"
  cp "$GOLDEN_DIR/normal-report.md" "$self_smoke_ok_dir/normal.md"
  cp "$GOLDEN_DIR/partial-report.md" "$self_smoke_ok_dir/partial.md"
  if bash "$CHECK_SMOKE_EVIDENCE" "$self_smoke_ok_dir" >"$self_smoke_ok_out" 2>&1; then
    smoke_ok_rc=0
  else
    smoke_ok_rc=$?
  fi
  if [[ "$smoke_ok_rc" == "0" ]]; then
    record_pass
  else
    record_finding FAIL S120 "$CHECK_SMOKE_EVIDENCE" "current-only smoke-evidence probe should exit 0 but returned $smoke_ok_rc; see $self_smoke_ok_out"
  fi
  check_literal FAIL S121 "$self_smoke_ok_out" 'Findings' "current-only smoke-evidence probe output is missing Findings"
  check_literal FAIL S122 "$self_smoke_ok_out" '- None' "current-only smoke-evidence probe should report no stale findings"

  mkdir -p "$self_smoke_stale_dir/reports"
  awk '$0 != "## Appendix"' \
    "$GOLDEN_DIR/normal-report.md" > "$self_smoke_stale_dir/reports/stale.md"
  if bash "$CHECK_SMOKE_EVIDENCE" "$self_smoke_stale_dir" >"$self_smoke_stale_out" 2>&1; then
    smoke_stale_rc=0
  else
    smoke_stale_rc=$?
  fi
  if [[ "$smoke_stale_rc" == "1" ]]; then
    record_pass
  else
    record_finding FAIL S123 "$CHECK_SMOKE_EVIDENCE" "stale smoke-evidence probe should exit 1 but returned $smoke_stale_rc; see $self_smoke_stale_out"
  fi
  check_regex FAIL S124 "$self_smoke_stale_out" 'FAIL E002 .*archived markdown smoke report is stale under the current validator:' "stale smoke-evidence probe should emit an E002 stale finding"

  if bash "$CHECK_SMOKE_EVIDENCE" "$self_tmp_dir/does-not-exist" >"$self_smoke_error_out" 2>&1; then
    smoke_error_rc=0
  else
    smoke_error_rc=$?
  fi
  if [[ "$smoke_error_rc" == "2" ]]; then
    record_pass
  else
    record_finding FAIL S134 "$CHECK_SMOKE_EVIDENCE" "bad-root smoke-evidence probe should exit 2 but returned $smoke_error_rc; see $self_smoke_error_out"
  fi
  check_literal FAIL S126 "$self_smoke_error_out" 'ERROR: smoke root not found or unreadable:' "bad-root smoke-evidence probe should surface the invocation error message"

  rm -rf "$self_tmp_dir"
fi
check_literal FAIL S034 "$README_FILE" 'Bash-compatible shell' "README no longer documents the Bash-compatible shell prerequisite"
check_literal FAIL S035 "$README_FILE" '| `jq` | Required | Used by config scripts; on Windows, a WinGet-installed `jq.exe` is acceptable if the active Bash environment can resolve it or discover it via `where.exe` |' "README no longer documents the jq prerequisite"
check_literal FAIL S039 "$README_FILE" 'Prefer Git Bash for the config scripts.' "README no longer preserves the Windows Git Bash preference"
check_literal FAIL S040 "$README_FILE" 'the same active Claude profile that the running session is using' "README no longer preserves the active-profile Windows shell boundary"
check_literal FAIL S041 "$PACKAGE_ROOT/references/phase-0-planning.md" 'If `bash` on `PATH` points to an incompatible environment, treat that as a script-error fallback rather than a silent success path.' "Phase 0 planning no longer preserves the incompatible-bash fallback boundary"
check_literal FAIL S042 "$TEST_SCENARIOS" 'the script is executed in a compatible bash environment where `jq` is installed and `$HOME/.claude/settings.json` resolves to the active Claude profile' "test-scenarios no longer preserves the compatible-bash active-profile precondition"
check_literal FAIL S043 "$TEST_SCENARIOS" 'treating an incompatible bash environment as a normal `STATUS: OK` path' "test-scenarios no longer guards the incompatible-bash failure mode"
check_literal FAIL S044 "$PACKAGE_ROOT/templates/subagent-template.md" 'paper -> PubMed for citation existence and original method-source checks, plus Brave Search / Brave LLM context search for broader factual or methodological cross-checks' "subagent template no longer preserves the stricter paper verification route"
check_literal FAIL S045 "$PACKAGE_ROOT/templates/subagent-template.md" '**Paper citation verification (mandatory)**' "subagent template no longer preserves explicit mandatory paper citation verification wording"
check_literal FAIL S046 "$PACKAGE_ROOT/templates/subagent-template.md" '**Method verification (mandatory for key methods)**' "subagent template no longer preserves explicit mandatory method verification wording"
check_literal FAIL S047 "$TEST_SCENARIOS" 'PubMed-backed citation verification remains mandatory for paper claims even when Brave Search or Brave LLM context search is used for supplementary cross-checks' "test-scenarios no longer guards the PubMed-first paper verification invariant"
check_literal FAIL S048 "$TEST_SCENARIOS" 'original method-source verification remains distinct from general paper fact-checking rather than collapsing into a single vague web-search path' "test-scenarios no longer guards the original-method-source paper invariant"
check_literal FAIL S049 "$PACKAGE_ROOT/templates/subagent-template.md" 'data analysis -> Grep for local result/table consistency plus Brave Search for external statistical, methodological, or standards verification' "subagent template no longer preserves the fixed data-analysis verification route"
check_literal FAIL S050 "$PACKAGE_ROOT/templates/subagent-template.md" 'mixed -> use the fixed path that matches the issue-bearing material, defaulting to the bound dominant type from `Mixed Target Routing` only when the issue does not clearly belong to one component' "subagent template no longer preserves the fixed mixed-target verification route"
check_literal FAIL S051 "$TEST_SCENARIOS" 'V rounds use the dedicated data-analysis verification path: local consistency checks via `Grep`, plus `Brave Search` for external statistical, methodological, or standards verification' "test-scenarios no longer guards the dedicated data-analysis verification route"
check_literal FAIL S052 "$TEST_SCENARIOS" 'mixed-target verification remains component-aware rather than collapsing to one generic or arbitrary verification rule' "test-scenarios no longer guards the mixed-target verification invariant"
check_literal FAIL S053 "$SKILL_EN" 'When any normal-path assumption breaks, follow `references/degradation-and-limitations.md`.' "SKILL.md no longer preserves the entry-layer degradation handoff summary"
check_literal FAIL S054 "$SKILL_EN" 'Any degraded path must be declared explicitly and must not be presented as equivalent to normal parallel isolated execution.' "SKILL.md no longer preserves the explicit degraded-path declaration summary"
check_literal FAIL S055 "$SKILL_EN" 'Sequential fallback lowers the independence guarantee and must be reported as such.' "SKILL.md no longer preserves the sequential-fallback independence summary"
check_literal FAIL S056 "$SKILL_ZH" '当正常路径的任一前提失效时，遵循 `references/degradation-and-limitations.md`。' "SKILL_ZH.md no longer preserves the entry-layer degradation handoff summary"
check_literal FAIL S057 "$SKILL_ZH" '任何降级路径都必须显式声明，不得伪装成与正常并行隔离执行等价。' "SKILL_ZH.md no longer preserves the explicit degraded-path declaration summary"
check_literal FAIL S058 "$SKILL_ZH" '顺序 fallback 会降低独立性保证，必须明确告知这一点。' "SKILL_ZH.md no longer preserves the sequential-fallback independence summary"
check_literal FAIL S059 "$PACKAGE_ROOT/templates/report-template.md" '**Audit Target**: [name/path]' "report template no longer preserves the fixed report metadata opening line"
check_literal FAIL S060 "$PACKAGE_ROOT/templates/report-template.md" '**Model**: [actual model used, if known from session context; omit if unavailable] | Extended thinking: [ON/OFF, if determinable; omit if unavailable]' "report template no longer preserves the fixed model metadata line"
check_literal FAIL S061 "$PACKAGE_ROOT/templates/report-template.md" '| Field | Content |' "report template no longer preserves the fixed issue-table scaffold"
check_literal FAIL S062 "$PACKAGE_ROOT/templates/report-template.md" '| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |' "report template no longer preserves the fixed summary-statistics table header"
check_literal FAIL S063 "$PACKAGE_ROOT/templates/report-template.md" '| Final Number | Original Number | Big Round Theme |' "report template no longer preserves the fixed appendix number-mapping header"
check_literal FAIL S064 "$PACKAGE_ROOT/templates/report-template.md" '| Issue | Source | Explanation |' "report template no longer preserves the fixed cross-round appendix header"
check_literal FAIL S065 "$TEST_SCENARIOS" 'the header metadata block keeps the fixed lines `**Audit Target**: [name/path]`' "test-scenarios no longer guards the fixed report metadata block"
check_literal FAIL S066 "$TEST_SCENARIOS" 'final issue entries keep the fixed field rows `| Category | R[k] · [theme name] |`' "test-scenarios no longer guards the fixed final issue-table rows"
check_literal FAIL S067 "$TEST_SCENARIOS" 'the `Configuration` line uses the fixed format `Configuration: N/A (detect+guide mode; no settings were modified)`' "test-scenarios no longer guards the full fixed final-summary configuration line"
check_literal FAIL S068 "$PACKAGE_ROOT/references/phase-0-planning.md" '- [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...' "phase-0 planning no longer preserves the canonical per-file Target Components mapping scaffold"
check_literal FAIL S069 "$TEST_SCENARIOS" 'surfaces canonical per-file mapping lines of the form `- [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...`' "test-scenarios no longer guards the canonical per-file Target Components mapping scaffold"
check_literal FAIL S070 "$README_FILE" 'Treat `C:/Windows/system32/bash.exe` or a WSL bash whose `~/.claude` does not match the running session as incompatible; that branch should enter the documented script-error fallback.' "README no longer preserves the explicit incompatible-Windows-bash example"
check_literal FAIL S071 "$SKILL_EN" 'On Windows, prefer Git Bash; treat `C:/Windows/system32/bash.exe` or a WSL bash that cannot see the active `~/.claude` profile as incompatible and route that branch to the documented script-error fallback' "SKILL.md no longer preserves the explicit incompatible-Windows-bash summary"
check_literal FAIL S072 "$SKILL_ZH" '在 Windows 上优先使用 Git Bash；若 `bash` 实际解析到 `C:/Windows/system32/bash.exe`，或解析到看不到当前活动 `~/.claude` 配置的 WSL bash，应视为不兼容并进入文档规定的 script-error fallback' "SKILL_ZH.md no longer preserves the explicit incompatible-Windows-bash summary"
check_literal FAIL S073 "$PACKAGE_ROOT/references/phase-0-planning.md" 'A quoted target path containing spaces must remain a single target argument through parameter parsing, readability checks, and pre-planning target loading.' "phase-0 planning no longer preserves the quoted-target-path parsing boundary"
check_literal FAIL S074 "$PACKAGE_ROOT/references/phase-0-planning.md" 'On Windows, `C:/Windows/system32/bash.exe` or a WSL bash whose `~/.claude` does not match the active session profile is incompatible and belongs to the documented script-error fallback branch.' "phase-0 planning no longer preserves the explicit incompatible-Windows-bash branch"
check_literal FAIL S075 "$TEST_SCENARIOS" 'the quoted target path remains one target argument instead of being split into multiple tokens' "test-scenarios no longer guards the quoted-target-path parsing boundary"
check_literal FAIL S076 "$TEST_SCENARIOS" 'treating `C:/Windows/system32/bash.exe` or a foreign WSL bash as a normal config-check success path' "test-scenarios no longer guards the explicit incompatible-Windows-bash failure mode"
check_literal FAIL S077 "$PACKAGE_ROOT/references/phase-0-planning.md" 'If a type keyword precedes that quoted path, validate only the full quoted path string; never probe internal fragments such as `C:/Users/jdoe/OneDrive` as if they were standalone targets.' "phase-0 planning no longer preserves the no-fragment-probe rule for quoted target paths"
check_literal FAIL S078 "$TEST_SCENARIOS" 'fragmentary probes such as `C:/Users/jdoe/OneDrive` are not treated as candidate targets when the full quoted path is available' "test-scenarios no longer guards the no-fragment-probe rule for quoted target paths"
check_literal FAIL S079 "$PACKAGE_ROOT/references/phase-0-planning.md" 'Quote-aware grouping must happen before type-vs-path heuristics and before any file/directory diagnosis.' "phase-0 planning no longer preserves the quote-aware grouping order rule"
check_literal FAIL S080 "$TEST_SCENARIOS" 'quote-aware grouping happens before type-vs-path heuristics, so the full quoted OneDrive-style path is captured as the single post-type target argument' "test-scenarios no longer guards the quote-aware grouping order rule"
check_literal FAIL S081 "$PACKAGE_ROOT/references/phase-0-planning.md" 'The exact raw substring inside the quotes is the authoritative target path; do not rewrite it to a shorter existing prefix directory during readability diagnosis.' "phase-0 planning no longer preserves the authoritative-quoted-path rule"
check_literal FAIL S082 "$TEST_SCENARIOS" 'the exact raw substring inside the quotes remains the authoritative target path instead of being rewritten to a shorter existing prefix directory' "test-scenarios no longer guards the authoritative-quoted-path rule"
check_literal FAIL S083 "$PACKAGE_ROOT/references/phase-0-planning.md" 'When quoted arguments are present or path parsing is ambiguous, you must feed the raw args after `---audit` to `python scripts/parse-audit-args.py` via stdin or a single string argument and use its JSON output as the authoritative argument list before readability checks.' "phase-0 planning no longer preserves the deterministic quoted-argument parser rule"
check_literal FAIL S084 "$TEST_SCENARIOS" 'if a fresh-session runtime still rewrites the quoted path to a prefix directory after the mandatory helper plus parse-preflight flow, classify that result as a documented platform limitation and switch to a documented mitigation such as a no-space staged path or `audit_object_temp.md` rather than weakening this contract' "test-scenarios no longer guards the documented limitation + mitigation boundary for persistent quoted-path failures"
check_literal FAIL S085 "$PACKAGE_ROOT/references/phase-0-planning.md" 'For any quoted target or output path containing spaces, emit a short parse preflight line before readability diagnosis so the preserved `type / target / out` values are visible.' "phase-0 planning no longer preserves the parse-preflight requirement for quoted paths"
check_literal FAIL S086 "$TEST_SCENARIOS" 'a short parse preflight line is emitted before target validation so the preserved `type / target / out` values are visible' "test-scenarios no longer guards the parse-preflight requirement for quoted paths"
check_literal FAIL S087 "$PACKAGE_ROOT/references/degradation-and-limitations.md" '- **Fresh-session quoted OneDrive paper-path limitation**: Some fresh sessions may still rewrite a quoted OneDrive-style paper target path to an existing prefix directory even after the mandatory helper-parser plus parse-preflight flow.' "degradation reference no longer preserves the documented quoted-OneDrive paper-path limitation"

# M6. Reference and template anchors
REFERENCE_ANCHORS=(
  "$PACKAGE_ROOT/references/phase-0-planning.md|## 0.0 Configuration Detection|R001"
  "$PACKAGE_ROOT/references/phase-0-planning.md|## 0.4 MCP Verification|R002"
  "$PACKAGE_ROOT/references/phase-0-planning.md|## 0.5 Announcement|R003"
  "$PACKAGE_ROOT/references/phase-1-dispatch.md|## 1.2 Dispatch Initial Batch|R004"
  "$PACKAGE_ROOT/references/phase-1-dispatch.md|## 1.5 Template Binding|R005"
  "$PACKAGE_ROOT/references/phase-2-merge.md|## 2.2 Cross-Round Dedup|R006"
  "$PACKAGE_ROOT/references/phase-2-merge.md|## 2.4 Generate Final Report|R007"
  "$PACKAGE_ROOT/references/phase-2-merge.md|## 2.7 Final Summary|R008"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md|## Failure Handling|R009"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md|### Partial Report Output Contract|R010"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md|### Output Verification Warning Contract|R011"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md|## MCP And Tool Availability|R012"
  "$PACKAGE_ROOT/references/degradation-and-limitations.md|## Context Pressure Guidance|R013"
  "$PACKAGE_ROOT/templates/subagent-template.md|## Execution Protocol: Discovery/Verification (D/V) Cycle|R014"
  "$PACKAGE_ROOT/templates/subagent-template.md|### Return Summary|R015"
  "$PACKAGE_ROOT/templates/subagent-template.md|### MCP-Free Tool-Table Variant|R016"
  "$PACKAGE_ROOT/templates/subagent-template.md|## Hard Constraints|R017"
  "$PACKAGE_ROOT/templates/report-template.md|## Issue List|R018"
  "$PACKAGE_ROOT/templates/report-template.md|## Summary Statistics|R019"
  "$PACKAGE_ROOT/templates/report-template.md|## Overall Assessment|R020"
  "$PACKAGE_ROOT/templates/report-template.md|## Recommended Next Steps|R021"
  "$PACKAGE_ROOT/templates/report-template.md|## Appendix|R022"
  "$PACKAGE_ROOT/references/phase-2-merge.md|## 2.4.1 Post-Write Content Verification|R023"
)
for entry in "${REFERENCE_ANCHORS[@]}"; do
  IFS='|' read -r file needle rule <<< "$entry"
  check_literal FAIL "$rule" "$file" "$needle" "missing required reference/template anchor: $needle"
done

# M7. Fixed-line fixtures
FIXTURE_LITERALS=(
  'ℹ️ Configuration Check: Current settings differ from AUDIT optimal configuration'
  '| Setting | Current Value | AUDIT Optimal Value |'
  '⚠️ Current model is not Opus. Subagents are explicitly set to `model: "opus"` and will use Opus regardless. The orchestrator model cannot be changed mid-session; restart the session if you need the orchestrator on Opus too.'
  'Target: [target name/type]'
  'Mode: [Paper / Code / Plan / Data Analysis / Mixed (note primary + secondary type)]'
  'Domain: [identified domain]'
  'Target Components: [omit for single-file targets; required for multi-file or mixed targets]'
  '- [file/path] -> [primary / secondary / supporting component] -> relevant big rounds: R1 | R2 | ...'
  'Big Round Plan:'
  'Mode Limits: [Standard / Lite (4 rounds/3D)]'
  'Report Language: [zh / en / auto]'
  'MCP Status: [Available / ⚠️ Unavailable]'
  'Subagent Model: opus (explicitly specified)'
  'Output Report: [path]'
  '`Target Components` remains omitted for single-file targets but mandatory for multi-file and `mixed` targets'
  '- when the helper scripts are exposed, the planning layer may recommend `scripts/config-optimize.sh` before restart only if the user wants to temporarily switch settings for the next audit session'
  '- when the helper scripts are exposed, the planning layer may recommend `scripts/config-restore.sh` after the audit only if the user previously applied `scripts/config-optimize.sh` before restarting into the audit'
  '- the audit itself still does not require any restore action; `scripts/config-restore.sh` remains an optional post-audit user action outside the audit flow'
  'R[k] Complete · [theme name]'
  'AUDIT Partial Report'
  'Completed Big Rounds'
  'Incomplete Big Rounds'
  'Partial Report Path'
  'Retained Temp Files'
  'Next Action: Manual follow-up required before trusting audit completeness'
  'AUDIT Output Verification Warning'
  'Manual Check: Readback failed; verify written outputs manually before trusting completion'
  'AUDIT Complete'
  'Big Rounds Executed'
  'Total Issues'
  'Cross-Round Independent Discoveries'
  'Cross-Round Dedup Merges'
  'Report Path'
  'Configuration'
  'Configuration: N/A (detect+guide mode; no settings were modified)'
  '**Audit Target**: [name/path]'
  '**Model**: [actual model used, if known from session context; omit if unavailable] | Extended thinking: [ON/OFF, if determinable; omit if unavailable]'
  '# AUDIT Report'
  '### R[k] · [big round theme name]'
  '**P-[n]**: [short title (≤15 characters)] [⭐ cross-round independent discovery]'
  '| Field | Content |'
  '| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |'
  '| Final Number | Original Number | Big Round Theme |'
  '| Issue | Source | Explanation |'
  '### Number Mapping Table'
  '### Cross-Round Independent Discoveries'
  '> Original numbers are listed in ascending R order (R1 before R2, etc.) within each merged entry.'
  '`AUDIT Complete` remains success-only and must not be reused for degraded partial-report or readback-warning branches'
  'R[m]-[i] and R[n]-[j] independently discovered across big rounds (confidence: very high)'
  '| Issue | Sources | Explanation |'
)
fixture_rule=1
for needle in "${FIXTURE_LITERALS[@]}"; do
  rule_id="$(printf 'T%03d' "$fixture_rule")"
  check_literal FAIL "$rule_id" "$TEST_SCENARIOS" "$needle" "missing required fixed-line fixture: $needle"
  fixture_rule=$((fixture_rule + 1))
done

# M8. Scenario and calibration assets
check_literal FAIL A001 "$TEST_SCENARIOS" '## Coverage Checklist' "test-scenarios.md is missing the Coverage Checklist section"
LOAD_ORDER_LITERALS=(
  '- Phase 0: `references/phase-0-planning.md`'
  '- Phase 1: `references/phase-1-dispatch.md`, then `templates/subagent-template.md`'
  '- Phase 2: `references/phase-2-merge.md`, then `templates/report-template.md`'
  '- Any failure, degradation, or platform-limitation branch: `references/degradation-and-limitations.md`'
)
for needle in "${LOAD_ORDER_LITERALS[@]}"; do
  check_literal FAIL A002 "$SKILL_EN" "$needle" "SKILL.md is missing required support-file load-order literal: $needle"
done
check_section_literal_order FAIL A002 "$SKILL_EN" '## Support File Load Order' \
  '### Normal Execution' \
  '- Phase 0: `references/phase-0-planning.md`' \
  '- Phase 1: `references/phase-1-dispatch.md`, then `templates/subagent-template.md`' \
  '- Phase 2: `references/phase-2-merge.md`, then `templates/report-template.md`' \
  '### Exceptional Execution' \
  '- Any failure, degradation, or platform-limitation branch: `references/degradation-and-limitations.md`'
ZH_LOAD_ORDER_LITERALS=(
  '- 阶段 0：`references/phase-0-planning.md`'
  '- 阶段 1：先读 `references/phase-1-dispatch.md`，再读 `templates/subagent-template.md`'
  '- 阶段 2：先读 `references/phase-2-merge.md`，再读 `templates/report-template.md`'
  '- 任何失败、降级或平台限制分支：`references/degradation-and-limitations.md`'
)
for needle in "${ZH_LOAD_ORDER_LITERALS[@]}"; do
  check_literal FAIL A003 "$SKILL_ZH" "$needle" "SKILL_ZH.md is missing required support-file load-order literal: $needle"
done
check_section_literal_order FAIL A003 "$SKILL_ZH" '## 支持文件加载顺序' \
  '### 正常执行' \
  '- 阶段 0：`references/phase-0-planning.md`' \
  '- 阶段 1：先读 `references/phase-1-dispatch.md`，再读 `templates/subagent-template.md`' \
  '- 阶段 2：先读 `references/phase-2-merge.md`，再读 `templates/report-template.md`' \
  '### 异常执行' \
  '- 任何失败、降级或平台限制分支：`references/degradation-and-limitations.md`'
mapfile -t CHECKLIST_ITEMS < <(contract_rest_lines coverage_item_literal)
if [[ ${#CHECKLIST_ITEMS[@]} -eq 0 ]]; then
  record_finding FAIL A130 "$CONTRACTS_FILE" "maintenance contracts file does not define any coverage_item_literal entries"
fi
check_expected_count A134 "$CONTRACTS_FILE" "coverage_item_literal" "${#CHECKLIST_ITEMS[@]}" 16
checklist_rule=4
for needle in "${CHECKLIST_ITEMS[@]}"; do
  rule_id="$(printf 'A%03d' "$checklist_rule")"
  check_section_literal FAIL "$rule_id" "$TEST_SCENARIOS" '## Coverage Checklist' "$needle" "Coverage Checklist is missing required item: $needle"
  checklist_rule=$((checklist_rule + 1))
done
mapfile -t COVERAGE_ITEM_REGEXES < <(contract_rest_lines coverage_item_regex)
if [[ ${#COVERAGE_ITEM_REGEXES[@]} -eq 0 ]]; then
  record_finding FAIL A131 "$CONTRACTS_FILE" "maintenance contracts file does not define any coverage_item_regex entries"
fi
check_expected_count A135 "$CONTRACTS_FILE" "coverage_item_regex" "${#COVERAGE_ITEM_REGEXES[@]}" 4
regex_rule=$checklist_rule
for pattern in "${COVERAGE_ITEM_REGEXES[@]}"; do
  rule_id="$(printf 'A%03d' "$regex_rule")"
  check_section_regex FAIL "$rule_id" "$TEST_SCENARIOS" '## Coverage Checklist' "$pattern" "Coverage Checklist is missing required regex-backed item: $pattern"
  regex_rule=$((regex_rule + 1))
done
mapfile -t SCENARIO_HEADINGS < <(contract_rest_lines scenario_heading_regex)
if [[ ${#SCENARIO_HEADINGS[@]} -eq 0 ]]; then
  record_finding FAIL A132 "$CONTRACTS_FILE" "maintenance contracts file does not define any scenario_heading_regex entries"
fi
check_expected_count A136 "$CONTRACTS_FILE" "scenario_heading_regex" "${#SCENARIO_HEADINGS[@]}" 18
scenario_rule=20
for pattern in "${SCENARIO_HEADINGS[@]}"; do
  rule_id="$(printf 'A%03d' "$scenario_rule")"
  check_regex FAIL "$rule_id" "$TEST_SCENARIOS" "$pattern" "missing required scenario-heading family: $pattern"
  scenario_rule=$((scenario_rule + 1))
done
check_file_exists A100 "$EXAMPLES_FILE" "examples.md is missing"
check_file_nonempty A101 "$EXAMPLES_FILE" "examples.md is empty"
if [[ -s "$EXAMPLES_FILE" ]]; then
  mapfile -t EXAMPLE_HEADINGS < <(contract_rest_lines example_heading)
  if [[ ${#EXAMPLE_HEADINGS[@]} -eq 0 ]]; then
    record_finding FAIL A133 "$CONTRACTS_FILE" "maintenance contracts file does not define any example_heading entries"
  fi
  check_expected_count A137 "$CONTRACTS_FILE" "example_heading" "${#EXAMPLE_HEADINGS[@]}" 8
  example_rule=102
  for needle in "${EXAMPLE_HEADINGS[@]}"; do
    rule_id="$(printf 'A%03d' "$example_rule")"
    check_literal WARN "$rule_id" "$EXAMPLES_FILE" "$needle" "examples.md is missing expected calibration surface: $needle"
    example_rule=$((example_rule + 1))
  done
  example_order_found=0
  example_order_count=0
  while IFS=$'\t' read -r -a fields; do
    [[ ${#fields[@]} -gt 0 ]] || continue
    example_order_found=1
    example_order_count=$((example_order_count + 1))
    check_between_headings_literal_order FAIL A107 "$EXAMPLES_FILE" \
      "${fields[1]}" \
      "${fields[2]}" \
      "${fields[@]:3}"
  done < <(awk -F '\t' '$0 !~ /^#/ && $1 == "example_order" { print }' "$CONTRACTS_FILE")
  if [[ $example_order_found -eq 0 ]]; then
    record_finding FAIL A107 "$CONTRACTS_FILE" "maintenance contracts file does not define any example_order entries"
  else
    check_expected_count A138 "$CONTRACTS_FILE" "example_order" "$example_order_count" 1
  fi
fi

print_summary
print_findings
print_manuals

if [[ $FAIL_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0
