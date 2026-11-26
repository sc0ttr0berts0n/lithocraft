# Tests at the screenshot tool's seam (tools/screenshot/shot_plan.gd): the
# arguments of one shot in, a Habitat staged for it out, read through the
# Habitat's simulation. The picture itself needs a window, so it is checked
# by running the tool (docs/conventions/running-and-testing.md, "Ad-hoc
# checks"), not here.
extends GdUnitTestSuite


func _plan(args: Array) -> ShotPlan:
	return ShotPlan.parse(PackedStringArray(args + ["--out", "unused.png"]))


## The Habitat of the shot these arguments ask for, staged and in the tree.
func _staged(args: Array) -> Node:
	var plan := _plan(args)
	assert_str(plan.error).is_empty()
	var habitat: Node = auto_free(plan.make_habitat())
	add_child(habitat)
	assert_str(plan.stage(habitat)).is_empty()
	return habitat


func test_a_shot_runs_the_named_scenario_to_its_time_with_the_crew_at_the_station() -> void:
	var habitat := _staged(["--scenario", "First dive", "--look", "Drive", "--time", "3"])

	var sim: DiveSimulation = habitat.simulation()
	assert_str(sim.scenario_title()).is_equal(Scenario.first_dive().title)
	assert_float(sim.dive_time()).is_equal_approx(3.0, 2.0 * ShotPlan.STEP)
	assert_bool(sim.attended(DiveSimulation.STATION_DRIVE)).is_true()
	assert_bool(sim.attended(DiveSimulation.STATION_REACTOR)).is_false()


func test_a_scenario_is_found_by_its_title_however_it_is_spaced() -> void:
	var habitat := _staged(["--scenario", "shift-drill", "--look", "Reactor", "--time", "0"])

	assert_str(habitat.simulation().scenario_title()).is_equal(Scenario.shift_drill().title)


func test_a_command_acts_from_its_time_on() -> void:
	var early := _staged(["--look", "Drive", "--time", "6", "--do", "1 set_power 1"])
	var late := _staged(["--look", "Drive", "--time", "6", "--do", "5 set_power 1"])
	var never := _staged(["--look", "Drive", "--time", "6"])

	assert_float(early.simulation().depth()).is_greater(late.simulation().depth())
	assert_float(late.simulation().depth()).is_greater(never.simulation().depth())


func test_commands_are_sent_in_time_order_whatever_order_they_are_given_in() -> void:
	var habitat := _staged(["--look", "Navigation", "--time", "3",
			"--do", "2 set_course 90 0", "--do", "1 set_course 45 0"])

	assert_float(habitat.simulation().course_heading()).is_equal(90.0)


func test_commands_for_the_same_time_are_sent_in_the_order_given() -> void:
	var up := _staged(["--look", "Drive", "--time", "1",
			"--do", "1 set_power 0.2", "--do", "1 set_power 0.7"])
	var down := _staged(["--look", "Drive", "--time", "1",
			"--do", "1 set_power 0.7", "--do", "1 set_power 0.2"])

	assert_float(up.simulation().power()).is_greater(down.simulation().power())


func test_a_command_that_needs_the_crew_at_a_station_works_seated_there() -> void:
	var override := ["--time", "2", "--do", "1 nudge_pitch -1"]
	var at_the_drive := _staged(["--look", "Drive"] + override)
	var elsewhere := _staged(["--look", "Thermal"] + override)

	assert_bool(at_the_drive.simulation().overriding()).is_true()
	assert_bool(elsewhere.simulation().overriding()).is_false()


func test_the_same_shot_twice_stages_the_same_dive() -> void:
	var shot := ["--look", "Drive", "--time", "20", "--do", "0 set_power 1",
			"--do", "5 set_course 30 60", "--do", "8 set_autopilot thermal true"]
	var first: DiveSimulation = _staged(shot).simulation()
	var second: DiveSimulation = _staged(shot).simulation()

	assert_float(first.depth()).is_greater(0.0)
	assert_float(second.depth()).is_equal(first.depth())
	assert_float(second.heading_degrees()).is_equal(first.heading_degrees())
	assert_float(second.vessel_temperature()).is_equal(first.vessel_temperature())


func test_time_is_dive_time_so_a_skip_counts_for_what_it_ran() -> void:
	var habitat := _staged(["--look", "Reactor", "--time", "62", "--do", "1 debug_skip 60"])

	assert_float(habitat.simulation().dive_time()).is_equal_approx(62.0, 2.0 * ShotPlan.STEP)


func test_a_shot_after_the_dive_has_ended_is_still_reached() -> void:
	var habitat := _staged(["--look", "Drive", "--time", "3", "--do", "1 debug_surface"])

	assert_bool(habitat.simulation().surfaced()).is_true()


func test_a_debug_command_the_simulation_refuses_fails_the_shot() -> void:
	var plan := _plan(["--look", "Drive", "--time", "3", "--do", "1 debug_surface",
			"--do", "2 debug_skip 10"])
	var habitat: Node = auto_free(plan.make_habitat())
	add_child(habitat)

	assert_str(plan.stage(habitat)).contains("debug_skip")


func test_the_screen_space_layer_is_hidden_unless_asked_for() -> void:
	var clean := _staged(["--look", "Drive", "--time", "0"])
	var with_notice := _staged(["--look", "Drive", "--time", "0", "--overlay"])

	assert_bool(clean.get_node("Overlay").visible).is_false()
	assert_bool(with_notice.get_node("Overlay").visible).is_true()
	assert_bool(with_notice.get_node("%DiveView").visible).is_false()


func test_a_station_is_seen_through_the_crews_eyes_and_the_bore_from_outside_it() -> void:
	var seated := _staged(["--look", "Thermal", "--time", "1"])
	var seated_camera := seated.get_viewport().get_camera_3d()
	var seated_to_pivot := seated_camera.global_position.distance_to(
			DiveTestKit.station_pivot("Thermal"))
	seated.free()
	var bore := _staged(["--look", "bore", "--time", "1"])
	var bore_camera := bore.get_viewport().get_camera_3d()

	assert_float(seated_to_pivot).is_less(1.5)
	assert_float(bore_camera.global_position.distance_to(ShotPlan.bore_eye())).is_less(0.01)
	# Clear of every Station, and looking at the Column on the Bore's axis.
	for place in DiveTestKit.station_places():
		assert_float(bore_camera.global_position.distance_to(
				DiveTestKit.station_pivot(DiveTestKit.station_name(place)))).is_greater(1.0)
	var eye := bore_camera.global_position
	var to_axis := Vector3(-eye.x, -eye.y, 0.0).normalized()
	assert_float((-bore_camera.global_basis.z).dot(to_axis)).is_greater(0.999)
	# Level with the ring of Stations, where the crew work and the Column's
	# features pass the Bore Station.
	assert_float(eye.z).is_equal_approx(DiveTestKit.station_pivot("Bore Station").z, 0.001)


## The Bore Station's name in the simulation is &"bore", which is also what
## --look calls the Bore: the two are different looks.
func test_the_bore_station_is_seen_seated_at_it_not_as_the_bore() -> void:
	var seated := _staged(["--look", "Bore Station", "--time", "1"])
	var camera := seated.get_viewport().get_camera_3d()

	assert_bool(seated.simulation().attended(DiveSimulation.STATION_BORE)).is_true()
	assert_float(camera.global_position.distance_to(DiveTestKit.station_pivot("Bore Station"))).is_less(1.5)
	seated.free()
	var bore := _staged(["--look", "bore", "--time", "1"])
	assert_bool(bore.simulation().attended(DiveSimulation.STATION_BORE)).is_false()
	assert_array(Array(ShotPlan._look_names())).contains(["bore", "crew"])


func test_arguments_that_make_no_shot_say_why() -> void:
	var shot := ["--look", "Drive", "--time", "5"]
	for wrong in [
		["--look", "Drive"],
		["--time", "5"],
		["--look", "Galley", "--time", "5"],
		["--look", "Drive", "--time", "soon"],
		shot + ["--scenario", "Second dive"],
		shot + ["--do", "set_power 1"],
		shot + ["--do", "1 fly_home"],
		shot + ["--do", "1 _step 1"],
		shot + ["--do", "1 set_power"],
		shot + ["--do", "1 set_power 1 2"],
		shot + ["--do", "6 set_power 1"],
		shot + ["--zoom", "2"],
		shot + ["--scenario"],
	]:
		assert_str(_plan(wrong).error).override_failure_message(
				"no error for %s" % [wrong]).is_not_empty()
	assert_str(_plan(shot).error).is_empty()


func test_the_bore_station_is_a_station_and_not_the_view_into_the_bore() -> void:
	var seated := _staged(["--look", "Bore Station", "--time", "1"])
	var camera := seated.get_viewport().get_camera_3d()

	assert_bool(seated.simulation().attended(DiveSimulation.STATION_BORE)).is_true()
	assert_float(camera.global_position.distance_to(
			DiveTestKit.station_pivot("Bore Station"))).is_less(1.5)


func test_the_column_is_seen_from_the_bore_station_turned_round_to_it() -> void:
	var seated := _staged(["--look", "Bore Station", "--time", "1"])
	var seat := seated.get_viewport().get_camera_3d().global_position
	seated.free()
	var turned := _staged(["--look", "column", "--time", "1"])
	var camera := turned.get_viewport().get_camera_3d()

	# The crew's own eyes at the Bore Station, looking square at the Bore's
	# axis instead of the screen.
	assert_bool(turned.simulation().attended(DiveSimulation.STATION_BORE)).is_true()
	assert_float(camera.global_position.distance_to(seat)).is_less(0.01)
	var to_axis := Vector3(-seat.x, -seat.y, 0.0).normalized()
	assert_float((-camera.global_basis.z).dot(to_axis)).is_greater(0.999)


func test_a_look_can_be_tilted_up_and_turned_from_where_the_eyes_are() -> void:
	var plain := _staged(["--look", "crew", "--time", "1"])
	var plain_camera := plain.get_viewport().get_camera_3d()
	var eye := plain_camera.global_position
	var ahead := -plain_camera.global_basis.z
	var up := plain_camera.global_basis.y
	var right := plain_camera.global_basis.x
	plain.free()
	var tilted := _staged(["--look", "crew", "--time", "1", "--tilt", "60"])
	var tilted_camera := tilted.get_viewport().get_camera_3d()
	var tilted_eye := tilted_camera.global_position
	var tilted_ahead := -tilted_camera.global_basis.z
	tilted.free()
	var turned := _staged(["--look", "crew", "--time", "1", "--turn", "90"])
	var turned_camera := turned.get_viewport().get_camera_3d()

	# The same eyes, looking up the room's height...
	assert_float(tilted_eye.distance_to(eye)).is_less(0.01)
	assert_float(tilted_ahead.dot(up)).is_greater(0.8)
	assert_float(tilted_ahead.dot(ahead)).is_greater(0.4)
	# ...or round to the crew's right, still level.
	assert_float(turned_camera.global_position.distance_to(eye)).is_less(0.01)
	assert_float((-turned_camera.global_basis.z).dot(right)).is_greater(0.999)
	assert_float(turned_camera.global_basis.y.dot(up)).is_greater(0.999)


func test_a_tilt_or_turn_that_is_not_a_number_of_degrees_makes_no_shot() -> void:
	assert_str(_plan(["--look", "crew", "--time", "1", "--tilt", "up"]).error).is_not_empty()
	assert_str(_plan(["--look", "crew", "--time", "1", "--turn", "left"]).error).is_not_empty()


## Looking at one Station while another is worked: attended in the same
## moment, before its command.
func test_a_station_attended_at_the_same_time_takes_its_command_while_another_is_looked_at() -> void:
	var habitat := _staged(["--look", "Navigation", "--time", "2",
			"--do", "1 set_attended drive true", "--do", "1 nudge_pitch -1"])

	assert_bool(habitat.simulation().overriding()).is_true()
	assert_bool(habitat.simulation().attended(DiveSimulation.STATION_DRIVE)).is_false()
