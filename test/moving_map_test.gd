# Navigation's moving map (ticket #42): a side-on cross-section of the whole
# dive. The simulation's side is tested at its interface (the remembered path,
# the Orders' target depth); the map's own logic (the path unrolled into a
# cross-section, the Inferred Boundaries seen side-on, the scale) is plain
# static code, tested directly. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite


func _diving(power := 0.5) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(1.0)))
	sim.set_power(power)
	return sim


# --- The remembered path -----------------------------------------------------

func test_the_remembered_path_runs_from_the_start_of_the_dive_to_the_head() -> void:
	var sim := _diving()
	DiveTestKit.run(sim, 120.0)

	var path := sim.remembered_path()

	assert_float(path[0].x).is_equal(0.0)
	assert_float(path[0].y).is_equal(0.0)
	assert_float(path[path.size() - 1].x).is_equal_approx(sim.distance(), 0.001)
	assert_float(path[path.size() - 1].y).is_equal_approx(sim.depth(), 0.001)
	for i in range(1, path.size()):
		assert_float(path[i].x).is_greater(path[i - 1].x)


func test_the_path_behind_stays_as_it_was_while_the_vessel_goes_on() -> void:
	var sim := _diving()
	DiveTestKit.run(sim, 200.0)
	var before := sim.remembered_path()
	sim.set_course(0.0, 0.0)
	DiveTestKit.run(sim, 3000.0)

	var after := sim.remembered_path()

	# All but the Head's own place, which the next step may still extend.
	assert_int(after.size()).is_greater(before.size())
	for i in before.size() - 1:
		assert_vector(after[i]).is_equal(before[i])
	assert_float(after[after.size() - 1].y).is_greater(before[before.size() - 1].y)


func test_the_remembered_path_is_a_copy() -> void:
	var sim := _diving()
	DiveTestKit.run(sim, 60.0)
	var path := sim.remembered_path()
	path[path.size() - 1] = Vector2(-1.0, -1.0)

	assert_float(sim.remembered_path()[sim.remembered_path().size() - 1].y).is_greater(0.0)


func test_a_new_dive_remembers_a_new_path() -> void:
	var sim := _diving()
	DiveTestKit.run(sim, 60.0)
	sim.debug_surface()

	sim.new_dive()

	assert_int(sim.remembered_path().size()).is_equal(1)


# --- The Orders' target depth -----------------------------------------------

func test_a_dive_with_no_orders_has_no_target_depth() -> void:
	var sim := _diving()

	assert_bool(is_nan(sim.target_depth())).is_true()


func test_the_target_depth_is_the_one_the_orders_set() -> void:
	var scenario := Scenario.new()
	scenario.layout = MediumLayout.uniform(DiveTestKit.rock(1.0))
	var goal := Scenario.Goal.new(&"deep", "Go deep", Scenario.when(func(_sim: DiveSimulation) -> bool: return false))
	goal.target_depth = 321.0
	scenario.orders = [Scenario.Goal.new(&"other", "Something else", Scenario.when(func(_sim: DiveSimulation) -> bool: return false)), goal]

	var sim := scenario.start()

	assert_float(sim.target_depth()).is_equal(321.0)


func test_the_first_dives_target_depth_is_the_top_of_the_medium_its_orders_name() -> void:
	var scenario := Scenario.first_dive()
	var deepest: float = scenario.layout.boundary_depths().back()
	var bottom := scenario.layout.medium_at(deepest + 0.01)

	var sim := scenario.start()

	assert_float(sim.target_depth()).is_equal_approx(deepest, 0.01)
	assert_str(sim.orders()[0].text).contains(String(bottom.name))


# --- The cross-section -------------------------------------------------------

func test_a_path_straight_down_stays_at_the_start_across_the_map() -> void:
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(50.0, 50.0), Vector2(120.0, 120.0)])

	var profile := MovingMap.profile(path)

	for i in path.size():
		assert_float(profile[i].x).is_equal_approx(0.0, 0.001)
		assert_float(profile[i].y).is_equal(path[i].y)


func test_a_level_path_runs_across_the_map_at_one_depth() -> void:
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(100.0, 100.0), Vector2(250.0, 100.0)])

	var profile := MovingMap.profile(path)

	assert_float(profile[2].x - profile[1].x).is_equal_approx(150.0, 0.001)
	assert_float(profile[2].y).is_equal(profile[1].y)


func test_a_slanting_path_goes_less_far_across_than_along() -> void:
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(100.0, 60.0)])

	var profile := MovingMap.profile(path)

	assert_float(profile[1].x).is_greater(0.0)
	assert_float(profile[1].x).is_less(100.0)


func test_a_point_ahead_of_the_vessel_lies_further_across_than_it() -> void:
	var head := Vector3(0.0, -100.0, 0.0)
	# Heading 90: along +X.
	var ahead := MovingMap.across(Vector3(80.0, -150.0, 0.0), head, 40.0, 90.0)
	var behind := MovingMap.across(Vector3(-80.0, -150.0, 0.0), head, 40.0, 90.0)

	assert_float(ahead).is_greater(40.0)
	assert_float(behind).is_less(40.0)


## A patch of ground at a depth, 20 m square, centred ahead of the origin
## along +X, rising `rise` metres per metre toward +X.
func _patch(depth: float, rise := 0.0) -> BoundaryPatch:
	var normal := Vector3(-rise, 1.0, 0.0).normalized()
	return BoundaryPatch.new(Vector3(50.0, -depth, 0.0), normal, Vector2(20.0, 20.0), 10, 0.9, 0.0)


func test_a_level_patch_ahead_is_seen_side_on_at_its_depth_ahead_of_the_vessel() -> void:
	# Heading 90: along +X.
	var side := MovingMap.side_on(_patch(200.0), Vector3.ZERO, 40.0, 90.0)

	assert_float(side[0].x).is_greater(40.0)
	assert_float(side[1].x).is_greater(side[0].x)
	assert_float(side[0].y).is_equal_approx(200.0, 0.001)
	assert_float(side[1].y).is_equal_approx(200.0, 0.001)


func test_a_patch_rising_ahead_is_seen_shallower_at_its_far_end() -> void:
	var side := MovingMap.side_on(_patch(200.0, 0.2), Vector3.ZERO, 40.0, 90.0)

	assert_float(side[1].y).is_less(side[0].y)


func test_the_map_covers_all_it_must_show_and_grows_with_the_dive() -> void:
	var small := MovingMap.span_for(150.0)
	var large := MovingMap.span_for(900.0)

	assert_float(small).is_greater_equal(150.0)
	assert_float(large).is_greater_equal(900.0)
	assert_float(large).is_greater(small)
	# It keeps one scale while the dive grows a little.
	assert_float(MovingMap.span_for(151.0)).is_equal(small)
