# The view

- `habitat.gd` owns the `DiveSimulation`, sets each Station's attendance from `_at(station)`, calls `advance(delta)` in `_physics_process`, then takes events.
  Child views get the sim handed to them (`DiveView.attach(sim)`, or a public `sim` var on a `Control`).
  A tool that drives a dive from outside (`tools/screenshot`) gets the sim from `simulation()` and sends it commands only, seats the crew with `seat_at(station)` (`Arm.seat()`: held at once, as after a carry), and steps the Habitat by calling `_physics_process(step)` itself with its physics processing off.
- `_at(station)`: the crew member is seated there by the Arm, or within `STATION_REACH` of its pivot.
  Every Station key is gated by `_at` of its Station, once, in the key map's dispatch (see Key map); a `_key_` handler need not check it.
- Nothing is drawn over the crew's view (story 52).
  What the crew must know goes on a Station screen, into the Bore, or into shake and sound.
  The one mark drawn over it is the centre dot (`habitat.gd::_build_dot`), shown only while the mouse is captured, brighter over a reading.
  The only screen-space text is the centre notice (`_show_notice(lines, seconds)`, 0 = until replaced), the F1 controls (`ControlsPanel`, hidden by default), the Tab checklist (`ChecklistPanel`, upper left, hidden by default; reads the simulation, and opening it sends `read_orders()`), the F3 `DiveView` debug overlay (upper right:
  its readings left of the survey and tunnel panels and the Column strip; hidden by default; reads only, sends no commands) and the numpad debug menu (`DebugPanel`, `view/debug_panel.gd`, hidden by default, drawn over the notice; it reads the simulation, and its keys, dispatched by the Habitat, send debug commands).
  The debug menu and F1 share the lower left: opening one closes the other.
  Keep Medium names off anything always on screen: the Medium is recognised by its look in the Bore.
- Mouse look goes through `CrewMember.look(relative)`, on foot and in the Arm alike.
  Held, the Arm sets the pose each frame and the look is kept as a turn in the harness on top of it; while carried, the look eases to the new screen unless the mouse has moved during the carry.
  `CrewMember.view()` is where the eyes look, the centre dot along its -Z.
- Pointing: `habitat.gd::under_dot()` returns the Station and the index of the reading under the centre dot (or -1 between readings, `{}` for no screen, and the Column in the Bore hides the screens across it).
  The geometry is `Pointing.under()` over each Station's `GimballedStation.face()`, whose readings are its screen text's lines (the name first), then its displays left to right, then a lone display's instruments;
  `reading(index)` gives a line's text, `is_display(index)` whether it is a display and `display_index(index)` which one, counting from the crew's left (Navigation shows two: the point cloud, then the moving map), `instrument(index)` an instrument's name.
  A display's instruments are passed to `show_display(texture, instruments)` as `{name: Rect2}` in shares of the picture (0 to 1, x across, y down), as `FlightDisplay.instrument_shares()` gives the Drive's.
  A later reading may lie over an earlier one, and the later is the one pointed at.
  A new kind of reading on a screen (a widget, a gauge) adds its rectangle to `face()` in face coordinates (metres, x the crew's right, y up).
- Station places: `habitat.gd::STATIONS` is the order round the ring, `place_angle()` / `pivot()` where each hangs (half a place off straight down, so level no Station is straight below or above the Bore).
  Each gimbal hangs `STATION_HANG` in from the outer wall and settles upright with its screen turned to face the Bore (`GimballedStation.settled_cradle()`): the crew work every Station from the Bore side, looking out at it with the wall behind the screen and the Column behind them.
  Tests read this layout data (`preload("res://view/habitat.gd")`), never a copy of it.
- Anything drawn along the Column pins each piece to its path position (`distance() - behind_head`) so it scrolls at exactly `speed()`.
  Never integrate speed in the view.
  The Bore's Column uses its own tube mesh with explicit UVs, because `CylinderMesh` shares its texture with its caps.
- Controls that sit over the Habitat set `mouse_filter = 2` so clicks reach the mouse capture.
  An `HSlider` sets `focus_mode = 0` so arrow keys reach `_unhandled_input`.
- The start menu (`StartMenu`, `view/start_menu.gd`) lists `Scenario.all()` and starts the chosen one in a fresh Habitat (`habitat.scenario`, set before it enters the tree; the First dive when the Habitat runs on its own).
  Its keys (1 to 9, main keys or keypad) are its own, outside the key map, and Enter does nothing there, so the Enter that ended a dive cannot start another.
  Enter at a dive's end changes scene back to the menu, so every dive is a fresh `DiveSimulation` from its Scenario (`new_dive()` stays on the simulation, but the view no longer calls it).
  The Habitat reads its copies of the Station settings (power, effort, heat split) from the simulation at `_ready`, never sends its own, since a Scenario may start with them set.
- The end of a dive (`OutcomeScreen`): once `surfaced()` or `dead()`, the crew's shake is only the end lurch, `OutcomeScreen.step()`, started by `_end_dive()` from the shake of the frame before and settling to exactly 0; the notice that was up goes as it starts, and the outcome sentence (`OutcomeScreen.sentence(_sim.outcome())`) with the breakdown under it shows once `still()`.
  Both endings' handlers (`_on_hull_failed`, `_on_paid`) hand their breakdown lines to `_end_dive()`; a new ending's breakdown does the same.
- Hull damage is felt, never drawn (`view/hull_feel.gd`, `HullFeel`): while `hull_taking_damage()` sparks spit from the outer wall (more emitters the faster it creeps) and `shake_metres()` adds to the crew's shake;
  groans come from points round the ring as `AudioStreamPlayer3D`s, timed and sized by `HullGroans` from wear and `hull_stress()`, and rising with `self_destruct_hold()` while the crew holds K.
  The Habitat calls `HullFeel.step(delta, felt)` after `advance`.
  Shake from any source sums into the one `_crew.shake()` call.
- Chance that shows in the picture is repeatable, so two screenshots of one moment match: drawn in the Habitat's physics step from the global generator, which the screenshot tool seeds (the crew's shake, where the sparks spit), or from a generator of the node's own with a fixed seed (a starved screen's flicker).
  Never from the global generator in `_process`, where the sounds draw on it by the clock, nor from one seeded with `randomize()`.
- Sounds are generated until real assets exist: a looping `AudioStreamGenerator` for continuous sound (`SlipSound`), an `AudioStreamWAV` built once at `_ready` for one-shots (`HullFeel._make_groan`).
