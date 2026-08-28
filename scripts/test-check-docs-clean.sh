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
#
# That review found the gap by eye. It won't be found by eye next time: the
# block below mechanically parses DENYLIST out of check-docs-clean.sh (never
# a second copy of the list) and cross-checks it against the expected-leak
# values the must_fail cases below actually register, in both directions —
# a pattern with no control, and a control that names a pattern no longer in
# the denylist. See check_denylist_coverage() near the bottom.
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

# Populated by must_fail (kind="denylist", the default) with the exact
# <expected_leak_substring> each control was given. This is the SAME string
# already passed to must_fail below -- registering it here is not a second
# copy of any pattern, just a second use of the one the call site already
# has. check_denylist_coverage() compares this set against DENYLIST, parsed
# fresh out of check-docs-clean.sh, so the two can never silently drift.
DENYLIST_CONTROLS=()

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

# must_fail <label> <expected_leak_substring> <content> [kind]
#
# Asserts, and reports separately, which of three things failed:
#   1. exit code is exactly 1 (not merely non-zero)
#   2. output contains <expected_leak_substring>
#   3. output contains exactly one line matching ^LEAK:
#
# [kind] defaults to "denylist": <expected_leak_substring> is registered into
# DENYLIST_CONTROLS as a control for that DENYLIST entry in check-docs-clean.sh.
# Pass kind="other" for a case that exercises a different mechanism (the
# barcode-SHAPE check is separate from DENYLIST) so it is excluded from that
# cross-check instead of showing up as an orphaned control.
must_fail() {
  local label="$1" expected="$2" content="$3" kind="${4:-denylist}" dir output rc
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

  if [ "$kind" = "denylist" ]; then
    DENYLIST_CONTROLS+=("$expected")
  fi
}

# check_denylist_coverage: parses the DENYLIST array out of check-docs-clean.sh
# (READ only -- never duplicated here) and fails, naming names, if:
#   - a DENYLIST pattern has no control in DENYLIST_CONTROLS (dead pattern), or
#   - a control names a pattern no longer in DENYLIST (orphaned control -- this
#     is exactly how 'ils-reports\.plch\.net' survived subsumed and untested).
check_denylist_coverage() {
  local pattern control found
  local -a actual_denylist dead orphaned

  mapfile -t actual_denylist < <(
    awk '/^DENYLIST=\(/{flag=1; next} flag && /^\)/{exit} flag' "$CHECK" \
      | grep -v '^[[:space:]]*#' \
      | sed -n "s/^[[:space:]]*'\(.*\)'[[:space:]]*\$/\1/p"
  )

  if [ "${#actual_denylist[@]}" -eq 0 ]; then
    echo "FAIL: could not parse any DENYLIST entries out of $CHECK" >&2
    fails=$((fails + 1))
    return
  fi

  dead=()
  for pattern in "${actual_denylist[@]}"; do
    found=0
    for control in "${DENYLIST_CONTROLS[@]}"; do
      if [ "$control" = "$pattern" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      dead+=("$pattern")
    fi
  done

  orphaned=()
  for control in "${DENYLIST_CONTROLS[@]}"; do
    found=0
    for pattern in "${actual_denylist[@]}"; do
      if [ "$control" = "$pattern" ]; then
        found=1
        break
      fi
    done
    if [ "$found" -eq 0 ]; then
      orphaned+=("$control")
    fi
  done

  if [ "${#dead[@]}" -eq 0 ] && [ "${#orphaned[@]}" -eq 0 ]; then
    echo "PASS: all ${#actual_denylist[@]} DENYLIST pattern(s) have a positive control, and every control names a live pattern"
    return
  fi

  for pattern in "${dead[@]}"; do
    echo "FAIL: DENYLIST pattern has no positive control: $pattern" >&2
  done
  for control in "${orphaned[@]}"; do
    echo "FAIL: control names a pattern no longer in DENYLIST: $control" >&2
  done
  fails=$((fails + 1))
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
must_fail "real item barcode"     "item-barcode shape found" "| A000000000097 | dc |" other
must_fail "other real barcode"    "item-barcode shape found" "the item scanned as A000000000098" other
must_fail "Sierra record number"  '\.[bijopv][0-9]{6,7}[0-9xa]' "the item record is .i12345678"

# --- Meta-check: DENYLIST <-> control coverage, mechanically, both directions.
check_denylist_coverage

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
