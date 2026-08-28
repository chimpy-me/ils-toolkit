# Bulk Holds reference

Facts about the Bulk Holds CLI (`bulk-holds.exe`, and its source form
`scripts/bulk_holds.py`). This page describes; it does not instruct. For
procedures see the [how-to guides](how-to.md).

Everything here was checked against `scripts/bulk_holds.py`, `scripts/bh_excel.py`,
and `scripts/bh_paths.py`.

- [Command-line options](#command-line-options)
- [Exit codes](#exit-codes)
- [Spreadsheet contract](#spreadsheet-contract)
- [Credentials](#credentials)
- [File locations](#file-locations)
- [Plan validation](#plan-validation)
- [Results](#results)
- [Running from source](#running-from-source)

---

## Command-line options

| Option | Meaning |
|---|---|
| `--init` | Set this machine up: credential template, runs folder, template spreadsheet, credential check. Places nothing. Safe to run again — see [The template workbook](#the-template-workbook). `--spreadsheet` is not required with it. |
| `--spreadsheet PATH` | `.xlsx` workbook containing a barcode column. **Required unless `--init`.** |
| `--pickup-location CODE` | Sierra pickup location code. Applies to every hold, or acts as the fallback when `--location-column` is set. |
| `--location-column [NAME]` | Read each row's location from column `NAME`. Bare flag defaults to `Branch Pickup Location`. |
| `--config PATH` | Sierra credentials JSON. Overrides the profile config. |
| `--note TEXT` | Hold note tag. Default `chpl-bulk-hold-script`. Must match the plan on an execute — it is how the batch is found again later. |
| `--output PATH` | CSV output path. Default: `results.csv` in the run folder. |
| `--log-dir DIR` | Artifacts root override. Default: the profile artifacts root. |
| `--plan PATH` | Plan file from a matching dry run. **Required with `--execute`.** |
| `--retention-days N` | Prune run folders older than N days. Default `90`. |
| `--execute` | Place holds. Requires `--plan` and a typed `yes`. |
| `--version` | Print the tool version and exit. |

At least one of `--pickup-location` / `--location-column` must be given.

---

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Success — a dry run completed, or every hold was placed. |
| `2` | Usage error: bad or missing arguments. |
| `3` | Input or validation failure. Covers an unreadable spreadsheet, a missing barcode or location column, more than 2000 barcodes, an unknown pickup location code, and a run folder that cannot be written. Returned on **either** step: a dry run writes no plan, an execute stops before the first hold. Nothing is placed either way. |
| `4` | Plan missing, mismatched, unconfirmed, or standard input is not interactive. Includes a plan whose routing no longer matches Sierra's current answer. No holds placed. |
| `5` | Sierra credentials absent, or present but rejected. See [Credentials](#credentials) for why these two are caught at different moments. Nothing is placed either way. |
| `6` | Execute completed, but some holds were rejected. See `results.csv`. |
| `7` | First run: a credential template was written. Fill it in and run again. |
| `8` | The run's disposable card could not be created, **or was created but could not be stamped with this run's details** — Sierra was unreachable or refused the request. Returned only on an execute, only after every other gate has passed. No holds placed. If the card was created, it is empty, cannot be logged in to, and lapses on its own — there is nothing to clean up. A re-run mints a fresh card under a new barcode. |

---

## Spreadsheet contract

**Worksheet.** `Sheet1` if the workbook contains it; otherwise the first
worksheet.

**Barcode column.** Located by scanning the header row. Column position is
irrelevant. Values are whitespace-stripped on load.

**Location column.** Used only with `--location-column`. Located by header
name; defaults to `Branch Pickup Location`. One Sierra pickup-location code
per row (`lv`, `sh`, `mo`, …).

### How columns are matched

Both headings are compared after normalizing: lowercased, with everything that
is not a letter or a digit removed. So `Barcode`, `BARCODE`, `Bar Code`,
`bar_code` and `Bar-Code` are all the same heading.

- **Barcode column** — matched as a *substring*. Any heading containing
  `barcode` after normalizing is accepted: `Barcode`, `Item Barcode`,
  `barcodes`. The first matching column wins.
- **Pickup location column** — matched by *equality*, against whatever
  `--location-column` names (default `Branch Pickup Location`). It is not a
  substring test: you named this column, so the tool binds that column or none.

The dry run prints which headings it bound:

```
Columns:  barcode <- "Item Barcode"   pickup location <- "Pick Location"
```

**When more than one heading matches, the dry run says so.** A sheet carrying
both a patron and an item barcode column — an ordinary export shape — has two
candidates; the leftmost is bound, and every match is named:

```
Columns:  barcode <- "Patron Barcode"
WARNING: 2 columns match "barcode": 'Patron Barcode', 'Item Barcode'. Bound 'Patron Barcode', the leftmost.
  If that is the wrong column, rename or remove the other one and run the dry run again.
```

The warning does not stop the run: `Barcode` alongside `Barcode Notes` is a
legitimate sheet on which the leftmost bind is the right one.

If a column is not found, the error names the headings your sheet actually has.

**Ceiling: 2000 barcodes per sheet.** Item lookup is a single Sierra query with
a hard limit of 2000 and no paging. A sheet over the limit is refused outright
(exit `3`) rather than run short; split into batches of 2000 or fewer.

**Location validation.** Every pickup-location code in play is checked against
Sierra's own list during the dry run. An unknown code fails the dry run, writes
no plan, and therefore cannot be executed.

---

## Credentials

On first run the tool writes a credential template into the user profile and
exits `7`, naming the path:

| Platform | Path |
|---|---|
| Windows | `%APPDATA%\CHPL\BulkHolds\config.json` |
| Linux / macOS | `~/.config/chpl/bulk-holds/config.json` |

Required keys: `sierra_api_base_url`, `sierra_api_key`, `sierra_api_secret`.
Optional: `verify_ssl`.

**Resolution order:** `--config` → profile config → the environment variables
`SIERRA_API_URL`, `SIERRA_API_KEY`, `SIERRA_API_SECRET`.

**Absent versus rejected credentials are caught at different moments.** Absent
— nothing in the config, `--config`, or the environment — is detected *before*
the confirmation prompt, so an unusable config never gets as far as asking you
to type `yes`. Rejected — an expired or revoked key, the wrong secret, the
wrong server — is only discovered when the first request goes out, which is
*after* you type `yes`. Both exit `5`; neither places anything.

**Test server caveat.** A Sierra test server is typically a periodic snapshot
of production. An item that exists on production may not resolve on test.
Full item validation only happens in a production dry run.

---

## File locations

Each run gets its own folder under the artifacts root in the user profile —
**not** the working directory:

| Platform | Artifacts root |
|---|---|
| Windows | `%USERPROFILE%\Documents\bulk-holds\runs\` |
| Linux / macOS | `~/bulk-holds/runs/` |

Run folders are named `bulk-holds-<timestamp>`. Each contains:

| File | Written by | Contents |
|---|---|---|
| `plan.json` | dry runs | what the run intended to do |
| `results.csv` | executes | one row per item, with any error |
| `*-log.jsonl`, `*-log.txt` | both | the full request-and-response record |

`--log-dir` overrides the root. On a managed Windows desktop `Documents` is
frequently redirected into OneDrive; if that folder is offline, full, or
locked, the run stops with exit `3` and names the path.

**Retention.** Run folders older than `--retention-days` (default 90) are
pruned at the start of each run. The current run's folder is never pruned.

### The template workbook

`--init` writes a blank spreadsheet alongside the runs folder, one level up:

| Platform | Template |
|---|---|
| Windows | `%USERPROFILE%\Documents\bulk-holds\template.xlsx` |
| Linux / macOS | `~/bulk-holds/template.xlsx` |

Re-running `--init` is safe. What it does is decided by the file's **contents**,
not by whether it exists:

| State | Behaviour |
|---|---|
| No `template.xlsx` | Written under exactly that name |
| Present, and still the blank this tool wrote | Rewritten in place |
| Present, and modified in any way | **Never touched.** The fresh copy is written as `template-<timestamp>.xlsx`, and `--init` prints its name |

"Modified" is judged strictly, and errs towards leaving the file alone: a second
worksheet, a renamed sheet, an added or reworded heading, a value anywhere below
the header row, or a workbook that will not open at all — each counts as yours.

---

## Plan validation

An execute re-derives everything and compares it against the plan. Any
mismatch stops the run with exit `4` and places nothing.

Checked:

- the spreadsheet's hash — an edited or re-saved workbook is refused
- the total item count
- every per-branch count
- the barcode sets themselves: which came back unresolved, which fell back to
  `--pickup-location`, and which have no pickup location
- `--pickup-location`, `--location-column`, `--note`
- the plan file's presence, readability, and version compatibility
- that standard input is a terminal

The card itself is not re-checked against Sierra, because there is nothing to
look up: the plan's reserved barcode — the string named on the confirmation
screen — is the exact barcode the execute step creates the card under.

Barcode sets are compared as well as totals — see
[Explanation → why identity is checked](explanation.md#why-identity-is-checked-not-just-totals).

The spreadsheet-hash and Sierra-routing checks run **after** the typed `yes` —
see [Explanation → why you can be refused after typing "yes"](explanation.md#why-you-can-be-refused-after-typing-yes).

---

## Results

**Success.** Sierra returns `204 No Content` (also `200` / `201`). All three
count as placed.

**Common rejection.** `XCirc error: This record is not available` (code 132) —
the item is not holdable at that moment. Recorded in the CSV with its
`error_type`. Not a tool fault.

**`error_type=no_pickup_location`.** The row had no location and no fallback.
Not placed.

**If `results.csv` cannot be written** — a redirected `Documents` folder again
— the run says so and names the path, but does **not** report itself as
failed. The holds were already placed by then, so the exit code goes on
reflecting the holds. The request-and-response log in the run folder is the
recoverable record of the batch.

---

## Running from source

The frozen `bulk-holds.exe` and `scripts/bulk_holds.py` are the same program.
Developers and operators on Linux run the source form from
`services/bulk-holds`:

```bash
uv run python scripts/bulk_holds.py \
  --spreadsheet "/path/to/batch.xlsx" \
  --location-column
```

Every option, exit code, and gate on this page applies identically.

For production, put the key and secret in the profile config (`chmod 600`) or
keep a separate file and pass `--config`:

```json
{
  "sierra_api_base_url": "https://<your-sierra-host>/iii/sierra-api/v6/",
  "sierra_api_key": "<PROD_KEY>",
  "sierra_api_secret": "<PROD_SECRET>",
  "verify_ssl": false
}
```

`verify_ssl` defaults to `false`; a deployment whose Sierra server presents a
valid certificate should set it to `true`.

**A test-server dry run checks parsing, not the batch.** Running the dry run
against test first confirms the sheet parses and the per-row location map
loads — expect `Loaded N barcodes` and `Loaded N per-row locations`. It does
not validate the batch: because test is a periodic snapshot, items may be
missing or return stale data. Only a production dry run validates what will
actually be placed, and only a production plan can be executed against
production.
