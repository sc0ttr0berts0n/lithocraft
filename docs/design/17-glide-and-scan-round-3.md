# The Glide and the scan, round 3

Grilled with the developer on 27 November 2026, following 16-glide-and-scan.md, which it overtakes where they disagree.

## How the Glide is flown, the Sweep's shape, and when it is built

- **The Glide runs straight; turns and surveying are the Crawl's (developer).**
  "Turns must crawl, and surveying must crawl as the core won't get vaporized."
  Navigation plots a Glide along the current Course with a chosen length, up to what the scan has shown, and the Drive starts it.
  A route is glides joined by crawled turns.
- **The Glide does not wear the Head by distance (developer: "is that so bad?").**
  "There are stretches of time where gliding is preferred because shit's literally and figuratively boring."
  The Glide being the better choice for ground nobody wants to survey is the point of it.
- **It is flown by hand, and wear comes from being off its line (developer's idea).**
  "Should it need to be flown manually with a need to keep it on target or you experience wear?"
  Real basis: a supercavitating body is unstable inside its bubble and must be steered the whole way; where it touches the bubble's wall it is slapped and damaged.
  Rock that is harder on one side pushes the vessel off its line; the Drive's crew holds it with nudges, and the Head and hull wear only while it is off.
  The Drive's autopilot may hold it too, loosely, at the cost of a little wear, so a lone crew member can glide while working another Station (developer: yes).
- **The Drive's attitude display becomes a ball** (developer: "Kerbal's nav ball likely understands what we're doing pretty well").
  It shows the Course, what the Drive steers for and the lean marker at the pole, with no dead spot when vertical; in a Glide it shows the line to hold.
- **The time rate after a warning.**
  A new warning drops the time rate to 1; once acknowledged, the crew may raise it again while the warning still shows, and a warning that grows more urgent drops it again.
  The developer: "feels wrong but would be annoying if you knew better and chose to do it and were unable."
- **The Sweep is a spiral over the forward hemisphere (developer), overtaking round 2's tilting slices.**
  "Maybe it's a spiral, starting at the blind spot of the beam pulse, and it swirls out wider and wider until it hits the relative 0 degree angle. So a hemisphere of data?
  I want scan priority in direction of travel, and then less and less priority behind and away."
  It starts at the edge of the Beam's cone and winds outward to square across the vessel; each turn of the spiral takes the same time, so the points lie thickest ahead and thin toward the sides, and nothing is taken behind, where the vessel and its tunnel are.
  Real basis: spiral and conical scans, used by tracking radars to search outward from where they point.
- **The Beam can be aimed (developer: "I am interested in targeting beam scans when desired to prospect").**
  Navigation swings the narrow Beam off the vessel's axis toward a place of interest and pulses it there; that is prospecting.
- **Timings follow range.**
  A Beam pulse returns within a second; a Sweep takes from about one to about three minutes by range, drawn as it arrives; under way it smears, which is why it pays to stop.
  The numbers are starting points to tune.
- **The Checklist through the granite (found by ticket #73's follower test).**
  The First dive could not be finished from the Checklist alone: the granite's pretune waited on a guess the scan never had, and nothing asked the crew to finish a Shift by hand.
  Before each pretune a step asks for pulses until Navigation shows the Boundary ahead; after each Shift a step asks that ACTIVE be tuned until the Residual is inside the Band.
  Round 4 reworks the First dive's Checklist again for the surface's survey, the Beam's own pulsing and the Glide.
- **Round 4 is built now and played with round 3 (developer).**
  "Let's fold these non-competing features together in the next playtest, no stop."
  The next checkpoint's play test covers rounds 3 and 4 together; the pick among the three scan views is made in that play test, so the Sweep is drawn in all three.
- **The First dive keeps its shape and gains the loop; the Glide gets an early tutorial (developer).**
  The survey is in the scan from the start, the Orders name one target in the granite, found with the Sweep and crawled through, and the climb home through rock already surveyed is a Glide.
  "I wouldn't mind a glide scenario in an early tutorial": a short Glide drill sits early on the start menu.
- **The scan says what kind of rock lies ahead, as far as sound can know (developer's question).**
  "With all of the pulsing, there is no real visual or indication of rock type. What's that about? Any plan for that?"
  There was none: the scan showed points by confidence and nothing of the rock.
  Real basis: an echo's strength and polarity give the contrast in acoustic impedance across a Boundary, so a seismic survey tells harder from softer and denser from more porous rock, and never a mineral's name.
  Each Inferred Boundary carries the scan's estimate of the rock beyond it relative to the rock before, as sure as its patch and wrong by an error that shrinks with confidence, shown in the space between Boundaries.
  Surface control's survey names the rock it expects as a guess; only the Column confirms a name.
- **The spec is #113; its tickets are #91 and #115 to #128.**
- **The First dive's Checklist through its Boundaries, as built (#73).**
  The Checklist follower (`test/checklist_follower_test.gd`) plays the First dive from the Checklist alone, and first lost the plasma 13 m into the granite: no step asked for a scan before "Pretune standby for the granite", and the first Shift had let the Reactor's autopilot go.
  Developer, 27 November 2026: before each pretune, "Pulse until Navigation shows the Boundary ahead", ticked when the scan has a guess of the Wobble ahead; after each Shift, "Select active and tune it until the Residual is inside the Band", ticked when it is, in the Medium entered.
  Both are built for the First dive's two Boundaries down; the Shift drill has the tuning step only, since its start state sends the pulse.
  The climb's two Boundaries are taken by the Reactor's autopilot: one step in "Turn and climb", "Engage the Reactor's autopilot for the climb", ticked while it is engaged.
  That is an agent's choice (the orchestrator's, the developer away), until #128 makes the climb a Glide, which crosses Boundaries with no Shift.
  Measured by the follower, both ways surfaced and paid: on the autopilot the Head wore 7.6% and the dive paid 4804; with a pulse, pretune, Shift and tune step at each Boundary on the climb (eight steps, not built) it wore 0.9% and paid 4853.
