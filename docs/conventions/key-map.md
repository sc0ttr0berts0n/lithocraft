# Key map

Stand-in keys until the Stations get their own widgets, levers and knobs.
`KeyMap.BINDINGS` (`view/key_map.gd`) is the one source: the Habitat's input, walking (`crew_member.gd` reads `KeyMap.held(&"walk")`), each Station's key panel, every key hint in a reading or notice and the F1 controls all read it, so none can disagree with what a key does.
Never write a key's name into text by hand: use `KeyMap.label(action)` ("[N/M]") or `KeyMap.label(action, index)` ("[N]").

**Adding a key is one line** in `BINDINGS`: `{where = <ANYWHERE or DiveSimulation.STATION_...>, keys = [KEY_...], does = "what it does", action = &"name"}`, plus its handler in `habitat.gd`, `func _key_<action>(index: int)` (`index` is which of the keys was pressed; `_minus_plus(index)` reads a "-/+" pair).
The panel, F1 and the dispatch follow with no other change.
`key_map_test.gd` fails if the handler is missing, if two press bindings share a key at one place, or if a Station key would be shadowed where it is shown.

- **Where**: a Station binding runs only while `_at` that Station; ANYWHERE always.
  A key may be bound at several places (the Course keys at Navigation and the Drive); a press runs the first binding, in list order, that applies where the crew stands.
  List order is also the order on the panel and in F1.
- **Held keys** (`held = true`): not run on a press; read each frame with `KeyMap.held(action)` (one bool per key).
  Use it for walking.
  A key that acts on its press and while held (K, self-destruct: press to start the hold or cancel, release to stop) is a press binding whose handler starts the hold; `_physics_process` reads `KeyMap.held(action)` for the release.
- **Prompts**: `KeyPrompt.texture(code)` finds `assets/prompts/keyboard/<Name>_Key_Light.png` by Godot's key name (exceptions in `KeyPrompt._FILE_NAMES`); a key with no picture is drawn as the blank key with `KeyPrompt.glyph(code)` on it, so a new key shows even before its picture is copied in.
  To give it its own, copy the light image from Xelu's pack (https://thoseawesomeguys.com/prompts/, CC0) into that folder.
  Keys that look the same (Enter, keypad Enter) are drawn once (`KeyPrompt.distinct`).
- **A new place**: give its bindings a new `where`; F1 lists every place in `KeyMap.places()` with its title from `habitat.gd::_build_controls` (except `KeyMap.DEBUG`), and the dispatch runs them once `_wheres()` includes it.
- **The debug menu** is the place `KeyMap.DEBUG`: its keys run only while the menu shows (`_wheres()` adds it then), and numpad minus (an ANYWHERE binding, `debug_menu`) opens and closes it.
  Each debug binding has one key, so the menu can write its `does` beside it; `DebugPanel.LAYOUT` places each numpad key (`key`, `at`, `span`; Num Lock, which does nothing, is left out), and a key with no debug binding shows what it does anywhere, or is dimmed.
  Its handlers pass what `DiveSimulation.debug_*` returns to `DebugPanel.report()`, so a refusal shows on the status line (or, for the overlay, toggle the view); they are not crew controls and F1 does not list them.
  A new debug key: a binding with `where = DEBUG` on a free numpad key, its `_key_debug_<name>` handler, and its `debug_*` command with a test (see Extension points).
  The numpad's own prompts: the main keys' pictures for digits, + - and *; Xelu's "Slash" is a backslash, so `/` and `.` are blank keys with glyphs; the tall + and Enter use the pack's `_Tall_` pictures (`KeyPrompt.texture(code, true)`).

| Where | Keys |
|---|---|
| Anywhere | WASD walk; mouse look (click captures, Esc releases); Space calls the Arm / lets go; A / D while held: next Station left / right |
| Anywhere | Tab the checklist (orders, next step, surface control) |
| Anywhere | `.` time rate x4 (held at x1 while any Station calls, except stranded or self-destructing), `,` normal; Enter / keypad Enter: back to the start menu (ignored unless surfaced or dead, and while the end lurch settles); F1 controls; F3 debug overlay; F4 debug: Navigation's next scan view (the three candidates of the point cloud) |
| Navigation | Plot the Course: 1 / 2 / 3 pitch dive / level / climb, Z / X pitch -/+15 deg, J / L heading -/+15 deg; P pulse; Q Quiet Ship |
| Drive | T / G power +/-10%; Y / H steering effort +/-10%; the Course keys override the Course from what the Drive steers toward now; O ends the override |
| Bore Station | F observe the next feature in the Column; U cycle upload priority; B stop / start the link |
| Thermal | C / V heat split outward / into the Column, 10% a press; stranded, how hard the pumps cool the hull on the store. Hold K three seconds: self-destruct (the view sends `hold_self_destruct()` each frame while K is held, the simulation counts the hold); K while it runs cancels it |
| Reactor | N / M STANDBY down / up 2%; R swaps STANDBY and ACTIVE: the Shift (again: swaps back, another Shift); I relight the Head from the emergency store (stranded only; its own key so a Shift pressed as the plasma goes cannot spend the store) |
| Every Station | E: that Station's autopilot on / off (any setting key there switches it off, with the disconnect tone and AUTOPILOT OFF flashing on the screen) |
| Anywhere | numpad - opens and closes the debug menu |
| Debug menu (open) | numpad: / overlay (as F3), * surface now, + skip 5 min; 7 / 4 hull wear +/-10%, 1 hull to the brink; 8 / 5 Head wear +/-10%, 2 a Shift due now; 9 to the next Boundary, 6 strand now, 3 lose the plasma; 0 refill the emergency store; . self-destruct now. Numpad Enter keeps its anywhere meaning (back to the start menu) |

The table is a summary for planning; `BINDINGS` is the truth.
Check both before binding a key.
