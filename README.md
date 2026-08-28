# The ILS Toolkit

Documentation for tools that libraries build on top of their ILS — the integrated library system.
The rendered site is at **<https://chimpy-me.github.io/ils-toolkit/>**.

This repository holds the documentation. Each tool has the same five pages — tutorial, how-to,
reference, explanation, and one page for a single library's specifics — following
[Diátaxis](https://diataxis.fr).

## Working on it

```bash
uv sync --extra docs
uv run mkdocs serve          # live preview at http://127.0.0.1:8000
bash scripts/gates.sh        # everything CI runs
```

`scripts/gates.sh` self-tests both guards, lints the source for tokens that must not be public,
builds strictly, resolves every internal link fragment against the generated HTML, and lints the
built site. CI runs that same script.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — how to add a tool, what belongs on each page, and the four
house conventions.

## Related

- [The Sierra REST API field guide](https://chimpy-me.github.io/sierra-ils-utils/) — the API these
  tools are built on.

## Licence

This documentation and the tooling in this repository are licensed under the MIT Licence — see
[LICENSE](LICENSE). Copyright is held by Ray Voelker.
