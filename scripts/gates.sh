#!/usr/bin/env bash
# The full gate sequence. CI runs this exact script, so local and CI cannot drift.
#
# Order matters: self-test each guard BEFORE trusting it (spec section 7), lint
# the source, build, then lint and link-check what was actually generated.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== 1/6 self-test the leak-lint =="
bash scripts/test-check-docs-clean.sh

echo "== 2/6 self-test the anchor gate =="
bash scripts/test-check-anchors.sh

echo "== 3/6 leak-lint the source =="
bash scripts/check-docs-clean.sh

echo "== 4/6 build the site (strict) =="
uv run mkdocs build --strict

echo "== 5/6 resolve internal fragment links =="
uv run python scripts/check_anchors.py site

echo "== 6/6 leak-lint the built site =="
bash scripts/check-docs-clean.sh site

echo "ALL GATES PASSED"
