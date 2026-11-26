# The vision and the ground rules

## The original vision

In the developer's words, lightly condensed:

- A 3D Godot game, similar in feel to operating a spaceship in Elite Dangerous: complicated simulated systems.
  Also like Iron Nest, and to an extent Uncle Chop's Rocket Shop.
- The Lithocraft works a bit like the Dune worm.
  It is a long ring, somewhere between a torus and a straw, with a glass cylinder in the middle where you observe the material it is travelling through.
- It can fly through rock and through air.
  It will penetrate the Moon, and Jupiter's cloud tops and core.
  It can reach space somehow.
  Hard science fiction.
- You start in loose soil like a desert and work your way through stronger rock.
  You manage heat, pressure and rock hardness.
- Open question at the start: a cockpit, or a place like a submarine where you walk around the ring?
  Spin-stabilised in space could be interesting, with a console that rotates and adapts.
- "I see it being something of a mining game."

## Lore

Fusion energy.
We thought its best perk was limitless energy.
But it also unlocked a form of travel where you can simply cut through anything, and direct magnetism to shape rocketry.
Guiding plasmas turned out to have a surprising amount of industrial application.

This lore does structural work: it explains why one reactor is the cutter, the rocket nozzle, the refinery and the fabricator's toolhead.

## Ground rules

Recorded in `docs/adr/0001-science-ground-rules.md`.

- Three permitted impossible things: compact fusion, the hull material, and warp.
  As few concessions as possible.
- Every relationship is physically true (more speed needs more power, more power makes more heat, deeper means more pressure).
  Constants are tuned for play.
  "We'll decide what's fast and slow by gameplay."
- Why: Jupiter's core is tens of megabars and about 20,000 K, beyond any real material.
  Melting a 12 m tunnel costs roughly 300 gigajoules per metre, so at 1 m/s that is 300 gigawatts, and a trip through the Moon would take about 40 days.
  Real numbers would rule out the destinations and dictate the pacing.
- Hull grade is the progression that gates depth.
- Warp (an Alcubierre-style drive enabled by the tokamak) is the answer for travel between planets.
  It is not designed yet and is not needed until the game leaves the Earth–Moon system.
  The fusion rocket only has to handle launch and orbit.
