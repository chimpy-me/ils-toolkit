#!/usr/bin/env bash
# Self-test for check_anchors.py, on a hand-built fixture site.
#
# The fixture is hand-written HTML rather than a real mkdocs build: it keeps the
# test fast and deterministic, and the thing under test is link RESOLUTION, not
# slug generation. The live positive case is the real cross-page fragment link
# in the Bulk Holds explanation page (Task 5).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="uv run python $SCRIPT_DIR/check_anchors.py"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

build_fixture() {
  # $1 = site dir, $2 = the fragment page-two links to
  local site="$1" frag="$2"
  mkdir -p "$site/one" "$site/two"
  cat > "$site/one/index.html" <<HTML
<html><body>
<h2 id="why-you-can-be-refused">Why you can be refused</h2>
<a href="#why-you-can-be-refused">self link</a>
</body></html>
HTML
  cat > "$site/two/index.html" <<HTML
<html><body>
<a href="../one/${frag}">cross-page link</a>
<a href="https://example.org/page/#not-ours">external, must be ignored</a>
<a href="#">bare hash, must be ignored</a>
</body></html>
HTML
}

# Case 1: every fragment resolves -> exit 0
GOOD="$TMP/good"
build_fixture "$GOOD" "#why-you-can-be-refused"
if $CHECK "$GOOD" >/dev/null 2>&1; then
  echo "PASS: resolving fragments accepted"
else
  echo "FAIL: a site with only good fragments was rejected" >&2
  fails=$((fails + 1))
fi

# Case 2: a seeded dangling fragment -> non-zero. THIS is the case that proves
# the gate can fail; mkdocs --strict is green on exactly this input.
BAD="$TMP/bad"
build_fixture "$BAD" "#heading-that-does-not-exist"
if $CHECK "$BAD" >/dev/null 2>&1; then
  echo "FAIL: dangling fragment was NOT caught" >&2
  fails=$((fails + 1))
else
  echo "PASS: dangling fragment correctly flagged"
fi

# Case 3: missing site directory must fail closed.
if $CHECK "$TMP/no-such-site" >/dev/null 2>&1; then
  echo "FAIL: missing site directory did not fail closed" >&2
  fails=$((fails + 1))
else
  echo "PASS: missing site directory fails closed"
fi

# Case 4: the SAME good fixture as Case 1, but invoked with a RELATIVE site
# path (cd into its parent, pass a bare dirname) instead of Case 1's absolute
# one. This is the shape gates.sh/CI actually uses (the default site arg is
# the relative "site"). A subshell keeps this from disturbing later cases'
# cwd. $CHECK embeds $SCRIPT_DIR, which is already absolute, so it survives
# the cd; `uv run` still finds an interpreter to run the stdlib-only script
# with from outside any project tree, so no --project override is needed --
# the site argument, not uv's project resolution, is the thing under test.
if ( cd "$TMP" && $CHECK good >/dev/null 2>&1 ); then
  echo "PASS: relative site path resolves the same as absolute"
else
  echo "FAIL: relative site path was rejected (absolute-only bug)" >&2
  fails=$((fails + 1))
fi

if [ "$fails" -ne 0 ]; then
  echo "check_anchors self-test FAILED ($fails case(s))" >&2
  exit 1
fi
echo "OK: check_anchors self-test passed"
