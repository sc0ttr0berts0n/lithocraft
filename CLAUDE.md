# Lithocraft

A hard-science-fiction 3D Godot game about operating the Lithocraft, a ring-shaped vessel that bores through rock. The first playable slice is one Earth desert dive. Specs: GitHub issue #1 (First dive), then #71 (After the second checkpoint). Every ticket is a sub-issue of #1. A spec lists the tickets that must land first, its own or not.

## Before any work

Read `GLOSSARY.md` and use its terms exactly. Read `docs/adr/0001-science-ground-rules.md`: relationships are physically true, constants are tuned for play, and only three impossible things are permitted.

For design questions, or anything the spec leaves out, read the index `docs/design-record.md`, then the files under `docs/design/` it names for the question: every decision with its reason, the developer's own ideas, the real science behind each, and the "Not yet designed" list.

## Implementing a ticket

Tickets are built in waves: read `docs/agents/waves.md` first and take the role your brief names (implementer, integrator, looker). The frontier is the open sub-issues of #1 with no open blockers and no assignee.

Before changing code, read the index `docs/conventions.md`, then its topic files for the area the ticket touches. The integrator records new conventions, once per wave.

- Work lands on `dev`, one PR per wave. `main` holds only stable builds, promoted from `dev` by the developer.
- Build test-first at the one seam, the simulation's interface: commands and a time step in, state and events out. The simulation is plain GDScript classes with no scene nodes; the view only reads it and sends commands.
- Tests assert relationships ("faster in sand than granite"), never tuned constants.
- The Habitat and the Arm have a browser reference on the `prototype/habitat-down` branch. Its geometry and feel carry over; its code does not.
- A ticket is done when every acceptance criterion is checked, "What runs when" (`running-and-testing.md`) passes and a review is clean: one, on the integration branch, for tickets built together.

## Designing with the developer

- Grill in rounds: numbered questions, each with a recommended answer worded so "yes" accepts it.
- Each question stands alone: say how the thing works today, then ask.
- Grill concepts. Decide a round's tickets yourself and report them.
- Given a play-test video, follow `docs/playtests/README.md`.
- The developer's side ideas are the best material in the design. Ground each in real science, fold it into the next round, and record it in the design record as it happens.
- When an idea needs something impossible, say so plainly and tie it to ADR 0001.
- Write resolved terms to `GLOSSARY.md` and decisions to the design record (`docs/design/`, through its index `docs/design-record.md`) as they happen.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in sc0ttr0berts0n/lithocraft, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default triage roles, applied as GitHub labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
