# The Glide, calls and the scan

Grilled with the developer on 27 November 2026, after round 3 (spec #71) merged to `dev`.
Nothing here is built; tickets follow once the grilling is done.
Rounds 1 to 3 are recorded; where they disagree the later section wins.

## The Glide

- **A second way of moving (developer's idea).**
  "I want a mode that doesn't require head tuning.
  It's just something cool sounding like vaporized glide.
  It turns everything in front of it to high pressure magma and thrusts rapidly through the rock rather than crawling like a worm.
  For fast travel."
- **What it is: the vessel's one principle applied to rock.**
  The Head melts the whole face, the Column included; the melt runs through the Bore as a pressurised jet and leaves at the Tail as thrust; the grippers let go.
  The vessel rides in a sheath of melt and vapour.
  It is "a reactor wrapped around a duct" with rock in the duct, as air makes it a ramjet (02-vessel-and-media.md).
  Real basis: supercavitation, a torpedo travelling inside its own gas bubble and meeting almost no drag; and "thrust from squirting melt backward", which the first session considered for the crawl.
- **The Bore becomes a river of glowing magma** in place of the Column: the developer's "cool visual chance".
- **Real speed, not the time rate.**
  The vessel covers ground many times faster while the crew's clock runs as normal; the time rate stays a separate thing.
  The developer's "maybe 64x" was the multiple that felt right in testing, his only analogue; the number is tuned in play.
- **No Wobble and no Shift while it runs.**
  The plasma touches only the melt sheath, never solid rock, so the Medium puts no Wobble on it and Boundaries pass without a Shift.
- **Its costs, each a true relationship (ADR 0001).**
  Melting a metre of rock costs the same energy at any speed, so many times the speed is at least as many times the power; compact fusion supplies it, and it takes the Reactor's whole output, so Navigation is starved.
  No survey: there is no Column, so nothing is recorded and no feature of interest is seen.
  Deaf: the jet drowns every pulse, so the vessel knows only the rock it scanned before setting off.
  Nearly straight: the turning circle grows with speed.
  Heat rises modestly: the jet carries most of it out, as a rocket's exhaust does, but the Column is gone as a sink.
- **It needs no fourth impossible thing** so long as those relationships hold.
- **Its tunnel (developer).**
  "I think it would look a bit like a tunnel of raw aluminum.
  Like lobe-like and lumpy."
  In porous rock the Glide leaves that open, lumpy tunnel.
  Rough walls scatter light, so the link runs at a reduced rate through a glided stretch (the developer's "80% quality vs 100% glass perfection", tuned in play), and a little less with each glided stretch behind.
  In dense rock the Glide seals the tunnel as the Crawl does: the melt has to go somewhere (ADR 0001), and the developer agreed.
- **Leaving it: the Head comes out at idle (developer).**
  "I would prefer to need to cold boot the head after a glide.
  The head can be on some low energy state after it comes out, like an idle engine.
  Then you use standby to set up the next correct wobble."
  Leaving the Glide lands the vessel halted with the Head at idle, the idle of Quiet Ship.
  It is not a Relight: no gamble and nothing drawn from the emergency store.
  The crew tunes STANDBY to the rock now round them, then R spins the Head up into the Crawl.
  Halted and idle is also the moment for a clean scan, and going back into the Glide needs no tuning.
  This overtakes round 1's "the Wobble is back at once".
- **Plan the Glide, do the Glide (developer: "that's a fun mechanic").**
  The crew can drop out at any time, and the Glide ends by itself at the edge of what the scan has shown; the Drive's screen shows the range left.
  A better scan before setting off buys a longer Glide, so the rhythm is scan, glide, stop, scan, then tune and crawl or glide again.
- **The words.**
  The long name is the Vapor Glide ("sounds cool, is kind of true"); tooling and the glossary say Glide, and the gripper drive is the Crawl.

## Calls and the time rate

- **Science does not stop the time rate (developer: "I didn't like being in fast travel and getting stopped to do science").**
  Only a call that puts the vessel at risk holds the time rate at 1: Boundary approaching, out of the Band, heat, starved, plasma lost, tunnel about to seal.
  A feature of interest chimes and lights the Bore Station's call light and leaves the time rate alone.
  A feature nobody observes is lost, as before, so speed against science is the crew's choice.
- **The Boundary call waits for a crew that is ready (developer).**
  "Boundary approaching is way too early if I'm tuned ahead; if I'm tuned into the band I only need a 30 second window."
  With STANDBY inside the Band against the scan's guess, the call stays quiet until about 30 seconds before the crossing; untuned, it calls early as before.

- **A master acknowledge (developer: "all alarms need a master acknowledge lol. So annoying after a time").**
  One key, anywhere, silences every call now sounding; the call lights stay lit, and an acknowledged call sounds again only if its reason changes or it grows more urgent.
  Real basis: an airliner's master caution reset.
  Any warning still drops the time rate to 1 ("don't change that").

## The scan: two tools, a survey to start from, and targets

- **Two tools at Navigation, overtaking round 1's three patterns.**
  The developer: "the tighter the forward cone, the further it can go? Or maybe you have two tools: a general scanner and a forward scanner?"
  The Beam is for the way ahead, in three widths: wide and short, middle, narrow and long.
  Real basis: a phased sonar array; the same energy over a smaller angle travels further.
  A switch pulses the Beam on a steady interval (developer: "I would like the pulse to periodically auto pulse"); pulses under way stay noisy, so Quiet Ship remains the skilled act.
- **The Sweep is for prospecting (developer).**
  "Make it function like the forward in a 360 slice sweep, that then changes the orientation and does another 360 slice sweep.
  I eventually need to prospect and it needs to seem like an ultrasound."
  A narrow beam turns a full circle to draw one slice, the slice tilts, and it draws the next, building a volume slice by slice; slow, shown as slices, best at Quiet Ship.
  Real basis: medical ultrasound and sector-scanning sonar build a picture from one steered beam.
- **Everything is three-dimensional (developer: "this will ultimately be 3d, so always consider that with all these scans").**
  Slices, targets and Boundaries have a place in space, never only a depth.
- **Boundaries are flat but a little wavy (developer).**
  Real basis: bedding planes are laid down flat and then gently folded and tilted.
- **The dive starts with surface control's survey in the scan.**
  The large Boundaries at rough depths, faint and low in confidence, drawn apart from the vessel's own points; the dive sharpens it, and it gives the Glide its first range.
  Real basis: nobody drills blind; seismic and gravity surveys from the surface come first.
- **The Orders name targets.**
  The surface's survey sees an anomaly it cannot identify and gives its place with a wide error; the Sweep narrows it, and passing it through the Bore as Column identifies it and pays.
  The loop: glide toward the target, stop, sweep, crawl through it.

## Triage of round 3's design questions

- **#89:** surface control says the turn for home deepens before it rises, when the vessel starts turning toward a plotted climb while still diving.
- **#90:** left as it is; a Station rarely pulling away from a crew member on foot is cost enough, until a play test says otherwise.
- **#92:** a Station's tint stays on its call light and gimbal bob, objects in the room, and leaves the Checklist's Station names, which are readings.
- **#93:** the forward scope's range steps to the nearest Inferred Boundary ahead, changing only on a pulse; world-up is left as it is so the pick is fair.
  The developer added that a tighter forward cone should reach further, or that there be two tools, a general scanner and a forward one (round 2).
- **#91:** a heading while vertical is the way the vessel leans when it starts to tilt (developer: "it's the way you will go when you start a tilt"; "Kerbal's nav ball likely understands what we're doing pretty well").
  While vertical, J and L turn a lean marker and the next pitch nudge tilts toward it; the vessel keeps its own gyro reference where a compass heading means nothing, as a ball attitude display shows at its pole.

## Round 3: how the Glide is flown, the Sweep's shape, and when it is built

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
  Whether the Drive's autopilot may hold it, loosely, is the last open question.
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
