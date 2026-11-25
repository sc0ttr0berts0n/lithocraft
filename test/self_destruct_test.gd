# Self-destruct, tested at the simulation's interface: the hold that arms it,
# the vessel mismanaging itself under way or dumping the emergency store into
# the hull stranded, cancelling, and death by it. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const STEP := 0.1


## A dive straight down at full power, every autopilot off.
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
	alone.set_autopilot(DiveSimulation.STATION_THERMAL, true)
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


func test_a_self_destruct_under_way_can_be_waited_out_fast() -> void:
	var sim := _under_way()
	_arm(sim)
	DiveTestKit.run(sim, 300.0)
	assert_bool(sim.heat_warning()).is_true()

	sim.set_time_rate(sim.max_time_rate())
	DiveTestKit.run(sim, 1.0)

	assert_bool(sim.dead()).is_false()
	assert_float(sim.time_rate()).is_greater(1.0)


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
	# The cause stays readable after death, for the Station screens.
	assert_str(String(destructing.cause_of_death())).is_equal("self_destruct")
	assert_str(String(cooked.cause_of_death())).is_equal("heat")


func test_no_cause_of_death_while_alive() -> void:
	var sim := _under_way()
	_arm(sim)
	DiveTestKit.run(sim, 5.0)
	assert_str(String(sim.cause_of_death())).is_empty()


## Test values only. Hot dense rock the melt fills behind the Tail, so the
## tunnel seals at once and a lost plasma strands the Lithocraft; it carries
## no sound, so nothing goes up once sealed.
func _hot_dense() -> Medium:
	return Medium.new(&"hot_dense", 1.0, 3.0, 0.0, 450.0, 1.0, {&"quartz": 1.0}, 0.0)


## A dive deep into hot dense rock, its heat all sent into the Column so the
## hull stays whole, then stranded where it stands, deep enough that the
## stranding clock runs out before the rescue arrives.
func _stranded() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(_hot_dense()))
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_heat_split(1.0)
	sim.set_power(1.0)
	DiveTestKit.run(sim, 300.0, 0.5)
	DiveTestKit.lose_plasma(sim)
	sim.take_events()
	assert_bool(sim.stranded()).is_true()
	assert_float(sim.stranding_clock()).is_less(sim.rescue_time())
	return sim


func test_self_destruct_stranded_spends_the_store_into_the_hull_and_fails_it_before_the_clock() -> void:
	var sim := _stranded()
	var clock := sim.stranding_clock()
	var store := sim.emergency_store()
	assert_float(store).is_greater(0.0)
	var twin := _stranded()

	_arm(sim)
	DiveTestKit.run(sim, 5.0)
	DiveTestKit.run(twin, 5.0 + sim.self_destruct_hold_length())

	# The store goes into the hull as heat: spent, and the hull hotter for it.
	assert_float(sim.emergency_store()).is_less(store)
	assert_float(sim.vessel_temperature()).is_greater(twin.vessel_temperature())
	var failed := []
	var death := _time_to_death(sim, clock * 2.0, failed)
	assert_float(death).is_less(clock)
	assert_float(sim.emergency_store()).is_equal(0.0)
	assert_str(String(failed[0].cause)).is_equal("self_destruct")


func test_the_stranding_clock_counts_a_running_self_destruct() -> void:
	var sim := _stranded()
	var before := sim.stranding_clock()

	_arm(sim)
	var clock := sim.stranding_clock()
	var death := _time_to_death(sim, before * 2.0)

	assert_float(clock).is_less(before)
	assert_float(death).is_between(clock * 0.95, clock * 1.05 + 1.0)


func test_cancelling_under_way_returns_the_stations_and_keeps_the_wear() -> void:
	var sim := _under_way()
	_arm(sim)
	DiveTestKit.run(sim, 300.0)
	var wear := sim.vessel_wear()
	assert_float(wear).is_greater(0.0)
	sim.take_events()

	sim.cancel_self_destruct()
	sim.set_power(0.0)
	sim.set_heat_split(1.0)
	sim.advance(1.0)

	assert_bool(sim.self_destructing()).is_false()
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"self_destruct_cancelled"])
	assert_float(sim.power()).is_equal(0.0)
	assert_float(sim.heat_split()).is_equal(1.0)
	assert_float(sim.vessel_wear()).is_greater_equal(wear)
	# Cancelled in time, the hull holds: the dive goes on.
	DiveTestKit.run(sim, 600.0)
	assert_bool(sim.dead()).is_false()


func test_cancelling_stranded_stops_the_dump_and_the_store_spent_stays_spent() -> void:
	var sim := _stranded()
	sim.set_uploading(false)  # Only the dump draws on the store.
	var store := sim.emergency_store()
	_arm(sim)
	# Dump until some of the store is spent but not all, however fast it runs.
	for i in 1000:
		if sim.emergency_store() < store * 0.75:
			break
		sim.advance(STEP)

	sim.cancel_self_destruct()
	var left := sim.emergency_store()
	DiveTestKit.run(sim, 10.0)

	assert_float(left).is_less(store)
	assert_float(left).is_greater(0.0)
	assert_float(sim.emergency_store()).is_equal(left)
	assert_bool(sim.stranded()).is_true()


func test_a_hold_after_cancelling_needs_the_command_let_go_first() -> void:
	var sim := _under_way()
	_arm(sim)
	sim.hold_self_destruct(true)  # Pressed again to cancel, and held on.
	sim.cancel_self_destruct()

	DiveTestKit.run(sim, sim.self_destruct_hold_length() * 2.0, STEP)

	assert_bool(sim.self_destructing()).is_false()


func test_the_hold_counts_only_with_the_crew_at_thermal() -> void:
	var sim := _under_way()
	sim.hold_self_destruct(true)

	DiveTestKit.run(sim, sim.self_destruct_hold_length() * 2.0, STEP)

	assert_bool(sim.self_destructing()).is_false()


func test_cancelling_under_way_restores_the_crews_settings_from_before_it_began() -> void:
	var sim := _under_way()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_power(0.3)
	sim.set_heat_split(0.5)
	sim.set_quiet_ship(true)
	sim.advance(1.0)
	_arm(sim)
	DiveTestKit.run(sim, 30.0)
	assert_float(sim.power()).is_equal(1.0)
	var wear := sim.vessel_wear()

	sim.cancel_self_destruct()

	assert_float(sim.power()).is_equal(0.3)
	assert_float(sim.heat_split()).is_equal(0.5)
	assert_bool(sim.quiet_ship()).is_true()
	# Only the settings are undone: the wear done stays.
	assert_float(sim.vessel_wear()).is_greater_equal(wear)


func test_cancelling_stranded_restores_the_pumps_the_crew_had_running() -> void:
	var sim := _stranded()
	sim.set_heat_split(0.4)  # The crew cools the hull on the store.
	sim.advance(STEP)
	_arm(sim)
	DiveTestKit.run(sim, 2.0, STEP)
	assert_float(sim.heat_split()).is_equal(0.0)

	sim.cancel_self_destruct()

	assert_float(sim.heat_split()).is_equal(0.4)


func test_a_self_destruct_that_loses_the_plasma_runs_on_as_the_dump_and_cancels_with_the_pumps_stopped() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_hot_dense()))
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_heat_split(1.0)
	sim.set_power(1.0)
	DiveTestKit.run(sim, 300.0, 0.5)
	_arm(sim)
	var store := sim.emergency_store()

	sim.debug_lose_plasma()
	assert_bool(sim.stranded()).is_true()
	DiveTestKit.run(sim, 2.0, STEP)

	assert_bool(sim.self_destructing()).is_true()
	assert_float(sim.emergency_store()).is_less(store)
	sim.cancel_self_destruct()
	# The pumps stopped with the Head; restarting them stays the crew's choice.
	assert_float(sim.heat_split()).is_equal(0.0)


## Test values only: dense rock the melt fills behind the Tail, as _hot_dense()
## but no hotter than the surface, so a stranding in it lasts.
func _cool_dense() -> Medium:
	return Medium.new(&"cool_dense", 1.0, 3.0, 0.0, 300.0, 1.0, {&"quartz": 1.0}, 0.0)


func test_stranded_with_the_store_empty_self_destruct_will_not_arm() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(_cool_dense()))
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_heat_split(1.0)
	sim.set_power(1.0)
	DiveTestKit.run(sim, 300.0, 0.5)
	DiveTestKit.lose_plasma(sim)
	assert_bool(sim.stranded()).is_true()
	sim.set_uploading(false)
	assert_bool(sim.can_self_destruct()).is_true()
	# Spend the store by self-destruct, then call it off.
	_arm(sim)
	for i in 2000:
		if sim.emergency_store() <= 0.0 or sim.dead():
			break
		sim.advance(STEP)
	sim.cancel_self_destruct()
	_release(sim)
	assert_bool(sim.dead()).is_false()
	assert_bool(sim.stranded()).is_true()
	assert_float(sim.emergency_store()).is_equal(0.0)

	_hold(sim, sim.self_destruct_hold_length() * 2.0)

	assert_bool(sim.can_self_destruct()).is_false()
	assert_bool(sim.self_destructing()).is_false()
	assert_float(sim.self_destruct_hold()).is_equal(0.0)
