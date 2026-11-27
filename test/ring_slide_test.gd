# The ring of Stations and the Arm's rail sliding along the Habitat when
# "down" flips from one end to the other, tested at the simulation's
# interface: where the ring is (station_ring(): 0 at working height above
# the Head end floor, 1 above the Tail end floor) as the vessel turns, and
# what goes on at the Stations meanwhile. Assert relationships, never tuned
# constants (ADR 0001).
extends GdUnitTestSuite

const STEP := 0.1
## Nearer level than this, degrees of pitch, neither end is the floor yet:
## well short of halfway from level to straight up or down.
const NEAR_LEVEL := 30.0
## Deep enough to turn all the way round without surfacing.
const DEEP_M := 2000.0


## Under way straight down, deep, steering as hard as it can, with Thermal's
## autopilot keeping the hull whole at full power.
func _diving() -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock()))
	sim.start_below(DEEP_M)
	sim.set_power(1.0)
	sim.set_steering_effort(1.0)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	DiveTestKit.run(sim, 5.0)
	return sim


## Plots this pitch and flies until the vessel is on it and the ring is still.
func _turned_to(sim: DiveSimulation, pitch: float) -> DiveSimulation:
	sim.set_course(sim.course_heading(), pitch)
	var there := func(s: DiveSimulation) -> bool: return absf(s.pitch() - pitch) < 1.0 and not s.ring_sliding()
	assert_bool(DiveTestKit.fly_until(sim, there, 6000.0)).is_true()
	return sim


## Diving, then turned toward a climb and stopped at the step the ring starts
## to slide, the time rate normal.
func _as_the_slide_starts() -> DiveSimulation:
	var sim := _diving()
	sim.set_course(sim.course_heading(), -90.0)
	var nearly := func(s: DiveSimulation) -> bool: return s.pitch() < -NEAR_LEVEL
	assert_bool(DiveTestKit.fly_until(sim, nearly, 6000.0)).is_true()
	assert_bool(sim.ring_sliding()).is_false()
	sim.set_time_rate(1.0)
	var sliding := func(s: DiveSimulation) -> bool: return s.ring_sliding()
	assert_bool(DiveTestKit.fly_until(sim, sliding, 600.0, STEP, false)).is_true()
	return sim


func test_in_a_dive_the_ring_is_above_the_head_end_floor() -> void:
	var sim := _diving()

	assert_float(sim.station_ring()).is_equal(0.0)
	assert_bool(sim.ring_sliding()).is_false()


func test_turning_from_a_dive_to_a_climb_the_ring_ends_above_the_tail_end_floor() -> void:
	var sim := _turned_to(_diving(), -90.0)

	assert_float(sim.station_ring()).is_equal(1.0)


func test_turning_back_to_a_dive_the_ring_ends_above_the_head_end_floor_again() -> void:
	var sim := _turned_to(_turned_to(_diving(), -90.0), 90.0)

	assert_float(sim.station_ring()).is_equal(0.0)


func test_levelling_off_the_ring_stays_where_it_last_was() -> void:
	var from_a_dive := _turned_to(_diving(), 0.0)
	var from_a_climb := _turned_to(_turned_to(_diving(), -90.0), 0.0)
	# Level for a good while, it still has not moved.
	DiveTestKit.run(from_a_dive, 60.0)
	DiveTestKit.run(from_a_climb, 60.0)

	assert_float(from_a_dive.station_ring()).is_equal(0.0)
	assert_float(from_a_climb.station_ring()).is_equal(1.0)


func test_the_ring_does_not_move_until_the_other_end_is_the_floor() -> void:
	var sim := _diving()
	sim.set_course(sim.course_heading(), -90.0)
	var nearly := func(s: DiveSimulation) -> bool: return s.pitch() < -NEAR_LEVEL

	assert_bool(DiveTestKit.fly_until(sim, nearly, 6000.0)).is_true()

	# Through level and into the start of the climb it has stayed put.
	assert_float(sim.station_ring()).is_equal(0.0)


func test_the_ring_slides_over_some_seconds_and_never_jumps() -> void:
	var sim := _as_the_slide_starts()
	var largest_move := 0.0
	var seconds := 0.0
	var before := sim.station_ring()

	while sim.ring_sliding() and seconds < 600.0:
		sim.advance(STEP)
		seconds += STEP
		largest_move = maxf(largest_move, absf(sim.station_ring() - before))
		# Always toward the Tail end, never back.
		assert_float(sim.station_ring()).is_greater_equal(before)
		before = sim.station_ring()

	assert_float(sim.station_ring()).is_equal(1.0)
	assert_float(seconds).is_greater(1.0)
	assert_float(largest_move).is_less(0.2)


func test_a_hold_at_an_attended_station_carries_through_the_slide() -> void:
	var sim := _as_the_slide_starts()
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.hold_self_destruct(true)

	# The Arm holds the crew member at Thermal, so it stays attended.
	DiveTestKit.run(sim, sim.self_destruct_hold_length() + 2.0 * STEP, STEP)

	assert_bool(sim.self_destructing()).is_true()


func test_a_hold_stops_when_the_station_slides_out_of_reach() -> void:
	var sim := _as_the_slide_starts()
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.hold_self_destruct(true)
	DiveTestKit.run(sim, sim.self_destruct_hold_length() * 0.5, STEP)
	var held_before := sim.self_destruct_hold()

	# On foot the Station has pulled away: the view reports it out of reach,
	# the key still down.
	sim.set_attended(DiveSimulation.STATION_THERMAL, false)
	DiveTestKit.run(sim, sim.self_destruct_hold_length() * 2.0, STEP)

	assert_float(held_before).is_greater(0.0)
	assert_float(sim.self_destruct_hold()).is_equal(0.0)
	assert_bool(sim.self_destructing()).is_false()


func test_the_stations_readings_and_autopilots_run_unbroken_through_the_slide() -> void:
	var sim := _as_the_slide_starts()
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.take_events()
	var seen := []
	var steps := 0

	while sim.ring_sliding() and steps < 6000:
		var distance_before := sim.distance()
		var pitch_before := sim.pitch()
		sim.advance(STEP)
		steps += 1
		seen.append_array(sim.take_events())
		# Every step of the slide the vessel still cuts and still turns, and
		# each Station's autopilot is still at work.
		assert_float(sim.distance()).is_greater(distance_before)
		assert_float(sim.pitch()).is_less(pitch_before)
		assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_true()
		assert_bool(sim.autopilot(DiveSimulation.STATION_THERMAL)).is_true()

	assert_int(steps).is_greater(1)
	assert_array(DiveTestKit.types(seen)).not_contains([&"autopilot_off"])
