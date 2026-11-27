# The Glide, calls and the scan

Grilled with the developer on 27 November 2026, after round 3 (spec #71) merged to `dev`.
Nothing here is built; tickets follow once the grilling is done.
Round 2's questions (leaving the Glide, its tunnel, the master acknowledge, the two scan tools, the surface's survey, targets, the words) are still open and are added below as they settle.

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
- **Not sealing behind (developer).**
  "I think it would look a bit like a tunnel of raw aluminum.
  Like lobe-like and lumpy."
  How that squares with dense rock, where the melt has nowhere to go, is open in round 2.

## Calls and the time rate

- **Science does not stop the time rate (developer: "I didn't like being in fast travel and getting stopped to do science").**
  Only a call that puts the vessel at risk holds the time rate at 1: Boundary approaching, out of the Band, heat, starved, plasma lost, tunnel about to seal.
  A feature of interest chimes and lights the Bore Station's call light and leaves the time rate alone.
  A feature nobody observes is lost, as before, so speed against science is the crew's choice.
- **The Boundary call waits for a crew that is ready (developer).**
  "Boundary approaching is way too early if I'm tuned ahead; if I'm tuned into the band I only need a 30 second window."
  With STANDBY inside the Band against the scan's guess, the call stays quiet until about 30 seconds before the crossing; untuned, it calls early as before.

## Triage of round 3's design questions

- **#89:** surface control says the turn for home deepens before it rises, when the vessel starts turning toward a plotted climb while still diving.
- **#90:** left as it is; a Station rarely pulling away from a crew member on foot is cost enough, until a play test says otherwise.
- **#92:** a Station's tint stays on its call light and gimbal bob, objects in the room, and leaves the Checklist's Station names, which are readings.
- **#93:** the forward scope's range steps to the nearest Inferred Boundary ahead, changing only on a pulse; world-up is left as it is so the pick is fair.
  The developer added that a tighter forward cone should reach further, or that there be two tools, a general scanner and a forward one (round 2).
- **#91:** the developer sees a use for a heading while vertical: "it's the way you will go when you start a tilt" (round 2).
