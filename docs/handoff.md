# Handoff: Lithocraft — continue ideating, then build the first dive

For a fresh agent picking this up on a different machine. The previous session ran on a Mac; the developer is moving to a PC.

## What this project is

A hard-science-fiction 3D Godot game about operating the Lithocraft, a ring-shaped vessel that bores through rock and also flies through air and space. No game code exists yet. One design session has been completed.

Repository: https://github.com/sc0ttr0berts0n/lithocraft

## Read these first, in this order

Everything decided so far is in the repo. Do not re-derive it or re-ask it.

1. `GLOSSARY.md` — the vocabulary. Use these terms exactly; each lists words to avoid.
2. `docs/adr/0001-science-ground-rules.md` — three permitted impossible things, real relationships, tuned numbers.
3. `docs/design-record.md` — the full design: every decision with its reason, the developer's own ideas and lore, the real science behind each idea, and the "Not yet designed" list. This is wider than the spec.
4. `.scratch/first-dive/spec.md` — the spec for the first playable slice, marked `ready-for-agent`.
5. `docs/agents/` and `CLAUDE.md` — issue tracker is local markdown under `.scratch/`, default triage labels, single-context domain docs.

The Habitat prototype is on the `prototype/habitat-down` branch at `prototypes/habitat-down/index.html` (three.js, opens by double-click, needs internet). It is throwaway and stays off `main`. That branch was cut before the design record was written, so read the docs on `main`.

## Where things stand

- Grilling on the vessel and underground traversal: complete, confirmed by the developer.
- Spec for the first dive: written, not yet split into tickets.
- Implementation: not started.
- Godot project: does not exist yet.

## Open items, in the order they block work

1. **Prototype verdict.** The developer could not play it comfortably on the Mac and will try on the PC. Ask for the verdict on whether the changing "down" feels right. If it is no, the Habitat stories in the spec need revisiting before they are built.
2. **Test seam, unconfirmed.** The spec proposes a single seam at the simulation's interface. The developer was asked and has not answered.
3. **Three scope choices in the spec that the agent made, unconfirmed.** Fabricator left out of the first dive; basic unattended-Station behaviour and a time-rate control included; Column features observe-only. Listed in the spec's Further Notes.
4. **Keeping Stations reachable when the vessel is level.** The prototype showed most Stations are unreachable. The spec requires a fix and leaves the method open. Candidates are in the design record.
5. **Language and test tooling.** GDScript or C#, and a test runner that can run the simulation without opening a scene. Not chosen.
6. **Wider design not yet done.** See "Not yet designed" in the design record: flight in air, space and gas giants; spin gravity (the prototype showed it is weak and uneven at this size); dimensions; warp; ports and buyers; art style; pressure as an active mechanic.

## How the developer likes to work

- Grilling in rounds worked well: numbered questions, each with a recommended answer worded so "yes" accepts it. The developer answers by number, usually briefly.
- The developer often adds a new idea alongside an answer (tunnel as fibre optics, atoms as printer ink, Fourier synthesis, "poorly shifting gears"). These are the best material in the design. Fold each into the next round with its real-science grounding, and record it.
- The developer values hard science and wants as few concessions as possible. When an idea needs something impossible, say so plainly and tie it to ADR 0001.
- Be honest about corrections. An earlier claim (that coring saves energy) was wrong and was corrected openly; that went well.
- The developer was anxious about losing this session's context. Write resolved terms to the glossary and decisions to the design record as they happen, and commit and push when asked, so nothing lives only in conversation.

## Suggested next steps

1. Get the prototype verdict and the answers to open items 2–5.
2. Amend the spec if any answer changes it.
3. Split the spec into tickets.
4. Create the Godot project and build ticket by ticket, test-first, simulation before view.
5. Grill the wider design (open item 6) whenever the developer wants to ideate; it does not block the first dive.

## Machine setup on the PC

- Clone the repository.
- Install the skills plugin again; it is installed per machine: `claude plugin install mattpocock-skills@claude-plugins-official`. Do not re-run the setup skill: its output is already in the repo.
- Install Godot 4. It was not installed on the Mac.
- On the prototype branch, `.claude/launch.json` serves the prototype with `python3`; on Windows that may need to be `python`. Double-clicking the HTML file avoids the server.
- `gh` was not installed on the Mac. The tracker is local markdown, so it is not needed.

## Suggested skills

- `mattpocock-skills:grill-with-docs` — to continue ideating; it drives `grilling` and `domain-modeling` and keeps `GLOSSARY.md` and ADRs current.
- `mattpocock-skills:to-tickets` — to split the first-dive spec into tickets under `.scratch/first-dive/issues/`.
- `mattpocock-skills:implement` — per ticket, clearing context between tickets.
- `mattpocock-skills:tdd` — for building the simulation test-first at the seam.
- `mattpocock-skills:prototype` — if another design question needs a runnable answer (for example, reaching Stations when level, or the Shift's feel).
- `mattpocock-skills:code-review` — to close out each ticket.
- `mattpocock-skills:ask-matt` — when unsure which skill fits.
