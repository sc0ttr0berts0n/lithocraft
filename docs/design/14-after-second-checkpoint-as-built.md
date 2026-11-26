# After the second checkpoint: as built

Agent's choices within round 3's design (spec #71), one bullet per ticket.

- **Navigation plans, the Drive deviates (ticket #65, agent's choices within the design).**
  A nudge is one fixed step, 15 degrees (tuned for play, ADR 0001), and the command carries only its direction, so nothing sent to the Drive can point it at a dive, level or a climb in one go.
  The override the nudges build is still a heading and pitch of its own, not an offset carried along with the Course: if Navigation replots while the Drive is off the Course, the Drive holds where it was steering and the deviation changes, which both screens show.
  An override that comes back onto the Course ends by itself, whether the Drive nudged back or Navigation plotted the Course onto it, so "off Course by nothing" is never a state and the Drive follows the next plot.
  This changes round 2's "the override ends only on O or the Drive's autopilot" (12-second-checkpoint.md); walking away still does not end it.
  Straight up or down a compass heading means nothing (real: at the pole of a sphere every direction is south), so the heading deviation reads zero there and a heading nudge does nothing until the pitch is nudged off vertical.
  The deviation is said in up / down / left / right, not signed degrees, because pitch is signed + diving and "-30" for "up" was part of the play test's confusion.
  The deviation is written in cyan, as the Course is: it is what the crew has selected, not a fault, so it lights no Caution lamp; "Following the Course" stays green.
  Navigation's screen gained one status line for it and nothing on its displays, which #67 is redrawing; the projected path already bends toward what the Drive steers for (#66), now under test for a nudged Drive.

- **Features of interest in the Column (ticket #70, agent's choices within the design).**
  The play test's iron concretions were drawn, but as marbles two to four centimetres across, the size of the grain speckle round them, at a place round the Column picked per feature, so often on the far side from the Bore Station.
  Every feature is now turned to the Bore Station's side of the Column: the crew turn round from its screen and it is there.
  Where a feature lies along the Bore is the simulation's alone (its distance behind the Head); which way it faces is the view's, since a Column is cut all the way round and the simulation says nothing of it.
  It passes the Bore Station (the height its gimbal hangs at) when the simulation's distance behind the Head equals the Station's, a little below the seated crew's eyes with the Tail up, and reaches eye height a moment later.
  Each kind has its own look, sized to be seen from across the Habitat (tuned for play, ADR 0001: real concretions and fulgurites are mostly smaller).
    - Iron concretions: rusty marbles in a patch of sandstone bleached pale.
      Real ones (the Navajo Sandstone's "Moqui marbles") grew where groundwater stripped the iron from the red rock, bleaching it, and dropped it again as balls of hematite and goethite; the pale patch is that bleached rock and is what makes them findable against red sandstone.
    - Petrified wood: a trunk cut across at a slant, so a tall oval of growth rings in agate reds and creams inside a rind of bark, with quartz in the drying cracks that run out from the heart.
      Silica replaces wood cell by cell, so the rings survive; iron colours it red and orange.
    - Fulgurite: a dark glass tube with a branch or two inside a pale sleeve of sintered sand, as lightning leaves in dune sand.
    - Quartz vein and pegmatite keep the looks they had: a white sheet right round the Column (a slanted plane unwrapped is a sine wave), and a pale pocket of giant crystals with tourmaline and garnet.
  A feature is still in the Habitat's stretch of the Bore for only a few seconds at speed, and the Bore Station's list gives it in metres behind the Head, which the crew cannot turn into "look now"; the taller Habitat (#68) lengthens the pass, and the screen's wording is left to the screens' rebuild (#62).
