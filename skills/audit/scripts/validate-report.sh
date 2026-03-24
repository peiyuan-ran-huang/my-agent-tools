#!/usr/bin/env bash
# Validate canonical AUDIT report shapes and documented richer full-report variants.
# Usage:
#   validate-report.sh <report-path>
# Exit codes:
#   0 = report shape passes
#   1 = report shape fails
#   2 = invocation/runtime error

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate-report.sh <report-path>
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 2
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

REPORT_PATH="$1"
[[ -f "$REPORT_PATH" ]] || die "report file not found: $REPORT_PATH"
[[ -r "$REPORT_PATH" ]] || die "report file is not readable: $REPORT_PATH"

declare -a ERRORS=()

has_literal() {
  local needle="$1"
  grep -Fq -- "$needle" "$REPORT_PATH"
}

require_literal() {
  local needle="$1"
  local message="$2"
  if ! has_literal "$needle"; then
    ERRORS+=("$message")
  fi
}

require_absent() {
  local needle="$1"
  local message="$2"
  if has_literal "$needle"; then
    ERRORS+=("$message")
  fi
}

require_prefix() {
  local prefix="$1"
  local message="$2"
  if ! grep -Fq -- "$prefix" "$REPORT_PATH"; then
    ERRORS+=("$message")
  fi
}

require_any_literal() {
  local message="$1"
  shift
  local needle
  for needle in "$@"; do
    if has_literal "$needle"; then
      return 0
    fi
  done
  ERRORS+=("$message")
}

require_regex() {
  local pattern="$1"
  local message="$2"
  if ! grep -Eq -- "$pattern" "$REPORT_PATH"; then
    ERRORS+=("$message")
  fi
}

report_mode=""
if has_literal "# AUDIT Partial Report"; then
  report_mode="partial"
elif has_literal "# AUDIT Report" && has_literal "## Issue List"; then
  report_mode="full"
elif has_literal "# AUDIT Report"; then
  report_mode="all-zero"
else
  ERRORS+=("unsupported report shape: missing canonical report header")
fi

case "$report_mode" in
  full)
    require_literal "# AUDIT Report" "full report is missing the canonical top-level heading"
    require_prefix "**Audit Target**:" "full report is missing the Audit Target metadata line"
    require_prefix "**Target Type**:" "full report is missing the Target Type metadata line"
    require_prefix "**Domain**:" "full report is missing the Domain metadata line"
    require_prefix "**Audit Date**:" "full report is missing the Audit Date metadata line"
    require_prefix "**Audit Architecture**:" "full report is missing the Audit Architecture metadata line"
    require_prefix "**Big Rounds Executed**:" "full report is missing the Big Rounds Executed metadata line"
    if grep -Fq -- "**Total Issues (post-dedup)**:" "$REPORT_PATH"; then
      require_prefix "**Pre-dedup Total**:" "full report with post-dedup totals is missing the Pre-dedup Total metadata line"
      require_prefix "**Cross-Round Dedup Merges**:" "full report with post-dedup totals is missing the Cross-Round Dedup Merges metadata line"
    elif grep -Fq -- "**Total Issues**:" "$REPORT_PATH"; then
      require_absent "**Pre-dedup Total**:" "full report must not mix the minimal Total Issues line with a richer Pre-dedup Total metadata line"
      require_absent "**Cross-Round Dedup Merges**:" "full report must not mix the minimal Total Issues line with a richer Cross-Round Dedup Merges metadata line"
    else
      ERRORS+=("full report is missing an accepted Total Issues metadata line")
    fi
    require_prefix "**Cross-Round Independent Discoveries**:" "full report is missing the Cross-Round Independent Discoveries metadata line"
    require_prefix "**Tool Degradation**:" "full report is missing the Tool Degradation metadata line"
    require_literal "## Issue List" "full report is missing the Issue List section"
    require_literal "| Field | Content |" "full report is missing the canonical issue-table scaffold"
    require_literal "## Summary Statistics" "full report is missing the Summary Statistics section"
    require_any_literal "full report is missing an accepted Summary Statistics table header" \
      "| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |" \
      "| Big Round | Theme | Critical | Major | Minor | Total (pre-dedup) | D/V Rounds | Tool Calls |"
    require_literal "## Overall Assessment" "full report is missing the Overall Assessment section"
    require_literal "## Recommended Next Steps" "full report is missing the Recommended Next Steps section"
    require_literal "## Appendix" "full report is missing the Appendix section"
    require_literal "### Number Mapping Table" "full report is missing the Number Mapping Table subsection"
    require_any_literal "full report is missing an accepted number-mapping table header" \
      "| Final Number | Original Number | Big Round Theme |" \
      "| Final Number | Original Number(s) | Big Round Theme | Notes |"
    require_literal "### Cross-Round Independent Discoveries" "full report is missing the Cross-Round Independent Discoveries appendix subsection"
    require_any_literal "full report is missing an accepted appendix cross-round table header" \
      "| Issue | Source | Explanation |" \
      "| Issue | Sources | Explanation |"
    require_regex '^> Original numbers( are)? listed in ascending R order( \(R1 before R2, etc\.\))? within each merged entry\.$' "full report is missing an accepted appendix explanatory note"
    ;;
  all-zero)
    require_literal "# AUDIT Report" "all-zero report is missing the canonical top-level heading"
    require_prefix "**Audit Target**:" "all-zero report is missing the Audit Target metadata line"
    require_prefix "**Target Type**:" "all-zero report is missing the Target Type metadata line"
    require_prefix "**Domain**:" "all-zero report is missing the Domain metadata line"
    require_prefix "**Audit Date**:" "all-zero report is missing the Audit Date metadata line"
    require_prefix "**Audit Architecture**:" "all-zero report is missing the Audit Architecture metadata line"
    require_prefix "**Big Rounds Executed**:" "all-zero report is missing the Big Rounds Executed metadata line"
    require_prefix "**Total Issues**:" "all-zero report is missing the Total Issues metadata line"
    require_prefix "**Cross-Round Independent Discoveries**:" "all-zero report is missing the Cross-Round Independent Discoveries metadata line"
    require_prefix "**Tool Degradation**:" "all-zero report is missing the Tool Degradation metadata line"
    require_literal "## Summary Statistics" "all-zero report is missing the Summary Statistics section"
    require_literal "| Big Round | Theme | Critical | Major | Minor | D/V Rounds | Tool Calls |" "all-zero report is missing the canonical Summary Statistics table header"
    require_literal "Audit complete, no issues found." "all-zero report is missing the fixed no-issues completion line"
    require_literal "## Overall Assessment" "all-zero report is missing the Overall Assessment section"
    require_absent "## Issue List" "all-zero report must not include the Issue List section"
    require_absent "## Appendix" "all-zero report must not include the Appendix section"
    ;;
  partial)
    require_literal "# AUDIT Partial Report" "partial report is missing the canonical degraded header"
    require_prefix "**Audit Target**:" "partial report is missing the Audit Target metadata line"
    require_prefix "**Target Type**:" "partial report is missing the Target Type metadata line"
    require_literal "**Completion Status**: Partial report due to degradation" "partial report is missing the canonical completion-status line"
    require_prefix "**Completed Big Rounds**:" "partial report is missing the Completed Big Rounds metadata line"
    require_prefix "**Incomplete Big Rounds**:" "partial report is missing the Incomplete Big Rounds metadata line"
    require_prefix "**Retained Temp Files**:" "partial report is missing the Retained Temp Files metadata line"
    require_prefix "**Interruption Note**:" "partial report is missing the Interruption Note metadata line"
    require_absent "# AUDIT Report" "partial report must not reuse the normal success report header"
    require_absent "## Issue List" "partial report must not reuse the normal Issue List scaffold"
    require_absent "## Summary Statistics" "partial report must not reuse the normal Summary Statistics scaffold"
    require_absent "## Recommended Next Steps" "partial report must not reuse the normal Recommended Next Steps scaffold"
    require_absent "## Appendix" "partial report must not reuse the normal Appendix scaffold"
    require_absent "### Number Mapping Table" "partial report must not claim the normal number-mapping appendix"
    require_absent "### Cross-Round Independent Discoveries" "partial report must not claim the normal cross-round appendix"
    require_absent "| Final Number | Original Number | Big Round Theme |" "partial report must not surface the normal number-mapping table header"
    require_absent "| Issue | Source | Explanation |" "partial report must not surface the normal cross-round appendix table header"
    require_absent "Audit complete, no issues found." "partial report must not reuse the all-zero success line"
    require_absent "AUDIT Complete" "partial report must not reuse the normal success summary label"
    ;;
  *)
    ;;
esac

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "FAIL (${#ERRORS[@]} errors)"
  for err in "${ERRORS[@]}"; do
    echo "- $err"
  done
  exit 1
fi

echo "PASS [$report_mode] $REPORT_PATH"
exit 0
