# Bulk Holds how-to guides

Recipes for real work. Each one assumes you have already worked through the
[tutorial](tutorial.md) and have your Sierra settings filled in.

All commands are typed in PowerShell, opened inside your `bulk-holds` folder
(Shift + right-click in the folder → **Open PowerShell window here**).

- [Send every item to the same branch](#send-every-item-to-the-same-branch)
- [Send each row to its own branch](#send-each-row-to-its-own-branch)
- [When the tool refuses to execute](#when-the-tool-refuses-to-execute)
- [When some holds fail](#when-some-holds-fail)
- [Save runs somewhere other than Documents](#save-runs-somewhere-other-than-documents)
- [Send a run for help](#send-a-run-for-help)

---

## Send every item to the same branch

Your spreadsheet needs one column whose heading contains the word **Barcode**.
No location column is needed.

**Step 1 — dry run.** Places nothing.

```powershell
.\bulk-holds.exe `
  --spreadsheet "C:\Users\you\Documents\cHQ Transfers.xlsx" `
  --pickup-location dc
```

This run does not use your own library card. It reserves a disposable card of
its own for the batch and names it on the confirmation screen as
`Card: BH-CLI-... (will be created)` — nothing exists in Sierra yet.

**Step 2 — read the breakdown.** Check three things before going further:

- `Items resolved: X/N` — if X is less than N, the barcodes Sierra could not
  find are named on `WARNING:` lines. Those items will not get holds. Decide
  whether that is acceptable before you continue.
- The per-branch count matches the size of the batch you meant to send.
- No warnings you were not expecting.

The dry run names a `plan.json` file. Copy that path.

**Step 3 — execute.** Same command, plus `--execute` and the plan:

```powershell
.\bulk-holds.exe `
  --spreadsheet "C:\Users\you\Documents\cHQ Transfers.xlsx" `
  --pickup-location dc `
  --execute `
  --plan "C:\Users\you\Documents\bulk-holds\runs\bulk-holds-...\plan.json"
```

Only now does the card named in the dry run actually get created in Sierra,
and only after every other check passes.

It re-prints the breakdown and waits. Type `yes` and press Enter. Anything
else places nothing.

---

## Send each row to its own branch

Add a column headed **Branch Pickup Location**, holding one branch code per
row. Column order does not matter.

Swap `--pickup-location dc` for `--location-column` in both steps:

```powershell
.\bulk-holds.exe `
  --spreadsheet "C:\Users\you\Documents\cHQ Transfers.xlsx" `
  --location-column
```

Then execute exactly as above, adding `--execute` and `--plan`. As with the
single-branch recipe, this run reserves its own disposable card and names it
on the confirmation screen; the card is not created until the execute step
succeeds.

**Rows with a blank location.** If you also pass `--pickup-location`, blank
rows fall back to that code, and the dry run warns you how many did. If you do
not pass it, blank rows get no hold at all — and the dry run warns you about
that too. Read those warnings; they are the difference between items going
somewhere unintended and going nowhere.

**If a branch count looks wrong,** the usual cause is stray whitespace or a
formatting difference in a barcode cell, which stops that row matching what
Sierra returned.

---

## When the tool refuses to execute

Being refused is normal, and it means nothing was placed. Find your message
below.

**"the spreadsheet no longer matches the plan"**

The workbook was edited or re-saved after the dry run — even just opening and
saving it counts. Run the dry run again and execute *that* plan.

**"plan 138, now 142"** (or any plan-versus-now comparison)

Sierra's answer changed between your dry run and your execute: a barcode
corrected overnight, an item added, deleted, or re-catalogued. The tool prints
the counts branch by branch, and names the barcodes that differ. Run the dry
run again, read the new breakdown, and execute that one.

**An argument differs from the plan**

`--pickup-location`, `--location-column`, and `--note` must all match the dry
run that produced the plan. Compare the two commands character by character,
or just re-run the dry run with the arguments you actually want.

**"Sierra refused to create the container card"**

Every other check passed, but the run's disposable card itself could not be
created. This is exit `8`, and it has three forms, depending on where the
attempt failed:

- `Sierra refused to create the container card <barcode>` — Sierra rejected
  the request outright, usually a permissions problem or a Sierra outage. No
  card was created.
- `Could not reach Sierra to create the container card` — the request never
  got an answer (network, DNS, timeout). No card was created.
- `Sierra accepted the card but returned no usable record id` — Sierra
  answered success, but the tool could not read back the card's record id.
  Unlike the other two, a card may already exist in Sierra under this run's
  barcode.

No holds are placed on any of these three. Whichever message you see, re-run
the dry run and execute again. A retry always mints a fresh card under a new
barcode — it never reuses or reaches back for the one from the failed
attempt.

**"stdin is not a terminal"**

The tool was run from a scheduled task, a script, or with input piped into it.
It will not place holds unattended. Run it by hand in PowerShell.

**It refused *after* I typed `yes`**

That is deliberate, and it is the tool working correctly — see
[why refusal after "yes" is correct](explanation.md#why-you-can-be-refused-after-typing-yes).
Nothing was placed.

---

## When some holds fail

The run finishes but reports rejected holds. Open `results.csv` in the run
folder; it has one row per item with the reason in the `error_type` column.

**`This record is not available`** — the item is not holdable right now. This
is Sierra declining, not the tool failing. Nothing to fix in your spreadsheet.

**`no_pickup_location`** — the row had no branch code and no fallback, so no
hold was attempted. Add a code and re-run those rows.

To retry, build a fresh spreadsheet from just the failed rows and run the
two-step sequence again on it.

---

## Save runs somewhere other than Documents

On a managed desktop, `Documents` is often redirected into OneDrive. If that
folder is offline, full, or locked, the run stops and names the path it could
not write.

Point it somewhere local instead, on both steps:

```powershell
.\bulk-holds.exe `
  --spreadsheet "C:\Users\you\Documents\cHQ Transfers.xlsx" `
  --location-column `
  --log-dir "C:\bulk-holds-runs"
```

---

## Send a run for help

Find the run's folder under `Documents\bulk-holds\runs\` — the folder name
ends in the date and time the run started. Right-click it, choose **Send to →
Compressed (zipped) folder**, and pass the zip on.

**That folder contains a copy of your spreadsheet, exactly as you supplied it.**
The tool reads two columns and ignores the rest — but the copy keeps every
column, including any the tool never looked at: requester names, staff notes,
phone numbers, whatever your workbook happened to carry. It also contains the
container card's barcode and every item record the run touched.

Look at what is in the folder before you send it. If the spreadsheet has
columns that should not leave the building, delete the copy from the run folder
first — the tool does not need it after the run.

Run folders are deleted automatically after 90 days.
