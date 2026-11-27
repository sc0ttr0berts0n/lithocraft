# Conventions

How the code is put together and the rules for changing it.
Read before changing `sim/`, `view/` or `test/`.
Each public method's meaning is in its doc comment; this file holds what the code does not say.

This file is the index.
Read it, then only the topic files for the area the ticket touches.
Each line gives the file, the sections of the old single file it holds, and when to read it.
The old "Extension points" and "Subsystems" sections are spread by topic; their paragraphs are named below by their bold leads.

## Always

- [conventions/layout.md](conventions/layout.md): Layout. Read when adding, moving or looking for a file: what lives in `sim/`, `view/`, `assets/` and `test/`, and how files are written.
- [conventions/running-and-testing.md](conventions/running-and-testing.md): What runs when, Running (the suite, the scene smoke check, Ad-hoc checks), Testing, Gotchas. Read before running the suite, the scene smoke check or an ad-hoc check, and before writing any test.
- [conventions/simulation-interface.md](conventions/simulation-interface.md): The simulation's interface, Frames and units, the rules of Subsystems. Read before adding or changing any command, query, event, per-step work or tuned constant on `DiveSimulation`, or any class in `sim/`.
- [conventions/review.md](conventions/review.md): Review standards. Read when reviewing a ticket's diff, in place of the other topic files, and before handing a ticket over for review: the judgement calls no test can make, and what counts as a finding.

## The simulation, by area (the old Extension points and Subsystems)

- [conventions/stations-and-autopilots.md](conventions/stations-and-autopilots.md): A new Station call, Autopilots. Read when a Station gains a command, a call or an autopilot rule, or a test needs a Station to steady itself.
- [conventions/power-and-heat.md](conventions/power-and-heat.md): A new power-drawing system, Reactor output, Heat. Read when touching the power budget, the heat split, hull temperature, hull wear (creep) or the Thermal Station.
- [conventions/plasma-and-shift.md](conventions/plasma-and-shift.md): The plasma and the Shift, The Shift dial, The look-ahead. Read when touching the Reactor: stability, tuning, ACTIVE and STANDBY, the Shift, the guess of the Wobble ahead, the Boundary countdown, Head wear, relighting or losing the plasma.
- [conventions/stranding-and-endings.md](conventions/stranding-and-endings.md): Stranding, rescue and death, The emergency store, Self-destruct, How a dive ended, New dives. Read when touching anything after the plasma is lost, how a dive ends, `outcome()`, or what a new dive resets.
- [conventions/survey-and-payment.md](conventions/survey-and-payment.md): Survey quality, Payment, New minerals. Read when touching the Column's record, the link, what a dive pays, the repair bill or a mineral.
- [conventions/scan.md](conventions/scan.md): The point cloud, Drawing the scan, Inferred Boundaries, The projected path. Read when touching pulses, `points()`, the Boundary fit, the projected path, or any view that shows Boundaries or the rock ahead.
- [conventions/scenarios-and-checklist.md](conventions/scenarios-and-checklist.md): Scenarios, Phase triggers. Read when touching a Scenario, its start state, the Orders, the Checklist's phases, steps and triggers, or surface control's messages.
- [conventions/debug-commands.md](conventions/debug-commands.md): Debug commands. Read when adding or using a `debug_*` command or a debug menu key.

## The view

- [conventions/view.md](conventions/view.md): The view. Read before changing anything in `view/`: who owns the simulation, `_at`, what may be drawn over the crew's view, mouse look, pointing, Station places, the start menu, the end of a dive, hull feel and sound.
- [conventions/station-screens.md](conventions/station-screens.md): The view's Station screens, the frame, the Theme and the colour language. Read when changing what every Station screen shares: `StationScreen`, `StationTheme`, Caution lamps, the key list, `GimballedStation`.
- [conventions/screen-thermal.md](conventions/screen-thermal.md): The view's Station screens, each Station's screen: the Thermal's. Read when changing the Thermal screen or `ThermalGauge`.
- [conventions/screen-reactor.md](conventions/screen-reactor.md): The view's Station screens, each Station's screen: the Reactor's. Read when changing the Reactor screen or `PlasmaDisplay`.
- [conventions/screen-drive.md](conventions/screen-drive.md): The view's Station screens, each Station's screen: the Drive's, and the deviation both the Drive and Navigation state. Read when changing the Drive screen, `FlightDisplay`, `FlightTape` or `CourseDeviation`.
- [conventions/screen-navigation.md](conventions/screen-navigation.md): The view's Station screens, each Station's screen: Navigation's. Read when changing Navigation's point cloud (`ScanDisplay`), moving map (`MovingMap`) or projected path display.
- The Bore Station has no screen conventions yet; a new file, with its line here, goes beside the others when it has some.
- [conventions/key-map.md](conventions/key-map.md): Key map. Read before binding, moving or naming a key, adding a key prompt, or adding a debug menu key.

## Writing these files

- Record a new convention in the topic file it belongs to; start a new file, with its line here, only for a new topic.
- One sentence per line, so a search returns the sentence and not a wall. No line over 400 characters, no topic file over 12 KB, this index under 60 lines.
- `python tools/docs/check_docs.py` checks those limits, and that every reference to this file by section names a section listed here.
