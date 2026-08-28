# Your first Bulk Holds run

By the end of this you will have run Bulk Holds once, on a spreadsheet you
made yourself, and read the report it gives back.

**Nothing you do here places a hold.** Every command on this page stops short
of that, on purpose — the worst that can happen is an error message.

Set aside about twenty minutes.

## What you need before you start

- The `bulk-holds` folder, unzipped somewhere in your Documents folder.
- Three items you can physically pick up — off a cart, off a shelf, anything.
  You need to be able to read their barcodes.
- The three Sierra settings you were given. Sierra is the library's catalog
  system; the tool needs these to talk to it. You will put them in a file in
  step 2.

You do not need to know what PowerShell is. Step 1 shows you.

## Step 1 — open PowerShell in the right folder

Open your `bulk-holds` folder in File Explorer. Hold **Shift**, right-click on
an empty part of the window, and choose **Open PowerShell window here**.

A black or blue window opens with a blinking cursor. This is PowerShell. You
type commands here and press Enter. Nothing you type runs until you press
Enter, so it is safe to type slowly and check your spelling.

Type this and press Enter:

```powershell
.\bulk-holds.exe --version
```

You should see a version number. If you do, the tool is working and you are in
the right folder.

> If you instead see *"is not recognized as the name of a cmdlet"*, PowerShell
> is not in the `bulk-holds` folder. Close the window and redo the Shift +
> right-click, making sure you are inside the folder that contains
> `bulk-holds.exe`.

## Step 2 — set this machine up

Run the setup command. It places nothing, and you will run it twice:

```powershell
.\bulk-holds.exe --init
```

The first time, the tool has no Sierra settings yet. It writes a settings file
for you, prints three paths, and says plainly that it could not check anything:

```
Credentials file: C:\Users\you\AppData\Roaming\CHPL\BulkHolds\config.json
Run folders:      C:\Users\you\Documents\bulk-holds\runs
Template:         C:\Users\you\Documents\bulk-holds\template.xlsx
  Open it, type your barcodes, and SAVE AS a new name -- keep this one blank.

Credentials are not filled in yet, so they were not checked.
Edit C:\Users\you\AppData\Roaming\CHPL\BulkHolds\config.json, then run --init again.
```

Open the file named after **Credentials file**. Fill in the three Sierra values
you were given, then save and close it:

```json
{
  "sierra_api_base_url": "...",
  "sierra_api_key": "...",
  "sierra_api_secret": "..."
}
```

Now run exactly the same command again:

```powershell
.\bulk-holds.exe --init
```

This time it has settings to check, so it asks Sierra who you are:

```
Credentials work.
  Your operator fingerprint: <a short code>
  Claimed account name:      <the name on your API key>
```

The tool can now talk to Sierra — proven before a spreadsheet is anywhere in
the picture. It will not ask again.

> The fingerprint is how your runs are attributed to you — it appears on every
> card this machine creates. Send it to whoever issued your API key. It is
> derived from the key and cannot be turned back into it.

## Step 3 — get a spreadsheet to work from

Step 2 printed a third path, the **Template**. That is the file you fill in
now.

Open it. It has two headings and nothing else:

| A | B |
|---|---|
| Barcode | Branch Pickup Location |

Now fetch your three items. In column A, type each item's barcode on its own
row. In column B, type `dc` on all three rows — that is a branch code, and for
now it does not matter which one.

You should end up with something like this:

| Barcode | Branch Pickup Location |
|---|---|
| A000000000001 | dc |
| A000000000002 | dc |
| A000000000003 | dc |

!!! note "These barcodes are made up"

    `A000000000001` and its neighbours are reserved example values — they are not real
    items anywhere. Use barcodes from your own shelves when you build your practice
    spreadsheet; the point of this step is the shape of the table, not the numbers.

Then **File → Save As** and name it `practice.xlsx`, in the same folder.

The save-as matters: `template.xlsx` is the blank you come back to next time.
If you save barcodes into it instead, `--init` will notice and leave your work
alone — but you will be left with a file named "template" full of real
barcodes.

> The headings matter more than the layout. The tool finds your barcodes by
> looking for a heading with the word *Barcode* in it — so the columns can be
> in any order, and the tab can have any name.

## Step 4 — the dry run

Back in PowerShell, type this. It is one command spread over four lines:

```powershell
.\bulk-holds.exe `
  --spreadsheet "practice.xlsx" `
  --location-column
```

> The backtick ` ` ` at the end of each line is how PowerShell continues one
> command onto the next line. It is the key above Tab, not an apostrophe. If
> you would rather not deal with it, type the whole thing on one line with
> single spaces instead.

Press Enter. The tool reads your spreadsheet, asks Sierra about each of the
three items, and prints a report.

## Step 5 — read what it tells you

You are looking for five things.

**How much it loaded.** Near the top:

```
Loaded 3 barcodes
Loaded 3 per-row locations
```

If it says 3 and 3, your spreadsheet was read correctly.

**Where things would go.** The routing breakdown:

```
Pickup location routing:
  dc: 3
```

All three going to `dc`, because that is what you typed in column B. On a real
batch this is the line you check hardest.

**Whether Sierra found your items:**

```
Items resolved: 3/3
```

Three out of three. Because you picked items you were physically holding, they
are all in the catalog, so they all resolve.

**Which card it will use.**

```
Card: BH-CLI-YOURNAME-2026-08-25T101500-0400 (will be created)
```

This tool never asks for your own library card. Each run mints a disposable
card of its own to hold the batch, and this line names it. "Will be created"
means exactly that — a dry run only reserves the name; nothing exists in
Sierra until you execute.

**Where it saved the plan.** The last few lines name a file called `plan.json`
and then say:

```
DRY RUN - no holds placed. Re-run with --execute --plan <plan.json>.
```

That is the tool confirming it did nothing.

## Step 6 — look at what it left behind

Every run gets its own folder, kept under Documents:

```
Documents\bulk-holds\runs\bulk-holds-2026-08-25T101500-0400\
```

Open the newest one. Inside is the `plan.json` it just mentioned, and two log
files recording everything it said to Sierra and everything Sierra said back.
You will never need to read these yourself — but if a real run ever goes
wrong, this folder is what you send on for help.

## You are done

You have run the tool, given it its settings, fed it a spreadsheet you built,
and read its report. That report is the same report a real batch of four
hundred items produces; there is just more of it.

When you have real work to do, go to the [how-to guides](how-to.md). That is
where `--execute` appears — the step that actually places holds — and where
the second half of the two-step sequence is explained.
