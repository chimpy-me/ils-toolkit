#!/usr/bin/env python3
"""Resolve every internal #fragment link in a built MkDocs site.

Why this exists: `mkdocs build --strict` validates missing FILES and nav
entries, but logs a link to a heading that does not exist at INFO — so the
build exits 0 with the link broken. Found 2026-08-02 on sierra-ils-utils.
See spec section 7.2.

Operates on the GENERATED HTML, never on the markdown source, because the id
a heading actually gets is decided by the toc extension at render time.

Exit codes: 0 all fragments resolve, 1 one or more dangle, 2 site dir missing.
"""

from __future__ import annotations

import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse


class _Page(HTMLParser):
    """Collect every id/name anchor and every href on one page."""

    def __init__(self) -> None:
        super().__init__()
        self.ids: set[str] = set()
        self.hrefs: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = dict(attrs)
        for key in ("id", "name"):
            if a.get(key):
                self.ids.add(a[key])
        if tag == "a" and a.get("href"):
            self.hrefs.append(a["href"])


def main(argv: list[str]) -> int:
    # Resolved once, at entry: rglob then yields absolute paths, so the
    # `parsed` dict keys and the `.resolve()`d cross-page lookups agree.
    # (Keying on the unresolved rglob paths while looking targets up via
    # `.resolve()` means the two never match, and every cross-page fragment
    # gets reported as "target page not in site" even when it is correct.)
    site = Path(argv[1] if len(argv) > 1 else "site").resolve()
    if not site.is_dir():
        print(f"ERROR: site directory does not exist: {site}", file=sys.stderr)
        return 2

    pages = sorted(site.rglob("*.html"))
    if not pages:
        # An empty scan is a failure, not a pass: it is how a gate silently
        # stops testing anything.
        print(f"ERROR: no HTML pages found under {site}", file=sys.stderr)
        return 2

    parsed: dict[Path, _Page] = {}
    for page in pages:
        p = _Page()
        p.feed(page.read_text(encoding="utf-8", errors="replace"))
        parsed[page] = p

    dangling: list[str] = []
    checked = 0
    for page, p in parsed.items():
        for href in p.hrefs:
            url = urlparse(href)
            if url.scheme or url.netloc:
                continue  # external
            # Use urlparse's own separated components rather than hand-rolling
            # a split -- url.path already excludes both the query string and
            # the fragment, so a query string before the fragment (e.g.
            # "../one/?v=2#target") no longer rides along into the path used
            # for resolution.
            target_path = url.path
            frag = unquote(url.fragment)
            if not frag:
                continue
            if target_path:
                if target_path.startswith("/"):
                    # Site-root-relative, not filesystem-absolute: resolve
                    # against the (already-resolved) site root. Path.__truediv__
                    # with an absolute right operand discards the left side
                    # entirely, so naively doing (page.parent / target_path)
                    # would land at the real filesystem root instead of the
                    # site-relative target.
                    resolved = (site / target_path.lstrip("/")).resolve()
                else:
                    resolved = (page.parent / target_path).resolve()
                if resolved.is_dir():
                    resolved = resolved / "index.html"
                target = parsed.get(resolved)
                if target is None:
                    dangling.append(
                        f"{page.relative_to(site)} -> {href} (target page not in site)"
                    )
                    continue
            else:
                target = p  # same-page link
            checked += 1
            if frag not in target.ids:
                dangling.append(f"{page.relative_to(site)} -> {href} (no id={frag!r})")

    for d in dangling:
        print(f"DANGLING ANCHOR: {d}", file=sys.stderr)
    if dangling:
        print(
            f"FAIL: {len(dangling)} dangling fragment link(s) of {checked + len(dangling)} checked",
            file=sys.stderr,
        )
        return 1
    print(f"OK: {checked} internal fragment link(s) all resolve")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
