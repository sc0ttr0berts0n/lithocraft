# After the second checkpoint: as built

Agent's choices within round 3's design (spec #71), one bullet per ticket.

- **The Thermal gauge (ticket #64, agent's choices within the design).**
  The hull's temperature is a bar along a scale in kelvin, with the amber range from the temperature the heat warning comes on at and the red from the temperature the hull bears: both the simulation's thresholds, so the gauge and the warning cannot disagree.
  The heat warning can also come on below the amber range, when the heat now sent outward will take the hull past what it bears; the gauge shows that as the trend arrow reaching into the amber or red, the HULL HOT lamp lit above it.
  The trend mark is borrowed from an airliner's speed tape: an arrow from the present value to where it will be in thirty seconds at the present rate, so its length is how fast and its tip is how bad.
  Real basis: a hull settling toward the temperature at which it sheds its heat changes fastest when furthest from it, so the arrow shortens as the hull settles.
  The scale starts below any rock the first dive meets and runs a little past what the hull bears; a hull hotter than its end is pinned there and the number still reads true.
  Where the heat is sent is one bar divided where the heat divides, with the amounts over it and the crew's setting as a cyan mark under it; the two differ only when the pumps are starved.
  The Medium's temperature is written beside the gauge, not marked on it: a mark among the scale's numbers read as one more threshold.
  A new simulation query, `hull_warming_rate()`, gives the trend; the hull's temperature and the split no longer repeat as status lines, and integrity and creep keep theirs.
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
