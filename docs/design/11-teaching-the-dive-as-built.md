# Teaching the dive: as built

- **How the Inferred Boundaries are fitted (ticket #40, agent's choices within the design).**
  The ground is gridded into square cells (16 m) and each cell's points are split into layers wherever a height gap opens (6 m), as multibeam surveys grid soundings into a height field; a plane is fitted to each layer by least squares, each point weighted by its confidence and the slope pulled gently toward level (a few bunched points barely tilt it;
  a cell full of them sets its own slope) (layered ground lies near level unless the points say otherwise).
  Three points at least make a surface: one or two are an echo.
  A patch covers only the ground its points span, never the rest of its cell.
  A patch's confidence is its points' summed confidence against a half-sure amount, so more points, or surer ones, make it surer; it is as old as its points on average and fades as they do.
  The patches are drawn as translucent green tiles among the points, opacity by confidence.
  Gridding the ground assumes Boundaries are more level than upright, true of every layout so far; a steep Boundary would want a 3D fit.
- **How the Checklist behaves (ticket #34, agent's choices within the design).**
  Steps tick in order, and only the next one can tick, so a step done early is done again when asked for (a real checklist is read in order).
  One action ticks one step.
  A phase begins once the one before is finished, or early when the dive reaches it (a Boundary approaching, a Shift past one, a climbing Course plotted, surfacing); steps left behind show as missed rather than holding the crew back.
  Startup plots the Course before engaging the Drive's autopilot, so the vessel moves only once it has somewhere to go.
  A Shift the Reactor's autopilot makes does not tick the crew's Shift.
  Turning the Shift dial is a selector, like an A320's heading knob, so it does not disengage the Reactor's autopilot.
  Surface control's messages come down at the link's own rate: about a second up the open tunnel, minutes through sealed granite (ADR 0001: the ratio follows the link, the rate is tuned).
- **The drills and the start menu (ticket #35, agent's choices within the design).**
  The Shift drill starts 40 m above the sandstone, under way with the Drive's and Thermal's autopilots engaged and the Reactor's off, so the crew's only work is the Reactor; its one goal is a clean Shift into the sandstone, and the drill has no end of its own (dive on, or turn for home).
  Stranded in the granite starts 200 m into the granite, the Lithocraft having cut straight down from the surface with clean Shifts, the whole Column aboard; the Head is worn (0.8) as the poor Shifts that lost its plasma would leave it, so a relight is a gamble.
  The depth is set so the race is real: uncooled, the hull fails just before the rescue cuts through; cooled on the store, it holds (ADR 0001: the relationship stands, the constants are set for play).
  Its checklist follows the ticket's order: relight first; if it lights, climb home making every Shift by hand (the Reactor's autopilot Shifts late, and a late Shift on the worn Head wears it through); if not, send the most valuable survey first, cool the hull on the store, wait for the rescue.
  Its one goal is coming home alive: a pay goal could not be met, since the rescue and the worn Head's repairs take all a stranded dive earns, and the store cannot both cool the hull and send a whole stretch before the rescue.
  The relight's luck runs on a fixed seed, so a fresh drill plays the same each time (its first relights fail).
  The menu starts every dive as a fresh simulation, so the "paid in all" total starts over with each one; a dive's end returns to the menu rather than offering another dive of the same Scenario.
  *Superseded in part (After the second checkpoint): there is no late Shift; the Head wears only while the Residual is outside the Band.*
- **How the Drive's flight display reads (ticket #41, agent's choices within the design).**
  The attitude indicator has no bank: the Lithocraft does not roll.
  Pitch keeps the Course's sign (+ diving), so diving rungs lie below the horizon as an airliner's nose-down rungs do, the surface's side above it.
  The Course is one cross on the attitude indicator at its pitch and aside by the true angle its heading takes it off the vessel's vertical plane (a heading difference counts for less the steeper the Course, and for nothing straight down), the way a flight director's bars show where to steer, with chevrons at its pitch on the ladder and a bug on the heading tape;
  a mark off its scale pins to the nearer edge, so it always says which way to turn.
  While the Drive overrides, its own target shows hollow over the Course's.
  Deeper lies lower on the depth tape, so the tape moves the way the vessel does, and under it the rate of descent is the speed along the pitch (real basis: an airliner's vertical speed beside the altitude tape).
  The throttle, steering effort and how hard the Head steers stay on the display as the DRIVE block.
  *Superseded in part by "Navigation plans, the Drive deviates" (After the second checkpoint): the Drive has no override presets; the display shows its deviation from the Course.*
- **How the moving map reads (ticket #42, agent's choices within the design).**
  Across is distance over the ground along the track, unrolled (as an airliner's vertical profile is drawn along its route), at one scale both ways, so a dive straight down is a vertical line and the turn for home a true U.
  The map fits the whole dive, the Orders' target included, and steps its scale through round spans so it holds while the dive grows a little.
  Boundaries are the Inferred Boundaries of the point cloud (#40), each patch drawn side-on between its corners, as sure as its confidence; on the map they do not fade with age, since it is the dive's record of what was heard.
  The Orders' target depth is where surface control's own survey puts the top of the deepest Medium the Orders name (for the First dive, the granite's top), so the target line and the granite's Boundary meet once the crew has heard it.
  Real basis: surface control would have a seismic survey of the site; the crew's scan is how they see it for themselves.
