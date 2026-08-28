# Contributing to The ILS Toolkit

## Adding a tool

1. **Pick the folder.** A tool that only makes sense with one integrated library system (ILS) goes
   under `docs/tools/<ils>/<tool>/` — for example `docs/tools/sierra/bulk-holds/`. A tool that is
   not tied to an ILS goes directly under `docs/tools/<tool>/`. There is no `general/` bucket, on
   purpose: it would quietly become the largest folder.
2. **Copy `docs/_template/` into it.** Six files: the five pages plus a deployment page, which you
   rename to `at-<your site>.md`. Renaming it means updating the link that points at it too —
   `index.md`'s "Running it at a particular library?" line hardcodes `at-your-site.md`, and nothing
   else will change it for you. `mkdocs build --strict` catches a missed rename, but only after
   you've burned a cycle finding out why.
3. **Add every page to `nav:` in `mkdocs.yml`.** A page not in the nav is a build failure, and the
   nav order is also the prev/next reading order.
4. **Run the gates before you commit:** `bash scripts/gates.sh`.

## What belongs on each page

The four modes come from [Diátaxis](https://diataxis.fr), and **they are never mixed on one page.**
The template's HTML comments state each mode's cardinal rule; leave them in while you draft.

| Page | Reader posture | Cardinal rule |
|---|---|---|
| Tutorial | Learning | One path that cannot fail. No choices. |
| How-to | Doing | Titled by the reader's goal, not the feature. |
| Reference | Looking up | Describes; never instructs. |
| Explanation | Understanding | No procedures; link to the how-to. |
| At *site* | Living somewhere | One deployment's facts. Nothing else may depend on it. |

## Four house conventions

These are not style preferences. Each one exists because of something that actually happened on
this site's sibling, and leaving them out is how this site and its sibling drift apart.

- **Plain language.** Unpack every acronym and term of art in plain words on first use. Keep jargon
  in code and paths, where it is literal, and out of prose, where it is decoration. Anything a
  reader might not share goes in the [glossary](docs/glossary.md). This rule exists because a page
  written by one team, for a peer reader who shares none of the authors' context, is unreadable
  without it.
- **Citation.** Cite an external source as `live ([archived YYYY-MM-DD](wayback-url))`, with a
  dated snapshot from the Wayback Machine. Pages outlive the links on them, and this convention was
  set after a published factual error traced back to a live link that had quietly changed under an
  unreplaced citation.
- **Provenance.** Any claim about how the ILS behaves carries
  `Tested against: <version> · <environment> · <date>`. A claim without one is a claim nobody can
  check or expire — the stamp exists so a reader can tell whether a described behaviour is still
  true of the version they run.
- **Graduation.** Content earns its own page **only when it is bigger standalone than it is
  inline.** The tell, in both directions: if splitting it out would create a stub shorter than the
  line it replaced, leave it inline. This is what keeps a five-page set from turning into thirty
  fragments — the rule was set after exactly that happened once already.

## The deployment page, and the denylist

Naming the library is deliberate — a real worked example is what makes the generic pages usable by
somebody else. Naming its **infrastructure** is not. `scripts/check-docs-clean.sh` blocks internal
hostnames, internal subnets, personal and staff email addresses, ILS record numbers, and the item
barcode shape; it allows the institution's name, its abbreviation, and branch codes.

Run it, and its self-test, before you commit:

```bash
bash scripts/test-check-docs-clean.sh   # proves the lint can still fail
bash scripts/check-docs-clean.sh        # lints your pages
```

If you add a pattern to the denylist, **add a positive control for it to the self-test in the same
commit.** A pattern nobody proved can fail is not a guard — `scripts/test-check-docs-clean.sh`
already enforces one positive control per denylist pattern, so this is a real requirement, not a
suggestion.

Need a barcode in an example? Use the reserved values `A000000000001`, `A000000000002`,
`A000000000003`. Real ones are blocked by shape, including yours.

## Branches

`main` is what the public site builds from, so it is always releasable. Work on `dev` or a feature
branch and open a pull request; continuous integration (CI) runs the same `scripts/gates.sh` you
ran locally.
