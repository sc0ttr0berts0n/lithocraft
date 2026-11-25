# Lithocraft

A hard-science-fiction 3D Godot game about operating the Lithocraft, a ring-shaped vessel that bores through rock. The first playable slice is one Earth desert dive, specified in GitHub issue #1 with its tickets as sub-issues.

## Before any work

Read `GLOSSARY.md` and use its terms exactly. Read `docs/adr/0001-science-ground-rules.md`: relationships are physically true, constants are tuned for play, and only three impossible things are permitted.

For design questions, or anything the spec leaves out, read `docs/design-record.md`: every decision with its reason, the developer's own ideas, the real science behind each, and the "Not yet designed" list.

## Implementing a ticket

One ticket per session. Take the frontier: an open sub-issue of #1 with no open blockers and no assignee.

- Build test-first at the one seam, the simulation's interface: commands and a time step in, state and events out. The simulation is plain GDScript classes with no scene nodes; the view only reads it and sends commands.
- Tests assert relationships ("faster in sand than granite"), never tuned constants.
- The Habitat and the Arm have a browser reference on the `prototype/habitat-down` branch. Its geometry and feel carry over; its code does not.
- The ticket is done when every acceptance criterion is checked, the whole suite passes headless, and a review is clean.

## Designing with the developer

- Grill in rounds: numbered questions, each with a recommended answer worded so "yes" accepts it.
- The developer's side ideas are the best material in the design. Ground each in real science, fold it into the next round, and record it in the design record as it happens.
- When an idea needs something impossible, say so plainly and tie it to ADR 0001.
- Write resolved terms to `GLOSSARY.md` and decisions to `docs/design-record.md` as they happen.

## Agent skills

### Issue tracker

Issues and specs live as GitHub issues in sc0ttr0berts0n/lithocraft, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default triage roles, applied as GitHub labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
