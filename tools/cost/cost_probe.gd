## The cost budget's probe (tools/cost/cost.sh): plays a Habitat one frame at
## a time, by hand, and says what each part of the frame cost.
##
## A frame is the game's own: one physics step of the Habitat (the simulation's
## step, then every Station's status lines), one `_process` of every node that
## has one, and every redraw those ask for. The probe takes the nodes'
## processing over so it can time each call, and listens for each
## CanvasItem's `draw` to time the redraws as the engine makes them, so each
## cost is charged to the Station whose screen it is and the part of the
## screen it was. Headless nothing reaches a GPU: this is the scripts' and the
## engine's own work on the CPU (text shaping included), which is where a slow
## query shows.
##
## The simulation's step is timed on a twin: a second simulation of the same
## Scenario given the same commands (send()), stepped beside the Habitat's.
class_name CostProbe
extends RefCounted

## Raised when a frame's redraws are all made.
signal drawn

const Habitat := preload("res://view/habitat.gd")

## The Habitat's step: the game's own physics step.
const STEP := 1.0 / 60.0
## The parts that are no Station's.
const SIMULATION_STEP := "Simulation / step"
const HABITAT_STEP := "Habitat / step: status lines, Arm, crew"
const OTHER_DEFERRED := "Habitat / other deferred work"
## Which group a display that hangs off the Habitat itself belongs to, by its
## class: the Station whose screen shows it, by the name on that screen. The
## Column in the Bore is no Station's.
const SHOWN_AT := {
	"FlightDisplay": "Drive",
	"ScanDisplay": "Navigation",
	"MovingMap": "Navigation",
	"ColumnStrip": "Bore",
}
## A frame's redraws may ask for more; this many rounds of them are waited for.
const _REDRAW_ROUNDS := 8

var _habitat: Node3D
var _sim: DiveSimulation
var _twin: DiveSimulation
## Every part met so far, and the microseconds each cost this frame.
var _parts: Array[String] = []
var _part_index := {}
var _usec := PackedInt64Array()
## The nodes whose `_process` the probe calls, and each one's part.
var _processors: Array[Node] = []
var _processor_parts := PackedInt32Array()
## Instance ids of the nodes already looked at.
var _adopted := {}
var _stale := true
## The redraw being timed: when the last `draw` or mark came, whose it was,
## and whether that node draws in a script (so the time after it is its own).
var _last_usec := 0
var _last_part := 0
var _last_scripted := false
var _drawn_since_end := 0
var _rounds := 0


## A probe on a Habitat that is in the tree, ready, and has not stepped: from
## here it steps only when frame() is called.
func _init(habitat: Node3D) -> void:
	_habitat = habitat
	_habitat.set_physics_process(false)
	_sim = habitat.simulation()
	_twin = (habitat.scenario as Scenario).start()
	_part(SIMULATION_STEP)
	_part(HABITAT_STEP)
	_part(OTHER_DEFERRED)
	habitat.get_tree().node_added.connect(_on_node_added)


## Sends a command to the Habitat's simulation and to the twin.
func send(method: StringName, arguments: Array = []) -> void:
	_sim.callv(method, arguments)
	_twin.callv(method, arguments)


## Plays one frame and returns what each part of it cost, in milliseconds:
## {"<Station or group> / <part>": ms}, only the parts that cost anything.
## Call with `await`, then wait for the tree's next frame before the next.
func frame() -> Dictionary:
	if _stale:
		_adopt(_habitat)
		_stale = false
	_usec.fill(0)
	_begin.call_deferred()
	var before_step := Time.get_ticks_usec()
	_habitat._physics_process(STEP)
	var habitat_step := Time.get_ticks_usec() - before_step
	for station in DiveSimulation.STATIONS:
		_twin.set_attended(station, _sim.attended(station))
	var before_twin := Time.get_ticks_usec()
	_twin.advance(STEP)
	var twin_step := Time.get_ticks_usec() - before_twin
	_twin.take_events()
	_usec[_part_index[SIMULATION_STEP]] = twin_step
	_usec[_part_index[HABITAT_STEP]] = maxi(habitat_step - twin_step, 0)
	for i in _processors.size():
		var node := _processors[i]
		if not is_instance_valid(node) or not node.is_inside_tree():
			continue
		var before := Time.get_ticks_usec()
		node._process(STEP)
		_usec[_processor_parts[i]] += Time.get_ticks_usec() - before
		_mark.call_deferred()
	_rounds = 0
	_drawn_since_end = 0
	_end.call_deferred()
	await drawn
	var cost := {}
	for i in _parts.size():
		if _usec[i] > 0:
			cost[_parts[i]] = _usec[i] / 1000.0
	return cost


## The simulation's queries a screen could poll: every public method of
## DiveSimulation that takes nothing and answers, the commands that answer
## (debug commands, take_events()) left out.
static func queries() -> PackedStringArray:
	var names := PackedStringArray()
	for method in (DiveSimulation as Script).get_script_method_list():
		var name: String = method.name
		var answers: bool = method.return.type != TYPE_NIL \
				or (method.return.usage & PROPERTY_USAGE_NIL_IS_VARIANT) != 0
		if answers and (method.args as Array).is_empty() and not name.begins_with("_") \
				and not name.begins_with("debug_") and not name.begins_with("take_") \
				and not name in names:
			names.append(name)
	return names


## Calls each of queries() once and returns what each call cost, {name:
## milliseconds}. They are asked of the twin, which no screen reads: a query
## that keeps its answer until the simulation changes is timed working it out,
## and the Habitat's frames are left as they were.
func time_queries() -> Dictionary:
	var cost := {}
	for query in queries():
		var before := Time.get_ticks_usec()
		_twin.call(query)
		cost[query] = (Time.get_ticks_usec() - before) / 1000.0
	return cost


## How far the twin has come apart from the Habitat's simulation: metres of
## depth plus seconds of dive time. 0 while its step is the same dive's.
func twin_drift() -> float:
	return absf(_twin.depth() - _sim.depth()) + absf(_twin.dive_time() - _sim.dive_time())


## Milliseconds a fixed piece of GDScript work takes on this machine now: one
## go of it. What the budget is a ratio to; take it often through a run and
## use the middle one, so it is timed under the load the frames are.
static func baseline_ms() -> float:
	var before := Time.get_ticks_usec()
	var turned := Vector3(1.0, 2.0, 3.0)
	var held: Array[Vector3] = []
	var total := 0.0
	for i in 10000:
		turned = turned.rotated(Vector3.UP, 0.001)
		total += turned.length()
		if i % 16 == 0:
			held.append(turned)
	return (Time.get_ticks_usec() - before) / 1000.0


func _on_node_added(_node: Node) -> void:
	_stale = true


## Takes over every node under this one not yet looked at: its `_process` is
## the probe's to call, and its redraws the probe's to time.
func _adopt(node: Node) -> void:
	var id := node.get_instance_id()
	if not _adopted.has(id):
		_adopted[id] = true
		if node.is_processing():
			node.set_process(false)
			_processors.append(node)
			_processor_parts.append(_part(_part_of(node)))
		if node is CanvasItem:
			(node as CanvasItem).draw.connect(_drew.bind(_part(_part_of(node)), node.has_method(&"_draw")))
	for child in node.get_children(true):
		_adopt(child)


## The part a node's cost is charged to: its Station by the name on its screen
## (or the group SHOWN_AT gives its display, or "Habitat"), then the nearest
## class with a name that it is or is inside.
func _part_of(node: Node) -> String:
	var group := ""
	var part := ""
	var at := node
	while at != null and at != _habitat:
		if part.is_empty():
			part = _class_of(at)
		if at is GimballedStation and group.is_empty():
			group = (at as GimballedStation).station_name
			if group.is_empty():
				group = "Empty mount"
		at = at.get_parent()
	if part.is_empty():
		part = "Habitat" if node == _habitat else String(node.name)
	if group.is_empty():
		group = SHOWN_AT.get(part, "Habitat")
	return group + CostBudget.JOIN + part


static func _class_of(node: Node) -> String:
	var script := node.get_script() as Script
	while script != null:
		if not script.get_global_name().is_empty():
			return script.get_global_name()
		script = script.get_base_script()
	return ""


func _part(name: String) -> int:
	if not _part_index.has(name):
		_part_index[name] = _parts.size()
		_parts.append(name)
		_usec.append(0)
	return _part_index[name]


# The engine redraws a CanvasItem from a deferred call: its own drawing (a
# Label's text), then its `draw` signal, then its script's `_draw`. So the
# time since the last signal is the last node's if that one draws in a script,
# and this node's own drawing if not. A mark, deferred between two nodes'
# calls, closes the first one's time.

func _begin() -> void:
	_last_usec = Time.get_ticks_usec()
	_last_part = _part_index[OTHER_DEFERRED]
	_last_scripted = false


func _drew(part: int, scripted: bool) -> void:
	var now := Time.get_ticks_usec()
	_usec[_last_part if _last_scripted else part] += now - _last_usec
	_last_usec = now
	_last_part = part
	_last_scripted = scripted
	_drawn_since_end += 1


func _mark() -> void:
	var now := Time.get_ticks_usec()
	_usec[_last_part if _last_scripted else _part_index[OTHER_DEFERRED]] += now - _last_usec
	_last_usec = now
	_last_part = _part_index[OTHER_DEFERRED]
	_last_scripted = false


func _end() -> void:
	_mark()
	_rounds += 1
	if _drawn_since_end > 0 and _rounds < _REDRAW_ROUNDS:
		# A redraw may have asked for another: those come after this call.
		_drawn_since_end = 0
		_end.call_deferred()
		return
	drawn.emit()
