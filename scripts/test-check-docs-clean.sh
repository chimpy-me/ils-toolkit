#!/usr/bin/env bash
# Self-test for check-docs-clean.sh.
#
# Spec §10 risk 1: "a pattern nobody proved can fail is not a guard." So this
# file carries one positive control PER denylist pattern, plus the allow-list
# cases that D6 (name CHPL on purpose) depends on, plus fail-closed.
#
# must_fail asserts three things, not just "non-zero exit": exit code is
# EXACTLY 1, the output contains the expected leak substring, and the output
# contains EXACTLY ONE line matching ^LEAK:. That third assertion is load-
# bearing: without it, a denylist entry that's subsumed by a broader pattern
# (so its own control keeps "passing" via the broader match, or a script that
# unconditionally exit 1's with no pattern logic at all) can pass every case
# here without ever having been exercised. Reviewed 2026-08-27: this exact gap
# let 'ils-reports\.plch\.net' sit dead in the denylist, fully subsumed by
# 'plch\.net', with a control that proved nothing.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$SCRIPT_DIR/check-docs-clean.sh"

if [ ! -x "$CHECK" ]; then
  echo "ABORT: $CHECK does not exist or is not executable" >&2
  exit 1
fi

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

# must_fail <label> <expected_leak_substring> <content>
#
# Asserts, and reports separately, which of three things failed:
#   1. exit code is exactly 1 (not merely non-zero)
#   2. output contains <expected_leak_substring>
#   3. output contains exactly one line matching ^LEAK:
must_fail() {
  local label="$1" expected="$2" content="$3" dir output rc
  dir="$(mktemp -d "$TMP/fail.XXXXXX")"
  printf '%s\n' "$content" > "$dir/page.md"

  output="$("$CHECK" "$dir" 2>&1)"
  rc=$?

  local case_fails=0

  if [ "$rc" -ne 1 ]; then
    echo "FAIL: '$label' — exit code was $rc, expected exactly 1" >&2
    case_fails=$((case_fails + 1))
  fi

  if ! printf '%s\n' "$output" | grep -qF -- "$expected"; then
    echo "FAIL: '$label' — output did not contain expected substring: $expected" >&2
    case_fails=$((case_fails + 1))
  fi

  local leak_lines
  leak_lines="$(printf '%s\n' "$output" | grep -c '^LEAK:')"
  if [ "$leak_lines" -ne 1 ]; then
    echo "FAIL: '$label' — expected exactly 1 line matching ^LEAK:, found $leak_lines" >&2
    case_fails=$((case_fails + 1))
  fi

  if [ "$case_fails" -eq 0 ]; then
    echo "PASS (blocked): $label"
  else
    fails=$((fails + 1))
  fi
}

# --- The allow-list. D6 names the institution; if these red, the site cannot build.
must_pass "institution name"   "Built at the Cincinnati & Hamilton County Public Library."
must_pass "CHPL abbreviation"  "At CHPL the zip is distributed to branch staff."
must_pass "branch code"        "Type dc in the Branch Pickup Location column."
must_pass "org and repo names" "See chimpy-me/ils-toolkit and chimpy-me/sierra-ils-utils."
must_pass "reserved barcodes"  "| A000000000001 | dc |"

# --- One positive control per blocked pattern.
must_fail "internal Sierra host"  "sierra-app-rh8"  "ssh to sierra-app-rh8 and restart it"
must_fail "internal subnet"       "10\.110\.10\."   "the box answers on 10.110.10.14"
must_fail "internal db host"      "sqldaia"         "connect to sqldaia for the report"
must_fail "storage appliance"     "qumulo"          "the share lives on qumulo"
must_fail "personal address"      "ray\.voelker"    "written by ray.voelker for the team"
must_fail "internal service host" "plch\.net"       "browse to ils-reports.plch.net/bulk-holds/"
must_fail "internal domain"       "plch\.net"       "any host under plch.net is internal"
must_fail "staff email"           '[a-z0-9._%+-]+@chpl\.org' "email a.librarian@chpl.org for access"
must_fail "real item barcode"     "item-barcode shape found" "| A000000000097 | dc |"
must_fail "other real barcode"    "item-barcode shape found" "the item scanned as A000000000098"
must_fail "Sierra record number"  '\.[bijopv][0-9]{6,7}[0-9xa]' "the item record is .i12345678"

# --- Fail closed: a missing target is an error, never a silent pass.
if "$CHECK" "$TMP/does-not-exist" >/dev/null 2>&1; then
  echo "FAIL: missing directory did not fail closed" >&2
  fails=$((fails + 1))
else
  rc=$?
  if [ "$rc" -ne 2 ]; then
    echo "FAIL: missing directory exit code was $rc, expected exactly 2" >&2
    fails=$((fails + 1))
  else
    echo "PASS: missing directory fails closed"
  fi
fi

if [ "$fails" -ne 0 ]; then
  echo "check-docs-clean self-test FAILED ($fails case(s))" >&2
  exit 1
fi
echo "OK: check-docs-clean self-test passed"
