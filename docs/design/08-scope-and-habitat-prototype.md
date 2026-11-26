# Scope and the Habitat prototype

## Scope and order

- One solar system: Earth desert, Moon, Jupiter.
- First playable slice: one Earth desert dive through sand, sandstone and granite and back.
  No space, no multiplayer, no warp.
  See the spec.
- The riskiest idea to build is the changing "down", so it was prototyped first.

## The Habitat prototype

On the `prototype/habitat-down` branch.
A browser stand-in built with three.js because Godot was not installed on the machine used; the geometry and motion carry over, the code does not.

- Dive, level, spin and coast behaved as designed.
  Climb was not exercised.
- **Verdict on feel: optimistic, go ahead (second session, 24 November 2026).**
  Played on the PC with the arm added; the developer said "works great. i'm optimistic" and chose to move on.
  The Habitat stories in the spec stand as written.
- **Finding: spin gravity is weak and uneven at this size.**
  At 10 rpm, 0.37 g at the feet and 0.18 g at the head.
  A full 1 g at the floor needs about 16 rpm, which would be nauseating in reality.
- **Finding: level travel strands most Stations.**
  The floor is the bottom of a curved wall; only the lowest one or two Stations are reachable on foot.
  Possible answers: ladders or handholds, a larger radius, Stations that travel around the ring, or a Habitat that rolls.
- Dimensions used: Bore wall radius 0.8 m, outer wall radius 3.3 m, length 2.4 m, Stations pivoting 1.1 m above the outer wall.
  Starting values only.
- **Developer's idea (second session): an arm that catches you.**
  Press a dedicated button and a robot arm or chain swings in, catches you, and carries you between Stations with left and right.
  The developer's reason: "when the ship is in a strange orientation, you can still make it work."
  It answers the stranded-Stations finding for every "down", not just level, and keeps walking for when "down" is kind.
  - **Real precedent.**
    The ISS's Canadarm2 rides a mobile base along a rail on the truss and carries astronauts clamped to a foot restraint on its end.
    A carriage on a ring rail is the same arrangement, so it needs no concession under ADR 0001.
  - **Real cost.**
    Unlike in free fall, the arm has to hold a person against up to about 1 g on a lever of a metre or two.
    That takes a strong joint and power, so it draws on the power budget and can fail.
  - **Prototyped, not decided.**
    Added to the prototype on 24 November 2026: a carriage on a rail around the Bore, a chain with a claw that grips a harness between the shoulders, Space to call it or let go, A/D to move one Station left or right.
    Jump moved to J.
    It was exercised in level, dive and spin.
    The developer tried it: "works great. i'm optimistic."
    Confirmed as the method on 25 November 2026 (see the spec, issue #1); its cost in play is not designed.
