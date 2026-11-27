# How often a Station screen's instrument brings itself up to the simulation
# (ScreenPace): every frame while the crew is at its Station, a few times a
# second while they are not, and never later than UNWATCHED_S and a frame.
extends GdUnitTestSuite

const FRAME := 1.0 / 60.0


## The frames, of `count` played `delta` apart, that were due.
func _due_frames(pace: ScreenPace, count: int, delta: float, watched: bool) -> Array[int]:
	var due: Array[int] = []
	for frame in count:
		if pace.due(delta, watched):
			due.append(frame)
	return due


func test_a_watched_screen_is_brought_up_every_frame() -> void:
	assert_int(_due_frames(ScreenPace.new(), 120, FRAME, true).size()).is_equal(120)


func test_an_unwatched_screen_is_brought_up_first_then_less_often_but_never_later_than_its_lag() -> void:
	for delta: float in [FRAME, 1.0 / 144.0, 1.0 / 30.0, 0.07]:
		var due := _due_frames(ScreenPace.new(), 240, delta, false)
		assert_int(due[0]).is_equal(0)
		assert_int(due.size()).is_less(240 if delta < ScreenPace.UNWATCHED_S else 241)
		for i in range(1, due.size()):
			assert_float((due[i] - due[i - 1]) * delta).is_less_equal(ScreenPace.UNWATCHED_S + delta)
		assert_float((239 - due[-1]) * delta).is_less_equal(ScreenPace.UNWATCHED_S + delta)
	# At the game's own frame it does a fraction of the work.
	assert_int(_due_frames(ScreenPace.new(), 240, FRAME, false).size()).is_less(240 / 4)


func test_being_watched_brings_it_up_at_once() -> void:
	var pace := ScreenPace.new()
	pace.due(FRAME, false)
	assert_bool(pace.due(FRAME, false)).is_false()
	assert_bool(pace.due(FRAME, true)).is_true()


func test_a_hurry_makes_the_next_frame_due_unwatched() -> void:
	var pace := ScreenPace.new()
	pace.due(FRAME, false)
	pace.hurry()
	assert_bool(pace.due(FRAME, false)).is_true()
	assert_bool(pace.due(FRAME, false)).is_false()


# --- Wired into the Habitat (ticket #136) ----------------------------------

## The Station each paced screen of the Habitat is watched from, by its class.
## A new paced screen is added here, or the test below fails naming it.
const PACED_AT := {
	"SurveyPanel": DiveSimulation.STATION_BORE,
	"TunnelPanel": DiveSimulation.STATION_BORE,
	"ThermalGauge": DiveSimulation.STATION_THERMAL,
	"PlasmaDisplay": DiveSimulation.STATION_REACTOR,
	"FlightDisplay": DiveSimulation.STATION_DRIVE,
}


## A ScreenPace that counts the frames it found due.
class _CountingPace extends ScreenPace:
	var due_frames := 0

	func due(delta: float, watched: bool) -> bool:
		var is_due := super(delta, watched)
		if is_due:
			due_frames += 1
		return is_due


static func _class_of(node: Node) -> String:
	var script := node.get_script() as Script
	while script != null:
		if not script.get_global_name().is_empty():
			return script.get_global_name()
		script = script.get_base_script()
	return ""


## Every paced screen under `node`: {name, pace (the screen's own, swapped
## for a counting one), processor (the node whose _process asks it, taken
## off the engine's hands so only the test plays its frames), overlay (on the
## debug overlay, which no Station watches: drawn every frame)}.
static func _paced_screens(node: Node, found: Array[Dictionary] = [], overlay := false) -> Array[Dictionary]:
	overlay = overlay or node is DiveView
	if node.get(&"_pace") is ScreenPace:
		var pace := _CountingPace.new()
		node.set(&"_pace", pace)
		# The Drive's display asks its pace from the canvas inside it.
		var processor: Node = node.get(&"_canvas") if node is FlightDisplay else node
		processor.set_process(false)
		found.append({name = _class_of(node), pace = pace, processor = processor, overlay = overlay})
	for child in node.get_children(true):
		_paced_screens(child, found, overlay)
	return found


func test_in_the_habitat_each_screen_is_brought_up_every_frame_at_its_own_station_and_less_often_elsewhere() -> void:
	var habitat := DiveTestKit.staged_habitat(self)
	await DiveTestKit.laid_out(self)
	var sim: DiveSimulation = habitat.simulation()
	var screens := _paced_screens(habitat)
	var names := screens.filter(func(s: Dictionary) -> bool: return not s.overlay) \
			.map(func(s: Dictionary) -> String: return s.name)
	for name: String in PACED_AT:
		assert_array(names).override_failure_message("The Habitat has no paced %s" % name).contains([name])
	for screen in screens:
		assert_bool(PACED_AT.has(screen.name)).override_failure_message(
				"%s is paced, but not listed in PACED_AT" % screen.name).is_true()
	const FRAMES := 60
	var most_unwatched := int(FRAMES * FRAME / ScreenPace.UNWATCHED_S) + 1
	for at in DiveSimulation.STATIONS:
		for station in DiveSimulation.STATIONS:
			sim.set_attended(station, station == at)
		for screen in screens:
			screen.pace.due_frames = 0
		for frame in FRAMES:
			for screen in screens:
				screen.processor._process(FRAME)
		for screen in screens:
			var due: int = screen.pace.due_frames
			if screen.overlay or PACED_AT[screen.name] == at:
				assert_int(due).override_failure_message("%s, watched from %s, was brought up %d of %d frames" % [
						screen.name, at, due, FRAMES]).is_equal(FRAMES)
			else:
				assert_int(due).override_failure_message("%s, the crew at %s, was brought up %d of %d frames" % [
						screen.name, at, due, FRAMES]).is_between(1, most_unwatched)
