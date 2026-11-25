# Spec: First dive

Status: ready-for-agent

## Problem Statement

The Lithocraft exists only as a design conversation, a glossary and one browser prototype. Nobody has yet operated it. The design rests on a set of ideas that are unproven as play: crawling through rock like a worm, routing heat between the vessel and the Column, watching the Column scroll through the Bore, sealing yourself in as the rock gets denser, performing a Shift at each Boundary, and working in a Habitat whose "down" follows the vessel's acceleration. Until one complete trip can be played from start to finish, there is no way to tell whether these ideas are a game.

## Solution

A single playable dive in Godot. A solo player boards the Lithocraft at the surface of an Earth desert, dives through sand, then sandstone, then granite to a depth of a few kilometres, turns in a wide arc, returns to the surface, and sells the survey of the Column they recorded on the way. The player walks the Habitat in first person and works five Stations. Everything outside the Habitat is seen only through the Bore and the instruments.

The dive is complete when the player can leave the surface, cross both Boundaries, become sealed in, come back, and be paid an amount that reflects how well they protected the Column.

## User Stories

### Moving through the Medium

1. As a crew member, I want to set the Lithocraft's power and heading at the Drive Station, so that I decide where it goes and how fast.
2. As a crew member, I want the Lithocraft to advance by gripping the tunnel wall in travelling waves, so that it moves like a worm rather than a vehicle.
3. As a crew member, I want grip to depend on the strength of the Medium, so that loose sand is easy to cut but hard to push against and granite is the reverse.
4. As a crew member, I want speed to rise with power and fall with the hardness of the Medium, so that going faster always has a cost.
5. As a crew member, I want the Lithocraft to respond slowly to heading changes and to have a wide turning arc, so that I have to plan the route back to the surface before I need it.
6. As a crew member, I want there to be no reverse, so that committing to a dive is a real decision.
7. As a crew member, I want to steer by heating one side of the Head harder than the other, so that turning costs heat.
8. As a crew member, I want to see my depth, heading, pitch and speed at the Drive Station, so that I always know the vessel's attitude.
9. As a crew member, I want slipping to be visible and audible when grip is too low for the power I am asking for, so that I can back off before wasting heat.

### The Bore and the Column

10. As a crew member, I want to see the Column sliding through the Bore from anywhere in the Habitat, so that the Medium I am travelling through is always in view.
11. As a crew member, I want the Column to scroll at the vessel's real speed, so that I can read my progress from it.
12. As a crew member, I want the Column to look different in sand, sandstone and granite, so that I can recognise a Boundary with my own eyes.
13. As a crew member, I want the Bore Station to record a survey of the Column as it passes, so that I am building something to sell.
14. As a crew member, I want the survey's quality to be shown as I go, so that I can see the effect of my decisions on my income.
15. As a crew member, I want features of interest to appear in the Column from time to time, so that there is a reason to watch the Bore.
16. As a crew member, I want a feature to be available only until it leaves the Tail, so that slowing down to study it is a trade against heat and time.

### Heat

17. As a crew member, I want every system that draws power to make heat, so that power and heat are one problem.
18. As a crew member, I want to choose at the Thermal Station how heat is split between the surrounding Medium and the Column, so that I decide what suffers.
19. As a crew member, I want heat sent outward to wear the vessel, so that protecting the Column has a cost.
20. As a crew member, I want heat sent into the Column to degrade the survey, so that protecting the vessel has a cost.
21. As a crew member, I want cooking the Column to be the most effective way to keep moving fast, so that the temptation is real.
22. As a crew member, I want the Medium's own temperature to rise with depth, so that the same power setting gets harder to sustain as I go down.
23. As a crew member, I want clear warning before heat damages the vessel, so that overheating is a consequence of a choice and never a surprise.

### The tunnel behind

24. As a crew member, I want the Lithocraft to leave an open glass-lined tunnel in porous Medium, so that I have a way back and a clear line to the surface.
25. As a crew member, I want the tunnel to fill behind me in dense Medium, so that going deep seals me in.
26. As a crew member, I want to see the porosity trend ahead of the point where the tunnel will seal, so that I watch that moment approach.
27. As a crew member, I want my link to the surface to be fast while the tunnel is open and a trickle once I am sealed in, so that the tunnel's state changes what I can do.
28. As a crew member, I want survey data to be paid for only once it reaches the surface, so that being sealed in means carrying unsold work home.
29. As a crew member, I want to choose which survey data goes up the slow link first, so that I can bank the most valuable part.

### Boundaries and the Shift

30. As a crew member, I want the Reactor Station to show the state of the Head's plasma and the power available, so that I know what the other Stations can draw.
31. As a crew member, I want a Boundary to change the load on the Head, so that crossing from one Medium to another is an event.
32. As a crew member, I want a window in which to perform a Shift as the Lithocraft crosses a Boundary, so that the crossing tests my timing.
33. As a crew member, I want a clean Shift to pass smoothly, so that skill is rewarded with nothing happening.
34. As a crew member, I want a poor Shift to cause a heat spike, a lurch and wear on the Head, so that a mistake hurts without ending the dive.
35. As a crew member, I want repeated poor Shifts to be able to lose the plasma, so that carelessness has a limit.
36. As a crew member, I want losing the plasma while sealed in to strand the Lithocraft, so that the worst outcome is a real one.
37. As a crew member, I want a stranded dive to end with a recovery that costs me the unsold survey and returns me to the surface, so that failure is expensive but not final.

### Seeing ahead

38. As a crew member, I want to send a sound pulse from the Navigation Station and see the echoes as points in a three-dimensional display, so that I can look at what lies ahead.
39. As a crew member, I want the points to be sparse and uncertain at range and sharper as I approach or pulse again, so that I am interpreting evidence and not reading a map.
40. As a crew member, I want a Boundary ahead to show in the display before I reach it, so that I can prepare for the Shift.
41. As a crew member, I want to call Quiet Ship to halt the vessel and idle the Head for a clean pulse, so that a good picture is a deliberate pause.
42. As a crew member, I want a pulse taken while moving to be noisy, so that Quiet Ship is worth its cost.
43. As a crew member, I want Quiet Ship to shutter the Bore instruments, so that scanning and surveying compete.
44. As a crew member, I want the Column to confirm or refute what the display suggested, so that my reading of the scan is tested moments later.

### The Habitat

45. As a crew member, I want to walk the Habitat in first person, so that I am aboard the vessel and not looking at a panel.
46. As a crew member, I want "down" to be the direction of the vessel's real acceleration, so that diving nose-down puts me on the Head end and travelling level puts me on the outer wall.
47. As a crew member, I want "down" to change smoothly as the vessel pitches, so that I can keep my footing through a turn.
48. As a crew member, I want each Station to swing on its gimbal to stay upright, so that it is usable at any pitch.
49. As a crew member, I want every Station to be reachable at every pitch the dive passes through, so that the vessel's attitude never locks me out of a system.
50. As a crew member, I want each Station to have its own tone and light when it needs attention, so that I can tell which one is calling and from which direction.
51. As a crew member, I want the urgency of a call to be carried by its pitch and tempo, so that I can prioritise without reading anything.
52. As a crew member, I want no markers or alerts drawn over my view, so that everything I know comes from the vessel itself.
53. As a crew member, I want no view of the Lithocraft from outside while underground, so that I have only the Habitat, the instruments and the Bore.

### Playing alone

54. As a solo player, I want each Station to hold a steady setting when I walk away from it, so that I can run the whole vessel by moving between Stations.
55. As a solo player, I want an unattended Station to handle steady conditions safely and sudden changes badly, so that Boundaries are where I must be in the right place.
56. As a solo player, I want time to be able to run faster during quiet stretches and to drop back to normal when a Station calls, so that a slow honest dive fits in one sitting.

### The trip as a whole

57. As a solo player, I want to begin at the surface with the Lithocraft ready to dive, so that I can start without preparation.
58. As a solo player, I want to pass through sand, then sandstone, then granite on the way down, so that I meet easy, middling and hard Medium in order.
59. As a solo player, I want to reach a depth of a few kilometres and return to the surface in an arc, so that the dive has an outbound leg, a turn and a homeward leg.
60. As a solo player, I want to sell my survey on return and see what I was paid and why, so that I understand how my choices became income.
61. As a solo player, I want to be able to start another dive straight away, so that I can try to do better.

## Implementation Decisions

- **Engine.** Godot, 3D, first person.
- **Simulation separate from view.** The state of the Lithocraft and the Medium is held and advanced by a simulation that knows nothing about rendering, input devices or the scene. The Habitat, the Stations, the Bore and all displays read from it and send it commands. This was decided so that multiplayer can be added later without a rewrite, and it is also what makes the game testable.
- **The simulation's interface.** It accepts Station commands (power, heading, heat split, Shift input, pulse, Quiet Ship, upload priority, time rate) and a time step, and exposes the resulting state and a stream of events (Boundary approaching, Boundary crossed, Shift result, tunnel sealed, plasma lost, stranded, surfaced, paid).
- **The Medium is data, not terrain.** A Medium is described by seven properties: hardness, strength, porosity, temperature, pressure, composition, and how well it carries sound. The world underground is a description of which Medium is at each point, queried along the Lithocraft's path and ahead of it for the scan. No underground terrain is built or rendered. A new Medium is a new set of values.
- **Every Station reads the same seven properties.** Hardness sets cutting cost, strength sets available grip, porosity sets whether the tunnel stays open, temperature and pressure rise with depth, composition sets the Column's appearance and survey value, and sound-carrying sets scan range and the slow link's rate.
- **Three shared budgets.** Power is supplied by the Reactor and drawn by Drive, Navigation and Thermal. Heat is produced by everything that draws power and is divided by Thermal. The Column is wanted cool by the Bore Station and wanted as a heat sink by Thermal. Conflicts between Stations arise only from these three; none are scripted.
- **Science ground rules.** As recorded in ADR 0001: relationships are physically true, constants are tuned for play. This dive uses two of the three permitted impossible things (compact fusion and the hull material) and does not use warp.
- **Movement model.** A single Head, no reverse. Advance comes from grip waves limited by Medium strength. Turning comes from uneven heating of the Head and has a minimum arc on the order of hundreds of metres, to be tuned.
- **Tunnel state.** The tunnel behind is either open or sealed, decided by the porosity of the Medium the Tail is leaving. The link to the surface is fast while a continuous open tunnel reaches the surface and slow otherwise.
- **The Shift.** Crossing a Boundary changes the load on the Head. The Reactor Station has a window to retune. The result is graded, not pass or fail, and its consequences are a heat spike, a lurch and wear on the Head. Wear accumulates; enough of it, or a poor Shift under bad conditions, loses the plasma.
- **Waves as the common language.** Station displays and inputs are built around waveforms: the Shift is a matter of matching the plasma's behaviour, the scan is pulses and echoes, the Bore Station reads composition as a spectrum.
- **The scan.** Pulses add points to a persistent three-dimensional point cloud at the Navigation Station, in the manner of Scanner Sombre. Point density and confidence fall with range and with the vessel's own noise. Quiet Ship removes that noise by halting the vessel and idling the Head, and shutters the Bore instruments while it lasts.
- **The Habitat.** An annular room around the Bore, walkable on its outer wall and both end caps. The player's "up" is the opposite of the local felt acceleration and is followed smoothly. Stations hang on gimbals that align the same way. From the prototype: the Habitat was modelled with a Bore wall radius of 0.8 m, an outer wall radius of 3.3 m and a length of 2.4 m, with Stations pivoting 1.1 m above the outer wall; these are starting values, not commitments.
- **Level travel must not strand Stations.** The prototype showed that when the vessel is level, the floor is the bottom of a curved wall and only the lowest one or two Stations can be reached on foot. The Habitat layout for this dive must solve that, since the arc back to the surface passes through level. The method is open (ladders or handholds, a larger radius, Stations that travel around the ring, or a Habitat that rolls).
- **Unattended Stations.** A Station holds its last setting and applies a simple steadying rule. It does not perform a Shift well.
- **Time rate.** The player can raise the rate at which the simulation runs. Any Station call returns it to normal.
- **Survey and payment.** The Bore Station accumulates a survey record along the path. Each stretch has a quality that is reduced by heat sent into the Column and by Quiet Ship shuttering. Payment is made for data that has reached the surface, by fast link, slow link or by returning with it.
- **Stranding.** Losing the plasma while sealed in ends the dive with a recovery: unsold survey data is lost and the player is returned to the surface.
- **Stations in this dive.** Reactor, Drive, Thermal, Navigation and the Bore Station. The Fabricator is not present.
- **Language and test tooling.** Not yet chosen (GDScript or C#, and the matching test runner). The choice must allow the simulation to be run and tested without opening a scene.

## Testing Decisions

- **One seam: the simulation's interface.** Tests construct a simulation with a described Medium layout, send Station commands, advance time, and assert on the exposed state and events. No test reaches inside the simulation, and no test depends on rendering, input devices or scene nodes.
- **What a good test looks like here.** It states a relationship the player can feel and checks it from outside. Examples: at equal power the Lithocraft advances faster in sand than in granite; asking for more power than the grip allows produces slip, not speed; sending heat into the Column lowers survey quality and sending it outward raises vessel wear; the tunnel reports sealed once the Tail leaves a Medium below the porosity threshold, and the link rate drops with it; a Shift entered inside the window grades better than one entered late; enough accumulated wear loses the plasma; losing the plasma while sealed in produces a stranded event and discards unsold data; a pulse under Quiet Ship returns more confident points than one taken under way.
- **Tests assert relationships, not constants.** Because ADR 0001 says constants are tuned for play, tests compare outcomes ("more than", "sooner than", "no longer open") and avoid exact figures that tuning would break.
- **A full-dive test.** One test drives a scripted set of commands through the whole trip, from the surface through both Boundaries and back, and asserts the sequence of events and that a payment results.
- **Not covered by automated tests.** How the Habitat feels to walk, whether Station calls are legible by sound, and whether the Shift is satisfying. These are judged by playing.
- **Prior art.** None in this repository. The browser prototype of the Habitat has no tests and is not a model for them.

## Out of Scope

- Flight in air, space and gas giants; the ascent to orbit; spin gravity; warp.
- Any body other than Earth, and any Medium other than sand, sandstone and granite.
- Multiplayer and crew of more than one.
- The Fabricator, Feedstock, sorting elements at the Head, and building parts by stacking waves.
- Hands-on repair of physical parts.
- Fuel, deep materials, hull grades and buying designs.
- Ports beyond a single place to sell the survey; contracts; any economy beyond one payment.
- Cutting samples out of the Column. Features of interest are observed and recorded, not extracted.
- Hazards beyond the two Boundaries (voids, water, gas pockets, magma, faults).
- Saving and loading.
- Final art, sound design and music.

## Further Notes

- The verdict on the Habitat prototype has not been given. It ran and behaved as designed, but whether the changing "down" feels right is still to be judged by the developer. If the verdict is no, the Habitat stories in this spec need revisiting before they are built.
- The prototype also showed that spin gravity at this size is weak and uneven (0.37 g at the feet and 0.18 g at the head at 10 rpm). That does not affect this dive but will matter when space flight is designed.
- Three scope choices in this spec were made during synthesis and were not put to the developer directly: leaving the Fabricator out, including simple unattended-Station behaviour and a time rate control, and making Column features observe-only. Each can be changed without disturbing the rest.
- The prototype is kept on the `prototype/habitat-down` branch as a primary source.
- Vocabulary follows `GLOSSARY.md`. Design reasoning for decisions not repeated here is in ADR 0001.
