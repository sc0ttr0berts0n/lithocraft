# Boundaries as gently wavy surfaces in three dimensions: where a dive crosses
# one, what the scan returns of it, and what the look-ahead makes of it, at
# the simulation's interface; and the layout's own queries of where a line
# meets a surface. Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

## Test values only: the mean depth of the one Boundary, how far its folds
## reach either side of it, and how long they are.
const MEAN := 60.0
const FOLD := 8.0
const WAVELENGTH := 80.0


func _clay() -> Medium:
	return Medium.new(&"clay", 1.0, 0.5, 0.4, 300.0, 1.0, {&"kaolinite": 1.0}, 0.5)


func _flat(mean := MEAN) -> MediumLayout:
	return MediumLayout.layered([[0.0, _clay()], [mean, DiveTestKit.basalt(4.0, 1.0, 0.02)]])


func _wavy(seed: int, mean := MEAN) -> MediumLayout:
	return _flat(mean).with_waviness(FOLD, WAVELENGTH, seed)


## A seed whose Boundary lies, under the start of the dive, well off its mean
## depth: deeper when `deeper`, shallower otherwise. The test's own search,
## so no test hangs on what one seed happens to give.
func _seed_folded_at_start(deeper: bool) -> int:
	for seed in range(1, 200):
		var off := _wavy(seed).boundary_depth_at(0, 0.0, 0.0) - MEAN
		if (off if deeper else -off) > FOLD * 0.6:
			return seed
	assert_bool(false).override_failure_message("No seed folds the start enough").is_true()
	return 0


## The depth under the Head's place of the layout's first Boundary.
func _surface_under(layout: MediumLayout, sim: DiveSimulation) -> float:
	return layout.boundary_depth_at(0, sim.head_position().x, sim.head_position().z)


## Dives until the first Boundary is crossed, straight down or on a slant
## (heading 90, `pitch` degrees down). Returns the crossing's event.
func _cross(layout: MediumLayout, pitch: float) -> Dictionary:
	var sim := DiveSimulation.new(layout)
	sim.set_power(0.5)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_course(90.0, pitch)
	var crossed := DiveTestKit.run_until(sim, &"boundary_crossed", 3000.0, [], 0.1)
	crossed.place = sim.head_position()
	crossed.surface = _surface_under(layout, sim)
	return crossed


func test_layered_and_uniform_layouts_are_flat_unless_folded() -> void:
	var flat := _flat()
	var uniform := MediumLayout.uniform(_clay())
	for place in [Vector2(0.0, 0.0), Vector2(37.0, -12.0), Vector2(-250.0, 410.0)]:
		assert_float(flat.boundary_depth_at(0, place.x, place.y)).is_equal(MEAN)
		for depth in [MEAN - 0.5, MEAN + 0.5]:
			var at := Vector3(place.x, -depth, place.y)
			assert_str(String(flat.medium_at_point(at).name)).is_equal(String(flat.medium_at(depth).name))
			assert_str(String(uniform.medium_at_point(at).name)).is_equal("clay")
	assert_float(flat.boundary_amplitude(0)).is_equal(0.0)


func test_a_folded_boundary_varies_with_place_and_stays_within_its_folds() -> void:
	var wavy := _wavy(3)
	var depths: Array[float] = []
	for i in 40:
		var depth := wavy.boundary_depth_at(0, i * 13.0, i * -7.0)
		depths.append(depth)
		assert_float(absf(depth - MEAN)).is_less_equal(wavy.boundary_amplitude(0))
	assert_float(depths.max() - depths.min()).is_greater(wavy.boundary_amplitude(0))


func test_two_dives_crossing_the_same_boundary_at_different_places_cross_it_at_different_depths() -> void:
	# Deep enough that the slanted dive has come round before it crosses.
	var deep := MEAN * 5.0
	var wavy := _wavy(3, deep)
	var straight := _cross(wavy, 90.0)
	var slanted := _cross(wavy, 50.0)

	assert_dict(straight).contains_keys(["depth"])
	assert_dict(slanted).contains_keys(["depth"])
	var apart := Vector2(straight.place.x - slanted.place.x, straight.place.z - slanted.place.z).length()
	assert_float(apart).is_greater(WAVELENGTH * 0.25)
	# Each crosses where the surface lies under it, not at the mean depth.
	for crossed in [straight, slanted]:
		assert_float(absf(crossed.depth - crossed.surface)).is_less(0.5)
	assert_float(absf(straight.depth - slanted.depth)).is_greater(1.0)
	# Flat, the same two dives cross at the one depth.
	var flat_straight := _cross(_flat(deep), 90.0)
	var flat_slanted := _cross(_flat(deep), 40.0)
	assert_float(absf(flat_straight.depth - flat_slanted.depth)).is_less(0.5)


func test_pulses_return_points_on_the_wavy_surface_and_the_inferred_boundary_follows_it() -> void:
	var wavy := _wavy(5)
	var sim := DiveSimulation.new(wavy)

	DiveTestKit.quiet_scan(sim, 6)

	var on_surface := 0.0
	var on_mean := 0.0
	var sure := 0
	for point in sim.points():
		if point.confidence < 0.5:
			continue
		sure += 1
		on_surface += absf(-point.position.y - wavy.boundary_depth_at(0, point.position.x, point.position.z))
		on_mean += absf(-point.position.y - MEAN)
	assert_int(sure).is_greater(20)
	assert_float(on_surface / sure).is_less(on_mean / sure * 0.5)
	var patches := sim.inferred_boundaries()
	assert_array(patches).is_not_empty()
	var patch_on_surface := 0.0
	var patch_on_mean := 0.0
	for patch in patches:
		patch_on_surface += absf(-patch.centre.y - wavy.boundary_depth_at(0, patch.centre.x, patch.centre.z))
		patch_on_mean += absf(-patch.centre.y - MEAN)
	assert_float(patch_on_surface).is_less(patch_on_mean * 0.5)


func test_the_boundary_countdown_follows_the_surface_along_the_vessels_own_line() -> void:
	for deeper in [true, false]:
		var wavy := _wavy(_seed_folded_at_start(deeper))
		var sim := DiveSimulation.new(wavy)
		sim.set_power(0.5)
		DiveTestKit.quiet_scan(sim, 6)
		DiveTestKit.run(sim, 2.0, 0.1)

		assert_float(sim.boundary_countdown()).is_less(sim.boundary_countdown_cap())
		var metres := sim.boundary_countdown() * sim.speed()
		var to_surface := _surface_under(wavy, sim) - sim.depth()
		var to_mean := MEAN - sim.depth()
		assert_float(absf(metres - to_surface)).is_less(absf(metres - to_mean))


func test_standby_guesses_the_rock_beyond_a_surface_still_ahead_where_a_flat_one_would_be_behind() -> void:
	var wavy := _wavy(_seed_folded_at_start(true))
	var surface := wavy.boundary_depth_at(0, 0.0, 0.0)
	var between := (MEAN + surface) * 0.5
	var sim := DiveSimulation.new(wavy)
	sim.start_below(between)
	sim.set_power(0.5)

	# Below the Boundary's mean depth, the Head is still above its surface here.
	assert_str(String(sim.medium().name)).is_equal("clay")
	DiveTestKit.quiet_scan(sim, 6)
	var guessed := DiveTestKit.wobble_ahead(sim)
	assert_bool(is_nan(guessed.x)).is_false()
	var beyond := DiveTestKit.wobble_in(DiveTestKit.basalt(4.0, 1.0, 0.02))
	var here := DiveTestKit.wobble_in(_clay())
	assert_float(absf(guessed.x - beyond.x)).is_less(absf(guessed.x - here.x))

	# On a flat Boundary at the same depth the Head is already through it.
	var flat := DiveSimulation.new(_flat())
	flat.start_below(between)
	assert_str(String(flat.medium().name)).is_not_equal("clay")


func test_the_same_scenario_gives_the_same_surfaces_every_run() -> void:
	var one := Scenario.first_dive().layout
	var other := Scenario.first_dive().layout
	var folded := false
	for index in one.boundary_depths().size():
		for i in 20:
			var x := i * 41.0 - 300.0
			var z := i * -29.0 + 150.0
			var depth := one.boundary_depth_at(index, x, z)
			assert_float(other.boundary_depth_at(index, x, z)).is_equal(depth)
			folded = folded or absf(depth - one.boundary_depths()[index]) > 0.5
	# The First dive's Boundaries are wavy.
	assert_bool(folded).is_true()


func test_a_line_meets_a_wavy_boundary_where_its_surface_lies() -> void:
	var wavy := _wavy(7)
	var from := Vector3(-120.0, -MEAN + 30.0, 40.0)
	var to := Vector3(200.0, -MEAN - 30.0, -60.0)

	var met := wavy.meets(from, to)

	assert_int(met.size()).is_greater(0)
	var way := (to - from).normalized()
	for crossing in met:
		var at: Vector3 = from + way * float(crossing[0])
		assert_float(absf(-at.y - wavy.boundary_depth_at(0, at.x, at.z))).is_less(0.01)
	# Going down it passes from the clay into what lies below, and back the other way.
	assert_str(String(met[0][2].name)).is_equal("clay")
	assert_str(String(wavy.meets(to, from)[0][3].name)).is_equal("clay")
	# The first meeting along a line, however far.
	var next := wavy.next_meet(from, way)
	assert_float(next[0]).is_equal_approx(met[0][0], 0.01)
