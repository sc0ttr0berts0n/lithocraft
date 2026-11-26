# Teaching the dive

Grilled with the developer on 25 November 2026, after the first play test (`docs/playtests/2026-11-25-first-dive.md`): every system was found, but the player never knew the goal, the first step, or what the readings mean.

- **Scenarios with procedure checklists (developer's idea).**
  The dive is taught by checklists, not a tutorial overlay: an ordered list of steps that tick themselves off when the simulation sees each one done, shown in the Habitat, never as a floating marker.
  The developer widened it: "sounds like we need a set of scenarios with procedure checklists."
  Real basis: submarines, aircraft and launch crews run every phase from checklists; the design already calls an ascent a procedure.
- **Goals, done and not yet done.**
  A dive opens with its orders: the target (into the granite and back) and how pay works.
  They stay readable all dive as a set of goals, each shown as achieved or not yet.
- **The orders come from surface control over the link.**
  Text only for now.
  They slow to a trickle once sealed in, as the link does, so the voice goes quiet when the crew are deepest.
  Real basis: light down an open glass-lined tunnel is high bandwidth; sound through sealed rock is a trickle (see Comms).
- **Autopilot is a switch, A320 style (developer's idea).**
  Replaces "an unattended Station runs its autopilot".
  Each Station's autopilot is engaged by a switch, and any crew action at that Station disengages it, as an Airbus's autopilot disconnects when the pilot moves the sidestick.
  Real basis: A320 autopilot and autothrust are engaged by pushbutton and disconnect on pilot input, with a distinct warning so the crew knows they now have control.
- **An explainer on anything (developer's idea).**
  Middle-clicking a reading opens a widget that explains it: what it is, what it means now, and what it asks of the crew.
  This replaces a manual or a help key.
- **A Shift can't be done blind.**
  The Reactor screen shows how close the tuning matches the plasma's wobble.
  The Boundary-approaching call sends the crew to the Reactor ahead of time to get the dial ready.
  The first Boundary of the first dive is tuned so one poor Shift on a fresh Head grinds but does not lose the plasma (ADR 0001: the relationship stands, the constant is set for play).
  *Superseded in part by "The Reactor cancels the rock's wobble" (After the second checkpoint): the screen shows the Residual against the Band, not a match.*
- **Three scenarios, from a start menu.**
  First dive (the whole dive from the surface), a Shift drill (sand, a short way above the sandstone, Reactor checklist only), and Stranded in the granite (Head dark, sealed in, the clock running: relight, the link, cooling, rescue).
  Drills put the parts a cold player never reaches in front of them.
- **The checklist is an overlay panel** on an easy-to-reach key.
  It shows the goals (done or not), the current phase's steps with the next one highlighted and its Station named, and surface messages at its foot.
- **The first dive's phases:** startup (orders, engage the autopilots, plot the Course), sand (pulse, Quiet Ship scan, observe a feature), the first Boundary (ready the dial, Shift), sandstone, granite (the tunnel seals: upload while the bandwidth lasts), turn and climb, surface (paid).
  The developer: "you're teaching me … we'll review if not."
- **No Comms Station yet.**
  The link stays at the Bore Station, as long as everything comms needs is covered there; surface messages show in the checklist panel.
  To revisit when radio and laser modes arrive.
- **The autopilot in detail.**
  One key engages it and again disengages it.
  Any command that changes a setting at that Station disengages it; taking a reading (a pulse, observing a feature) does not.
  Disengaging plays a distinct tone at the Station and the screen shows AUTOPILOT OFF.
  A Station with the autopilot off and nobody there holds its setting and does nothing more; its calls still come.
  Every autopilot starts off, and engaging them is a startup step.
  The Drive's autopilot follows the Course at slow, safe power, so a plotted Course gets the vessel moving once the Drive's autopilot is on.
- **Pointing.**
  With mouse look (in the Arm too), a centre dot marks what the crew is looking at; middle-clicking a reading opens its explainer beside the screen in three lines: what it is, what it reads now, what it asks.
  Opening one drops the time rate to 1 without pausing.
  The first step toward clicking.
- **Screens stay clean.**
  No permanent explanation lines; a calling Station says what its call wants, and the explainer covers the rest.
- **Power reads as set point against actual** ("are you trying to tell me that it's about the set point versus actual?"): each Station's draw is shown as what it asked for against what the Reactor supplied, as a share of Reactor output.
- **The point cloud is head-up.**
  The Lithocraft is fixed at the centre, Head up the screen, and the display never turns on its own.
  The Course is drawn ahead, and points stream toward the marker as the vessel advances.
  *Superseded by "The point cloud needs a visual redesign" (After the second checkpoint): head-up is one view being replaced, chosen from three candidates.*
- **Points are limited and fade.**
  A fixed number of points; a newer return from the same place replaces the older one, and points fade with age (an old echo describes rock the vessel has since moved relative to).
- **Inferred topology (developer's idea).**
  "It would be cool if topology would be inferred and better visualized as a result of the points, and then as the craft moved, that topology would animate."
  Real basis: multibeam sonar surveys build seabed surfaces by fitting them to point soundings, and the confidence of each patch follows how many soundings support it.
- **Driving needs real-time feedback, "somewhere between Elite Dangerous and Microsoft Flight Simulator" (developer).**
  Controlling without seeing what you control was not enough; the crew needs a map and the instruments Elite shows when driving.
  Real basis: an airliner's primary flight display (attitude, speed and altitude tapes, heading with a selected-course bug) and navigation display (a moving map).
- **Power wording:** "Power: set 8% · actual 3%: starved"; "starved" when the actual falls short.
- **Keys:** Tab opens and closes the checklist; E engages and disengages the autopilot at every Station.
- **The switch alone decides whether a Station's autopilot runs.**
  Being at a Station matters only because commands are given there; a crew member can stand and watch an autopilot work.
- **Topology is honest.**
  Surfaces are fitted only to returned points, never read from the real layout; a patch's opacity follows how many points support it; surfaces stream past as the vessel moves and fade with their points.
  Boundaries between Media only this iteration; hazards once hazards exist.
- **The Drive is a primary flight display** (the developer: an "enthusiastic yes"): attitude indicator, speed tape, a depth tape where altitude goes, a heading tape with the Course bug, power set against actual, grip and slip.
- **Navigation has a moving map** beside the point cloud: a side-on cross-section of the whole dive (depth against distance) with the surface, the path behind (a perfect record), the Course ahead, Boundaries as inferred, and the orders' target depth.
- **No HUD.**
  Instruments live on the Station screens; the checklist is the only overlay.
- **Iterations.**
  The developer sets the parameters (one playable build per iteration, no tweaks in between) and leaves the process to the agents.
- **Play tests** are played cold, narrated and screen-recorded (the developer uses NVIDIA ShadowPlay); frames are pulled at the stuck moments and reviewed together.
  First dive first, then the drills.
- **Habitat layout.**
  Every Station faces inward to the Bore, and the Drive sits beside Navigation.
- **Small fixes taken as stated:** the cut-off Thermal text, and the end-of-dive shake becomes a lurch that settles into the still outcome screen.
  Clicking widgets, levers and knobs stays for later.
- **Every dive ends on a still screen that names the outcome** (surfaced, rescued, or dead and why) in a sentence before the payment breakdown.
  The play test's "we're dead" was the developer's "dead in the water", said in fun, not a misreading; the plain outcome line is still wanted.
