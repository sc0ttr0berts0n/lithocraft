# Building a round in waves

How several tickets are built together.
An agent's context is the scarce thing: each role below does one kind of work and sees only what that work needs.
Agreed with the developer on 28 November 2026, after round 4 spent about 8 million subagent tokens with every implementer also merging, documenting and reading pictures.

## The roles

| Role | Does | Model |
|---|---|---|
| **Orchestrator** | Cuts the round into waves, starts the agents, reports to the developer | the session's |
| **Implementer** | One ticket: code and tests in the files it owns | Opus |
| **Integrator** | One wave: merges, wires, runs the checks, writes the paperwork, lands it | Opus |
| **Looker** | Regenerates the screenshot sheets a wave names and says what they show | Opus |

A **wave** is a set of tickets whose owned files do not overlap, built in parallel from one base commit of `dev`.

## Orchestrator

1. Cut the wave. For each ticket name the files it owns. Two tickets that own the same file go in different waves. A ticket that must change `sim/dive_simulation.gd` beyond wiring a subsystem in runs alone.
2. Start one implementer per ticket, each in its own worktree at the wave's base commit. The brief is the ticket's number, its owned files, the base commit, and "you are an implementer: read `docs/agents/waves.md`".
3. When every implementer has handed back, start the integrator with the hand-back notes and the branch names.
4. If any hand-back names states worth a picture, start the looker after the wave has landed.
5. Report the wave to the developer in one message, then cut the next wave from the new `dev`.

Name a model on every agent.

The loop this serves: the developer plays, gives their thoughts, and starts a session with a definition of done; the session runs unattended to that definition; the developer comes back and plays.
The definition of done sets the round's size, however many waves that takes.
A choice that is the developer's does not stop the run: make it, keep it small, record it under "For the developer", and list every such choice in the final report.
Stop only when the definition of done cannot be met without contradicting the spec or the existing game.

## Implementer

- Read `GLOSSARY.md`, `docs/adr/0001-science-ground-rules.md`, the ticket, and the convention files for your area through the index `docs/conventions.md`.
- Write code and tests in the files you own, test-first at the simulation's interface.
- Stay on your base commit. Other tickets' work reaches `dev` through the integrator.
- Leave shared files to the integrator: `docs/`, `GLOSSARY.md`, the key map, the screenshot recipes, the cost budget's conditions, the issue's checkboxes. Where you need a line in `sim/dive_simulation.gd` to wire your class in, make it and say so.
- Run the suites for your code as you go, and the lint once at the end. The whole suite is the integrator's.
- Push your branch and hand back. Done is: your tests pass, the lint is clean, the branch is pushed.

The **hand-back** is this note and nothing longer:

```
Branch:
Built: (two or three lines)
Choices: (each choice the ticket left open, and why, one line each)
For the developer: (any choice that is theirs to rule on)
Keys wanted: (Station, key, what it does)
Terms: (new or changed glossary terms)
Conventions: (what the next agent in this code must know that the code does not say)
Outside my files: (changes you needed and made or did not make)
Worth a picture: (screen states, each as the commands that stage it)
Unverified:
```

Stop and hand back early when the ticket contradicts the spec or the existing game.

## Integrator

1. Branch `wave/<name>` from `dev` and merge the implementers' branches in the order given.
2. Resolve conflicts, wire subsystems into the simulation's main class, and give out keys so no Station binds one twice.
3. Run the whole suite, the lint, the docs check and the cost budget once. Fix what the merge broke; send a fault in one ticket's own logic back through the orchestrator.
4. Write the paperwork once, from the hand-backs: conventions, glossary, key map, screenshot recipes, and one design-record entry for the wave holding each agent's choices and what awaits the developer.
5. Tick each ticket's criteria that the merged code meets, and list the ones it does not.
6. Open one PR for the wave into `dev`, read a green CI result on its final head, merge it, and close the tickets by hand.

## Looker

Regenerate each sheet the wave named, read it once, and report what each tile shows against its name.
Correct a recipe whose staging no longer reaches its state.
Change nothing else.

## Review

One review per round, on `dev`, by `docs/conventions/review.md`.
