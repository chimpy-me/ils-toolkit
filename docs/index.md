# The ILS Toolkit

Tools that libraries build on top of their **ILS** — the integrated library system, the software
that holds the catalogue, the items, and the borrowing. Each tool here has a full set of
documentation: something to learn from, recipes for real work, facts to look up, and background on
why it works the way it does.

The tools are built and used at the Cincinnati & Hamilton County Public Library, and written up so
another library can pick them up. Where something is true only of one deployment, it lives on its
own page — see [Bulk Holds → At CHPL](tools/sierra/bulk-holds/at-chpl.md) for the pattern.

## Which tool do you need?

**Placing a lot of holds at once, from a spreadsheet** →
[Bulk Holds](tools/sierra/bulk-holds/index.md). A command-line tool for Windows. Sierra only.

## How these pages are organised

Every tool has the same five pages, so you always know where to look:

| Page | What it is for |
|---|---|
| Tutorial | Learning. A first run, start to finish, that cannot break anything. |
| How-to | Doing. Recipes for real jobs. |
| Reference | Looking up. Options, exit codes, file locations, contracts. |
| Explanation | Understanding. Why it works this way. |
| At *your site* | One deployment's specifics: codes, locations, who to ask. |

This is the [Diátaxis](https://diataxis.fr) structure, and the four modes are deliberately never
mixed on one page.

New words are unpacked in the [glossary](glossary.md).

## Related

The [Sierra REST API field guide](https://chimpy-me.github.io/sierra-ils-utils/) is the sibling to
this site: that one documents the API these tools are built on, this one documents the tools.
