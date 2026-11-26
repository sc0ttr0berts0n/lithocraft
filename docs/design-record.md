# Design record: the Lithocraft and how it travels

A record of the first design session (24 November 2026). It holds the decisions, the reasons behind them, the ideas that were raised but not yet designed, and the real science each idea leans on. Vocabulary follows `GLOSSARY.md`. The first playable slice is specified separately in GitHub issue #1 (Spec: First dive), with its tickets as sub-issues; this document is wider than that spec and is the place to look for anything the spec left out.

## The original vision

In the developer's words, lightly condensed:

- A 3D Godot game, similar in feel to operating a spaceship in Elite Dangerous: complicated simulated systems. Also like Iron Nest, and to an extent Uncle Chop's Rocket Shop.
- The Lithocraft works a bit like the Dune worm. It is a long ring, somewhere between a torus and a straw, with a glass cylinder in the middle where you observe the material it is travelling through.
- It can fly through rock and through air. It will penetrate the Moon, and Jupiter's cloud tops and core. It can reach space somehow. Hard science fiction.
- You start in loose soil like a desert and work your way through stronger rock. You manage heat, pressure and rock hardness.
- Open question at the start: a cockpit, or a place like a submarine where you walk around the ring? Spin-stabilised in space could be interesting, with a console that rotates and adapts.
- "I see it being something of a mining game."

## Lore

Fusion energy. We thought its best perk was limitless energy. But it also unlocked a form of travel where you can simply cut through anything, and direct magnetism to shape rocketry. Guiding plasmas turned out to have a surprising amount of industrial application.

This lore does structural work: it explains why one reactor is the cutter, the rocket nozzle, the refinery and the fabricator's toolhead.

## Ground rules

Recorded in `docs/adr/0001-science-ground-rules.md`.

- Three permitted impossible things: compact fusion, the hull material, and warp. As few concessions as possible.
- Every relationship is physically true (more speed needs more power, more power makes more heat, deeper means more pressure). Constants are tuned for play. "We'll decide what's fast and slow by gameplay."
- Why: Jupiter's core is tens of megabars and about 20,000 K, beyond any real material. Melting a 12 m tunnel costs roughly 300 gigajoules per metre, so at 1 m/s that is 300 gigawatts, and a trip through the Moon would take about 40 days. Real numbers would rule out the destinations and dictate the pacing.
- Hull grade is the progression that gates depth.
- Warp (an Alcubierre-style drive enabled by the tokamak) is the answer for travel between planets. It is not designed yet and is not needed until the game leaves the Earth–Moon system. The fusion rocket only has to handle launch and orbit.

## The vessel

- **Shape.** A straw in three sections: Head, Habitat, Tail. The Bore runs through all three.
- **The Head is the tokamak.** A tokamak is already a ring with a hole through the middle, so the reactor's shape is the vessel's shape and the Bore passes through the hole. The developer's idea was that the tokamak is the heated cutting end and that its magnetism keeps high heat off the inside.
- **Honest limits on the magnetism.** Magnets do nothing to cold rock. They act only on things that conduct: molten rock, ionised gas and the plasma itself. Fusion heat mostly arrives as radiation absorbed in the structure and must be carried to the cutting rim. Magnetic fields therefore have three jobs: confine the plasma, pump molten rock outward, and form the exhaust nozzle.
- **The Bore.** About 1.5 m across ("we can change as needed"). The Column sliding through it is the game's signature image and the crew's main instrument. "That's the gimmick."
- **Coring is not an energy saving.** With a 1.5 m Column inside a ring perhaps 12 m across, the Column is under 2% of the cross-section. Nearly all the rock is still removed. Coring is kept for what it shows, not what it saves.
- **Single Head, no reverse.** To come back up the vessel steers a wide arc by heating one side of the rim harder. A turning circle of hundreds of metres makes route planning a real decision. A second Head at the Tail was considered and not chosen.

## One principle for every Medium

The Lithocraft is a reactor wrapped around a duct, and whatever is in the duct gets heated.

- **Rock.** Melted, and the melt pressed into the tunnel wall as a glass lining. Real precedent: the Los Alamos "subterrene" of the 1970s.
- **Air.** Heated and expelled as a nuclear ramjet. Real precedent: Project Pluto.
- **Vacuum.** Stored propellant fed through and heated, as a nuclear thermal rocket.
- **Gas giant.** The same ramjet, breathing hydrogen.

This answers how a vessel optimised for rock reaches space, and it makes the ring shape necessary instead of decorative. Three separate drive systems were the alternative and were rejected.

**Ascent to orbit, in three steps.** Leave the ground on stored propellant heated by the Head; switch to breathing air through the Bore once moving fast enough; return to stored propellant above the atmosphere. Water is the propellant, taken from ice or wet rock, so a dive also has to bring back enough water to leave.

## Moving through rock

- **Worm drive.** Gripper pads clamp the tunnel wall and move in travelling waves down the hull, so the vessel crawls like the Dune worm. Alternatives considered: weight alone (only works going down) and thrust from squirting melt backward.
- **Materials decide efficiency.** Grip depends on rock strength. Hard rock grips well but cuts slowly; loose sand cuts easily but gives nothing to push against. The developer liked materials driving how efficient the system is, "or if it's needed at all" — in some Mediums the grippers may be unnecessary.
- **Where the melt goes.** Porous rock absorbs it as lining and leaves an open tunnel. Dense rock has no pore space, so the melt is pumped aft and fills the tunnel. Shallow, you leave a retreat path. Deep, you seal yourself in, and the player watches that transition approach. At depth the rock also creeps shut on its own, like a submarine below crush depth.
- **A Medium is seven properties.** Hardness (cost to cut), strength (grip available), porosity (open tunnel or sealed), temperature, pressure, composition (Feedstock yield and survey value), and how well it carries sound (sensing and comms range). Every system reads the same seven. Air and vacuum are the same list with most values near zero. The developer's reaction: "this sounds extensible."
- **Honest speeds with time acceleration.** Around a metre per second in hard rock, much faster in sand, air and space, with Kerbal-style time warp that drops out when something needs attention. Power sets speed; heat limits power.

## Heat

- Underground there is nowhere to radiate heat. The only sinks are the melt, the surrounding rock and the Column. In space you radiate. Heat is the central resource in every Medium.
- **The key dilemma.** Heat can go outside and hurt the vessel, or inside and hurt the Column. Cooking the Column may be the best decision for mobility while ruining much of what the dive is trying to acquire. Income and survival sit on the same dial.

## Comms

The developer's idea: treat the tunnel like fibre optics, or use sonar, switching comm modes depending on the material.

- **Open glass-lined tunnel:** light down the tunnel, high bandwidth.
- **Sealed in rock:** sound through the rock, a trickle.
- **Air or space:** radio or laser.
- **Bandwidth decides when you get paid.** Survey data sells only once uploaded. Sealed in, you carry unsold data home or dribble it out and choose what goes first.

## Seeing ahead

- The Column shows only what the vessel is already inside. Looking forward needs instruments: sound pulses for structure, gravity readings for density, heat readings for magma.
- The picture ahead is fuzzy and interpreted; the record behind is perfect. Hazards (voids, water, gas pockets, magma, faults) appear as ambiguous readings the navigator must judge. The Column confirms or refutes the guess seconds later.
- **Display.** An accumulating 3D point cloud at the Navigation Station, with Scanner Sombre as the visual reference. Points are sparse and coloured by confidence, sharpening with proximity or repeated pulses.
- **Quiet Ship.** For a clean scan the vessel halts, the Head idles and the Bore instruments shutter, because the vessel's own cutting noise drowns the echo. A pulse taken under way is noisy. The developer suggested a safety procedure that blinds other systems during a scan; this is that procedure with a physical reason.
- **No outside camera underground.** The only views are the Habitat, the instruments and the Bore ("but the Column will scroll by"). This keeps the submarine feeling, and it means the planet underground never has to be built as 3D terrain, only described as which Medium is at each point. This is the largest single saving in the design.

## The Habitat and the crew

- **Walkable**, not a cockpit. Small: one ring, six Stations.
- **"Down" is whatever the real acceleration is.** Diving, it points at the Head. Under thrust, at the Tail. Spinning in space, outward at the hull. Level, at the bottom of the outer wall. Stations hang on gimbals. The developer's rotating console becomes the rule for the whole interior.
- **Six Stations:** Reactor, Drive, Thermal, Navigation, Bore Station, Fabricator. Each maps to one design decision; none exists only to fill a seat.
- **Crew of one to four.** The developer felt multiplayer from the start makes sense, and asked how to keep a full crew busy while still playing well alone. The answer: each Station has an autopilot that is safe but mediocre, and a human there gets more out of it. Solo, you move between Stations and choose which deserves you. A full crew is busy because every Station rewards attention.
- **Build order.** The simulation is kept separate from the view from day one so networking can be added without a rewrite, but solo play is made fun first.
- **Conflicts come from three shared budgets.** Power (the Reactor supplies; everything else draws), heat (everything makes it; Thermal decides who suffers) and the Column (Thermal wants to cook it; the Bore Station wants it pristine). No conflicts are scripted. The developer is interested in conflicts between Stations being something to manage.
- **Calling for attention.** Signals inside the vessel only. Each Station has its own tone and light, and because the Habitat is a ring you can hear the direction. Urgency is in pitch and tempo. No floating markers. The developer stressed that a Station needing a human must be telegraphed well.
- **Systems management, not stick flying.** You set heading, power, grip and heat routing and the vessel responds slowly. An ascent is a procedure, not joystick flying. One control style covers every Medium.
- **Navigation plots, the Drive steers (25 November 2026).** Navigation sets the Course (a target heading and pitch) on the point cloud, where the Medium ahead is seen. The Drive steers toward it: how hard to turn, and so how much power and heat to spend, is the Drive's call, and it can override. An unattended Drive follows the Course at a safe, slow turn rate. Chosen over heading on the Drive alone (Navigation was passive) and heading on Navigation alone (steering's power and heat cost belongs with the Drive). Real precedent: a ship's navigator plots the course and the helmsman steers it.

## The plasma and the Shift

- The plasma is the one thing that cannot be ignored. Harder rock loads the Head; a sudden void unloads it. Either can destabilise the plasma.
- Crossing a Boundary requires a Shift: retuning the plasma for the new load within a window. The developer's image: "like poorly shifting gears."
- A clean Shift is smooth. A bad one grinds: a heat spike, a lurch, wear on the Head. Several bad Shifts in a row, or one at the wrong depth, loses the plasma.
- The Reactor autopilot holds steady conditions but handles sudden changes badly, so Boundaries are where a human is needed. This gives the game its rhythm: calm stretches, tense Boundaries.

## Waves as the common language

- The developer wants to do something with Fourier ideas: lining up sine waves to make other shapes, for molecular synthesis.
- **Real science behind it.** Each kind of ion circles a magnetic field at its own frequency, so one element can be picked out by tuning to it. Chemists already steer reactions with light pulses built by adding chosen frequencies. Sorting a plasma into its elements with magnetic fields is a real proposed technique.
- **Fabrication as wave-building.** Each thing you can make has a target waveform. You pick Feedstocks by tuning to their frequencies, then stack and adjust sine waves until the sum matches the target. A closer match gives a better part; a sloppy match gives a part that works but wears out sooner. Skill produces quality, not pass or fail, so a rushed repair in a crisis is possible but costs later.
- **Every Station speaks in waves.** The Reactor's plasma wobbles in modes you cancel with opposing waves. Navigation's scan is pulses and echoes. The Fabricator stacks sines. The Bore Station reads composition as spectral lines. One skill learned once applies everywhere, and the displays share a look.

## Feedstock and fabrication

- The developer's idea: grabbing atoms and molecules like printer ink to synthesise things.
- The Head is also the refinery. Some of the melt is ionised and magnetically sorted by element into Feedstock: iron, silicon, carbon, water and so on.
- What a part costs is a recipe of elements, so the rock you are in decides what you can repair right now. A basalt dive is rich in iron and poor in carbon.
- **Print versus buy.** Print consumables and replacement parts from Feedstock. Buy designs for new parts with survey money. Hull grades need both a bought design and deep materials you fetched yourself.
- **Repairs by hand.** Parts are physical objects in the Habitat that you pull, inspect and replace, as in Uncle Chop's Rocket Shop.

## Why you dive

The developer's question: what do you seek out as you dive into planets? "You need to seek out and obtain things and then cash them in."

- **Fuel.** Deuterium from ice, helium-3 from gas giants. Needed to keep moving.
- **Survey data.** The record of the Column is itself the product, sold to whoever wants to know what is down there. The developer especially liked surveying and selling data.
- **Deep materials.** Things that exist only at pressure, needed for the next hull grade.
- **The loop.** Go deeper, get materials, upgrade the hull, go deeper.
- **Mining is a by-product of travel.** Everything cut must become lining, propellant, heat sink, Feedstock or cargo, so "what do I do with this rock?" is asked every metre. Bulk ore hauling stays out; the vessel has little room for cargo.
- **The Column as a moving window.** You see a vein slide into the Bore and have only until it leaves the Tail to cut a piece out. Slowing down gives more time but costs heat and schedule.

## Failure

- Stranding is the usual failure: sealed in, plasma out, running on the emergency store. It is recoverable at a price (a rescue, a relight, a restart from the last port). It does not delete the save.
- Hull failure is death, with a rebuy; see the next section.

## Hull wear, death and rescue

Grilled with the developer on 25 November 2026. Before this, heat sent outward wore the hull but wear did nothing, so protecting the Column cost nothing (stories 19, 21 and 23 were hollow).

- **The developer's model is Elite Dangerous heat.** Zero hull is death; unmanaged heat brings hull damage, and how far over the limit sets how fast the hull declines. Telegraphing is juice, as in Elite near a star or under silent running.
- **Damage curve (Elite plus creep).** Below the hull's rated temperature, no damage. Above it, integrity falls at a rate set by how far over, multiplied by depth (pressure is the stress that drives creep). Real basis: creep is negligible below a material's temperature limit and accelerates steeply above it and with stress.
- **Lingering deep heats the hull.** Hot surrounding rock conducts heat in at any power, so careful means efficient, not slow. This answers the developer's worry that impatient players kill themselves: a careful dive is not a slow one. Better ships later make today's unviable depths and pressures reachable. In the first dive (2 km) the rock never wears an idle hull; lingering starts to bite on deeper dives, and the first dive teaches heat routing (confirmed by the developer).
- **Wear is permanent within a dive** and repaired at the surface. Surfacing deducts a repair bill proportional to wear, shown in the payment breakdown. Later the Fabricator may print hull patches, their quality set by the waveform match.
- **Telegraphing.** The hull groans as it creeps, louder and more often with wear and stress, heard around the ring. Sparks and screen shake while damage is actively happening. The Thermal screen shows wear and creep rate. No markers on the view.
- **Hull failure is death with an Elite-style rebuy.** All unsold data is lost and a rebuy is paid; the save is kept. The first dive has no saved money yet, so death ends the dive with the rebuy shown as a line in the breakdown, charged once a balance exists.
- **A worn Head.** No wear by running hours ("repair is repair"). A worn Head delivers less power, narrows the Shift window and grades it harsher, and at high wear a poor Shift can lose the plasma. Head repair is a line in the repair bill.
- **Losing the plasma loses main power.** The developer asked whether the Head, being the fusion generator, drops to a backup. Real basis: a tokamak cannot restart itself; striking a plasma takes a large pulse of stored energy from outside (JET drew its pulses from huge flywheel generators, not the grid).
- **One emergency store** (the developer loved this) is the backup power once the plasma is lost. Uploading survey data, cooling, and a relight all draw on it, so every choice while stranded spends the same store.
- **Relighting the Head.** The Reactor can try: it costs a big pulse from the store. Success ends the stranding and the dive goes on; failure spends the energy. A healthy Head almost always relights; the odds fall with Head wear.
- **Built (#26, 25 November 2026).** The store is full at the start of each dive and untouched while the plasma holds; a relight is a pulse of about two fifths of it, so the store buys two tries or an hour or so of the slow link, not both. Choices the implementation made, open to the developer:
  - A stranding keeps the survey aboard so the link can still send it on the store; the recovery (a stand-in for rescue until #21) loses what is left. Before, stranding lost it at once.
  - The Bore Station can stop the link (B), so the store can be saved for a relight.
  - A poor Shift on a badly worn Head can disrupt the plasma without wearing the Head through: the Head keeps only the wear that Shift did, and the relight rolls at that real wear (from about nine in ten on a fresh Head down to about two in five on one worn through). Wearing the Head through still loses the plasma. The Reactor screen shows the odds on the Head as it is. A clean Shift wears nothing, so even a relit Head worn through holds through clean ones and is lost again to any poor one.
  - Relight gets its own Reactor key (I), not R, so a Shift pressed as the plasma goes cannot spend the store.
  - While stranded the time rate may be raised although the Reactor calls: the crew wait on the link and the store.
- **The stranding clock (the developer's idea)** is the time to hull failure as heat from the surrounding rock soaks in with the Head dark. Its length depends on the rock's heat (depth), the hull's wear, and battery spent on cooling.
- **Rescue time** is a fast run down the open tunnel plus a slow cut through the sealed length behind the Lithocraft. The Thermal screen shows the clock as a live estimate beside the rescue time, so rescue or death can be read at a glance.
- **Rescue brings the data home.** Unsent data is lost only on death, so uploading is insurance for when the clock is shorter than the rescue time. Rescue costs a line in the payment breakdown, scaled by how long it took. It sits between a clean surfacing and a rebuy.
- **Built (#21, 25 November 2026).** Choices the implementation made, open to the developer:
  - What soaks in is the melt the Head left round the vessel and in the sealed tunnel behind, a fixed margin (about 300 K) above the surrounding rock. Real basis: a melt front sits near the rock's melting point, far hotter than the far rock, and with the Head dark no pumps carry its heat away. The rock alone (300 to 400 K in the first dive) is far below the hull's rated 600 K, so it could never fail the hull. Deeper, the rock is hotter and presses harder, so the clock is shorter; a worn hull has less left to lose. Confirmed by the developer: the melt is the source, and a shallow dive staying safe is just how it is.
  - The clock is worked out exactly from the same soak and creep rules the hull follows, so the time shown is the time the hull fails if nothing changes. In cool shallow rock it can be hours; in hot or deep rock, minutes.
  - Cooling is the Thermal Station's heat split (C / V), which while stranded sets how hard the pumps carry the soaked heat into the Column on the store. The pumps stop with the Head (the split drops to 0 at the stranding), so spending the store on cooling is the crew's choice, never automatic. No new key.
  - The rescue is called at the stranding and arrives on its own after the rescue time: a run down the open tunnel at about 5 m/s plus a cut through the sealed length at about 0.2 m/s, about 0.4 pay per second of it. Enter no longer calls a recovery; the crew can relight, wait (time can run fast while stranded), or die. In the first dive the tunnel seals only in granite, so a stranding a hundred metres into the granite is a near race and a deep one usually needs cooling or insurance.
  - The rescue bills the rescue line and the hull and Head repairs, as surfacing does, and sells everything aboard. **A dive's pay never goes below 0 (developer, 25 November 2026):** whatever the rescue and repairs cost beyond what the dive earned is "on us" when they save you. The game models no debt for no reason.
  - Once sealed in, the Thermal screen shows the clock and the rescue time as "if stranded" estimates while under way, so the crew can judge the risk before it happens.
- **Time pressures are tracked, not felt, in the first dive.** Fuel burned, the rock creeping shut, and a contract clock are measured and described but have no effect yet.
- **Self-destruct by overheating (developer's idea, 25 November 2026).** Asked whether a stranded crew should be able to give up, the developer chose agency over a skip button: "self destruct is at least cool and gives the player agency. overheating is the way to go."
  - **Self-destruct is the vessel mismanaging itself on purpose.** Under way, the in-system way to make immense heat already exists: the Reactor at full power with Thermal sending all heat outward. Self-destruct sets exactly that and takes the Stations off the crew. Stranded, with the Head dark, the only energy aboard is the emergency store, so self-destruct dumps it into the hull as heat (real basis: stored electrical energy discharged through a resistive load all becomes heat).
  - **It is armed by holding a key for three seconds**, with the groans rising while held. It is not a one-way door: the crew can cancel it while it runs, keeping whatever wear (or store) it has already spent.
  - **Death by self-destruct** is its own cause of death, named as such, with the same price as any death: unsent data lost and the rebuy line shown.
- **A numpad debug menu (developer's idea, 25 November 2026).** Numpad minus opens a visual debug menu that draws the rest of the numpad with what each key does written out. Anything useful for testing goes there (the developer: "anything you dream up goes there"), with F3's overlay folded in.
- **Keys are stated plainly on screen for now (25 November 2026).** Ultimately the Stations will be widgets, levers and knobs; until then each Station's screen clearly says which keys do what, using key prompt images from Xelu's free prompts (CC0, thoseawesomeguys.com/prompts). The added Station keys (relight, the link, cooling while stranded, fast time while stranded) stay ordinary crew controls; the debug menu holds only testing shortcuts.
- **Quiet Ship stands as designed.** The developer likes it: it halts and idles so the picture sharpens, at the cost of time and shuttered survey stretches.

## Scope and order

- One solar system: Earth desert, Moon, Jupiter.
- First playable slice: one Earth desert dive through sand, sandstone and granite and back. No space, no multiplayer, no warp. See the spec.
- The riskiest idea to build is the changing "down", so it was prototyped first.

## The Habitat prototype

On the `prototype/habitat-down` branch. A browser stand-in built with three.js because Godot was not installed on the machine used; the geometry and motion carry over, the code does not.

- Dive, level, spin and coast behaved as designed. Climb was not exercised.
- **Verdict on feel: optimistic, go ahead (second session, 24 November 2026).** Played on the PC with the arm added; the developer said "works great. i'm optimistic" and chose to move on. The Habitat stories in the spec stand as written.
- **Finding: spin gravity is weak and uneven at this size.** At 10 rpm, 0.37 g at the feet and 0.18 g at the head. A full 1 g at the floor needs about 16 rpm, which would be nauseating in reality.
- **Finding: level travel strands most Stations.** The floor is the bottom of a curved wall; only the lowest one or two Stations are reachable on foot. Possible answers: ladders or handholds, a larger radius, Stations that travel around the ring, or a Habitat that rolls.
- Dimensions used: Bore wall radius 0.8 m, outer wall radius 3.3 m, length 2.4 m, Stations pivoting 1.1 m above the outer wall. Starting values only.
- **Developer's idea (second session): an arm that catches you.** Press a dedicated button and a robot arm or chain swings in, catches you, and carries you between Stations with left and right. The developer's reason: "when the ship is in a strange orientation, you can still make it work." It answers the stranded-Stations finding for every "down", not just level, and keeps walking for when "down" is kind.
  - **Real precedent.** The ISS's Canadarm2 rides a mobile base along a rail on the truss and carries astronauts clamped to a foot restraint on its end. A carriage on a ring rail is the same arrangement, so it needs no concession under ADR 0001.
  - **Real cost.** Unlike in free fall, the arm has to hold a person against up to about 1 g on a lever of a metre or two. That takes a strong joint and power, so it draws on the power budget and can fail.
  - **Prototyped, not decided.** Added to the prototype on 24 November 2026: a carriage on a rail around the Bore, a chain with a claw that grips a harness between the shoulders, Space to call it or let go, A/D to move one Station left or right. Jump moved to J. It was exercised in level, dive and spin. The developer tried it: "works great. i'm optimistic." Confirmed as the method on 25 November 2026 (see the spec, issue #1); its cost in play is not designed.

## Play tests

- **First dive, 25 November 2026** (`docs/playtests/2026-11-25-first-dive.md`): every system was found, but the player never knew what to do. "I bet you this is fun if I knew what I was doing." Teaching the dive is the biggest gap; mouse look in the Arm is the top control fix.

## Teaching the dive

Grilled with the developer on 25 November 2026, after the first play test (`docs/playtests/2026-11-25-first-dive.md`): every system was found, but the player never knew the goal, the first step, or what the readings mean.

- **Scenarios with procedure checklists (developer's idea).** The dive is taught by checklists, not a tutorial overlay: an ordered list of steps that tick themselves off when the simulation sees each one done, shown in the Habitat, never as a floating marker. The developer widened it: "sounds like we need a set of scenarios with procedure checklists." Real basis: submarines, aircraft and launch crews run every phase from checklists; the design already calls an ascent a procedure.
- **Goals, done and not yet done.** A dive opens with its orders: the target (into the granite and back) and how pay works. They stay readable all dive as a set of goals, each shown as achieved or not yet.
- **The orders come from surface control over the link.** Text only for now. They slow to a trickle once sealed in, as the link does, so the voice goes quiet when the crew are deepest. Real basis: light down an open glass-lined tunnel is high bandwidth; sound through sealed rock is a trickle (see Comms).
- **Autopilot is a switch, A320 style (developer's idea).** Replaces "an unattended Station runs its autopilot". Each Station's autopilot is engaged by a switch, and any crew action at that Station disengages it, as an Airbus's autopilot disconnects when the pilot moves the sidestick. Real basis: A320 autopilot and autothrust are engaged by pushbutton and disconnect on pilot input, with a distinct warning so the crew knows they now have control.
- **An explainer on anything (developer's idea).** Middle-clicking a reading opens a widget that explains it: what it is, what it means now, and what it asks of the crew. This replaces a manual or a help key.
- **A Shift can't be done blind.** The Reactor screen shows how close the tuning matches the plasma's wobble. The Boundary-approaching call sends the crew to the Reactor ahead of time to get the dial ready. The first Boundary of the first dive is tuned so one poor Shift on a fresh Head grinds but does not lose the plasma (ADR 0001: the relationship stands, the constant is set for play).
- **Three scenarios, from a start menu.** First dive (the whole dive from the surface), a Shift drill (sand, a short way above the sandstone, Reactor checklist only), and Stranded in the granite (Head dark, sealed in, the clock running: relight, the link, cooling, rescue). Drills put the parts a cold player never reaches in front of them.
- **The checklist is an overlay panel** on an easy-to-reach key. It shows the goals (done or not), the current phase's steps with the next one highlighted and its Station named, and surface messages at its foot.
- **The first dive's phases:** startup (orders, engage the autopilots, plot the Course), sand (pulse, Quiet Ship scan, observe a feature), the first Boundary (ready the dial, Shift), sandstone, granite (the tunnel seals: upload while the bandwidth lasts), turn and climb, surface (paid). The developer: "you're teaching me … we'll review if not."
- **No Comms Station yet.** The link stays at the Bore Station, as long as everything comms needs is covered there; surface messages show in the checklist panel. To revisit when radio and laser modes arrive.
- **The autopilot in detail.** One key engages it and again disengages it. Any command that changes a setting at that Station disengages it; taking a reading (a pulse, observing a feature) does not. Disengaging plays a distinct tone at the Station and the screen shows AUTOPILOT OFF. A Station with the autopilot off and nobody there holds its setting and does nothing more; its calls still come. Every autopilot starts off, and engaging them is a startup step. The Drive's autopilot follows the Course at slow, safe power, so a plotted Course gets the vessel moving once the Drive's autopilot is on.
- **Pointing.** With mouse look (in the Arm too), a centre dot marks what the crew is looking at; middle-clicking a reading opens its explainer beside the screen in three lines: what it is, what it reads now, what it asks. Opening one drops the time rate to 1 without pausing. The first step toward clicking.
- **Screens stay clean.** No permanent explanation lines; a calling Station says what its call wants, and the explainer covers the rest.
- **Power reads as set point against actual** ("are you trying to tell me that it's about the set point versus actual?"): each Station's draw is shown as what it asked for against what the Reactor supplied, as a share of Reactor output.
- **The point cloud is head-up.** The Lithocraft is fixed at the centre, Head up the screen, and the display never turns on its own. The Course is drawn ahead, and points stream toward the marker as the vessel advances.
- **Points are limited and fade.** A fixed number of points; a newer return from the same place replaces the older one, and points fade with age (an old echo describes rock the vessel has since moved relative to).
- **Inferred topology (developer's idea).** "It would be cool if topology would be inferred and better visualized as a result of the points, and then as the craft moved, that topology would animate." Real basis: multibeam sonar surveys build seabed surfaces by fitting them to point soundings, and the confidence of each patch follows how many soundings support it.
- **Driving needs real-time feedback, "somewhere between Elite Dangerous and Microsoft Flight Simulator" (developer).** Controlling without seeing what you control was not enough; the crew needs a map and the instruments Elite shows when driving. Real basis: an airliner's primary flight display (attitude, speed and altitude tapes, heading with a selected-course bug) and navigation display (a moving map).
- **Power wording:** "Power: set 8% · actual 3%: starved"; "starved" when the actual falls short.
- **Keys:** Tab opens and closes the checklist; E engages and disengages the autopilot at every Station.
- **The switch alone decides whether a Station's autopilot runs.** Being at a Station matters only because commands are given there; a crew member can stand and watch an autopilot work.
- **How the Inferred Boundaries are fitted (ticket #40, agent's choices within the design).** The ground is gridded into square cells (16 m) and each cell's points are split into layers wherever a height gap opens (6 m), as multibeam surveys grid soundings into a height field; a plane is fitted to each layer by least squares, each point weighted by its confidence and the slope pulled gently toward level (a few bunched points barely tilt it; a cell full of them sets its own slope) (layered ground lies near level unless the points say otherwise). Three points at least make a surface: one or two are an echo. A patch covers only the ground its points span, never the rest of its cell. A patch's confidence is its points' summed confidence against a half-sure amount, so more points, or surer ones, make it surer; it is as old as its points on average and fades as they do. The patches are drawn as translucent green tiles among the points, opacity by confidence. Gridding the ground assumes Boundaries are more level than upright, true of every layout so far; a steep Boundary would want a 3D fit.
- **Topology is honest.** Surfaces are fitted only to returned points, never read from the real layout; a patch's opacity follows how many points support it; surfaces stream past as the vessel moves and fade with their points. Boundaries between Media only this iteration; hazards once hazards exist.
- **The Drive is a primary flight display** (the developer: an "enthusiastic yes"): attitude indicator, speed tape, a depth tape where altitude goes, a heading tape with the Course bug, power set against actual, grip and slip.
- **Navigation has a moving map** beside the point cloud: a side-on cross-section of the whole dive (depth against distance) with the surface, the path behind (a perfect record), the Course ahead, Boundaries as inferred, and the orders' target depth.
- **No HUD.** Instruments live on the Station screens; the checklist is the only overlay.
- **Iterations.** The developer sets the parameters (one playable build per iteration, no tweaks in between) and leaves the process to the agents.
- **Play tests** are played cold, narrated and screen-recorded (the developer uses NVIDIA ShadowPlay); frames are pulled at the stuck moments and reviewed together. First dive first, then the drills.
- **Habitat layout.** Every Station faces inward to the Bore, and the Drive sits beside Navigation.
- **Small fixes taken as stated:** the cut-off Thermal text, and the end-of-dive shake becomes a lurch that settles into the still outcome screen. Clicking widgets, levers and knobs stays for later.
- **How the Checklist behaves (ticket #34, agent's choices within the design).** Steps tick in order, and only the next one can tick, so a step done early is done again when asked for (a real checklist is read in order). One action ticks one step. A phase begins once the one before is finished, or early when the dive reaches it (a Boundary approaching, a Shift past one, a climbing Course plotted, surfacing); steps left behind show as missed rather than holding the crew back. Startup plots the Course before engaging the Drive's autopilot, so the vessel moves only once it has somewhere to go. A Shift the Reactor's autopilot makes does not tick the crew's Shift. Turning the Shift dial is a selector, like an A320's heading knob, so it does not disengage the Reactor's autopilot. Surface control's messages come down at the link's own rate: about a second up the open tunnel, minutes through sealed granite (ADR 0001: the ratio follows the link, the rate is tuned).
- **The drills and the start menu (ticket #35, agent's choices within the design).** The Shift drill starts 40 m above the sandstone, under way with the Drive's and Thermal's autopilots engaged and the Reactor's off, so the crew's only work is the Reactor; its one goal is a clean Shift into the sandstone, and the drill has no end of its own (dive on, or turn for home). Stranded in the granite starts 200 m into the granite, the Lithocraft having cut straight down from the surface with clean Shifts, the whole Column aboard; the Head is worn (0.8) as the poor Shifts that lost its plasma would leave it, so a relight is a gamble. The depth is set so the race is real: uncooled, the hull fails just before the rescue cuts through; cooled on the store, it holds (ADR 0001: the relationship stands, the constants are set for play). Its checklist follows the ticket's order: relight first; if it lights, climb home making every Shift by hand (the Reactor's autopilot Shifts late, and a late Shift on the worn Head wears it through); if not, send the most valuable survey first, cool the hull on the store, wait for the rescue. Its one goal is coming home alive: a pay goal could not be met, since the rescue and the worn Head's repairs take all a stranded dive earns, and the store cannot both cool the hull and send a whole stretch before the rescue. The relight's luck runs on a fixed seed, so a fresh drill plays the same each time (its first relights fail). The menu starts every dive as a fresh simulation, so the "paid in all" total starts over with each one; a dive's end returns to the menu rather than offering another dive of the same Scenario.
- **How the Drive's flight display reads (ticket #41, agent's choices within the design).** The attitude indicator has no bank: the Lithocraft does not roll. Pitch keeps the Course's sign (+ diving), so diving rungs lie below the horizon as an airliner's nose-down rungs do, the surface's side above it. The Course is one cross on the attitude indicator at its pitch and aside by the true angle its heading takes it off the vessel's vertical plane (a heading difference counts for less the steeper the Course, and for nothing straight down), the way a flight director's bars show where to steer, with chevrons at its pitch on the ladder and a bug on the heading tape; a mark off its scale pins to the nearer edge, so it always says which way to turn. While the Drive overrides, its own target shows hollow over the Course's. Deeper lies lower on the depth tape, so the tape moves the way the vessel does, and under it the rate of descent is the speed along the pitch (real basis: an airliner's vertical speed beside the altitude tape). The throttle, steering effort and how hard the Head steers stay on the display as the DRIVE block.
- **Every dive ends on a still screen that names the outcome** (surfaced, rescued, or dead and why) in a sentence before the payment breakdown. The play test's "we're dead" was the developer's "dead in the water", said in fun, not a misreading; the plain outcome line is still wanted.
- **How the moving map reads (ticket #42, agent's choices within the design).** Across is distance over the ground along the track, unrolled (as an airliner's vertical profile is drawn along its route), at one scale both ways, so a dive straight down is a vertical line and the turn for home a true U. The map fits the whole dive, the Orders' target included, and steps its scale through round spans so it holds while the dive grows a little. Boundaries are the Inferred Boundaries of the point cloud (#40), each patch drawn side-on between its corners, as sure as its confidence; on the map they do not fade with age, since it is the dive's record of what was heard. The Orders' target depth is where surface control's own survey puts the top of the deepest Medium the Orders name (for the First dive, the granite's top), so the target line and the granite's Boundary meet once the crew has heard it. Real basis: surface control would have a seismic survey of the site; the crew's scan is how they see it for themselves.

## The second checkpoint

Grilled with the developer on 25 November 2026, getting back on course after round 2's tickets (#31 to #43) piled up as unmerged PRs.

- **A checkpoint has the shape of the first.** Every ticket of the round merged to `dev`, the whole suite passing headless, one playable build with no tweaks in between, then a cold, narrated, recorded play test (First dive, then the drills) written up in `docs/playtests/`. No new tickets join a round once it is cut; new ideas wait for its play test.
- **`main` stays one stable build behind.** Checkpoint 1 (the build played on 25 November) was promoted to `main` (#18); each later checkpoint gets its own promotion.
- **Agents merge into `dev`** once a PR is up to date with `dev` and the suite is green, and stop to ask only when a conflict forces a design choice. Overlapping PRs merge one at a time in one session. Tickets are built one session each, in parallel where their files do not overlap; the explainer (#33) goes last because it covers every reading on every screen.
- **Choices from round 2's PRs, accepted:** the Shift dial is a selector and does not disengage the Reactor's autopilot (only R does); the Drive's override holds after the crew walks away, ending on O or on engaging the Drive's autopilot; the Shift match is shown against the window narrowed by Head wear, so what is seen is what is graded; the Checklist ticks strictly in order (a step done early is redone, steps left behind show as missed), to be judged in play; the point cloud's camera angle, 90 s fade and 2,000-point cap are judged in the play test, not tuned before it. Enter is ignored during the end-of-dive lurch so it cannot skip the outcome screen.
- **The play test's bar:** the First dive is finished cold, from the Checklist and explainers alone, surfacing and paid without asking what to do. Held loosely: the developer designed the game and is not a true cold player, so being stuck for other reasons is a finding, not a failure.
- **"Not yet designed" stays parked** until after the second play test, then is ranked by what it shows.
- **Found in merging: the MATCH meter and "ready the dial" disagreed.** The meter (#36) compared the dial to the wobble of the Medium the Head is in, while the Boundary call and the Checklist (#34) ask the crew to set the dial for the Medium ahead, so readying the dial correctly made the meter fall.
- **The Shift dial as a radio's active and standby channels (developer's idea).** "It might be cool for the interface to work like a flight control channel selector. You can tune the next behaviour and then when you MATCH you just [switch] from channel to channel." Real basis: an airliner's VHF radio holds an active and a standby frequency; the crew tunes the standby ahead of time and a transfer (flip-flop) key swaps them in one press. Here the dial tunes the standby while the active holds the plasma, and the Shift is the swap, so readying the dial and making the Shift are separate acts, the second a single press timed to the crossing.
  - **Two lanes, ACTIVE and STANDBY, each with its own MATCH.** ACTIVE against the wobble of the Medium the Head is in; STANDBY against the wobble expected in the Medium ahead, shown once the Boundary-approaching call comes. N/M tune whichever channel the crew is on (developer's refinement), not only the standby.
  - **R swaps the channels, and the swap is the Shift**, graded as a Shift is: the new active's match to the wobble at that moment, then lateness. A swap made early, still in the old Medium, is a poor Shift; a late one is punished by the window.
  - **The old active drops to standby**, so a second press swaps back; swapping back is a Shift too, so undoing an early swap costs a second one.
  - **Homework buys a preview (developer's idea).** "If you do your homework you can know a bit about the next rock (good scans, etc.) and maybe you can get a sine wave that is noisy, and the better you do you get a preview on the sine wave to come on the standby channel." The STANDBY lane shows the projected wobble of the rock ahead, noisy in proportion to how little the scans know, so pretuning is a reward for scanning well. Real basis: seismic and sonar surveys estimate the properties of rock ahead from echoes, and the estimate sharpens with more and cleaner returns, which is why Quiet Ship exists.
  - **Built before the second play test**, as a fix to #36, before the explainer (#33) so it describes both channels.

## Not yet designed

- Flight in air, space and gas giants beyond the three-step ascent.
- Spin gravity, given what the prototype showed.
- The vessel's actual dimensions.
- Warp.
- Ports, and who buys the data.
- Art style beyond the scan display.
- Pressure as an active mechanic beyond gating depth by hull grade.
