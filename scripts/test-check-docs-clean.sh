#!/usr/bin/env bash
# Self-test for check-docs-clean.sh.
#
# Spec §10 risk 1: "a pattern nobody proved can fail is not a guard." So this
# file carries one positive control PER denylist pattern, plus the allow-list
# cases that D6 (name CHPL on purpose) depends on, plus fail-closed.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-docs-clean.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

# must_pass <label> <content>
must_pass() {
  local label="$1" content="$2" dir
  dir="$(mktemp -d "$TMP/pass.XXXXXX")"
  printf '%s\n' "$content" > "$dir/page.md"
  if "$CHECK" "$dir" >/dev/null 2>&1; then
    echo "PASS (allowed): $label"
  else
    echo "FAIL: '$label' was wrongly flagged as a leak" >&2
    fails=$((fails + 1))
  fi
}

# must_fail <label> <content>
must_fail() {
  local label="$1" content="$2" dir
  dir="$(mktemp -d "$TMP/fail.XXXXXX")"
  printf '%s\n' "$content" > "$dir/page.md"
  if "$CHECK" "$dir" >/dev/null 2>&1; then
    echo "FAIL: '$label' was NOT caught" >&2
    fails=$((fails + 1))
  else
    echo "PASS (blocked): $label"
  fi
}

# --- The allow-list. D6 names the institution; if these red, the site cannot build.
must_pass "institution name"   "Built at the Cincinnati & Hamilton County Public Library."
must_pass "CHPL abbreviation"  "At CHPL the zip is distributed to branch staff."
must_pass "branch code"        "Type dc in the Branch Pickup Location column."
must_pass "org and repo names" "See chimpy-me/ils-toolkit and chimpy-me/sierra-ils-utils."
must_pass "reserved barcodes"  "| A000000000001 | dc |"

# --- One positive control per blocked pattern.
must_fail "internal Sierra host"  "ssh to sierra-app-rh8 and restart it"
must_fail "internal subnet"       "the box answers on 10.110.10.14"
must_fail "internal db host"      "connect to sqldaia for the report"
must_fail "storage appliance"     "the share lives on qumulo"
must_fail "personal address"      "written by ray.voelker for the team"
must_fail "internal service host" "browse to ils-reports.plch.net/bulk-holds/"
must_fail "internal domain"       "any host under plch.net is internal"
must_fail "staff email"           "email a.librarian@chpl.org for access"
must_fail "real item barcode"     "| A000000000097 | dc |"
must_fail "other real barcode"    "the item scanned as A000000000098"
must_fail "Sierra record number"  "the item record is .i12345678"

# --- Fail closed: a missing target is an error, never a silent pass.
if "$CHECK" "$TMP/does-not-exist" >/dev/null 2>&1; then
  echo "FAIL: missing directory did not fail closed" >&2
  fails=$((fails + 1))
else
  echo "PASS: missing directory fails closed"
fi

if [ "$fails" -ne 0 ]; then
  echo "check-docs-clean self-test FAILED ($fails case(s))" >&2
  exit 1
fi
echo "OK: check-docs-clean self-test passed"
