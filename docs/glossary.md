# Glossary

Terms used across this site. Anything marked **(Sierra)** is specific to the Sierra integrated
library system and may be called something else in another ILS.

**ILS** — integrated library system. The software that holds the catalogue, the item records, the
borrower accounts, and the borrowing itself.

**Sierra** — the ILS sold by Innovative Interfaces, and the one the tools in the `Sierra` section
are built against.

**CLI** — command-line interface. A tool you run by typing commands into a window and pressing
Enter, rather than clicking through a web page or app. Bulk Holds ships as a CLI.

**API** — application programming interface. The way one piece of software asks another to do
something, over the network, without a person clicking through a screen. Sierra's API is what
these tools talk to instead of the staff interface.

**Item** — one physical thing on a shelf, with its own barcode. A title can have many items.

**Item barcode** — the number on the sticker, which identifies one item.

**Hold** — a request that an item be routed to a location and kept for a borrower.

**Pickup location** — where a hold is to be delivered and held.

**Branch code (Sierra)** — the short code a location is known by inside the ILS, such as `dc`.
Branch codes are what the tools ask for, not the branch's full name.

**Plan and execute** — the two-step shape these tools use: the first step reads everything and
shows you what it *would* do without changing anything; the second step does only what the first
step showed.

**Dry run** — the tools' own name for the plan half of plan and execute: it reads the spreadsheet,
asks Sierra about every item, and shows the result, without changing anything. See **Plan and
execute**.

**Container card** — a library card record created only to hold one run's batch of holds, not a
real person's card. Nobody logs in as it, and it belongs to neither the requester nor the operator
running the tool. Some pages call this a *disposable card* or a *container patron*; they all mean
the same thing.

**Patron type (Sierra)** — a numeric code on a Sierra patron record that governs its borrowing
rules, such as how long it lasts and what it may do. The container card these tools create carries
a specific patron type set aside for this purpose.

**Run** — one invocation of a tool, and the folder of artifacts it leaves behind.

**Exit code** — the number a command-line tool returns when it finishes. `0` means success; each
non-zero value means a specific kind of failure, listed on each tool's reference page.

**XCirc (Sierra)** — the part of Sierra's API that handles circulation actions, such as placing a
hold. An error message beginning `XCirc error` is Sierra's circulation logic declining the
request, not a fault in the tool.

**Sierra Desktop (Sierra)** — the staff-facing desktop application for Sierra, as distinct from the
API these tools talk to instead.

**Diátaxis** — the documentation structure this site follows: tutorials, how-to guides, reference,
and explanation, never mixed on one page. See [diataxis.fr](https://diataxis.fr).
