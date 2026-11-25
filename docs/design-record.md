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
- **Lingering deep heats the hull.** Hot surrounding rock conducts heat in at any power, so careful means efficient, not slow. This answers the developer's worry that impatient players kill themselves: a careful dive is not a slow one. Better ships later make today's unviable depths and pressures reachable.
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
  - Losing the plasma by a Shift always wears the Head through, so a stranded Head relights at the worn-through odds (about two in five); the Reactor screen shows the odds on the Head as it is. Relit, a worn-through Head holds through clean Shifts and is lost again to any poor one.
  - Relight gets its own Reactor key (I), not R, so a Shift pressed as the plasma goes cannot spend the store.
  - While stranded the time rate may be raised although the Reactor calls: the crew wait on the link and the store.
- **The stranding clock (the developer's idea)** is the time to hull failure as heat from the surrounding rock soaks in with the Head dark. Its length depends on the rock's heat (depth), the hull's wear, and battery spent on cooling.
- **Rescue time** is a fast run down the open tunnel plus a slow cut through the sealed length behind the Lithocraft. The Thermal screen shows the clock as a live estimate beside the rescue time, so rescue or death can be read at a glance.
- **Rescue brings the data home.** Unsent data is lost only on death, so uploading is insurance for when the clock is shorter than the rescue time. Rescue costs a line in the payment breakdown, scaled by how long it took. It sits between a clean surfacing and a rebuy.
- **Time pressures are tracked, not felt, in the first dive.** Fuel burned, the rock creeping shut, and a contract clock are measured and described but have no effect yet.
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

## Not yet designed

- Flight in air, space and gas giants beyond the three-step ascent.
- Spin gravity, given what the prototype showed.
- The vessel's actual dimensions.
- Warp.
- Ports, and who buys the data.
- Art style beyond the scan display.
- Pressure as an active mechanic beyond gating depth by hull grade.
