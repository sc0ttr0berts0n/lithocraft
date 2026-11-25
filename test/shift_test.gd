# Boundaries and the Shift, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only: two Media strong enough that the grip waves never slip,
## one soft and one hard, so crossing between them changes the load.
func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 3.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


## Soft rock with one Boundary into hard rock at this depth.
func _one_boundary(at := 20.0) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [at, _hard()]]))
	sim.set_power(0.5)
	return sim


func test_a_boundary_ahead_is_announced_before_it_is_crossed() -> void:
	var sim := _one_boundary()
	var seen := []

	var crossed := DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, seen)

	assert_dict(crossed).is_not_empty()
	var types := DiveTestKit.types(seen)
	assert_int(types.count(&"boundary_approaching")).is_equal(1)
	assert_int(types.find(&"boundary_approaching")).is_less(types.find(&"boundary_crossed"))
	assert_str(String(crossed.from)).is_equal("soft")
	assert_str(String(crossed.to)).is_equal("hard")


## Crosses the one Boundary, then performs a Shift to `frequency` (the
## plasma's own by default) after waiting `wait` seconds, and returns the Shift
## result event. Only the step that takes the Shift is advanced afterwards.
func _shift_after(wait: float, off_by := 1.0, sim: DiveSimulation = null) -> Dictionary:
	if sim == null:
		sim = _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_crossed")
	for i in int(wait / 0.1):
		sim.advance(0.1)
	sim.take_events()
	sim.shift(sim.plasma_frequency() * off_by)
	sim.advance(0.1)
	for event in sim.take_events():
		if event.type == &"shift_result":
			return event
	return {}


func test_the_reactors_autopilot_shifts_late_and_poorly() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.run_until(sim, &"boundary_crossed")

	var result := DiveTestKit.run_until(sim, &"shift_result")

	assert_bool(result.autopilot).is_true()
	assert_bool(result.clean).is_false()
	assert_bool(sim.shift_due()).is_false()


func test_a_poor_shift_spikes_the_heat_wears_the_head_and_lurches() -> void:
	var clean_sim := _one_boundary()
	var poor_sim := _one_boundary()
	var clean := _shift_after(0.0, 1.0, clean_sim)
	var poor := _shift_after(_window() + 4.0, 1.0, poor_sim)
	assert_bool(clean.clean).is_true()
	assert_bool(poor.clean).is_false()
	# Both are tuned now and draw the same power; only the poor one grinds.
	var clean_heat := clean_sim.heat_produced()
	var poor_heat := poor_sim.heat_produced()
	var clean_felt := clean_sim.felt_acceleration()
	var poor_felt := poor_sim.felt_acceleration()
	for i in 100:
		clean_sim.advance(0.1)
		poor_sim.advance(0.1)

	assert_float(clean_sim.head_wear()).is_equal(0.0)
	assert_float(poor_sim.head_wear()).is_greater(0.0)
	# The heat spike: a poor Shift makes more heat than the same running does
	# once it has passed; a clean one makes none.
	assert_float(clean_heat).is_equal_approx(clean_sim.heat_produced(), 1e-6)
	assert_float(poor_heat).is_greater(poor_sim.heat_produced() + 1e-3)
	# The lurch: felt in the Habitat as a jolt on top of gravity, then gone.
	assert_float(clean_sim.lurch()).is_equal(0.0)
	assert_vector(clean_felt).is_equal_approx(clean_sim.felt_acceleration(), Vector3.ONE * 1e-6)
	assert_float(poor_felt.distance_to(poor_sim.felt_acceleration())).is_greater(0.5)
	assert_float(poor_sim.lurch()).is_less(0.01)


func test_crossing_a_boundary_opens_a_window_for_the_shift() -> void:
	var sim := _one_boundary()
	assert_bool(sim.shift_due()).is_false()
	assert_float(sim.shift_window()).is_equal(0.0)

	DiveTestKit.run_until(sim, &"boundary_crossed")

	assert_bool(sim.shift_due()).is_true()
	assert_float(sim.shift_window()).is_greater(0.0)


func test_a_new_load_unsettles_the_plasma_until_the_shift_matches_it() -> void:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_crossed")
	sim.advance(0.1)
	assert_float(sim.plasma_stability()).is_less(1.0)

	sim.shift(sim.plasma_frequency())
	sim.advance(0.1)

	assert_bool(sim.shift_due()).is_false()
	assert_float(sim.plasma_stability()).is_equal(1.0)


func test_harder_rock_loads_the_plasma_into_a_different_wobble() -> void:
	var sim := _one_boundary()
	var soft_frequency := sim.plasma_frequency()
	DiveTestKit.run_until(sim, &"boundary_crossed")

	assert_float(sim.plasma_frequency()).is_not_equal(soft_frequency)


## Seconds the window for the Shift stays open after crossing a Boundary.
func _window() -> float:
	var sim := _one_boundary()
	DiveTestKit.run_until(sim, &"boundary_crossed")
	return sim.shift_window()


func test_a_shift_inside_the_window_grades_better_than_one_entered_late() -> void:
	var in_time := _shift_after(0.0)
	var late := _shift_after(_window() + 1.0)

	assert_dict(in_time).is_not_empty()
	assert_dict(late).is_not_empty()
	assert_float(late.grade).is_less(in_time.grade)


func test_a_shift_matching_the_plasma_grades_better_than_a_mismatched_one() -> void:
	var matched := _shift_after(0.0)
	var mismatched := _shift_after(0.0, 1.3)

	assert_float(mismatched.grade).is_less(matched.grade)
	assert_bool(matched.clean).is_true()
	assert_bool(mismatched.clean).is_false()


## Soft and hard rock taking turns every 15 m: Boundary after Boundary, each
## Shift left to the Reactor's autopilot.
func _many_boundaries() -> DiveSimulation:
	var layers := []
	for i in 40:
		layers.append([i * 15.0, _soft() if i % 2 == 0 else _hard()])
	var sim := DiveSimulation.new(MediumLayout.layered(layers))
	sim.set_power(1.0)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	return sim


func test_poor_shifts_wear_the_head_until_the_plasma_is_lost() -> void:
	var sim := _many_boundaries()
	var seen := []

	var lost := DiveTestKit.run_until(sim, &"plasma_lost", 20000.0, seen, 0.25)

	assert_dict(lost).is_not_empty()
	var shifts := seen.filter(func(e: Dictionary) -> bool: return e.type == &"shift_result")
	# Carelessness has a limit, but not at the first mistake.
	assert_int(shifts.size()).is_greater(1)
	for shift in shifts:
		assert_bool(shift.clean).is_false()
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_bool(sim.plasma_lost()).is_true()
	assert_float(sim.plasma_stability()).is_equal(0.0)
	DiveTestKit.run_until(sim, &"never", 60.0)
	assert_float(sim.reactor_output()).is_equal(0.0)
	assert_float(sim.speed()).is_equal(0.0)


func test_one_poor_shift_wears_the_head_without_losing_the_plasma() -> void:
	var sim := _one_boundary()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)  # Its late Shift is the poor one.
	var result := DiveTestKit.run_until(sim, &"shift_result")

	assert_bool(result.clean).is_false()
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_bool(sim.plasma_lost()).is_false()


func test_clean_shifts_never_wear_the_head() -> void:
	var sim := _many_boundaries()
	for i in 10:
		DiveTestKit.run_until(sim, &"boundary_crossed", 20000.0, [], 0.25)
		sim.shift(sim.plasma_frequency())

	sim.advance(0.25)
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_bool(sim.plasma_lost()).is_false()


func test_a_poor_shift_with_the_hull_hot_wears_the_head_more() -> void:
	var hot := _shift_hot_or_cool(1.0)
	var cool := _shift_hot_or_cool(0.2)

	assert_float(hot.vessel_temperature()).is_greater(cool.vessel_temperature())
	assert_float(hot.head_wear()).is_greater(cool.head_wear())


## Dives at this power to a deep Boundary, so the hull settles hot or cool,
## then lets the autopilot make the Shift.
func _shift_hot_or_cool(power: float) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [300.0, _hard()]]))
	sim.set_power(power)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	DiveTestKit.run_until(sim, &"boundary_crossed", 20000.0, [], 0.25)
	DiveTestKit.run_until(sim, &"shift_result", 600.0, [], 0.25)
	return sim


func test_the_boundary_is_crossed_when_the_head_enters_the_new_medium() -> void:
	var sim := _one_boundary()

	var approaching := DiveTestKit.run_until(sim, &"boundary_approaching")
	assert_str(String(sim.medium().name)).is_equal("soft")
	DiveTestKit.run_until(sim, &"boundary_crossed")
	assert_str(String(sim.medium().name)).is_equal("hard")
	assert_str(String(approaching.to)).is_equal("hard")


## Wears the Head of a sim still short of its first Boundary with poor Shifts
## (each wide of the wobble, then back onto it cleanly) until it is more than
## half worn, and returns the sim tuned again.
func _worn(sim: DiveSimulation) -> DiveSimulation:
	var on := sim.plasma_frequency()
	while sim.head_wear() <= 0.5:
		sim.shift(on * 1.5)
		sim.advance(0.1)
		sim.shift(on)
		sim.advance(0.1)
	sim.take_events()
	assert_bool(sim.plasma_lost()).is_false()
	assert_bool(sim.shift_due()).is_false()
	return sim


func test_a_worn_head_delivers_less_power_at_the_same_reactor_setting() -> void:
	var fresh := _one_boundary(1000.0)
	var worn := _worn(_one_boundary(1000.0))
	for sim in [fresh, worn]:
		sim.set_power(1.0)
		DiveTestKit.run(sim, 5.0, 0.1)

	assert_float(worn.plasma_tuning()).is_equal(fresh.plasma_tuning())
	assert_float(worn.reactor_output()).is_less(fresh.reactor_output())


func test_a_worn_head_narrows_the_window_for_the_shift() -> void:
	var fresh := _one_boundary()
	var worn := _worn(_one_boundary())
	assert_float(worn.shift_window_length()).is_less(fresh.shift_window_length())
	DiveTestKit.run_until(fresh, &"boundary_crossed")
	DiveTestKit.run_until(worn, &"boundary_crossed")

	assert_float(worn.shift_window()).is_greater(0.0)
	assert_float(worn.shift_window()).is_less(fresh.shift_window())


func test_the_same_shift_grades_worse_on_a_worn_head() -> void:
	# A Shift a little wide of the wobble, made at once.
	var fresh_wide := _shift_after(0.0, 1.05)
	var worn_wide := _shift_after(0.0, 1.05, _worn(_one_boundary()))
	assert_float(worn_wide.grade).is_less(fresh_wide.grade)

	# A Shift on the wobble, made after the fresh Head's window has closed.
	var late := _window() + 1.0
	var fresh_late := _shift_after(late)
	var worn_late := _shift_after(late, 1.0, _worn(_one_boundary()))
	assert_float(worn_late.grade).is_less(fresh_late.grade)


func test_a_poor_shift_loses_the_plasma_on_a_badly_worn_head_but_not_a_fresh_one() -> void:
	var fresh := _one_boundary()
	var worn := _worn(_one_boundary())
	var worn_before := worn.head_wear()

	var fresh_poor := _shift_after(0.0, 1.5, fresh)
	var worn_poor := _shift_after(0.0, 1.5, worn)

	assert_bool(fresh_poor.clean).is_false()
	assert_bool(worn_poor.clean).is_false()
	assert_bool(fresh.plasma_lost()).is_false()
	assert_bool(worn.plasma_lost()).is_true()
	# Not merely the last straw: what the same Shift wore into a fresh Head
	# would not have worn this one through.
	assert_float(worn_before + fresh_poor.wear).is_less(1.0)
