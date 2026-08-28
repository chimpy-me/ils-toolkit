# Bulk Holds — the CLI

This is the Bulk Holds command-line tool, as used at the Cincinnati & Hamilton County Public
Library. The four pages below are written for any Sierra site; **[At CHPL](at-chpl.md)** carries
the details that are specific to one deployment.

Bulk Holds places holds on a list of items, so they can be routed to branches
through the holds system. You give it a spreadsheet; it does the rest.

This is the **CLI** — `bulk-holds.exe`, the one that arrives as a zip folder
you unpack yourself.

## Start here

**Never used it before?** → **[Tutorial](tutorial.md)**

Twenty minutes, on a spreadsheet you make up yourself. It places no holds at
all, so nothing you do can go wrong. Read this one first even if you are in a
hurry — the rest of these pages assume you have done it once.

**Done that, and now you have real work?** → **[How-to guides](how-to.md)**

Step-by-step recipes for the actual jobs: all items to one branch, each row to
its own branch, and what to do when the tool refuses to run.

**Need a specific fact?** → **[Reference](reference.md)**

Every command-line option, every exit code, where the settings file lives,
where runs get saved, and what the spreadsheet has to contain. Look things up
here; it does not teach.

**Want to know why it works this way?** → **[Explanation](explanation.md)**

Why the tool makes you run it twice, why being turned down after you type
`yes` is the tool working correctly, and what that temporary library card is
doing.

## The one thing to know up front

The tool always runs in **two steps**, and you cannot skip the first one.

The first step changes nothing. It reads your spreadsheet, asks Sierra about
every item, and shows you exactly what it *would* do. Only the second step
places holds, and it will only place the holds the first step showed you.

If you remember nothing else, remember that the first step is free.
