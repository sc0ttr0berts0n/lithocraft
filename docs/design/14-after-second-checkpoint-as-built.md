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
- **How the Reactor cancels the Wobble (ticket #60, agent's choices within the design).**
  The Wobble's frequency rises with the Medium's hardness, as before; its amplitude rises with the Medium's strength (stronger rock pushes back on the Head harder), so sand, sandstone and granite each differ in both.
  Only that ordering is meant true; the numbers are tuned (ADR 0001).
  The phase lock is played up from a real one: the Counter-wave's phase holds to the Wobble's on average and swings about it at the difference of the two frequencies, wider the further off, a full half turn each way past the lock's range.
  That gives the two looks the design asks for from one sum of two waves: a wrong amplitude alone leaves a steady Residual, a wrong frequency alone leaves beats that slow and shrink as it nears.
  Real basis: two waves of unlike frequency beat at the difference of their frequencies, and a phase-locked loop near the edge of its range slips and recovers.
  Wear is charged on the Residual's distance outside the Band, averaged along the beat, at a fixed rate; nothing is charged at the swap, so a Shift is only ever as good as the Counter-wave swapped in.
  The grinding is live too: the heat and the shudder that a poor Shift used to give in one lump now last exactly as long as the Residual is outside the Band.
  The plasma's steadiness falls only for the Residual outside the Band and for the Head's own wear, so a hot hull shows as a cause (HOT) only while the Band it narrowed is costing something.
  A disruption needs time: a Residual far outside the Band must stay there about four seconds on a badly worn Head before the plasma is lost.
  Without that, a Head worn past half could never cross a Boundary by hand, since no crew swaps in the very instant of the crossing; with it, a prompt swap saves a worn Head and the slow autopilot does not, which is what Stranded in the granite teaches.
  The Reactor's autopilot makes no Shift at all: it tunes ACTIVE toward the Wobble at a slow fixed rate and leaves STANDBY alone, so the First dive's four Boundaries cost it about a tenth of the Head and the crew's prepared swaps cost nothing.
  The Checklist's phase after a Boundary begins once the Residual is inside the Band in the new Medium, however it got there, since the autopilot no longer raises a Shift to begin it.
  A Reactor nobody tends is no longer merely weak: left alone past a Boundary it loses the plasma within minutes, so a dive with nobody at the Reactor engages its autopilot.
  (Before, an untuned plasma only supplied less power for ever, which also kept a full-power hull cool by accident.)
  Stand-in keys at the Reactor: C selects the channel, N / M tune frequency, J / K tune amplitude, R swaps.
  The Reactor's call for a Residual outside the Band is `out_of_band`, and the debug menu's "a Shift due now" became "detune ACTIVE now".
