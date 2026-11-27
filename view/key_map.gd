## The key map: every key the crew can press, where it works and what it does.
## The one source for the Habitat's input, each Station's key panel, the key
## prompts in its readings and notices, and the F1 controls, so none of them can
## disagree with another. Stand-in keys until the Stations get their own
## widgets, levers and knobs.
class_name KeyMap
extends RefCounted

## Where a binding works when it is not at a Station.
const ANYWHERE := &"anywhere"
## Where the developer's debug keys work: anywhere, but only while the numpad
## debug menu is open. Not crew controls: each runs a simulation debug command
## (DiveSimulation.debug_*) or a view toggle.
const DEBUG := &"debug"
## The mouse as a key: any mouse button pressed.
const MOUSE := -1

## One line per binding, in the order the F1 controls and each Station's panel
## show them:
## - `where`: ANYWHERE, DEBUG (only while the debug menu is open), or the
##   simulation's name for the Station the crew must be at (the Habitat
##   checks `_at`, so handlers need not).
## - `keys`: physical keycodes (or MOUSE); the handler is told which by index.
## - `does`: what the keys do, shown beside their prompts. Several keys share
##   one line, "/" between what each does.
## - `action`: the Habitat runs `_key_<action>(index)` on a press.
## - `held` (optional, default false): not run on a press; whoever needs it
##   reads `KeyMap.held(action)` each frame. A key that acts on its press and
##   also while held (K, self-destruct) is a press binding whose handler
##   starts the hold, and reads `KeyMap.held(action)` for the release.
## A key may be bound in several places (Z / X and J / L plot the Course at
## Navigation and nudge off it at the Drive); a press runs the first binding, in this order, that applies
## where the crew stands.
const BINDINGS: Array[Dictionary] = [
	{where = ANYWHERE, keys = [MOUSE], does = "capture the mouse to look", action = &"capture_mouse"},
	{where = ANYWHERE, keys = [KEY_ESCAPE], does = "let go of the mouse", action = &"release_mouse"},
	{where = ANYWHERE, keys = [KEY_W, KEY_A, KEY_S, KEY_D], does = "walk", action = &"walk", held = true},
	{where = ANYWHERE, keys = [KEY_SPACE], does = "call the Arm / let go", action = &"arm"},
	{where = ANYWHERE, keys = [KEY_A, KEY_D], does = "carried: next Station left / right", action = &"next_station"},
	{where = ANYWHERE, keys = [KEY_PERIOD], does = "time x4 (an unacknowledged warning holds it at x1, but stranded or self-destructing)", action = &"time_faster"},
	{where = ANYWHERE, keys = [KEY_COMMA], does = "time normal", action = &"time_normal"},
	{where = ANYWHERE, keys = [KEY_SLASH], does = "acknowledge every call sounding (its light stays lit)", action = &"acknowledge_calls"},
	{where = ANYWHERE, keys = [KEY_ENTER, KEY_KP_ENTER], does = "dive over: back to the start menu", action = &"new_dive"},
	{where = ANYWHERE, keys = [KEY_F1], does = "these controls", action = &"toggle_controls"},
	{where = ANYWHERE, keys = [KEY_TAB], does = "the checklist: orders, next step, surface control", action = &"toggle_checklist"},
	{where = ANYWHERE, keys = [KEY_F3], does = "debug overlay", action = &"toggle_debug"},
	{where = ANYWHERE, keys = [KEY_KP_SUBTRACT], does = "debug menu", action = &"debug_menu"},
	{where = ANYWHERE, keys = [KEY_F4], does = "debug: Navigation's next scan view", action = &"scan_view"},
	# E at every Station: its autopilot's switch (DiveSimulation.set_autopilot()).
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_E], does = "autopilot on / off", action = &"autopilot_navigation"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_1, KEY_2, KEY_3], does = "Course dive / level / climb", action = &"plot_pitch"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_Z, KEY_X], does = "Course pitch -/+15 deg", action = &"plot_pitch_step"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_J, KEY_L], does = "Course heading -/+15 deg", action = &"plot_heading_step"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_P], does = "pulse", action = &"pulse"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_Q], does = "Quiet Ship", action = &"quiet_ship"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_B, KEY_N], does = "Beam wider / narrower", action = &"beam_width"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_O], does = "Beam pulses by itself on / off", action = &"beam_pulsing"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_V], does = "Sweep: start / stop", action = &"sweep"},
	{where = DiveSimulation.STATION_NAVIGATION, keys = [KEY_G, KEY_T], does = "Sweep range shorter / longer", action = &"sweep_range"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_E], does = "autopilot on / off", action = &"autopilot_drive"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_T, KEY_G], does = "throttle +/-10%", action = &"power_step"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_Y, KEY_H], does = "steering effort +/-10%", action = &"effort_step"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_Z, KEY_X], does = "nudge off the Course: up / down", action = &"nudge_pitch"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_J, KEY_L], does = "nudge off the Course: left / right", action = &"nudge_heading"},
	{where = DiveSimulation.STATION_DRIVE, keys = [KEY_O], does = "back to the Course", action = &"end_override"},
	{where = DiveSimulation.STATION_BORE, keys = [KEY_E], does = "autopilot on / off", action = &"autopilot_bore"},
	{where = DiveSimulation.STATION_BORE, keys = [KEY_F], does = "observe the next feature", action = &"observe"},
	{where = DiveSimulation.STATION_BORE, keys = [KEY_U], does = "which survey goes up first", action = &"upload_priority"},
	{where = DiveSimulation.STATION_BORE, keys = [KEY_B], does = "stop / start the link", action = &"link"},
	{where = DiveSimulation.STATION_THERMAL, keys = [KEY_E], does = "autopilot on / off", action = &"autopilot_thermal"},
	{where = DiveSimulation.STATION_THERMAL, keys = [KEY_C, KEY_V], does = "heat out / into the Column", action = &"heat_split"},
	{where = DiveSimulation.STATION_THERMAL, keys = [KEY_K], does = "hold: self-destruct; again: cancel", action = &"self_destruct"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_E], does = "autopilot on / off", action = &"autopilot_reactor"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_C], does = "tune STANDBY / ACTIVE", action = &"select_channel"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_N, KEY_M], does = "Counter-wave frequency down / up", action = &"tune_frequency"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_J, KEY_K], does = "Counter-wave amplitude down / up", action = &"tune_amplitude"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_R], does = "swap STANDBY in: the Shift", action = &"shift"},
	{where = DiveSimulation.STATION_REACTOR, keys = [KEY_I], does = "stranded: relight the Head", action = &"relight"},
	# The numpad debug menu, laid out as the numpad: one key each, so the
	# menu can write what each does beside it.
	{where = DEBUG, keys = [KEY_KP_DIVIDE], does = "debug overlay (F3)", action = &"debug_overlay"},
	{where = DEBUG, keys = [KEY_KP_MULTIPLY], does = "surface now", action = &"debug_surface"},
	{where = DEBUG, keys = [KEY_KP_ADD], does = "skip 5 minutes", action = &"debug_skip"},
	{where = DEBUG, keys = [KEY_KP_7], does = "hull wear +10%", action = &"debug_hull_wear_up"},
	{where = DEBUG, keys = [KEY_KP_4], does = "hull wear -10%", action = &"debug_hull_wear_down"},
	{where = DEBUG, keys = [KEY_KP_1], does = "hull to the brink", action = &"debug_hull_brink"},
	{where = DEBUG, keys = [KEY_KP_8], does = "Head wear +10%", action = &"debug_head_wear_up"},
	{where = DEBUG, keys = [KEY_KP_5], does = "Head wear -10%", action = &"debug_head_wear_down"},
	{where = DEBUG, keys = [KEY_KP_2], does = "detune ACTIVE now", action = &"debug_detune"},
	{where = DEBUG, keys = [KEY_KP_9], does = "to the next Boundary", action = &"debug_next_boundary"},
	{where = DEBUG, keys = [KEY_KP_6], does = "strand now", action = &"debug_strand"},
	{where = DEBUG, keys = [KEY_KP_3], does = "lose the plasma", action = &"debug_lose_plasma"},
	{where = DEBUG, keys = [KEY_KP_0], does = "refill the emergency store", action = &"debug_refill_store"},
	{where = DEBUG, keys = [KEY_KP_PERIOD], does = "self-destruct now", action = &"debug_self_destruct"},
]

## Short names for keys where Godot's own is long or a word for a symbol.
const _NAMES := {
	KEY_PERIOD: ".",
	KEY_COMMA: ",",
	KEY_SLASH: "/",
	KEY_ESCAPE: "Esc",
	KEY_KP_ENTER: "Enter",
	MOUSE: "Click",
	KEY_KP_ADD: "Num +",
	KEY_KP_SUBTRACT: "Num -",
	KEY_KP_MULTIPLY: "Num *",
	KEY_KP_DIVIDE: "Num /",
	KEY_KP_PERIOD: "Num .",
	KEY_NUMLOCK: "Num Lock",
}


## Every binding, each with every field (`held` filled in).
static func bindings() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for binding in BINDINGS:
		var full := binding.duplicate()
		full.held = binding.get(&"held", false)
		all.append(full)
	return all


## The bindings that work at one place (ANYWHERE or a Station), in order.
static func bindings_at(where: StringName) -> Array[Dictionary]:
	var here: Array[Dictionary] = []
	for b in bindings():
		if b.where == where:
			here.append(b)
	return here


## The binding for an action, or {} if there is none.
static func binding(action: StringName) -> Dictionary:
	for b in bindings():
		if b.action == action:
			return b
	return {}


## Every place with keys, ANYWHERE first, in the order they first appear.
static func places() -> Array[StringName]:
	var found: Array[StringName] = []
	for b in BINDINGS:
		if not found.has(b.where):
			found.append(b.where)
	return found


## What a press of `code` runs where the crew stands (`wheres`: ANYWHERE and
## the Stations they are at): `{action, index}`, or {} when nothing.
static func find(code: int, wheres: Array) -> Dictionary:
	for b in bindings():
		if b.held or not wheres.has(b.where):
			continue
		var index: int = b.keys.find(code)
		if index >= 0:
			return {action = b.action, index = index}
	return {}


## The key code a fresh press in this event is, MOUSE for a mouse button, or
## KEY_NONE for anything else (a release, an echo, motion).
static func code_of(event: InputEvent) -> int:
	if event is InputEventMouseButton and event.pressed:
		return MOUSE
	if event is InputEventKey and event.pressed and not event.echo:
		return (event as InputEventKey).physical_keycode
	return KEY_NONE


## Whether each of a held binding's keys is down now, in its key order.
static func held(action: StringName) -> Array[bool]:
	var down: Array[bool] = []
	for code in binding(action).keys:
		down.append(Input.is_physical_key_pressed(code))
	return down


## A key's short name as written in text: "T", "Enter", ".", "Num 7".
static func name_of(code: int) -> String:
	if code >= KEY_KP_0 and code <= KEY_KP_9:
		return "Num %d" % (code - KEY_KP_0)
	return _NAMES.get(code, OS.get_keycode_string(code))


## An action's keys for a reading or notice: "[N/M]"; with `index`, only
## that one of them: "[N]".
static func label(action: StringName, index := -1) -> String:
	var keys: Array = binding(action).keys
	if index >= 0:
		keys = [keys[index]]
	var names := PackedStringArray()
	for code in keys:
		if not names.has(name_of(code)):
			names.append(name_of(code))
	return "[%s]" % "/".join(names)
