# Assets: agent guide

How to work in this repo and where to find things. The linked documents are canonical; this file does not repeat them.

## Where to find information

| Need                                                 | Read                                                                                                            |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Layout, categories, referencing, export steps, tools | [`README.md`](README.md)                                                                                        |
| PR checks, commit style, consumers, release          | [`.factory/loop-contract.md`](.factory/loop-contract.md)                                                        |
| Org context, delivery loop, approval boundaries      | `crucibledx/hq` `AGENTS.md` (private, see below)                                                                |
| Org engineering standards                            | `engineering-standards` skill (`crucibledx/factory-loop` `plugins/crucible-loop/skills/engineering-standards/`) |
| Specs                                                | [`specs/`](specs/)                                                                                              |

`crucibledx/hq` is private: agents with a local clone read its `AGENTS.md`; the hosted reviewer can't. Since
factory-loop#57 the reviewer gets the org rules in its prompt from `crucibledx/factory-loop`
`plugins/crucible-loop/skills/engineering-standards/org-rules.md`, so its 404 fetching hq is expected, not a problem.

## How to work

Run `git lfs install` before you clone or commit; GIF, PNG, JPG, WebP and MP4 files are stored in Git LFS.

- Edit sources (`.drawio`, `.tape`) and light variants only. Produce dark SVGs and demo GIFs with the scripts in
  `scripts/`; never export or hand-edit a dark variant.
- Commit the source and every output it produces in the same PR.
- Other repos link these files by raw GitHub URL. Search the org before you rename or move anything (the command is in
  the loop contract).
- Generation scripts work from the main clone or any Git worktree, including checkouts under `.worktrees/` or another
  hidden parent directory. They skip hidden directories inside the checkout, such as `.git/` and `.github/`.
- A change to the factory-loop delivery diagram pairs with a `crucibledx/factory-loop` PR; link the two PRs.

## Boundaries

- Never push to `main`, force push or merge. Nazar's code-owner approval is the merge gate.
- No tags in agent PRs; `v1`, `v2` tags are manual.
