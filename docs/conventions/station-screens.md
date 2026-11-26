# The Station screens

## The frame, the Theme and the colour language

- **A Station screen is a composition, not floating text.**
  Each `GimballedStation` shows a `StationScreen` (`view/station_screen.gd`): Controls and Containers in a `SubViewport`, under the one `StationTheme`, drawn on the screen's panel as a texture.
  No Station shows a `Label3D`: every reading is on the screen, and `station_screen_test.gd` fails a Station that floats text or lays a reading off its screen.
- **The frame, top to bottom:** the header strip, the body, the status lines, the footer.
  The header strip is laid out the same on every Station: its name, its autopilot's state (green AUTOPILOT, amber while AUTOPILOT OFF flashes, then white), and its Caution lamps at the right.
  The body is the Station's own instrument and takes all the room the rest leaves; a Station with none yet (Thermal) gives the room to its status lines.
  The status lines are the Station's readings as text, shrunk together until every line is whole (`StationScreen.fitting_font_size()`), at most `STATUS_MOST` of the room under an instrument.
  The footer is one line every Station shows alike (the time rate).
- **Putting a Station's instrument in the body** is one call as the Station is built in `habitat.gd::_build_stations`:
  `station.screen().set_instrument(control)` for any Control (it is made to fill the body and resized with it: lay it out by its own `size` or build it of Containers; the Bore Station's `_bore_instrument()` is the example);
  or `station.show_display(texture, instruments)` / `show_displays(textures)` for a picture drawn in its own `SubViewport` (a 3D display, or one not yet moved onto Controls), which keeps its shape, centred in the body.
  Size such a viewport from `StationScreen.body_size(lines)`, the body's pixels over that many status lines.
  A Station should come to look its own by its instrument; the name in the header is the fallback.
- **Status lines** go through `station.show_lines(lines)` every frame from the Habitat's `_show_<station>()`: each line a String (white) or `[text, meaning]`, the meaning one of `StationTheme`'s.
  `show_reading(text)` is the same with every line white.
- **Caution lamps** (`GLOSSARY.md`) are declared in `CautionLamps.of(sim, station)` (`view/caution_lamps.gd`): one line per lamp, its label and the simulation query that lights it.
  The Habitat hands each Station's to its header strip every frame (`show_lamps()`), so a lamp lights and clears from the simulation's state alone; a lamp keeps its place lit or not.
  A cause with no query of its own gets one small function there: the Reactor's HEAD WORN reads `CautionLamps.head_worn()`, today `head_wear()` at a whole percent or more, the one place to repoint it.
  Tested in `caution_lamps_test.gd`, through the simulation.
- **One colour language on every screen, an airliner's** (`StationTheme`, `view/station_theme.gd`): white is what is happening now, cyan what the crew has selected or aims for (the Course, a setting, a target), green engaged and working, amber a caution, red a warning (what is about to kill the crew).
  Beside the five are only the screen's neutrals, which say nothing: its background, the grey of a legend (a title, a unit, a scale), the darker grey of a rule or an unlit lamp, and two backdrops for a picture of the world.
  The rock's own colours (`ColumnLook`) are a picture too, not language.
  A Station's hue (`habitat.gd::STATIONS`) is for its call light, its gimbal's bob and its name on the checklist, never its screen.
- **The Theme is the only place a screen's colours are written.**
  Controls take them from `StationTheme.theme()` by type variation (`StationTheme.variation(meaning)` on a Label); a display that draws itself reads the constants (`StationTheme.CAUTION_COLOUR`), fainter through `StationTheme.faded()`.
  `station_theme_test.gd` fails any script in `view/` that writes a colour (`Color(...)`, `Color.NAME`), unless it is listed there as drawing nothing on a Station screen; a new screen script is checked without being listed.
- **The key list** beside each screen (`KeyList`, `view/key_list.gd`, on the crew's right) is built the same way from `show_keys(KeyMap.bindings_at(station))`: what a key does wraps, and the whole list shrinks until every row is on the panel, so it is never cut off (`station_screen_test.gd`).
- **Read from the Arm's hold.**
  The screen (`GimballedStation.SCREEN_SIZE`) and key panel are sized so both are whole in the view from the working pose at 1152x648; check a change with a screenshot per Station (`tools/screenshot/shot.sh --look <Station>`).
  A Control's place is known only once its Station is in the tree and a frame has passed, so a test of `face()` adds the Station as a child and awaits two frames.
- `GimballedStation` besides: `set_supplied(share)` dims a starved screen and its key list, `set_call(urgency)` beats the Station's tone and flashes its light.
  Set `call_tone_hz` / `call_pips` before `_ready`.
  The autopilot's disconnect tone (`disengage_tone()`) is soft on purpose: no note above the Stations' call tones, no hard edge, quieter than a call (`autopilot_caption_test.gd`).

## Each Station's screen

- `head_wear()` (the Head, from poor Shifts) and `vessel_wear()` (the hull, from heat) are different things.
  The Thermal screen shows the hull as `hull_integrity()` and `hull_creep_rate()`, and once sealed in `stranding_clock()` beside `rescue_time()` ("if stranded" estimates under way, the race itself while stranded).
- The Reactor's screen (`PlasmaDisplay`, `view/plasma_display.gd`, on a `SubViewport`) shows the Shift dial as two lanes, ACTIVE over STANDBY, each its wobble (white) against its tuning's opposing wave (cyan) with its MATCH at the right:
  ACTIVE against `plasma_frequency()` by `shift_match(plasma_tuning())`, STANDBY against `wobble_ahead()` by `standby_match()`, the tuning's wave alone and "MATCH —" while those are NAN (`PlasmaDisplay.match_text()`, tested directly).
  It reads only the simulation; the view keeps no copy of either channel.
  The window bar runs along the bottom.
- The Drive's screen is a primary flight display (`FlightDisplay`, `view/flight_display.gd`), drawn on a `SubViewport` like the Reactor's: attitude (pitch ladder), speed and depth tapes, heading tape, power, grip and steering, each read from the simulation's queries every frame;
  its status line says only whether the Drive follows the Course or overrides it (or how the dive ended).
  A tape's scale is a `FlightTape`: the reading stays at its middle, a value's place is `place(value, reading)` (the short way round on the compass), and a bug off the tape is `pinned()` to its nearer end.
  On the attitude indicator a mark lies aside by `FlightTape.sideways()`, the true angle off the vessel's vertical plane, not the bare heading difference, which means nothing in a steep dive.
  The Course is always cyan (`StationTheme.SELECTED_COLOUR`), the override hollow in the same cyan: both are what the crew has selected.
  Pitch follows the simulation's sign (+ diving), so diving rungs lie below the horizon, as nose-down ones do on an airliner's.
- Navigation's point cloud (`ScanDisplay`) is head-up: the vessel fixed at the centre, its Head up the screen, the camera set from `heading()` and `heading_degrees()` over its back and right side, so it turns only as the vessel does and a Course differing in pitch or heading shows beside the heading line.
  The cloud is placed at `-head_position()`, so points stream toward the marker at the simulation's speed; their places are rebuilt only when `pulses_sent()` changes (never by copying `points()` each frame), their fade (by `point_age()`) every frame.
  The Inferred Boundary patches are a `MultiMeshInstance3D` child of the cloud (so they stream past with it), each a unit `PlaneMesh` stretched over `corners()`, placed with the points and faded each frame by `confidence` times the points' fade (`patch_age()`).
- Navigation's moving map (`MovingMap`, `view/moving_map.gd`) is a 2D cross-section of the whole dive, redrawn a few times a second: across is ground distance along the unrolled track (`MovingMap.profile()` of `remembered_path()`, the simulation's perfect record of the path), down is depth, at one scale both ways.
  Its Boundaries are the Inferred Boundaries (`inferred_boundaries()`), never the layout: each patch drawn side-on between its corners, placed across by how far ahead of the Head along the heading they lie (`MovingMap.across()`), as sure as its `confidence`.
  The target depth is `target_depth()`, from the Orders (`Scenario.Goal.target_depth`, NAN for a goal with none).
