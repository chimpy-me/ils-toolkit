# Why Bulk Holds works this way

Background for anyone who has to support Bulk Holds, or who has been refused
by it and wants to know whether that was correct. Nothing here is a
procedure — see the [how-to guides](how-to.md) for those.

- [Why there are two steps](#why-there-are-two-steps)
- [Why you can be refused after typing "yes"](#why-you-can-be-refused-after-typing-yes)
- [Why identity is checked, not just totals](#why-identity-is-checked-not-just-totals)
- [What the card is doing](#what-the-card-is-doing)
- [Why one card per run](#why-one-card-per-run)
- [Why the hold note matters](#why-the-hold-note-matters)
- [Why runs are kept, and why they expire](#why-runs-are-kept-and-why-they-expire)

---

## Why there are two steps

A bulk hold is easy to place and tedious to undo. Four hundred holds routed to
the wrong branch is not a mistake anyone can quietly fix; it is four hundred
items moving across the system, and staff time at both ends.

The expensive part is not the placing. It is that the operator cannot see what
they are about to do. A spreadsheet of four hundred barcodes looks identical
whether the branch column is right or wrong.

So the tool splits the work in half. The dry run does everything except place
holds — it reads the sheet, resolves every barcode against Sierra, applies the
routing, and prints the result as a per-branch breakdown. That breakdown is
the operator's only real chance to notice that ninety items are going
somewhere they did not intend.

The dry run is free, so there is no reason to skip it. Which is why the tool
does not let you: `--execute` without `--plan` is refused. There is no bypass
flag.

## Why you can be refused after typing "yes"

Two of the checks — the spreadsheet's hash, and Sierra's current answer — run
*after* the confirmation prompt, not before. Being turned down at that moment
feels like a fault. It is the opposite.

The point of the confirmation screen is that **the breakdown you reviewed is
the breakdown that runs**. That promise is only worth something if it is
verified at the last possible instant. A check that runs before the prompt
leaves a window — however short — in which the world can change between the
check and the first hold. Someone re-saves the workbook while the prompt sits
open. A cataloguer fixes a barcode overnight, on a run that was confirmed
before lunch.

Moving the checks after the `yes` closes that window. The cost is that you can
be refused at the last moment; the benefit is that when the tool does proceed,
what it places is what you read.

Nothing is placed when this happens. The remedy is always the same: run the
dry run again, read the new breakdown — it will differ from the old one, and
the difference is the thing you were about to do by accident — and execute
*that* plan.

## Why identity is checked, not just totals

The obvious way to compare a plan against the present is to compare the
numbers: 142 items then, 142 items now, same per-branch counts, proceed.

That check passes on a batch that has genuinely changed. One barcode becomes
resolvable overnight while another stops — perhaps the item was withdrawn.
Both branches keep the same count. Every number the operator reviewed is
intact. It is a different set of items.

So the tool compares the barcodes themselves: which resolved, which fell back
to the default location, which have none. When they differ, the differing
barcodes are printed by name, so the operator can see which rows to look at
rather than being told only that something moved.

The card does not need this treatment, and for a different reason: it is not
looked up at all. Each run mints its own card fresh, under the exact barcode
reserved in the plan, so there is no existing record whose identity could
drift between the dry run and the execute.

## What the card is doing

Every hold has to belong to somebody. In this workflow that somebody is a card
minted for the occasion, not the person who eventually receives the item, and
not a staff member's own card. The tool never asks for one.

The dry run reserves the card's barcode — `BH-CLI-<USER>-<RUN_ID>`, so the
card names its own run folder — and shows it on the confirmation screen as
"will be created." Nothing exists in Sierra yet at that point. Only the
execute step, after every other gate has passed, actually creates the card:
patron type `196`, expiring today plus 60 days. Every hold placed in that run
carries `neededBy` equal to the card's expiry, so the holds fall off Sierra's
books on the same schedule the card does — nobody has to remember to clean
them up separately.

The card is also created with a random PIN, so nobody can log in as it: it is
a container for holds, not an account anyone uses.

This is worth knowing because it explains a class of surprise: holds placed by
this tool are all on one card, so anything that looks at that card sees the
whole batch at once. It also means this tool cannot place a hold on a real
patron's own card, even by accident — there is no argument left that would let
you.

> The Bulk Holds *web app* handles this differently — it creates and manages a
> temporary "container patron" for you, the same idea. The CLI now does too;
> it no longer takes any argument naming a real staff card.

## Why one card per run

Run, card, and batch are the same thing: one dry run reserves one card
barcode, and that barcode is what the matching execute creates and places
every hold in the batch against.

Retrying does not reuse a card. Whatever stops an execute short — a refused
plan, a mint failure, anything else — the remedy is always to dry-run again,
and a fresh dry run reserves a new barcode from a new run folder. The old,
unused reservation is simply abandoned; it was never created in Sierra, so
there is nothing to clean up. Two attempts at the same batch produce two
different cards, never one card reused.

## Why the hold note matters

`--note` writes a tag onto every hold in the batch, defaulting to
`chpl-bulk-hold-script`.

It looks cosmetic. It is how the batch is found again. Once holds are sitting
in Sierra alongside holds from every other source, the note is the only thing
that distinguishes *this run's* holds from the rest. Without it, cancelling or
auditing a batch means reconstructing the item list by hand.

That is why the note is one of the arguments compared against the plan. An
execute whose note differs from its dry run would place holds that are tagged
differently from the ones described in the plan — findable, but not findable
as the batch you thought you were placing.

## Why runs are kept, and why they expire

Each run writes its own folder: the plan, the results, and a complete record
of the conversation with Sierra. It is kept because it is the only durable
account of what happened. When a run goes wrong, that folder is the evidence —
and if the results file could not be written, the log is the sole remaining
record of holds that were genuinely placed. That is also why a failure to
write the results file does not mark the run as failed: by that point the
holds exist, and the exit code has to keep reflecting the holds rather than
the paperwork.

They expire because of what is in them. The folder holds the container card's
barcode, every item record the run touched, and — since Sprint 2 — a copy of
the spreadsheet exactly as it was supplied. The tool reads two columns and
ignores the rest, but the copy keeps all of them, including any the tool never
looked at. That is deliberate: the workbook is the run's input, and a record of
what happened is worth little without it. It does mean the folder can hold more
than the tool ever read. Every run prunes folders older than 90 days, so the
retention does not depend on anyone remembering to clean up.

## Why the card records a fingerprint and not your name

Every card this tool creates carries one line of run details, written into a
Sierra field staff can read:

```
CHPL-BH1 run=2026-08-25T101501-0400 items=142 sha256=<64 hex> tool=1.1.0 key=a3f19c4e77b2 op=RAY
```

`op` is your Windows account name. It is a *claim*: the tool asks the operating
system who you are and writes down the answer. That answer can be wrong, and on
a shared or misconfigured machine it can be `UNKNOWN`.

`key` is the *verified* half. Every operator gets their own Sierra API key, so
holding a working key already proves who you are — Sierra issued the token. The
tool turns that key into twelve characters that can be published, and the
conversion only runs one way: the fingerprint cannot be turned back into the
key. The key itself is written nowhere.

Both are kept, and that is the point. The fingerprint is the trustworthy one,
but the account name is the one a human reads — **and the two disagreeing is
itself worth knowing.** Collapsing them into a single field would throw that
away.

Turning a fingerprint into a person is a lookup someone does by hand, from a
list kept by whoever issues the keys. Deliberately: the tool never learns whose
key it is holding, so there is nothing there to leak. Run `--init` to see your
own fingerprint.

### Why not just ask you to log in

We tried the obvious thing first and measured it. Sierra does have a login
endpoint that works. But since each operator already has their own API key, a
password prompt proves nothing the key has not already proven — while adding a
step to every run and a lockout risk on the same account you need for Sierra
Desktop. So: no login.
