#!/usr/bin/env bash
# The full gate sequence. CI runs this exact script, so local and CI cannot drift.
#
# Order matters: self-test each guard BEFORE trusting it (spec section 7), lint
# the source, build, then lint and link-check what was actually generated.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== 1/7 self-test the leak-lint =="
bash scripts/test-check-docs-clean.sh

echo "== 2/7 self-test the anchor gate =="
bash scripts/test-check-anchors.sh

echo "== 3/7 leak-lint the docs source =="
bash scripts/check-docs-clean.sh

# Finding C2 (2026-08-27): the docs/-only lint above left README.md,
# CONTRIBUTING.md, mkdocs.yml, .github/, scripts/*, and every other tracked
# file unscanned -- proved by pasting a denylisted host into README.md and a
# staff email into CONTRIBUTING.md and watching "OK: docs clean" anyway. This
# step covers the whole tracked worktree instead.
#
# The guard pair (check-docs-clean.sh, test-check-docs-clean.sh) is excluded
# here, narrowly and by name -- NOT as a blanket "scripts/ is exempt". They
# necessarily contain the literal denylist entries themselves, plus positive
# controls that reproduce each one, so the guard can prove it fires. A
# denylist cannot block a token without writing that token down once, in the
# file that IS the denylist and the file that proves it fires. That is
# categorically different from Finding C1, where the barcode controls in
# test-check-docs-clean.sh leaked REAL transactional data that had no reason
# to be real -- any value matching the barcode SHAPE proves the same thing,
# so C1's fix used synthetic ones instead. The rule this exclusion buys: any
# fixture added to either guard script must be synthetic, or must be one of
# the entries the denylist itself already names -- never a new real,
# otherwise-undisclosed sensitive value. Everything else in the repo,
# including every other file under scripts/ and this file, is scanned like
# any other file. (Do not describe the denylist entries in prose in any
# scanned file, this comment included -- that would trip the guard too;
# see check-docs-clean.sh for what is actually blocked.)
echo "== 4/7 leak-lint the tracked worktree =="
mapfile -t TRACKED_FILES < <(
  git ls-files | grep -vE '^scripts/(check-docs-clean|test-check-docs-clean)\.sh$'
)
bash scripts/check-docs-clean.sh "${TRACKED_FILES[@]}"

echo "== 5/7 build the site (strict) =="
uv run mkdocs build --strict

echo "== 6/7 resolve internal fragment links =="
uv run python scripts/check_anchors.py site

echo "== 7/7 leak-lint the built site =="
bash scripts/check-docs-clean.sh site

echo "ALL GATES PASSED"
