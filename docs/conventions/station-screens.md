# The Station screens

## The frame, the Theme and the colour language

- **A Station screen is a composition, not floating text.**
  Each `GimballedStation` shows a `StationScreen` (`view/station_screen.gd`): Controls and Containers in a `SubViewport`, under the one `StationTheme`, drawn on the screen's panel as a texture.
  No Station shows a `Label3D`: every reading is on the screen, and `station_screen_test.gd` fails a Station that floats text or lays a reading off its screen.
- **The frame, top to bottom:** the header strip, the body, the status lines, the footer.
  The header strip is laid out the same on every Station: its name, its autopilot's state (green AUTOPILOT, amber while AUTOPILOT OFF flashes, then white), and its Caution lamps at the right.
  The body is the Station's own instrument and takes all the room the rest leaves; a Station with none yet gives the room to its status lines.
  The status lines are the Station's readings as text, shrunk together until every line is whole (`StationScreen.fitting_font_size()`), at most `STATUS_MOST` of the room under an instrument.
  The footer is one line every Station shows alike (the time rate).
- **Putting a Station's instrument in the body** is one call as the Station is built in `habitat.gd::_build_stations`:
  `station.screen().set_instrument(control)` for any Control (it is made to fill the body and resized with it: lay it out by its own `size` or build it of Containers; the Bore Station's `_bore_instrument()` is the example);
  or `station.show_display(texture, instruments)` / `show_displays(textures)` for a picture drawn in its own `SubViewport` (a 3D display, or one not yet moved onto Controls), which keeps its shape, centred in the body.
  Size such a viewport from `StationScreen.body_size(lines)`, the body's pixels over that many status lines.
  A Station should come to look its own by its instrument; the name in the header is the fallback.
- **A screen the crew is not at draws less** (`ScreenPace`, `view/screen_pace.gd`): an instrument that redraws itself does so every frame while the crew is at its Station (`attended()`), and every `ScreenPace.UNWATCHED_S` (0.1 s, to the frame) while they are not, so a changed reading is on a watched screen the next frame and on any other within that.
  Each instrument asks `_pace.due_at(delta, sim, station)` in its `_process` and calls `_pace.hurry()` when it is resized, so a new size is drawn at once; a panel shown off any Station (the debug overlay's) names none and draws every frame.
  The Reactor's, the Drive's, the Thermal's and the Bore Station's instruments are paced; Navigation's keep their own pace (`screen-navigation.md`) and the Column is no Station's.
  A shot repeats byte for byte all the same: the simulation does not move while it is drawn, and the first frame always draws.
- **Status lines** go through `station.show_lines(lines)` every frame from the Habitat's `_show_<station>()`: each line a String (white) or `[text, meaning]`, the meaning one of `StationTheme`'s.
  `show_reading(text)` is the same with every line white.
- **Caution lamps** (`GLOSSARY.md`) are declared in `CautionLamps.of(sim, station)` (`view/caution_lamps.gd`): one line per lamp, its label and the simulation query that lights it.
  The Habitat hands each Station's to its header strip every frame (`show_lamps()`), so a lamp lights and clears from the simulation's state alone; a lamp keeps its place lit or not.
  The Reactor's three (HEAD WORN, HOT, OUT OF BAND) are the causes `steadiness_causes()` names, one lamp each.
  Tested in `caution_lamps_test.gd`, through the simulation.
- **One colour language on every screen, an airliner's** (`StationTheme`, `view/station_theme.gd`): white is what is happening now, cyan what the crew has selected or aims for (the Course, a setting, a target), green engaged and working, amber a caution, red a warning (what is about to kill the crew).
  Beside the five are only the screen's neutrals, which say nothing: its background, the grey of a legend (a title, a unit, a scale), the darker grey of a rule or an unlit lamp, and two backdrops for a picture of the world.
  The rock's own colours (`ColumnLook`) are a picture too, not language.
  A Station's hue (`habitat.gd::STATIONS`) is for objects in the room, its call light and its gimbal's bob, which let the crew tell across the Habitat which Station calls; never a reading, so not its screen and not its name on the checklist (`ChecklistPanel` writes in the five colours and the legend grey).
- **The Theme is the only place a screen's colours are written.**
  Controls take them from `StationTheme.theme()` by type variation (`StationTheme.variation(meaning)` on a Label); a display that draws itself reads the constants (`StationTheme.CAUTION_COLOUR`), fainter through `StationTheme.faded()`.
  `station_theme_test.gd` fails any script in `view/` that writes a colour (`Color(...)`, `Color.NAME`), unless it is listed there as drawing nothing on a Station screen; a new screen script is checked without being listed.
- **The key list** beside each screen (`KeyList`, `view/key_list.gd`, on the crew's right) is built the same way from `show_keys(KeyMap.bindings_at(station))`: what a key does wraps, and the whole list shrinks until every row is on the panel, so it is never cut off (`station_screen_test.gd`).
- **Read from the Arm's hold.**
  The screen (`GimballedStation.SCREEN_SIZE`) and key panel are sized so both are whole in the view from the working pose at 1152x648; check a change with the sheet of every Station (`tools/screenshot/shot.sh --sheet tools/screenshot/recipes/stations.txt`).
  A Control's place is known only once its Station is in the tree and a frame has passed, so a test of `face()` adds the Station as a child and awaits two frames.
- `GimballedStation` besides: `set_supplied(share)` dims a starved screen and its key list, `set_call(urgency)` beats the Station's tone and flashes its light.
  Set `call_tone_hz` / `call_pips` before `_ready`.
  The autopilot's disconnect tone (`disengage_tone()`) is soft on purpose: no note above the Stations' call tones, no hard edge, quieter than a call (`autopilot_caption_test.gd`).
