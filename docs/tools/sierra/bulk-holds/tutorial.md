# Your first Bulk Holds run

By the end of this you will have run Bulk Holds once, on a spreadsheet you
made yourself, and read the report it gives back.

**Nothing you do here places a hold.** Every command on this page stops short
of that, on purpose. You can get every step wrong and the worst that happens
is an error message. That is the whole point of doing it this way first.

Set aside about twenty minutes.

## What you need before you start

- The `bulk-holds` folder, unzipped somewhere in your Documents folder.
- Three items you can physically pick up — off a cart, off a shelf, anything.
  You need to be able to read their barcodes.
- The three Sierra settings you were given. Sierra is the library's catalogue
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

## Step 2 — let the tool ask for its settings

Run the tool for the first time:

```powershell
.\bulk-holds.exe --spreadsheet "x.xlsx" --pickup-location dc
```

It will not run. It will tell you that it has written a settings file, and
name the file's full path. This is expected — it is how the tool asks for its
Sierra settings the first time.

Open the file it named. Fill in the three Sierra values you were given, save
the file, and close it.

That was your first success: you ran the tool, it told you what it needed, and
you gave it. It will not ask again.

## Step 3 — get a spreadsheet to work from

Run the setup command. It places nothing:

```powershell
bulk-holds --init
```

It prints three paths. The one you want is the template:

```
Template:         C:\Users\you\Documents\bulk-holds\template.xlsx
  Open it, type your barcodes, and SAVE AS a new name -- keep this one blank.
```

Open that file. It has two headings and nothing else:

| A | B |
|---|---|
| Barcode | Branch Pickup Location |

Now fetch your three items. In column A, type each item's barcode on its own
row. In column B, type `dc` on all three rows — that is a branch code, and for
now it does not matter which one, because nothing is going to be placed.

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

The save-as matters. `template.xlsx` is the blank you come back to next time,
and this tutorial refers to it by name. If you save your barcodes into it
instead, `--init` will notice and leave your work alone — but you will have a
file called "template" with real barcodes in it, which is a confusing thing to
find in six months.

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
batch this is the line you check hardest — it is the tool telling you what it
thinks you asked for, in time to disagree.

**Whether Sierra found your items:**

```
Items resolved: 3/3
```

Three out of three. Because you picked items you were physically holding, they
are all in the catalogue, so they all resolve.

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

Delete `practice.xlsx` whenever you like. It has served its purpose.
