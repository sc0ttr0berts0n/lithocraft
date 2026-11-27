# The view

- `habitat.gd` owns the `DiveSimulation`, sets each Station's attendance from `_at(station)`, calls `advance(delta)` in `_physics_process`, then takes events.
  Child views get the sim handed to them (`DiveView.attach(sim)`, or a public `sim` var on a `Control`).
  A tool that drives a dive from outside (`tools/screenshot`) gets the sim from `simulation()` and sends it commands only, seats the crew with `seat_at(station)` (`Arm.seat()`: held at once, as after a carry), and steps the Habitat by calling `_physics_process(step)` itself with its physics processing off.
- A Station's tint (`habitat.gd::STATIONS`) is allowed only on objects in the room: its call light and its gimbal's bob. Never on a reading (a screen, the checklist, a notice): readings use the five colours of `StationTheme`, held by `station_theme_test.gd`'s source check, which reads `checklist_panel.gd` too.
- `_at(station)`: the crew member is seated there by the Arm, or within `STATION_REACH` of its pivot where it is now.
  That is all the view says of a Station that slides away: it reports reach each step (`set_attended()`), and the simulation decides what a held command does (see Self-destruct), so there is no reach check per command.
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
  The geometry is `Pointing.under()` over each Station's `GimballedStation.face()`, whose readings are its screen's text top to bottom (the header strip with the name first, each status line, the footer), then its displays left to right, then a lone display's instruments, then the readings inside an instrument made of Controls;
  `reading(index)` gives a line's text, `is_display(index)` whether it is a display and `display_index(index)` which one, counting from the crew's left (Navigation shows two: the point cloud, then the moving map), `instrument(index)` an instrument's name.
  A display's instruments are passed to `show_display(texture, instruments)` as `{name: Rect2}` in shares of the picture (0 to 1, x across, y down), as `FlightDisplay.instrument_shares()` gives the Drive's.
  A later reading may lie over an earlier one, and the later is the one pointed at.
  An instrument put in the body by `set_instrument()` names what the crew can point at on it with `readings() -> Dictionary`, `{name: Rect2}` in its own pixels (`ThermalGauge.readings()`, `PlasmaDisplay.readings()`, the Bore Station's two panels);
  `StationScreen.instrument_readings()` finds every Control in the body that has one, `face()` adds them and `instrument(index)` gives their names, so a new gauge adds only its `readings()`.
  `pointing_test.gd` seats the crew at each Station of a real Habitat and turns the look (`Habitat.look_onto(point)`) onto a reading inside its instrument.
  Any other kind of reading adds its rectangle to `face()` in face coordinates (metres, x the crew's right, y up); `GimballedStation._on_face()` turns a rectangle in the screen's pixels into them.
- Station places: `habitat.gd::STATIONS` is the order round the ring, `place_angle()` / `pivot()` where each hangs (half a place off straight down, so level no Station is straight below or above the Bore).
  Each gimbal hangs `STATION_HANG` in from the outer wall and settles upright with its screen turned to face the Bore (`GimballedStation.settled_cradle()`): the crew work every Station from the Bore side, looking out at it with the wall behind the screen and the Column behind them.
  Tests read this layout data (`preload("res://view/habitat.gd")`), never a copy of it.
- The Habitat's shape: `LENGTH` along the Bore (its height in a dive or a climb) is about 1.45 times its width, and the node's origin is the middle of that length, the Head end cap at `-LENGTH / 2`.
  `habitat.gd::ring_z(slid)` is the one place that says where along the Bore the ring of Stations and the Arm's rail are: `RING_ABOVE_HEAD_FLOOR` from the Head end cap at 0, `RING_ABOVE_TAIL_FLOOR` from the Tail end cap at 1.
  `slid` is the simulation's `station_ring()`, which owns the slide (when it starts, how long it takes); `Habitat._place_ring()` puts the Stations, their struts and the Arm's rail (`Arm.slide_to()`) there each step, and nothing else may place them along the axis.
  The static `pivot(place, slid)` and `new_arm(slid)` default to the Head end, for tests and tools; anything that wants the ring now reads the Station's `position` or `ring_z(sim.station_ring())`.
  `habitat_layout_test` holds every screen and key panel inside the room at every pitch at both ends and all along the slide; a larger screen or a ring nearer a wall must keep it passing.
- The Arm's rail runs along the Bore (`Arm.rail_z()`, drawn by `ArmView`): level with the ring unless called, when it first runs to the crew member (`RUN_SPEED`), reaches only once level with them, then runs back as it carries them.
  Seated, the crew member's pose is their Station's each step, so they ride a slide with nothing more done.
- Anything drawn along the Column pins each piece to its path position (`distance() - behind_head`) so it scrolls at exactly `speed()`.
  Never integrate speed in the view.
  The Bore's Column uses its own tube mesh with explicit UVs, because `CylinderMesh` shares its texture with its caps.
  `ColumnStrip` builds each band's grains once, as one mesh it keeps while the band is in the strip, and each frame only moves it: the Bore's strip holds some twelve thousand grains, too many to place and draw one by one every frame.
  `Habitat.column_z(behind_head)` (and `behind_head_at(z)`, its inverse) is the one account of where the Habitat sits along the vessel: place anything in the Bore from the simulation's distance behind the Head through it, never from the Habitat's length.
- A feature of interest is drawn by `FeatureLook` (`view/feature_look.gd`) on the Column strip, in metres, at the row of its `ColumnFeature.at` (`ColumnStrip.feature_box()`).
  A new kind adds its line to `FeatureLook.LOOKS` (how wide across the Column, and its paint function); `feature_look_test` fails on a kind any Scenario's layout holds that has none.
  A look must read from across the Habitat against the grain speckle: a backing or a rim, pieces several grains wide, and no near-black, which shows green in the Bore.
  In the Bore every feature is turned to the Bore Station (`ColumnStrip.features_face`, set each step from `bore_station_place()`), so the crew turn from its screen and find it; the flat overlay strip leaves it at -1 and each feature keeps a place of its own.
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
  The Habitat calls `HullFeel.step(delta, felt, crew_z)` after `advance`.
  Sparks and groans keep to the `TUNED_IN_M` of wall about the crew (`HullFeel.near_crew()`), never the Habitat's whole length: a longer room must not thin them, and a denser feel is a retune there, not more emitters.
  `hull_feel_test` holds the density per metre of wall near the crew to a room `TUNED_IN_M` long.
  Shake from any source sums into the one `_crew.shake()` call.
- Chance that shows in the picture is repeatable, so two screenshots of one moment match: drawn in the Habitat's physics step from the global generator, which the screenshot tool seeds (the crew's shake, where the sparks spit), or from a generator of the node's own with a fixed seed (a starved screen's flicker).
  Never from the global generator in `_process`, where the sounds draw on it by the clock, nor from one seeded with `randomize()`.
- Sounds are generated until real assets exist: a looping `AudioStreamGenerator` for continuous sound (`SlipSound`), an `AudioStreamWAV` built once at `_ready` for one-shots (`HullFeel._make_groan`).
