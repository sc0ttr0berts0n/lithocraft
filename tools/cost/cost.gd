## The cost budget's main loop, run headless by tools/cost/cost.sh. Plays the
## Shift drill in a Habitat with every Station's screen live through the
## conditions that have been slow, times every frame and every simulation
## query (CostProbe), prints the report (CostBudget) and quits: 0 inside the
## budget, 1 over it or if the measurement could not be made.
extends SceneTree

## The conditions, played in this order, each for the same stretch of dive
## time: the commands that set it up, and (the full point cloud) whether the
## cloud is filled first and how many frames lie between the pulses sent while
## it is played, then a Sweep at its shortest range (its rays and batches
## come quickest) started on that full cloud and left running through the
## rest, and (the last) the Station the crew is seated at instead of
## Navigation, so the screen they watch is timed as well as those they do not,
## and (the hull at its worst) whether the hull is first heated until it takes
## damage and worn until it would fail within HULL_WORST_S, so every spark
## emitter spits and the groans come thick, and (a Glide) whether the
## Glide it starts is dropped out of after it, the Head spun up again with a
## Shift and the Crawl waited for, so the next condition crawls.
## The Course is turned well off the way the drill dives, so the projected
## path is a turn under every one after the first.
const CONDITIONS := [
	{name = "under way, a Boundary ahead", send = []},
	{name = "a Glide plotted and waiting", send = [[&"plot_glide", [100000.0]]]},
	{name = "gliding", send = [[&"plot_glide", [100000.0]], [&"start_glide", []]], glide = true},
	{name = "a slow turn", send = [[&"set_course", [90.0, 20.0]], [&"set_power", [0.3]],
			[&"set_steering_effort", [0.1]]]},
	{name = "steering effort at zero", send = [[&"set_steering_effort", [0.0]]]},
	{name = "low power", send = [[&"set_steering_effort", [1.0]], [&"set_power", [0.05]]]},
	{name = "a full point cloud", send = [[&"set_power", [0.5]]], fill = true, pulse_every = 30},
	{name = "a Sweep running", send = [[&"set_sweep_range", [DiveSimulation.SWEEP_RANGES[0]]],
			[&"start_sweep", []]]},
	{name = "seated at the Reactor", send = [], seat = DiveSimulation.STATION_REACTOR},
	{name = "the hull at its worst", send = [[&"set_autopilot", [DiveSimulation.STATION_THERMAL, false]],
			[&"set_heat_split", [0.0]], [&"set_power", [1.0]]], hull_worst = true},
]
## The hull at its worst would fail this many seconds after it is worn: well
## inside the time HullFeel shows the fullest sparks for, and long after the
## condition is played.
const HULL_WORST_S := 60.0
## Dive time skipped at a go (debug_skip) while the hull heats, and the most
## skipped in all, seconds.
const HEAT_SKIP_S := 5.0
const HEAT_MOST_S := 600.0
## Dive time each condition is played for unless --seconds says, seconds.
const SECONDS := 4.0
## Frames played before the first that counts: the screens' first layout.
const WARM_UP_FRAMES := 30
## The queries are timed after one frame in this many (see
## CostProbe.time_queries()). Prime, so it falls in step with nothing.
const QUERY_EVERY := 7
## The baseline is timed after one frame in this many.
const BASELINE_EVERY := 10
## The most frames waited for a Glide to halt, and for the Crawl after it.
const GLIDE_WAIT_FRAMES := 1200
## The most pulses sent to fill the point cloud.
const FILL_PULSES := 600

var _probe: CostProbe
var _sim: DiveSimulation


func _initialize() -> void:
	var seconds := SECONDS
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() == 2 and arguments[0] == "--seconds" and arguments[1].is_valid_float() \
			and arguments[1].to_float() > 0.0:
		seconds = arguments[1].to_float()
	elif not arguments.is_empty():
		_fail("the only argument is --seconds <dive time for each condition>")
		return
	var scenario := Scenario.shift_drill()
	var habitat: Node3D = (load("res://view/habitat.tscn") as PackedScene).instantiate()
	habitat.scenario = scenario
	root.add_child(habitat)
	if not habitat.is_node_ready():
		await habitat.ready
	_probe = CostProbe.new(habitat)
	_sim = habitat.simulation()
	# The crew at Navigation, where the lag was first seen, and the Reactor
	# steadying itself, so crossing the Boundary does not lose the plasma.
	habitat.seat_at(DiveSimulation.STATION_NAVIGATION)
	_probe.send(&"set_autopilot", [DiveSimulation.STATION_REACTOR, true])
	for frame in WARM_UP_FRAMES:
		await _frame()

	var budget := CostBudget.new()
	var baselines: Array[float] = []
	var states := PackedStringArray()
	var frames := roundi(seconds / CostProbe.STEP)
	for condition: Dictionary in CONDITIONS:
		for command: Array in condition.send:
			_probe.send(command[0], command[1])
		if condition.has("seat"):
			habitat.seat_at(condition.seat)
		if condition.get("fill", false):
			var pulses := 0
			while _sim.point_count() < _sim.point_capacity() and pulses < FILL_PULSES:
				_probe.send(&"pulse")
				await _frame()
				pulses += 1
		if condition.get("hull_worst", false):
			var skipped := 0.0
			while not _sim.hull_taking_damage() and skipped < HEAT_MOST_S:
				_probe.send(&"debug_skip", [HEAT_SKIP_S])
				await _frame()
				skipped += HEAT_SKIP_S
			if not _sim.hull_taking_damage():
				_fail("the hull never took damage in %d s at full power" % roundi(skipped))
				return
			var wear := _sim.hull_integrity() - _sim.hull_creep_rate() * HULL_WORST_S
			if wear > 0.0:
				_probe.send(&"debug_wear_hull", [wear])
		for frame in frames:
			if condition.has("pulse_every") and frame % int(condition.pulse_every) == 0:
				_probe.send(&"pulse")
			budget.add_frame(condition.name, await _frame())
			if frame % BASELINE_EVERY == 0:
				baselines.append(CostProbe.baseline_ms())
			if frame % QUERY_EVERY == 0:
				var cost := _probe.time_queries()
				for query: String in cost:
					budget.add_query(condition.name, query, cost[query])
		states.append("  %-34s speed %.2f m/s, depth %.0f m, %d of %d points, %d projected path points" % [
				condition.name, _sim.speed(), _sim.depth(), _sim.point_count(), _sim.point_capacity(),
				_sim.projected_path().size()])
		var failure: String = await _condition_failure(condition)
		if not failure.is_empty():
			_fail(failure)
			return
	if _probe.twin_drift() > 1e-6:
		_fail("the simulation timed alone came apart from the Habitat's: its step was another dive's")
		return

	# The middle baseline of those taken among the frames: it was timed under
	# the load they were, and a go another program disturbed does not move it.
	baselines.sort()
	budget.baseline_ms = baselines[baselines.size() / 2]
	print("COST BUDGET  %s, %d conditions of %s s of dive time each, in steps of 1/60 s" % [
			scenario.title, CONDITIONS.size(), seconds])
	print("each condition as it ended:")
	for state in states:
		print(state)
	print("%d queries timed alone, %d of them with representative arguments, one call each every %d frames, on a twin simulation no screen reads" % [
			CostProbe.queries().size() + CostProbe.argued_queries().size(), CostProbe.argued_queries().size(), QUERY_EVERY])
	for line in budget.report():
		print(line)
	_probe = null
	habitat.free()
	await process_frame
	quit(0 if budget.over().is_empty() else 1)


## Plays one frame of the Habitat and one of the engine's; returns its parts.
## Why the condition just played left nothing fit to measure, or "" when it
## did not: the dive stopped, the hull short of its worst, the cloud never
## filled, or (a Glide) the Crawl never came back after it.
func _condition_failure(condition: Dictionary) -> String:
	if _sim.plasma_lost() or _sim.dead() or _sim.surfaced() or _sim.speed() <= 0.0:
		return "the dive stopped in \"%s\": nothing left to measure" % condition.name
	if condition.get("hull_worst", false) and HullFeel.how_severe(_sim.hull_creep_rate(), _sim.hull_integrity()) < 1.0:
		return "the hull was not at its worst at the end of \"%s\": its sparks short of their fullest" % condition.name
	if condition.get("fill", false) and _sim.point_count() < _sim.point_capacity():
		return "the point cloud never filled: %d of %d points" % [_sim.point_count(), _sim.point_capacity()]
	if condition.get("glide", false) and not await _out_of_the_glide():
		return "the Glide never gave way to the Crawl after \"%s\"" % condition.name
	return ""


## Drops out of the Glide, waits for it to halt, spins the Head up with a
## Shift (the Reactor's autopilot steadying the new ACTIVE on the rock round
## the vessel) and waits for the Crawl: true once the vessel crawls.
func _out_of_the_glide() -> bool:
	_probe.send(&"drop_out_of_glide")
	for frame in GLIDE_WAIT_FRAMES:
		if not _sim.gliding():
			break
		await _frame()
	_probe.send(&"shift")
	_probe.send(&"set_autopilot", [DiveSimulation.STATION_REACTOR, true])
	for frame in GLIDE_WAIT_FRAMES:
		if _sim.speed() > 0.0:
			return true
		await _frame()
	return false


func _frame() -> Dictionary:
	var cost: Dictionary = await _probe.frame()
	await process_frame
	return cost


func _fail(why: String) -> void:
	printerr("COST FAILED  %s" % why)
	quit(1)
