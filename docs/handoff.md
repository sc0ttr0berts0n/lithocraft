# Handoff: Lithocraft — build the first dive

For a fresh agent picking this up. Updated 25 November 2026 at the end of the second session (on the developer's Windows PC).

## What this project is

A hard-science-fiction 3D Godot game about operating the Lithocraft, a ring-shaped vessel that bores through rock and also flies through air and space. No game code exists yet.

Repository: https://github.com/sc0ttr0berts0n/lithocraft

## Read these first, in this order

Everything decided so far is in the repo or its issues. Do not re-derive it or re-ask it.

1. `GLOSSARY.md` — the vocabulary. Use these terms exactly; each lists words to avoid.
2. `docs/adr/0001-science-ground-rules.md` — three permitted impossible things, real relationships, tuned numbers.
3. `docs/design-record.md` — the full design: every decision with its reason, the developer's own ideas and lore, the real science behind each idea, and the "Not yet designed" list. Wider than the spec.
4. GitHub issue #1, "Spec: First dive" — the spec for the first playable slice. Its 15 sub-issues (#2–#16) are the tickets, labelled `ready-for-agent`, with native blocked-by links.
5. `docs/agents/` and `CLAUDE.md` — issue tracker is GitHub Issues via `gh`, default triage labels, single-context domain docs.

The Habitat prototype is on the `prototype/habitat-down` branch at `prototypes/habitat-down/index.html` (three.js, needs internet). It now includes the arm. It is throwaway, stays off `main`, and is the reference for tickets #3 and #4.

## Where things stand

- Prototype verdict: given. The developer played it and is optimistic; the Habitat stories stand.
- The arm (the developer's idea): a button calls a chain-arm that catches you and carries you between Stations. Confirmed as the way Stations stay reachable at every pitch.
- Decided: one test seam at the simulation's interface; GDScript with GdUnit4 run headless; Fabricator out of the first dive; unattended Stations and a time rate in; Column features observe-only.
- Spec: published as issue #1 and split into tickets #2–#16.
- Implementation: not started. Godot project does not exist yet.

## Next steps

1. Work the frontier: start with #2 (walking skeleton), which blocks everything. After it, #3 and #5 can run in parallel.
2. Build each ticket test-first at the simulation's interface, simulation before view. Close each ticket with a review.
3. Grill the wider design (the "Not yet designed" list) whenever the developer wants to ideate; it does not block the first dive.

## How the developer likes to work

- Grilling in rounds: numbered questions, each with a recommended answer worded so "yes" accepts it. The developer answers by number, usually briefly.
- The developer often adds a new idea alongside an answer (tunnel as fibre optics, atoms as printer ink, Fourier synthesis, "poorly shifting gears", the arm). These are the best material in the design. Fold each into the next round with its real-science grounding, and record it.
- The developer values hard science and wants as few concessions as possible. When an idea needs something impossible, say so plainly and tie it to ADR 0001.
- Be honest about corrections.
- Write resolved terms to the glossary and decisions to the design record as they happen, and commit and push when asked, so nothing lives only in conversation.

## Machine setup on the PC

- `mattpocock-skills` plugin: installed (user scope). The `claude` CLI is at `~/.local/bin/claude.exe` and not on PATH.
- `gh` 2.96: installed and logged in.
- Godot: a 4.3 download sits in Downloads and is not on PATH. Install the current stable Godot 4 and put it on PATH so tests run from the command line.
- Python: use `python`, not `python3` (which opens the Microsoft Store). The prototype branch's `.claude/launch.json` uses `python3`.
- .NET SDKs are 3.1 and 6.0 only, which is fine since the project uses GDScript.

## Suggested skills

- `mattpocock-skills:tdd` — building the simulation test-first at the seam.
- `mattpocock-skills:code-review` — to close out each ticket.
- `mattpocock-skills:grilling` / `mattpocock-skills:domain-modeling` — to continue ideating and keep `GLOSSARY.md` and ADRs current.
- `mattpocock-skills:prototype` — if another design question needs a runnable answer.
