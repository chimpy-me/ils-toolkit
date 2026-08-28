# Bulk Holds at CHPL

Everything on this page is specific to one library — the Cincinnati & Hamilton County Public
Library (CHPL). The [tutorial](tutorial.md), [how-to guides](how-to.md), [reference](reference.md)
and [explanation](explanation.md) are written for any Sierra site and do not depend on anything
here. If you are at another library, read this page as a worked example of what your own
deployment page would say.

## Where to get the tool

There is no self-service download yet. Distribution is being built out in stages:

- **Today.** `bulk-holds.exe` is handed out as a zip you unpack yourself; there is no download
  link. If you don't already have the zip, ask through the channel below.
- **Next (planned).** Once the tool's source moves into this repository, each release will be
  published here as a versioned GitHub Release — a `bulk-holds-<version>-win-x64.zip` asset.
- **Eventually (planned).** Packaged into CHPL's managed software distribution
  (Configuration Manager / Intune), arriving on staff workstations like any other approved
  application.

## Who to ask for help

The help desk queue, which routes to the ILS Team — the people who look after the integrated library system.

## Pickup location codes

The `Branch Pickup Location` column (or `--pickup-location` on the command line) takes a Sierra
pickup-location code, such as `dc` in the [tutorial](tutorial.md). The authoritative list lives
in Sierra, so it is not copied here: CHPL staff can open the Bulk Holds web application's
**New Batch** page and expand the **"View valid pickup location codes"** panel to see every code
alongside its branch name. The CLI checks each code against that same Sierra-backed list during
the dry run, so an unrecognized code is caught before anything is placed (see
[Reference → Exit codes](reference.md#exit-codes), exit `3`).

If you are at another library, point at wherever your own Sierra pickup-location list is
surfaced to staff rather than hand-maintaining a table here.

## Local conventions

- Runs are kept under your `Documents` folder by default; see
  [Reference → File locations](reference.md#file-locations).
- The tool is distributed as a zip you unpack yourself; there is no installer and no admin
  right required.

*Tested against: Sierra 6.6 · CHPL production · 2026-08-27*
