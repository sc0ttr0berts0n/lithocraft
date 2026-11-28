# The Glide seen, heard and felt

Ticket #127: the Bore carries a river of melt in a Glide, its light floods the Habitat, the jet roars and shakes the crew, and the tunnel behind is drawn by its wall.
The choices and their reasons are in the design record, "The Glide seen, heard and felt (#127)" (`docs/design-record.md` names the file).
The simulation's side is `glide.md`; this file is the view's.

## The melt in the Bore

- `BoreMelt` (`view/bore_melt.gd`) is a node of the Habitat (`Habitat.bore_melt()`), stepped by `_physics_process` after `advance()`: it reads `gliding()`, `glide_thrust()`, `column_absent()` and `dive_time()` and nothing else, so a staged shot repeats.
- The melt is drawn on the Column's own surface, never on a second mesh: the Column strip's SubViewport is transparent (`transparent_bg`), `ColumnStrip` leaves every band where `column_absent()` is true undrawn, and that surface's shader (`BoreMelt.material()`) paints melt wherever the strip is clear.
  So the melt replaces the Column exactly where the simulation has none, band by band, and the Column coming back in at the Head end after a Glide pushes it out toward the Tail with nothing more done.
- Its temperature is the one number behind the look (`BoreMelt.temperature()`): with the thrust while a Glide runs, then cooling toward a crust from the dive time the Glide ended, which `step()` notes when `gliding()` turns false.
  Colour is a hot body's at that temperature (`BoreMelt.colour()`), brightness its fourth power (`radiance()`).
- Motion is never integrated: the patterns' travel is the dive time times a fixed rate, frozen at the dive time the Glide ended, and the jet's streaks fade in over the slow lumps with the thrust.
- Light: `BoreMelt.LIGHTS` omni lights on the Bore's axis, one per quarter of its length, each lit only while `column_absent()` at its place, with the melt's colour and an energy by `radiance()`; the room's ambient light leans to the melt's colour, and the `Environment`'s glow is on only while a melt light is lit.
  The glow's threshold is above the screens' white, so only the melt blooms; a new emissive thing brighter than 1 would bloom too.

## The roar and the shake

- `JetRoar` (`view/jet_roar.gd`), a looping `AudioStreamGenerator` beside `SlipSound`, reads only `glide_thrust()` while `gliding()`: band-passed noise whose peak (`peak_hz()`) and loudness (`loudness_db()`) rise with the thrust, a low rumble and a faint whine under it; silent at thrust 0, so the idle after a Glide is quiet.
  It draws noise from a generator of its own, never the global one, and plays nothing when the audio driver is `Dummy` (`running-and-testing.md`, Gotchas).
- The crew's shake adds `Habitat.GLIDE_SHAKE_M` times the thrust to the one `_crew.shake()` sum.

## The tunnel behind

- `TunnelLook` (`view/tunnel_look.gd`) is how every view draws the tunnel: glass a plain white line, rough the same white beaded, sealed the legend's grey, all Theme colours, named "glass", "rough" and "sealed" where a view names them.
- A view keeps a `TunnelLook` and asks it for `pieces(sim)`: it reads `tunnel_walls()` again only when `tunnel_wall_count()` changes and runs the newest piece on to the Tail; ahead of the Tail is the vessel, not tunnel (`wall_at()` gives `&""`).
- Navigation's moving map draws the path behind piece by piece in its wall (`MovingMap._draw_tunnel()`); the Bore Station's tunnel panel draws a strip along its graph's foot behind the Tail, each stretch named where it fits.
  A new view of the tunnel uses `TunnelLook` the same way.

## Keys, screens and tests

- No key was added: the Glide's keys are #123's (`key-map.md`).
- The Bore Station's screen says "No Column in the Bore: melted by the Glide" while gliding or while the Column is missing level with the Bore Station.
- `tools/screenshot/recipes/glide.txt` is the evidence; it has no climbing tile until a Scenario can plot a Glide up (#128).
- `test/glide_look_test.gd` stages Glides as the screenshot tool does and reads `BoreMelt`, `JetRoar` and `TunnelLook`, never pixels.
- The cost budget's Glide condition covers the melt, the lights and the roar; `glide_thrust()` is O(1).
