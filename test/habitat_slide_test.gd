# The ring of Stations sliding as the Habitat shows it: a Habitat in the
# tree, stepped by hand, turned from a dive to a climb. Where the Stations
# and the Arm's rail are against where the simulation says the ring is
# (station_ring()), and what the Habitat reports to the simulation of the
# crew's reach: the simulation decides from that what a held command does
# (ring_slide_test.gd).
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
const STEP := 1.0 / 60.0
## Deep enough to turn up without surfacing.
const DEEP_M := 1500.0


## A Habitat on the First dive, in the tree, stepped only by the test.
func _habitat() -> Node3D:
	return DiveTestKit.staged_habitat(self, Scenario.first_dive())


## Turns the Habitat's dive from deep and straight down toward a climb, as
## far as a climb still too shallow for the ring to have set off. The
## simulation is flown on its own: the Habitat does not step.
func _fly_into_a_shallow_climb(habitat: Node3D) -> void:
	var sim: DiveSimulation = habitat.simulation()
	sim.start_below(DEEP_M)
	sim.set_power(1.0)
	sim.set_steering_effort(1.0)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_course(sim.course_heading(), -90.0)
	var nearly := func(s: DiveSimulation) -> bool: return s.pitch() < -30.0
	assert_bool(DiveTestKit.fly_until(sim, nearly, 6000.0, 1.0, false)).is_true()
	sim.set_time_rate(1.0)
	assert_bool(sim.ring_sliding()).is_false()


## Flies on, the simulation on its own, to the step the ring starts to slide.
func _fly_to_the_start_of_the_slide(habitat: Node3D) -> void:
	var sliding := func(s: DiveSimulation) -> bool: return s.ring_sliding()
	assert_bool(DiveTestKit.fly_until(habitat.simulation(), sliding, 600.0, 0.1, false)).is_true()


## The simulation's names of the Stations it has been told are attended.
func _attended(sim: DiveSimulation) -> Array:
	return DiveSimulation.STATIONS.filter(func(s: StringName) -> bool: return sim.attended(s))


func test_the_stations_and_the_arms_rail_are_where_the_simulation_says_the_ring_is() -> void:
	var habitat := _habitat()
	var sim: DiveSimulation = habitat.simulation()
	habitat._physics_process(STEP)
	var by_the_head: float = habitat.bore_station_place().z
	_fly_into_a_shallow_climb(habitat)
	_fly_to_the_start_of_the_slide(habitat)
	var part_way := NAN

	for step in 1200:
		habitat._physics_process(STEP)
		# Every step of the slide, the Station is where the simulation's
		# share of the slide puts it by the Habitat's layout.
		assert_float(habitat.bore_station_place().z) \
				.is_equal_approx(Habitat.ring_z(sim.station_ring()), 0.001)
		if sim.station_ring() > 0.3 and sim.station_ring() < 0.7:
			part_way = habitat.bore_station_place().z
		if not sim.ring_sliding():
			break

	assert_float(by_the_head).is_equal_approx(Habitat.ring_z(0.0), 0.001)
	assert_float(part_way).is_between(Habitat.ring_z(0.0) + 1.0, Habitat.ring_z(1.0) - 1.0)
	assert_bool(sim.ring_sliding()).is_false()
	assert_float(habitat.bore_station_place().z).is_equal_approx(Habitat.ring_z(1.0), 0.001)


func test_on_foot_the_crew_member_and_the_stations_part_until_the_ring_has_slid_to_them() -> void:
	var habitat := _habitat()
	var sim: DiveSimulation = habitat.simulation()
	habitat._physics_process(STEP)
	var reached_in_the_dive := _attended(sim)
	_fly_into_a_shallow_climb(habitat)

	# On foot the climb tips the crew member down the wall toward the Tail
	# end, while the ring still hangs by the Head end: nothing is in reach.
	for step in 600:
		habitat._physics_process(STEP)
	var reached_once_parted := _attended(sim)
	var ring_once_parted := sim.station_ring()
	# Then the Tail end is the floor, and the ring slides to it.
	_fly_to_the_start_of_the_slide(habitat)
	for step in 1200:
		habitat._physics_process(STEP)
		if not sim.ring_sliding():
			break

	assert_array(reached_in_the_dive) \
			.override_failure_message("the crew member did not start within reach of a Station") \
			.is_not_empty()
	assert_float(ring_once_parted).is_equal(0.0)
	assert_array(reached_once_parted).is_empty()
	assert_float(sim.station_ring()).is_equal(1.0)
	assert_array(_attended(sim)).is_not_empty()


func test_held_by_the_arm_the_crew_member_rides_the_slide_and_the_station_stays_attended() -> void:
	var habitat := _habitat()
	var sim: DiveSimulation = habitat.simulation()
	habitat.seat_at(DiveSimulation.STATION_THERMAL)
	_fly_into_a_shallow_climb(habitat)
	_fly_to_the_start_of_the_slide(habitat)
	var eyes: Camera3D = habitat.get_viewport().get_camera_3d()
	var steps := 0

	for step in 1200:
		habitat._physics_process(STEP)
		steps += 1
		# Attended at every step, the eyes travelling with the Station.
		assert_bool(sim.attended(DiveSimulation.STATION_THERMAL)).is_true()
		assert_float(eyes.global_position.z) \
				.is_equal_approx(Habitat.ring_z(sim.station_ring()), 1.5)
		if not sim.ring_sliding():
			break

	assert_int(steps).is_greater(60)
	assert_bool(sim.ring_sliding()).is_false()
	assert_float(eyes.global_position.z).is_greater(0.0)
