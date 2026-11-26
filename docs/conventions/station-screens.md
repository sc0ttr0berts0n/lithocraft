# The Station screens

- Station screens are `GimballedStation`: `show_keys(KeyMap.bindings_at(station))` puts the Station's key panel beside its screen (on the crew's right), `show_reading(text)` for text (on a text screen the font shrinks from `screen_font_size` until every line fits the screen, `fitting_font_size()`, so a long reading is never cut off;
  above a display it does not), `show_display(texture, instruments)` for a `SubViewport` texture (the Bore, Reactor and Drive screens do this), `show_displays(textures)` for several side by side with no instruments, each sized to `display_rect(index, count)` and each its own reading (Navigation:
  the point cloud and the moving map), `set_supplied(share)` dims a starved screen, `set_call(urgency)` beats the Station's tone and flashes its light.
  Set `call_tone_hz` / `call_pips` before `_ready`.
- `head_wear()` (the Head, from poor Shifts) and `vessel_wear()` (the hull, from heat) are different things.
  The Thermal screen shows the hull as `hull_integrity()` and `hull_creep_rate()`, and once sealed in `stranding_clock()` beside `rescue_time()` ("if stranded" estimates under way, the race itself while stranded).
- The Reactor's screen (`PlasmaDisplay`, `view/plasma_display.gd`, on a `SubViewport`) shows the Shift dial as two lanes, ACTIVE over STANDBY, each its wobble (Reactor hue) against its tuning's opposing wave (white) with its MATCH at the right:
  ACTIVE against `plasma_frequency()` by `shift_match(plasma_tuning())`, STANDBY against `wobble_ahead()` by `standby_match()`, the tuning's wave alone and "MATCH —" while those are NAN (`PlasmaDisplay.match_text()`, tested directly).
  It reads only the simulation; the view keeps no copy of either channel.
  The window bar runs along the bottom.
- The Drive's screen is a primary flight display (`FlightDisplay`, `view/flight_display.gd`), drawn on a `SubViewport` like the Reactor's: attitude (pitch ladder), speed and depth tapes, heading tape, power, grip and steering, each read from the simulation's queries every frame;
  its text above says only whether the Drive follows the Course or overrides it (or how the dive ended).
  A tape's scale is a `FlightTape`: the reading stays at its middle, a value's place is `place(value, reading)` (the short way round on the compass), and a bug off the tape is `pinned()` to its nearer end.
  On the attitude indicator a mark lies aside by `FlightTape.sideways()`, the true angle off the vessel's vertical plane, not the bare heading difference, which means nothing in a steep dive.
  The Course is always Navigation's cyan (`ScanDisplay.COURSE_COLOUR`), the override hollow in the Drive's hue.
  Pitch follows the simulation's sign (+ diving), so diving rungs lie below the horizon, as nose-down ones do on an airliner's.
- Navigation's point cloud (`ScanDisplay`) is head-up: the vessel fixed at the centre, its Head up the screen, the camera set from `heading()` and `heading_degrees()` over its back and right side, so it turns only as the vessel does and a Course differing in pitch or heading shows beside the heading line.
  The cloud is placed at `-head_position()`, so points stream toward the marker at the simulation's speed; their places are rebuilt only when `pulses_sent()` changes (never by copying `points()` each frame), their fade (by `point_age()`) every frame.
  The Inferred Boundary patches are a `MultiMeshInstance3D` child of the cloud (so they stream past with it), each a unit `PlaneMesh` stretched over `corners()`, placed with the points and faded each frame by `confidence` times the points' fade (`patch_age()`).
- Navigation's moving map (`MovingMap`, `view/moving_map.gd`) is a 2D cross-section of the whole dive, redrawn a few times a second: across is ground distance along the unrolled track (`MovingMap.profile()` of `remembered_path()`, the simulation's perfect record of the path), down is depth, at one scale both ways.
  Its Boundaries are the Inferred Boundaries (`inferred_boundaries()`), never the layout: each patch drawn side-on between its corners, placed across by how far ahead of the Head along the heading they lie (`MovingMap.across()`), as sure as its `confidence`.
  The target depth is `target_depth()`, from the Orders (`Scenario.Goal.target_depth`, NAN for a goal with none).
