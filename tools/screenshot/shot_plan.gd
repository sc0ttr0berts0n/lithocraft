## One shot of the screenshot tool (tools/screenshot/shot.sh): which Scenario,
## the dive time to run to, what to look at, the commands to send on the way
## and where the PNG goes. parse() reads it from the tool's arguments and
## stage() brings a Habitat to that moment.
##
## It drives the dive as the view does: the Habitat owns the simulation and
## steps it, and the plan only sends the simulation commands. Nothing here
## reads the clock or a random number, so the same arguments stage the same
## dive every time.
class_name ShotPlan
extends RefCounted

const Habitat := preload("res://view/habitat.gd")
const HABITAT_SCENE := "res://view/habitat.tscn"

## The Habitat's step while staging: the game's own physics step.
const STEP := 1.0 / 60.0
## Looks that are not a Station: the crew's own view from where the dive
## starts them, into the Bore from outside the glass, and the Column as the
## crew see it turning round from the Bore Station's screen. Never one of the
## simulation's names for a Station (the Bore Station's is &"bore").
const LOOK_CREW := &"view:crew"
const LOOK_BORE := &"view:bore"
const LOOK_COLUMN := &"view:column"
## Those looks by the name --look takes.
const VIEWS := {"bore": LOOK_BORE, "column": LOOK_COLUMN, "crew": LOOK_CREW}
## Where the Bore is seen from (Habitat frame): by the outer wall, level with
## the ring of Stations, at this angle round the ring from the first Station
## place, which is midway between two places. It looks straight across at the
## Column with the Tail up, so the Head end is at the bottom of the picture,
## as the Column strip draws it.
const BORE_EYE_RADIUS := 2.6
const BORE_EYE_PLACE := 3.5

## Why the arguments make no shot; empty when they do.
var error := ""
var scenario: Scenario = null
## The dive time the shot is taken at, seconds.
var time := 0.0
## LOOK_CREW, LOOK_BORE, LOOK_COLUMN, or the simulation's name of the Station
## looked at.
var look := &""
## The commands to send, in the order they are sent: each {at = dive time,
## method = a DiveSimulation method, arguments = its arguments}.
var commands: Array[Dictionary] = []
var out := ""
var overlay := false
## How far the look is turned from what it names, in degrees, the eyes staying
## where they are: tilted up (down if negative) and turned to the right (left
## if negative) about the view's own up. For a look along the room's height.
var tilt := 0.0
var turn := 0.0


## The plan these arguments ask for; its `error` says why if they ask for none.
static func parse(arguments: PackedStringArray) -> ShotPlan:
	var plan := ShotPlan.new()
	var scenario_name := "First dive"
	var look_name := ""
	var time_text := ""
	var angles := {"--tilt": "0", "--turn": "0"}
	var i := 0
	while i < arguments.size() and plan.error.is_empty():
		var flag := arguments[i]
		i += 1
		if flag == "--overlay":
			plan.overlay = true
			continue
		if not flag in ["--scenario", "--look", "--time", "--do", "--out", "--tilt", "--turn"]:
			plan.error = "unknown argument '%s'" % flag
		elif i >= arguments.size():
			plan.error = "%s needs a value" % flag
		else:
			var value := arguments[i]
			i += 1
			match flag:
				"--scenario": scenario_name = value
				"--look": look_name = value
				"--time": time_text = value
				"--out": plan.out = value
				"--do": plan._add_command(value)
				"--tilt", "--turn": angles[flag] = value
	if not plan.error.is_empty():
		return plan
	plan.scenario = _scenario_named(scenario_name)
	plan.look = _look_named(look_name)
	if plan.scenario == null:
		plan.error = "no Scenario titled '%s'; there are: %s" % [scenario_name,
				", ".join(Scenario.all().map(func(s: Scenario) -> String: return s.title))]
	elif look_name.is_empty():
		plan.error = "--look is needed: one of %s" % ", ".join(_look_names())
	elif plan.look == &"":
		plan.error = "nothing to look at called '%s'; there are: %s" % [look_name,
				", ".join(_look_names())]
	elif not time_text.is_valid_float() or time_text.to_float() < 0.0:
		plan.error = "--time needs the dive time in seconds, 0 or more"
	elif plan.out.is_empty():
		plan.error = "--out is needed: where the PNG goes"
	for flag: String in angles:
		if plan.error.is_empty() and not (angles[flag] as String).is_valid_float():
			plan.error = "%s needs degrees, got '%s'" % [flag, angles[flag]]
	if not plan.error.is_empty():
		return plan
	plan.time = time_text.to_float()
	plan.tilt = (angles["--tilt"] as String).to_float()
	plan.turn = (angles["--turn"] as String).to_float()
	for command in plan.commands:
		if command.at > plan.time:
			plan.error = "'%s' is sent at %s s, after the shot at %s s" % [
					command.method, command.at, plan.time]
	return plan


## A fresh Habitat that will play the plan's Scenario; add it to the tree,
## then stage() it.
func make_habitat() -> Node3D:
	var habitat: Node3D = (load(HABITAT_SCENE) as PackedScene).instantiate()
	habitat.scenario = scenario
	return habitat


## Brings a Habitat from make_habitat(), now in the tree, to the shot: the
## crew seated at the Station looked at, the dive run to the plan's time in
## the game's own steps with each command sent at its time, and the view set
## on what the plan looks at. From here the Habitat steps only when told, so
## the dive stays at that moment. Returns why it could not, or "".
##
## Times are dive time (DiveSimulation.dive_time()), so a debug_skip() or a
## raised time rate counts for what it ran; once the dive has ended each step
## counts as its own length.
func stage(habitat: Node3D) -> String:
	habitat.set_physics_process(false)
	var sim: DiveSimulation = habitat.simulation()
	if look == LOOK_COLUMN:
		habitat.seat_at(DiveSimulation.STATION_BORE)
	elif not look in VIEWS.values():
		habitat.seat_at(look)
	var after_the_end := 0.0
	var sent := 0
	while true:
		var now := sim.dive_time() + after_the_end
		while sent < commands.size() and commands[sent].at <= now + STEP / 2.0:
			var refused := _send(sim, commands[sent])
			if not refused.is_empty():
				return refused
			sent += 1
			now = sim.dive_time() + after_the_end
		if now >= time - STEP / 2.0:
			break
		habitat._physics_process(STEP)
		if sim.dive_time() + after_the_end <= now:
			after_the_end += STEP
	_frame(habitat)
	return ""


## Sends one command; returns why the simulation refused it, or "".
func _send(sim: DiveSimulation, command: Dictionary) -> String:
	var result: Variant = sim.callv(command.method, command.arguments)
	# Only debug commands answer: a StringName, empty when they acted.
	if result is StringName and result != &"":
		return "'%s' at %s s was refused: %s" % [command.method, command.at, result]
	return ""


## Sets the view on what the plan looks at. Seated, the crew's own eyes
## already do; the Bore gets a camera of its own, and the Column one where
## the crew's eyes are at the Bore Station, turned from the screen to look
## square at the Bore's axis, up still the crew's up. A tilt or turn is taken
## from there, by a camera of its own where that one's eyes are.
func _frame(habitat: Node3D) -> void:
	habitat.get_node("Overlay").visible = overlay
	if look == LOOK_COLUMN:
		var eyes := habitat.get_viewport().get_camera_3d()
		var eye := eyes.global_position
		var turned := Camera3D.new()
		turned.fov = eyes.fov
		habitat.add_child(turned)
		turned.look_at_from_position(eye, Vector3(0.0, 0.0, eye.z), eyes.global_basis.y)
		turned.make_current()
	if look == LOOK_BORE:
		var camera := Camera3D.new()
		camera.fov = 80.0
		habitat.add_child(camera)
		var eye := bore_eye()
		camera.look_at_from_position(eye, Vector3(0.0, 0.0, eye.z), Vector3.BACK)
		camera.make_current()
	if tilt != 0.0 or turn != 0.0:
		var named := habitat.get_viewport().get_camera_3d()
		var moved := Camera3D.new()
		moved.fov = named.fov
		habitat.add_child(moved)
		moved.global_transform = Transform3D(named.global_basis * Basis(Vector3.UP, -deg_to_rad(turn))
				* Basis(Vector3.RIGHT, deg_to_rad(tilt)), named.global_position)
		moved.make_current()


## Where the Bore is seen from (Habitat frame).
static func bore_eye() -> Vector3:
	var angle := Habitat.place_angle(0) + TAU * BORE_EYE_PLACE / Habitat.STATIONS.size()
	return Vector3(cos(angle), sin(angle), 0.0) * BORE_EYE_RADIUS + Vector3(0.0, 0.0, Habitat.ring_z())


## Reads one --do value, "<seconds> <command> [arguments]", checking the
## command against DiveSimulation's public methods, and files it by its time,
## after those already there for the same time.
func _add_command(text: String) -> void:
	var words := text.split(" ", false)
	if words.size() < 2 or not words[0].is_valid_float() or words[0].to_float() < 0.0:
		error = "--do needs \"<seconds> <command> [arguments]\", got \"%s\"" % text
		return
	var method := _command_named(words[1])
	if method.is_empty():
		error = "DiveSimulation has no command '%s'" % words[1]
		return
	var given := words.size() - 2
	var takes: Array = method.args
	if given > takes.size() or given < takes.size() - (method.default_args as Array).size():
		error = "'%s' takes %s, got %d" % [words[1], ", ".join(takes.map(
				func(a: Dictionary) -> String: return a.name)) if not takes.is_empty() else "nothing", given]
		return
	var arguments := []
	for a in given:
		arguments.append(_argument(words[a + 2], takes[a].type))
	var command := {at = words[0].to_float(), method = StringName(words[1]), arguments = arguments}
	var place := commands.size()
	while place > 0 and commands[place - 1].at > command.at:
		place -= 1
	commands.insert(place, command)


## A word of a --do value as the type its parameter takes.
static func _argument(word: String, type: Variant.Type) -> Variant:
	match type:
		TYPE_BOOL: return word.to_lower() in ["true", "on", "yes", "1"]
		TYPE_INT: return word.to_int()
		TYPE_FLOAT: return word.to_float()
		TYPE_STRING_NAME: return StringName(word)
	return word


## DiveSimulation's public method of this name, as its method list gives it,
## or {}.
static func _command_named(name: String) -> Dictionary:
	if name.begins_with("_"):
		return {}
	for method in (DiveSimulation as Script).get_script_method_list():
		if method.name == name:
			return method
	return {}


## A name as it is matched: letters and digits only, lower case, so
## "First dive", "first-dive" and "first_dive" are one name.
static func _plain(name: String) -> String:
	var plain := ""
	for character in name.to_lower():
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			plain += character
	return plain


static func _scenario_named(name: String) -> Scenario:
	for candidate in Scenario.all():
		if _plain(candidate.title) == _plain(name):
			return candidate
	return null


## What a shot can look at, as --look takes it.
static func _look_names() -> PackedStringArray:
	var names := PackedStringArray()
	for station in Habitat.STATIONS:
		if station[2] != &"":
			names.append(station[0])
	names.append_array(VIEWS.keys())
	return names


## The look of this name: a Station by the name on its screen, or one of
## VIEWS; &"" for none.
static func _look_named(name: String) -> StringName:
	for station in Habitat.STATIONS:
		if station[2] != &"" and _plain(station[0]) == _plain(name):
			return station[2]
	for view in VIEWS:
		if _plain(view) == _plain(name):
			return VIEWS[view]
	return &""
