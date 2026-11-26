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
- **The Habitat as a can of beans (ticket #68, agent's choices within the design).**
  The Habitat is 9.6 m along the Bore against 6.6 m across (1.45 to 1): 9.6 rather than 9.5 so the Column's texture is a whole number of pixels long.
  The ring of Stations and the Arm's rail are one piece of layout (a single height above the Head end floor), which is what the slide to the other floor (#69) will move.
  Until #69 the ring stays by the Head end: in a climb the floor is the Tail end cap, 8 m from the Stations, and only the Arm reaches them.
  Two clearances were opened a little, because the larger screens (#62) put a corner through a wall at some pitches between level and a climb.
    - The ring is 1.3 m above the Head end floor, where it was 1.2 m: a key panel's corner went 3 cm through the floor in a shallow climb.
    - Each Station pivots 0.85 m in from the outer wall, where it was 0.75 m: an upper Station's top corner went 3 cm through the wall near 25 degrees of climb.
      It is now at least 6 cm inside at every pitch, and a test holds it there.
  Four times the Column is in view, so its grains are built once per band and kept, where they were placed afresh every frame: the picture is the same to the byte and the frame time is back where it was.
  The ribs keep their 0.8 m spacing up the whole wall, and lamps hang on the Bore's axis every 2.4 m from the ring up, so the working level is lit as it was.
- **Stations and the Arm's ring slide when "down" flips (ticket #69, agent's choices within the design).**
  The slide belongs to the simulation: it knows which way "down" is, so it says where the ring is, and every view (and a later second player's) shows the same slide.
  An end counts as the floor once "down" points more toward it than toward the outer wall, past 45 degrees of dive or climb; nearer level the ring stays where it last was, or finishes a slide it had begun.
  The slide takes six seconds, eased at both ends (tuned for play, ADR 0001): long enough to watch a Station leave, short beside the turn that causes it.
  It follows gravity only, so the jolt of a poor Shift cannot send the Stations off.
  The ring hangs 1.45 m above the Tail end floor against 1.3 m above the Head end floor: a Station is not its own mirror image (its key panel hangs to one side), and at 1.3 m a key panel's corner went 7 cm through the Tail end cap in a shallow dive with the ring still by the Tail.
  Each Station's strut rides a rail up the wall, drawn from one end's place to the other's.
  The Arm's rail runs along the Bore at 4 m/s, faster than the ring ever slides: called, it runs to the crew member first and reaches only once level with them, so a call from the far end takes about two seconds longer than one from beside the ring; then it runs back as it carries them.
  A held crew member rides the slide with nothing to do, since the Arm holds them at their Station's own working place each step.
  What breaks a held action is the simulation's existing rule that a hold counts only at an attended Station; the view reports reach each step and nothing checks reach per command.
  Found on the way, and left alone: on foot the crew member slides down the tipping wall toward the new floor well before the ring sets off (the body creeps on any slope), so in play they and the Stations part early in the turn, by the crew member's leaving, and meet again when the ring arrives; a Station visibly pulling away from someone standing at it happens only if they walk uphill to stay.
  Either way the hold stops for as long as the Station is out of reach, and the Arm is the way to keep working through a turn.
  A Scenario that begins in a climb would begin with the ring by the Head end and slide in its first seconds; none does yet.
