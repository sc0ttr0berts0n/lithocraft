# How a dive ended and why (outcome()), tested at the simulation's interface:
# surfaced, brought home, rescued, dead by heat, dead by self-destruct. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const PLENTY_S := 20000.0
const STEP_S := 0.25


## Test values only. Porous rock the melt lines, so the tunnel stays open.
func _open_rock() -> Medium:
	return Medium.new(&"open", 1.0, 3.0, 0.5, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Test values only. Hot dense rock the melt fills behind the Tail, so the
## tunnel seals at once and a lost plasma strands the Lithocraft.
func _hot_dense() -> Medium:
	return Medium.new(&"hot_dense", 1.0, 3.0, 0.0, 450.0, 1.0, {&"quartz": 1.0}, 0.0)


## Test values only. Dense rock as cool as the surface: it seals the tunnel
## too, but soaks the hull slowly, so a rescue comes before the hull fails.
func _cool_dense() -> Medium:
	return Medium.new(&"cool_dense", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.0)


## A dive into `medium` at full power, its heat all sent into the Column so
## the hull stays whole, for `seconds`.
func _dive(medium: Medium, seconds: float) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(medium))
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_heat_split(1.0)
	sim.set_power(1.0)
	DiveTestKit.run(sim, seconds, 0.5)
	return sim


## Sealed in hot dense rock and stranded there by a rough Shift.
func _stranded() -> DiveSimulation:
	var sim := _dive(_hot_dense(), 300.0)
	DiveTestKit.lose_plasma(sim)
	sim.take_events()
	assert_bool(sim.stranded()).is_true()
	return sim


## Runs until the dive is over (surfaced or dead), in whole seconds.
func _until_over(sim: DiveSimulation, seconds: float, seen: Array = []) -> void:
	for i in int(seconds):
		if sim.surfaced() or sim.dead():
			return
		sim.advance(1.0)
		seen.append_array(sim.take_events())


## Holds the self-destruct command at Thermal until it starts, then lets go.
func _self_destruct(sim: DiveSimulation) -> void:
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.hold_self_destruct(true)
	for i in roundi(sim.self_destruct_hold_length() / 0.1) + 2:
		sim.advance(0.1)
	sim.hold_self_destruct(false)
	assert_bool(sim.self_destructing()).is_true()


func test_a_dive_under_way_has_no_outcome_yet() -> void:
	var sim := _dive(DiveTestKit.rock(), 30.0)

	var outcome := sim.outcome()

	assert_str(String(outcome.ending)).is_equal("under_way")
	assert_str(String(outcome.cause)).is_empty()
	assert_float(outcome.stranded_for).is_equal(0.0)


func test_surfacing_under_its_own_power_is_surfaced_with_no_cause() -> void:
	var sim := _dive(DiveTestKit.rock(), 20.0)
	var deepest := sim.depth()
	sim.set_course(sim.course_heading(), -90.0)

	_until_over(sim, PLENTY_S)

	var outcome := sim.outcome()
	assert_bool(sim.surfaced()).is_true()
	assert_str(String(outcome.ending)).is_equal("surfaced")
	assert_str(String(outcome.cause)).is_empty()
	assert_str(String(outcome.plasma_lost_by)).is_empty()
	assert_float(outcome.stranded_for).is_equal(0.0)
	assert_float(deepest).is_greater(0.0)


func test_a_rough_shift_on_a_worn_head_is_why_the_plasma_was_lost() -> void:
	var sim := _dive(_hot_dense(), 300.0)
	var seen := []

	DiveTestKit.lose_plasma(sim)
	seen.append_array(sim.take_events())

	var lost: Array = seen.filter(func(e: Dictionary) -> bool: return e.type == &"plasma_lost")
	assert_int(lost.size()).is_equal(1)
	assert_str(String(lost[0].cause)).is_equal("disrupted")
	assert_str(String(sim.outcome().plasma_lost_by)).is_equal("disrupted")
	# Stranded is not an ending: the dive goes on, on the store.
	assert_str(String(sim.outcome().ending)).is_equal("under_way")


func test_a_rescue_names_why_the_plasma_was_lost_and_how_long_the_crew_was_stranded() -> void:
	var sim := _dive(_cool_dense(), 120.0)
	DiveTestKit.lose_plasma(sim)
	sim.take_events()
	assert_bool(sim.stranded()).is_true()
	var seen := []

	var rescued := DiveTestKit.run_until(sim, &"rescued", PLENTY_S, seen, 1.0)

	assert_dict(rescued).is_not_empty()
	var outcome := sim.outcome()
	assert_str(String(outcome.ending)).is_equal("rescued")
	assert_str(String(outcome.cause)).is_equal("disrupted")
	assert_str(String(outcome.plasma_lost_by)).is_equal("disrupted")
	assert_float(outcome.stranded_for).is_greater(0.0)
	assert_float(outcome.stranded_for).is_equal_approx(rescued.rescue_time, 0.001)
	assert_float(outcome.depth).is_equal_approx(rescued.depth, 0.001)


func test_a_longer_stranding_reads_as_longer() -> void:
	var shallow := _dive(_cool_dense(), 60.0)
	var deep := _dive(_cool_dense(), 180.0)
	for sim: DiveSimulation in [shallow, deep]:
		DiveTestKit.lose_plasma(sim)
		DiveTestKit.run_until(sim, &"rescued", PLENTY_S, [], 1.0)

	assert_str(String(deep.outcome().ending)).is_equal("rescued")
	assert_str(String(shallow.outcome().ending)).is_equal("rescued")
	assert_float(deep.outcome().stranded_for).is_greater(shallow.outcome().stranded_for)


func test_losing_the_plasma_with_the_tunnel_open_is_brought_home_with_its_cause() -> void:
	var sim := _dive(_open_rock(), 120.0)

	DiveTestKit.lose_plasma(sim)
	sim.take_events()

	var outcome := sim.outcome()
	assert_bool(sim.surfaced()).is_true()
	assert_str(String(outcome.ending)).is_equal("brought_home")
	assert_str(String(outcome.cause)).is_equal("disrupted")
	assert_float(outcome.stranded_for).is_equal(0.0)
	assert_float(outcome.depth).is_greater(0.0)


func test_a_hull_cooked_through_under_way_is_dead_by_heat() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_heat_split(0.0)
	sim.set_power(1.0)

	_until_over(sim, 8000.0)

	var outcome := sim.outcome()
	assert_bool(sim.dead()).is_true()
	assert_str(String(outcome.ending)).is_equal("dead")
	assert_str(String(outcome.cause)).is_equal("heat")
	assert_str(String(outcome.plasma_lost_by)).is_empty()
	assert_float(outcome.stranded_for).is_equal(0.0)
	assert_float(outcome.depth).is_greater(0.0)


func test_the_stranding_clock_running_out_is_dead_by_heat_after_the_time_stranded() -> void:
	var sim := _dive(_hot_dense(), 300.0)
	DiveTestKit.lose_plasma(sim)
	sim.take_events()
	var clock := sim.stranding_clock()
	assert_float(clock).is_less(sim.rescue_time())

	_until_over(sim, clock * 2.0)

	var outcome := sim.outcome()
	assert_str(String(outcome.ending)).is_equal("dead")
	assert_str(String(outcome.cause)).is_equal("heat")
	assert_str(String(outcome.plasma_lost_by)).is_equal("disrupted")
	assert_float(outcome.stranded_for).is_greater(0.0)
	assert_float(outcome.stranded_for).is_less_equal(clock + 2.0)


func test_self_destruct_is_dead_by_self_destruct() -> void:
	var sim := _dive(DiveTestKit.rock(), 30.0)
	_self_destruct(sim)
	var seen := []

	_until_over(sim, 4000.0, seen)

	var outcome := sim.outcome()
	assert_bool(sim.dead()).is_true()
	assert_str(String(outcome.ending)).is_equal("dead")
	assert_str(String(outcome.cause)).is_equal("self_destruct")
	# Every screen names the same cause.
	assert_str(String(outcome.cause)).is_equal(String(sim.cause_of_death()))
	var failed: Array = seen.filter(func(e: Dictionary) -> bool: return e.type == &"hull_failed")
	assert_str(String(outcome.cause)).is_equal(String(failed[0].cause))


func test_self_destruct_stranded_is_dead_by_self_destruct_after_the_time_stranded() -> void:
	var sim := _stranded()
	_self_destruct(sim)

	_until_over(sim, PLENTY_S)

	var outcome := sim.outcome()
	assert_str(String(outcome.ending)).is_equal("dead")
	assert_str(String(outcome.cause)).is_equal("self_destruct")
	assert_str(String(outcome.plasma_lost_by)).is_equal("disrupted")
	assert_float(outcome.stranded_for).is_greater(0.0)


func test_a_relit_head_leaves_no_stranding_or_lost_plasma_in_the_outcome() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_cool_dense()))
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	var lit := false
	# Relights are luck: strand again (rescued, then a new dive) until one lights.
	for attempt in 20:
		if lit:
			break
		sim.new_dive()
		sim.set_power(1.0)
		DiveTestKit.run(sim, 60.0, 0.5)
		DiveTestKit.lose_plasma(sim)
		DiveTestKit.run(sim, 30.0)
		assert_float(sim.outcome().stranded_for).is_greater(0.0)
		while not lit and sim.emergency_store() >= sim.relight_cost():
			sim.relight()
			lit = DiveTestKit.run_until(sim, &"relight_result", 1.0, [], 0.25).outcome == &"lit"
		if not lit:
			DiveTestKit.run_until(sim, &"rescued", PLENTY_S, [], 1.0)
	assert_bool(lit).is_true()

	var outcome := sim.outcome()

	assert_str(String(outcome.ending)).is_equal("under_way")
	assert_str(String(outcome.plasma_lost_by)).is_empty()
	assert_float(outcome.stranded_for).is_equal(0.0)


func test_a_new_dive_has_no_outcome_until_it_ends() -> void:
	var sim := _dive(_cool_dense(), 60.0)
	DiveTestKit.lose_plasma(sim)
	DiveTestKit.run_until(sim, &"rescued", PLENTY_S, [], 1.0)
	assert_str(String(sim.outcome().ending)).is_equal("rescued")

	sim.new_dive()

	var outcome := sim.outcome()
	assert_str(String(outcome.ending)).is_equal("under_way")
	assert_str(String(outcome.cause)).is_empty()
	assert_str(String(outcome.plasma_lost_by)).is_empty()
	assert_float(outcome.stranded_for).is_equal(0.0)
