# Bulk Holds at CHPL

Everything on this page is specific to one library — the Cincinnati & Hamilton County Public
Library (CHPL). The [tutorial](tutorial.md), [how-to guides](how-to.md), [reference](reference.md)
and [explanation](explanation.md) are written for any Sierra site and do not depend on anything
here. If you are at another library, read this page as a worked example of what your own
deployment page would say.

## Where to get the tool

There is no self-service download yet. That gap is deliberate rather than an oversight — the
tool's distribution path is being built out in stages, and this page will be updated as each
stage lands rather than rewritten:

- **Today.** `bulk-holds.exe` is handed out as a zip you unpack yourself; there is no download
  link.
- **Next (planned).** Once the tool's source moves into this repository, each release will be
  published here as a versioned GitHub Release — a `bulk-holds-<version>-win-x64.zip` asset you can
  download yourself.
- **Eventually (planned).** The tool will be packaged into CHPL's managed software-distribution
  system (Configuration Manager / Intune), so it arrives on a staff workstation the same way any
  other approved application does.

None of the later stages exist yet. If you don't already have the zip, ask through the channel
below.

## Who to ask for help

The help desk queue, which routes to the ILS (integrated library system) team.

## Pickup location codes

The `Branch Pickup Location` column (or `--pickup-location` on the command line) takes a Sierra
pickup-location code, such as `dc` in the [tutorial](tutorial.md). At CHPL, the authoritative list
of codes is **not** reproduced on this page: it lives in Sierra and is synced into the Bulk Holds
web application's database on startup, so a table copied here would be a second copy that goes
stale the moment a branch code changes there.

To see the current list, CHPL staff can open the Bulk Holds web application's **New Batch** page
and expand the **"View valid pickup location codes"** panel near the top — it shows every code
alongside its full branch name. The CLI checks each code against that same Sierra-backed list
during the dry run, so an unrecognized code is caught before anything is placed (see
[Reference → Exit codes](reference.md#exit-codes), exit `3`).

If you are at another library, the equivalent for your deployment is wherever your own Sierra
pickup-location list is surfaced to staff — this section exists so you know to point at that,
rather than to hand-maintain a table of codes that already lives somewhere authoritative.

## Local conventions

- Runs are kept under your `Documents` folder by default; see
  [Reference → File locations](reference.md#file-locations).
- The tool is distributed as a zip you unpack yourself; there is no installer and no admin
  right required.

*Tested against: Sierra 6.6 · CHPL production · 2026-08-27*
