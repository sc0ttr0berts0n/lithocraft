# Design record: the Lithocraft and how it travels

A record of the first design session (24 November 2026).
It holds the decisions, the reasons behind them, the ideas that were raised but not yet designed, and the real science each idea leans on.
Vocabulary follows `GLOSSARY.md`.
The first playable slice is specified separately in GitHub issue #1 (Spec: First dive), with its tickets as sub-issues; this document is wider than that spec and is the place to look for anything the spec left out.

Sections are in the order they were decided.
Where two disagree, the later one wins; a bullet that has been overtaken ends with a note in italics naming what replaced it.
Add that note whenever a new decision overtakes an old one.

This file is the index.
Read it, then only the files for the question in hand.
The files are numbered in the order their sections were decided; each line gives the sections a file holds and when to read it.

## The first design session

- [design/01-vision-and-ground-rules.md](design/01-vision-and-ground-rules.md): The original vision, Lore, Ground rules. Read for what the game is, the developer's first words, and why real numbers are tuned.
- [design/02-vessel-and-media.md](design/02-vessel-and-media.md): The vessel, One principle for every Medium, Moving through rock. Read for the vessel's shape, the Head, the Bore, how it moves, a Medium's seven properties, or flight beyond rock.
- [design/03-heat-comms-and-seeing-ahead.md](design/03-heat-comms-and-seeing-ahead.md): Heat, Comms, Seeing ahead. Read for the heat dilemma, the link and when data pays, the scan, Quiet Ship, or why there is no outside camera.
- [design/04-habitat-and-crew.md](design/04-habitat-and-crew.md): The Habitat and the crew. Read for "down", the six Stations, crew size, the shared budgets, Station calls, or who plots and who steers.
- [design/05-plasma-waves-and-fabrication.md](design/05-plasma-waves-and-fabrication.md): The plasma and the Shift, Waves as the common language, Feedstock and fabrication. Read for the first design of the Shift, waves on every Station, or the Fabricator.
- [design/06-why-you-dive.md](design/06-why-you-dive.md): Why you dive. Read for what a dive is for: fuel, survey data, deep materials, the loop, mining as a by-product.
- [design/07-failure-hull-wear-and-rescue.md](design/07-failure-hull-wear-and-rescue.md): Failure, Hull wear, death and rescue. Read for hull creep, Head wear, death and the rebuy, the emergency store, relighting, the stranding clock, rescue, self-destruct, the debug menu, or keys shown on screen.
- [design/08-scope-and-habitat-prototype.md](design/08-scope-and-habitat-prototype.md): Scope and order, The Habitat prototype. Read for what the first slice leaves out, the prototype's findings, or the Arm.

## From the play tests

- [design/09-play-tests.md](design/09-play-tests.md): Play tests. Read for the one-line result of each play test and where its write-up is; add a line after each one.
- [design/10-teaching-the-dive.md](design/10-teaching-the-dive.md): Teaching the dive. Read for Scenarios, the Checklist, the Orders, the autopilot switch, the explainer, pointing, the flight display, the moving map or Inferred Boundaries as designed.
- [design/11-teaching-the-dive-as-built.md](design/11-teaching-the-dive-as-built.md): Teaching the dive, its five bullets of agent's choices (tickets #34, #35, #40, #41, #42). Read for how the Boundary fit, the Checklist, the drills and start menu, the flight display or the moving map were built, and why.
- [design/12-second-checkpoint.md](design/12-second-checkpoint.md): The second checkpoint. Read for what a checkpoint is, how agents merge, and the Shift dial as ACTIVE and STANDBY with its preview.
- [design/13-after-second-checkpoint.md](design/13-after-second-checkpoint.md): After the second checkpoint. Read for round 3 (spec #71): Checklist triggers, the Wobble, Counter-wave, Residual and Band, the colour language, Navigation plans and the Drive deviates, the point cloud redesign, the taller Habitat and sliding Stations.
- [design/14-after-second-checkpoint-as-built.md](design/14-after-second-checkpoint-as-built.md): After the second checkpoint, as built. Read for the agent's choices in round 3's tickets: how features of interest look in the Column and which way they face (#70); how the Drive's nudges, the override and the deviation behave (#65); the Thermal gauge's scale, trend arrow and split bar (#64); the point cloud's three candidate views awaiting the developer's pick (#67).
- [design/15-after-second-checkpoint-as-built-continued.md](design/15-after-second-checkpoint-as-built-continued.md): After the second checkpoint, as built, continued. Read for the agent's choices in round 3's later tickets: how the Wobble, Counter-wave, Residual and Band were built (#60), STANDBY's guess and the Boundary countdown (#61), the sliding ring of Stations and the Arm's run along the Bore (#69), the Reactor screen's composition (#63), hull feel near the crew (#94). Add new as-built bullets here.

## Round 4

- [design/16-glide-and-scan.md](design/16-glide-and-scan.md): The Glide, Calls and the time rate, The scan, Triage of round 3's design questions. Read for the Glide and its costs, which calls hold the time rate, the master acknowledge, the Beam and the Sweep, the surface's survey, targets, or how #89 to #93 were decided.
- [design/17-glide-and-scan-round-3.md](design/17-glide-and-scan-round-3.md): How the Glide is flown, the Sweep's shape, and when it is built. Read for the Glide as a straight run flown by hand, the ball display, the spiral Sweep and the aimed Beam, the time rate after a warning, the Checklist's pulse and trim steps, or why round 4 is played with round 3; Boundaries as wavy surfaces, as built (#116). Round 4's later decisions go in 18.
- [design/18-round-4-as-built.md](design/18-round-4-as-built.md): Round 4, as built. Read for round 4's tickets as built once 17 was full: the Drive's attitude ball (#119) and why it reads as it does; the Beam's three widths, its pulsing by ground, its keys, how its width shows and the forward scope's stepped ranges (#117); surface control's survey in the scan (#118); the Sweep's spiral, timings by range, smear, keys and drawing (#121). Round 4's later decisions go in 19.
- [design/19-round-4-as-built-continued.md](design/19-round-4-as-built-continued.md): Round 4, as built, continued. Read for round 4's tickets as built once 18 was full: the Beam aimed off the vessel's axis, its two directions, nothing from behind, its keys and how it shows (#120); the scan's estimate of the rock beyond a Boundary, how wrong it is and why it never contradicts STANDBY's guess, how it is drawn and said, and surface control's named expectations (#122). Round 4's later decisions go in 20.
- [design/20-round-4-as-built-continued-further.md](design/20-round-4-as-built-continued-further.md): Round 4, as built, continued further. Read for round 4's tickets as built once 19 was full: the Glide: its keys, speed multiple, spin-up and arrival, what the scan has shown, heat, power, calls, the idle after it, and the Sweep and pulses it drowns (#123); targets: the one kind (hematite breccia) and why, its size, the first error and how it narrows, what it pays, how it is drawn, and the Prospecting drill (#124).
- [design/21-round-4-as-built-continued-again.md](design/21-round-4-as-built-continued-again.md): Round 4, as built, continued again. Read for round 4's tickets as built once 20 was full: the Glide's tunnel, rough or sealed, the light up it and how the loss adds, and what a Glide home up the First dive does to the link and rescue (#125); the Glide flown by hand: what pushes it, the finer nudges, wear off the line, the autopilot, the call and the ball, and what a Glide on the autopilot costs (#126); the Glide seen, heard and felt: the melt in the Bore, its light, the roar, the shake and the tunnel drawn by its wall (#127). Round 4's later decisions go in 22.
- [design/22-round-4-as-built-continued-once-more.md](design/22-round-4-as-built-continued-once-more.md): Round 4, as built, continued once more. Read for round 4's tickets as built once 21 was full: the scan views' one layout for their words, and how survey points and softer and harder rock are told apart (#151). Add round 4's later decisions here.

## Open

- [design/not-yet-designed.md](design/not-yet-designed.md): Not yet designed. Read before designing anything new, and add to it whatever a decision parks.

## Writing these files

- A new decision goes at the end of the last numbered file, in its section; when that would pass 12 KB (file 13 is nearly there), start the next numbered file and add its line here.
- One sentence per line, no line over 400 characters, no topic file over 12 KB, this index under 60 lines: `python tools/docs/check_docs.py` checks them.
