#!/usr/bin/env bash
# Fail if a token that must never be public appears in the docs or the built site.
# Usage: check-docs-clean.sh [PATH ...]   (defaults to docs/; PATH may be a file or a directory)
#
# Adapted from sierra-ils-utils @ 3de20e9. The DENYLIST is DELIBERATELY DIFFERENT:
# that site is fully anonymised, this one names the institution on purpose
# (spec D6), so 'chpl' / 'cincinnatilibrary' are ALLOWED here. What is blocked is
# infrastructure, personal contact details, and live record identifiers.
#
# Counted repetition ({12}) is safe here: scripts get GNU grep. Do not paste these
# patterns into an interactive shell on ray-desktop, which shims grep to ugrep.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  TARGETS=("$ROOT/docs")
fi

# Fail closed: a missing target (file or directory) is an error, not a silent
# pass — otherwise grep's "no such file" (exit 2) reads as "no match", and the
# guard would wrongly report the docs clean.
for target in "${TARGETS[@]}"; do
  if [ ! -e "$target" ]; then
    echo "ERROR: target does not exist: $target" >&2
    exit 2
  fi
done

# Case-insensitive denylist. Extended regex (grep -E).
DENYLIST=(
  'sierra-app-rh8'
  'sqldaia'
  'qumulo'
  'ray\.voelker'
  # Subsumes the specific internal host ils-reports.plch.net that the spec named,
  # plus every other host on the domain — do not re-add the narrower entry, it
  # can never fire independently of this one.
  'plch\.net'
  '10\.110\.10\.'
  '[a-z0-9._%+-]+@chpl\.org'
  '\.[bijopv][0-9]{6,7}[0-9xa]'
)

# Item barcodes are handled separately: the SHAPE is blocked, but three reserved
# documentation values are exempt so tutorials can show a realistic table.
BARCODE_SHAPE='\bA[0-9]{12}\b'
RESERVED_BARCODES='A000000000001|A000000000002|A000000000003'

status=0
for pattern in "${DENYLIST[@]}"; do
  if grep -rniE "$pattern" "${TARGETS[@]}" 2>/dev/null; then
    echo "LEAK: denylist pattern '$pattern' found above" >&2
    status=1
  fi
done

if grep -rnoE "$BARCODE_SHAPE" "${TARGETS[@]}" 2>/dev/null \
     | grep -vE "($RESERVED_BARCODES)" ; then
  echo "LEAK: item-barcode shape found above." >&2
  echo "      Use a reserved documentation barcode instead: $RESERVED_BARCODES" >&2
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "OK: docs clean — no sensitive tokens found"
fi
exit "$status"
