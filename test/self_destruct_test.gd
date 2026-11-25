# Self-destruct, tested at the simulation's interface: the hold that arms it,
# the vessel mismanaging itself under way or dumping the emergency store into
# the hull stranded, cancelling, and death by it. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const STEP := 0.1


## A dive straight down at full power, the Drive and Thermal left alone.
func _under_way(seconds := 30.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.set_power(1.0)
	DiveTestKit.run(sim, seconds)
	sim.take_events()
	return sim


## Holds the self-destruct command at Thermal for `seconds`, in short steps.
func _hold(sim: DiveSimulation, seconds: float) -> void:
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.hold_self_destruct(true)
	for i in roundi(seconds / STEP):
		sim.advance(STEP)


func _release(sim: DiveSimulation) -> void:
	sim.hold_self_destruct(false)
	sim.advance(STEP)


func test_holding_the_full_hold_starts_it_and_a_shorter_hold_does_not() -> void:
	var short := _under_way()
	var full := _under_way()
	var hold := short.self_destruct_hold_length()

	_hold(short, hold * 0.8)
	assert_float(short.self_destruct_hold()).is_greater(0.0)
	_release(short)
	# A second short hold starts again from nothing: the holds do not add up.
	_hold(short, hold * 0.8)
	_release(short)
	_hold(full, hold + 2.0 * STEP)

	assert_bool(short.self_destructing()).is_false()
	assert_float(short.self_destruct_hold()).is_equal(0.0)
	assert_bool(full.self_destructing()).is_true()
	assert_array(DiveTestKit.types(full.take_events())).contains([&"self_destruct_started"])


## Runs `sim` in steps of 1 s until the hull fails and returns how long that
## took, or INF if it outlasted `seconds`. The &"hull_failed" event, if any,
## is appended to `failed`.
func _time_to_death(sim: DiveSimulation, seconds: float, failed: Array = []) -> float:
	var t := 0.0
	while t < seconds:
		sim.advance(1.0)
		t += 1.0
		for event in sim.take_events():
			if event.type == &"hull_failed":
				failed.append(event)
		if sim.dead():
			return t
	return INF


## Starts self-destruct with a full hold, then lets the command go.
func _arm(sim: DiveSimulation) -> void:
	_hold(sim, sim.self_destruct_hold_length() + 2.0 * STEP)
	sim.hold_self_destruct(false)
	assert_bool(sim.self_destructing()).is_true()


func test_self_destruct_under_way_fails_the_hull_much_sooner_than_the_dive_left_alone() -> void:
	var destructing := _under_way()
	var alone := _under_way()
	_arm(destructing)
	destructing.set_attended(DiveSimulation.STATION_THERMAL, false)

	var destructing_death := _time_to_death(destructing, 4000.0)
	var alone_death := _time_to_death(alone, 4000.0)

	assert_bool(destructing.dead()).is_true()
	assert_float(destructing_death).is_less(alone_death / 2.0)


func test_self_destruct_takes_the_stations_off_the_crew() -> void:
	var sim := _under_way()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_power(0.3)
	sim.set_heat_split(0.5)
	sim.advance(1.0)
	_arm(sim)

	sim.set_power(0.0)
	sim.set_heat_split(1.0)
	sim.set_quiet_ship(true)
	DiveTestKit.run(sim, 5.0)

	assert_float(sim.power()).is_equal(1.0)
	assert_float(sim.heat_split()).is_equal(0.0)
	assert_bool(sim.quiet_ship()).is_false()
	assert_float(sim.heat_outward()).is_equal_approx(sim.heat_produced(), 1e-9)


func test_death_by_self_destruct_is_its_own_cause_with_the_usual_price() -> void:
	var destructing := _under_way()
	var cooked := _under_way()
	_arm(destructing)
	cooked.set_attended(DiveSimulation.STATION_THERMAL, true)
	cooked.set_attended(DiveSimulation.STATION_DRIVE, true)
	cooked.set_heat_split(0.0)
	var destructed := []
	var overheated := []

	_time_to_death(destructing, 4000.0, destructed)
	_time_to_death(cooked, 8000.0, overheated)

	assert_int(destructed.size()).is_equal(1)
	assert_int(overheated.size()).is_equal(1)
	assert_str(String(destructed[0].cause)).is_equal("self_destruct")
	assert_str(String(overheated[0].cause)).is_equal("heat")
	# The usual price: the unsent survey lost, the rebuy shown.
	assert_float(destructed[0].lost).is_greater(0.0)
	assert_float(destructing.unsold_value()).is_equal(0.0)
	assert_float(destructed[0].rebuy).is_equal(overheated[0].rebuy)
	assert_bool(destructing.self_destructing()).is_false()


func test_the_hold_counts_only_with_the_crew_at_thermal() -> void:
	var sim := _under_way()
	sim.hold_self_destruct(true)

	DiveTestKit.run(sim, sim.self_destruct_hold_length() * 2.0, STEP)

	assert_bool(sim.self_destructing()).is_false()
