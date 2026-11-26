# Lithocraft

A hard-science-fiction simulation game about operating a ring-shaped vessel that travels through rock, atmosphere and space.

## Language

**Lithocraft**:
The player's vessel: a ring-shaped craft that advances through a Medium while a Column passes through its Bore.
_Avoid_: Ship, drill, borer, worm

**Bore**:
The glass-walled passage along the Lithocraft's central axis.
_Avoid_: Core, tube, cylinder, window

**Head**:
The forward section of the Lithocraft: the tokamak ring that cuts into the Medium.
_Avoid_: Drill, bit, nose, cutter

**Habitat**:
The walkable middle section of the Lithocraft where the crew works at stations.
_Avoid_: Cockpit, bridge, cabin, deck

**Tail**:
The aft section of the Lithocraft, where melt and exhaust leave.
_Avoid_: Stern, nozzle, engine

**Medium**:
Whatever the Lithocraft is currently travelling through, such as sand, rock, atmosphere or vacuum.
_Avoid_: Terrain, environment, material

**Column**:
The uncut Medium that slides through the Bore as the Lithocraft advances.
_Avoid_: Core, sample, plug

**Feedstock**:
A store of a single element, sorted out of the Medium by the Head and used to make parts.
_Avoid_: Ore, resource, ink, cargo

**Boundary**:
The place where one Medium gives way to another along the Lithocraft's path.
_Avoid_: Transition, interface, layer change

**Inferred Boundary**:
A Boundary as Navigation's scan suggests it: surfaces fitted to the point cloud alone, each patch as sure as the points that support it.
_Avoid_: Terrain mesh, real Boundary (for what the scan shows)

**Shift**:
The change of Counter-wave the crew makes as the Lithocraft crosses a Boundary and the Wobble changes.
_Avoid_: Gear change, transition, retune

**Shift dial**:
The Reactor's two channels of tuning, like an airliner radio's: ACTIVE holds the plasma now, STANDBY holds a Counter-wave prepared for the Medium ahead, and the Shift swaps them.
_Avoid_: Dial (alone), selector, preset

**Active**:
The Shift dial's channel whose tuning holds the plasma now.
_Avoid_: Current, live, primary

**Standby**:
The Shift dial's staged channel, pretuned for the Medium ahead and changing nothing until the Shift swaps it in.
_Avoid_: Next, preset, queued

**Wobble**:
The wave the Medium puts on the Head's plasma, different in every Medium.
_Avoid_: Noise, vibration, signal, rock wave

**Counter-wave**:
The wave the crew tunes at the Reactor to cancel the Wobble.
_Avoid_: Tuning (for the wave itself), inverse, anti-wave, match

**Residual**:
What is left of the Wobble once the Counter-wave is summed with it; a flat line when the cancelling is perfect.
_Avoid_: Leftover, error, resultant, match

**Band**:
How much Residual the Head can bear without wearing; it narrows as the Head wears or runs hot.
_Avoid_: Window, tolerance, margin

**Quiet Ship**:
The state in which the Lithocraft halts and idles its Head so Navigation can take a clean scan.
_Avoid_: Silent running, scan mode

**Course**:
The heading and pitch Navigation plots for the Lithocraft to follow; the Drive steers toward it.
_Avoid_: Route, waypoint, path, heading (for the plotted target)

**Nudge**:
One small fixed step by which the Drive moves the pitch or heading it steers for off the Course; the only way the Drive leaves the Course.
_Avoid_: Override preset, trim, adjustment

**Deviation**:
How far what the Drive steers for is off the Course, in pitch and in heading; nothing while the Drive follows the Course.
_Avoid_: Error, offset, drift, override (for the amount)

**Projected path**:
Where the Lithocraft goes from here if nothing changes: through its turn toward what the Drive steers for, then straight on; Navigation draws it.
_Avoid_: Trend, trajectory, prediction, flight plan (a dive plan of legs is a later idea)

**Emergency store**:
The one store of energy the Lithocraft falls back on once the Head's plasma is lost; the link, a relight and cooling all draw on it.
_Avoid_: Battery, backup, reserve

**Relight**:
Striking the Head's lost plasma again with a large pulse from the emergency store.
_Avoid_: Restart, reboot, reignite

**Stranding clock**:
The time until heat soaking in from the melt and rock round a stranded Lithocraft, its Head dark, fails the hull.
_Avoid_: Timer, countdown, air left

**Rescue**:
The way home from a stranding: rescuers run down the open tunnel behind and cut through its sealed length to bring the crew and everything aboard to the surface. Its time races the stranding clock.
_Avoid_: Recovery, evacuation, retrieval

**Arm**:
The chain-arm that rides a rail around and along the Bore, catches a crew member by their harness and carries them between Stations whatever "down" is.
_Avoid_: Crane, grabber, lift, tether

**Scenario**:
A dive chosen from the start menu, with its own starting state, Orders and Checklist: the First dive, or a drill such as the Shift drill.
_Avoid_: Level, mission, tutorial

**Orders**:
What surface control asks of a Scenario's dive, set out as goals, each achieved or not yet.
_Avoid_: Objectives, quests, briefing

**Checklist**:
A Scenario's ordered steps, grouped in phases, each ticked off when the simulation sees it done.
_Avoid_: Tutorial, hints, to-do list

**Surface control**:
The people at the surface who send the Orders and messages down the link.
_Avoid_: Mission control, HQ, dispatcher

**Autopilot**:
A Station's own safe but mediocre control of its system, engaged by a switch and disengaged by any crew command that changes that Station's setting.
_Avoid_: AI, auto mode, unattended

**Explainer**:
The short account of a reading opened by pointing at it: what it is, what it reads now, and what it asks of the crew.
_Avoid_: Tooltip, help, manual

**Caution lamp**:
A labelled lamp on a Station's screen, lit while one cause is pulling its system down.
_Avoid_: Flag, warning (for a caution), bulb, indicator

## Stations

**Station**:
A fixed place in the Habitat where a crew member controls one of the Lithocraft's systems.
_Avoid_: Console, panel, terminal, seat

**Reactor**:
The Station that controls the Head's plasma and the power it supplies.

**Drive**:
The Station that controls how the Lithocraft pushes itself through the Medium, and steers it along the Course.
_Avoid_: Helm, engine

**Thermal**:
The Station that controls where the Lithocraft's heat is sent.
_Avoid_: Cooling

**Navigation**:
The Station that senses the Medium ahead and plots the Course.
_Avoid_: Sonar, radar, helm

**Bore Station**:
The Station that surveys and samples the Column.

**Fabricator**:
The Station that makes parts from Feedstock.
_Avoid_: Printer, workshop, crafting
