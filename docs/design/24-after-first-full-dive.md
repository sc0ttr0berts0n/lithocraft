# After the first full dive

The grill on the play test of 28 November 2026 (`docs/playtests/2026-11-28-first-full-dive.md`), in rounds, with the developer.
Finding numbers are the write-up's.


## Round 1 (28 November 2026)

### Decided

- **Steps keep ticking on deeds, and each step names the deed it waits for** (findings 1, 2): "Switch on the Beam's own pulsing" says it waits for the Beam to cover its 15 m, "Narrow the Beam" says to pulse, and Navigation shows "next pulse in N m" while the Beam pulses by itself.
  No manual tick: the developer's wish for a bypass was to finish the play test, and messaging and diagnosing did that.
- **STANDBY's guess is drawn, not printed** (findings 3, 24): the guessed Wobble as a fuzzy trace whose width is how sure the guess is, matched by eye, with tuning steps finer than the guess resolves.
  Real basis: a spectral estimate from noisy data is a peak with a spread that narrows as data comes in.
- **The predicted Residual is shown as odds, not a verdict** (finding 4): the spread of Residuals the rock could give, against the Band, so a doubtful guess straddles the Band's edge; the word BAND only once the guess is sure.
- **The Glide is not gated by the scan's Boundaries** (finding 22): the developer chose play over the reflection rule, wanting to glide some 5 km, further with upgrades.
  "Someday the system may find us travelling into the Earth's core … can you imagine the tedium": the core's top is about 2,900 km down, some 64 hours at today's Glide speed.
  The reflection system itself stays, as the scan; what a Glide's reach is instead is round 2's.
- **The scan colours the rock between Boundaries by inferred density** (findings 14, 23; the developer's pool-pH-strip idea): one palette shared with Navigation's ground report, and on hover the rocks that density could be, ranked by how likely each is at that depth.
  Real basis: reflection times give each layer's sound speed (the Dix interval velocity), and sound speed gives density (Gardner's rule, density about as speed to the quarter power).
  It replaces "Beyond: MUCH HARDER, DENSER".
- **The Shift has a window, about 0.25 s, for now** (finding 6): a Shift within it of the crossing is on time, and "Shift into the sand" ticks on any clean Shift in it.
  The developer's number; the Head's crossing time was the agent's offer.
- **Planned low power is a calm, intended power-down** (finding 8): at Quiet Ship and in the idle after a Glide, the non-essentials shed first (the lights dim, the movement machinery goes), the pulse is taken, then the systems come back up.
  Shown in a cooling blue for safe, expected low power, never the alarm; aviate, navigate, communicate is the order of what is kept.
- **Upload is a transmission, all or nothing** (finding 21; the developer's speed-test idea): Comms shows the data to send, what is sent and the rate, and a record pays only when it has all gone; a cut link loses the whole transmission.
  The Tunnel sealing warning stays as it is: it says this is the last chance for a fast transmission.
- **The fibre line is parked** as a later upgrade (see `not-yet-designed.md`).
- **Observing a feature is done by hand from the Arm** (the developer's idea): find it in the Column, click to lock on, and ride along the Bore with it, with a Drive halt at the Bore Station; the F key no longer observes.
  Facing the Column, A and D carry the Arm round it and W and S along it, always up toward the Head or the Tail as gravity has it; with gravity square across the Bore, it keeps the last way it had.
- **Stations become a pair of panels folding out from the Habitat ring** (finding 10): readings on the left, the selected detail on the right (the Sweep's target zoomed, finding 17), clicked from the Arm, keys kept as shortcuts.
  The developer: in the end more like a scientific instrument than a panel; this is a step toward that.
- **The Drive is entered, not ridden past** (findings 12, 18): from the Arm the crew glances at the Drive; a key takes them into its seat (the Cockpit, round 2), where W and S pitch, A and D yaw, Q and E roll.
  "You arm over for a quick glance, but hop in the cockpit for a more thorough drive." The Beam's aim keys are named beam pitch and beam roll.

### The agent's own calls, reported

- Hold-to-repeat on tuning keys (finding 7); a mouse sensitivity setting (20); M undoes the Glide plot (13); the forward scope's labels kept off its data (11); labelled axes on the Bore Station's density plot (16); the Column's flicker fixed (15); the surface drawn on Navigation (19).
- Finding 5 is a bug: a Glide started from the Crawl recorded the rock it began in as no Wobble at full confidence, because the Wobble on the plasma was read after the Glide had begun; the Glide crossed no Boundary, so the idle Head was left with that zero guess.
- Finding 6 is a bug as well as a window: the Shift is applied before the Head moves in a step, and steps tick strictly in order, so a Shift on the count before the crossing never counted.

### The developer's new idea

- **Windows fore and aft**, to see the material coming in, going out, and the tokamak. Taken into round 2.


## Round 2 (28 November 2026)

### Decided

- **A Glide's reach is set by heat, tuned to about 5 km**: the melt jet soaks heat into the Head faster than Thermal sheds it, so a Glide runs until the Head must stop and cool; better cooling and hull grade carry it further.
  The scan no longer gates a Glide; it decides what is known of where the Glide stops, and past what the scan shows STANDBY's guess for that rock is unsure. A climbing Glide still stops 20 m below the surface.
- **The panels are found by a throwaway browser prototype**, the Reactor's first: its pair of panels at true scale, in variants side by side, on made-up but physically shaped data, the guess as a fuzzy trace and the Residual as odds.
  The chosen variant's geometry and feel carry over to Godot, as the Habitat prototype's did; its code does not.
- **Quiet Ship powers down in order, and the Arm never stops**: the Fabricator first, then the Habitat lights dim to blue, then the Bore Station shutters, then Comms holds a transmission paused (only a cut link loses one); the Reactor at idle, Thermal, Navigation and the Arm stay on, and it comes back up in reverse.
  The developer: think of Elite's power priorities; Quiet Ship is the lowest power for a clean blast.
- **Quiet is never silence** (the developer's idea): simulated well, a Quiet Ship's noise is as low as the running systems allow, never zero, and a better pulse module hears cleanly through a louder ship.
  Real basis: a sonar's detection is signal against the noise floor, and a better receiver needs less margin over it.
- **The windows are bigger than realistic, and their shutters have three stages** (the developer's stress): wide open in shallow rock, down to an observation level deeper, and shut at Quiet Ship and in emergencies. *The depth stages are overtaken by round 3: a free picture.*
  The front window looks into the Head, its plasma ring and the Column coming in; the back one onto the Tail, melt and exhaust leaving; the plasma's glow flickers with the Residual, so a glance tells the tuning.
  Real basis: tokamaks are watched through fused-silica and sapphire viewports behind shutters, since vapour coats them; heat radiated through a window grows steeply with the rock's temperature, which is why deeper wants it closed.
- **The Shift's window is derived by a system, tuned so about 0.25 s is reasonable**, not a bare constant; which system is round 3's.
- **The Cockpit is the Drive's seat, the only one for now**: F takes the crew into it and F or Esc out to the Arm; in it W and S pitch, A and D yaw, Q and E roll.
  It always faces the Head, whatever down is; the Arm carries the crew to it in awkward attitudes. "Cockpit" is the developer's word, so the Habitat no longer lists it to avoid.


## Round 3 (28 November 2026)

### Decided

- **Power has priorities, Elite's way, as a model only for now**: every system has a priority from 1 to 5; when power runs short the lowest sheds first, and Quiet Ship sheds down to priority 1; the same order serves a real shortage.
  Defaults: 1 the Reactor at idle, Thermal, Navigation and the Arm; 2 Comms; 3 the Bore Station; 4 the Habitat lights; 5 the Fabricator. The crew's screen to reorder them waits.
- **The ship's noise is the sum of what runs**, a moving Head by far the loudest, and a pulse's clarity is its echo against that floor; a better pulse module needs less margin over it.
  So keeping a system up through Quiet Ship costs a noisier pulse. Real basis: sonar detection is signal over the noise floor.
- **The Shift's window is the plasma's energy confinement time**, tuned to about 0.25 s: how long the plasma's stored heat rides out a mismatched Counter-wave before the mismatch takes hold.
  A worn Head shortens it, as it narrows the Band, and an upgrade lengthens it. Real basis: tokamak confinement times run from a tenth of a second to a few seconds, longer in bigger plasmas.
  The Head's crossing time was rejected: minutes at a Crawl and nothing at speed.
- **The windows are a free picture** (the developer, overtaking round 2's depth stages): the Habitat's air handling can almost always vent their heat, so the shutters close only in their prescribed moments, Quiet Ship and emergencies, and never cost heat. *Overtaken: they stay open at Quiet Ship too, closing only in emergencies (25).*
  Radiation, not yet modelled, might one day drive them too.
- **A Glide's heat limit is plotted, and only heat does damage**: Navigation's plot is capped at the reach heat allows, and Thermal shows the Glide's heat climbing.
  A drop out the crew chooses is a planned stop, safe though not plotted; one forced at the heat limit costs no more than what the heat itself has done to the ship (round 4).
- **Past what the scan shows, the only cost for now is an unsure guess**: the crew pulses and tunes STANDBY at idle before the Shift; hazards in a Glide stay parked.
- **The Cockpit sits at the front window**, facing the Head: the crew drives with the plasma ring and the Column funnelling through the tokamak into the Bore in view, its glow flickering with the Residual.
