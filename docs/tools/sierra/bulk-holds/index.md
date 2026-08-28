# Bulk Holds — the CLI

This is the Bulk Holds command-line tool, as used at the Cincinnati & Hamilton County Public
Library. The four pages below are written for any Sierra site; **[At CHPL](at-chpl.md)** carries
the details that are specific to one deployment.

Bulk Holds places holds on a list of items, so they can be routed to branches
through the holds system. You give it a spreadsheet; it does the rest.

This is the **CLI** — `bulk-holds.exe`, the one that arrives as a zip folder
you unpack yourself.

## Start here

- **[Tutorial](tutorial.md)** — your first run, about twenty minutes, on a
  spreadsheet you make up yourself. Places no holds. Do it once before
  anything else; the other pages assume you have.
- **[How-to guides](how-to.md)** — recipes for real work: all items to one
  branch, each row to its own branch, and what to do when the tool refuses.
- **[Reference](reference.md)** — every option, exit code, file location, and
  the spreadsheet contract. For looking things up; it does not teach.
- **[Explanation](explanation.md)** — why the tool runs in two steps, why a
  refusal after `yes` is correct, and what the temporary card is for.

## The one thing to know up front

The tool always runs in **two steps**, and you cannot skip the first one.

The first step changes nothing: it reads your spreadsheet, asks Sierra about
every item, and shows you exactly what it *would* do. Only the second step
places holds, and it will only place the holds the first step showed you.
