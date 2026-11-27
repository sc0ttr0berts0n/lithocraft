# Navigation plots the Course, the Drive steers toward it. Tested at the
# simulation's interface: a Course from Navigation, the Drive's steering
# effort and nudges off the Course in; the path, heading, pitch and heat out.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## A Lithocraft under power, diving straight down in plain rock. Below full
## power, so the Reactor has power to spare for steering.
func _diving(power := 0.5) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(1.0)))
	sim.set_power(power)
	return sim


func test_navigation_plots_a_course_the_simulation_reports() -> void:
	var sim := _diving()

	sim.set_course(30.0, 45.0)

	assert_float(sim.course_heading()).is_equal(30.0)
	assert_float(sim.course_pitch()).is_equal(45.0)


func test_the_course_is_the_way_the_lithocraft_points_once_it_has_turned_onto_it() -> void:
	var sim := _diving()

	sim.set_course(30.0, 45.0)
	DiveTestKit.run(sim, 6000.0)

	assert_float(sim.course_direction().angle_to(sim.heading())).is_less(0.001)


func test_a_course_out_of_range_is_kept_to_real_headings_and_pitches() -> void:
	var sim := _diving()

	sim.set_course(-45.0, 200.0)

	assert_float(sim.course_heading()).is_equal(315.0)
	assert_float(sim.course_pitch()).is_equal(90.0)


func test_a_drive_nobody_is_at_still_turns_the_lithocraft_toward_the_course() -> void:
	var sim := _diving()
	assert_bool(sim.attended(DiveSimulation.STATION_DRIVE)).is_false()

	sim.set_course(90.0, 0.0)
	DiveTestKit.run(sim, 6000.0)

	assert_float(sim.pitch()).is_equal_approx(0.0, 0.01)
	assert_float(sim.heading_degrees()).is_equal_approx(90.0, 0.01)


## Turns from the dive onto a level Course and returns how long the turn took
## (seconds until within a degree of the Course) and the most heat made per
## second on the way.
func _turn_onto_level_course(sim: DiveSimulation) -> Dictionary:
	sim.set_course(0.0, 0.0)
	var seconds := 0.0
	var hottest := 0.0
	while absf(sim.pitch()) > 1.0 and seconds < 20000.0:
		sim.advance(1.0)
		seconds += 1.0
		hottest = maxf(hottest, sim.heat_produced())
	return {seconds = seconds, hottest = hottest}


func test_the_drives_autopilot_follows_the_course_more_gently_than_a_crew_steering_hard() -> void:
	var autopiloted := _diving()
	autopiloted.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	# The same power as the autopilot's, so only the steering differs.
	var hard := _diving(autopiloted.power())
	hard.set_steering_effort(1.0)

	var steered := _turn_onto_level_course(hard)
	var followed := _turn_onto_level_course(autopiloted)

	assert_float(steered.seconds).is_less(20000.0)
	assert_float(followed.seconds).is_less(20000.0)
	assert_float(followed.seconds).is_greater(steered.seconds)
	assert_float(followed.hottest).is_less(steered.hottest)


func test_less_steering_effort_turns_more_slowly_and_makes_less_heat() -> void:
	var hard := _diving()
	hard.set_attended(DiveSimulation.STATION_DRIVE, true)
	hard.set_steering_effort(1.0)
	var easy := _diving()
	easy.set_attended(DiveSimulation.STATION_DRIVE, true)
	easy.set_steering_effort(0.2)

	var hard_turn := _turn_onto_level_course(hard)
	var easy_turn := _turn_onto_level_course(easy)

	assert_float(easy.steering_effort()).is_less(hard.steering_effort())
	assert_float(easy_turn.seconds).is_greater(hard_turn.seconds)
	assert_float(easy_turn.hottest).is_less(hard_turn.hottest)


## A Lithocraft travelling level on a Course of heading 0, its Drive attended.
func _on_level_course() -> DiveSimulation:
	var sim := _diving()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_course(0.0, 0.0)
	DiveTestKit.run(sim, 6000.0)
	return sim


func test_an_attended_drive_nudges_its_steering_off_the_course() -> void:
	var sim := _on_level_course()

	sim.nudge_heading(1.0)
	DiveTestKit.run(sim, 6000.0)

	assert_bool(sim.overriding()).is_true()
	assert_float(sim.course_heading()).is_equal(0.0)
	assert_float(sim.steered_heading()).is_greater(0.0)
	assert_float(sim.steered_pitch()).is_equal(sim.course_pitch())
	assert_float(sim.heading_degrees()).is_equal_approx(sim.steered_heading(), 0.01)


func test_each_nudge_moves_on_from_where_the_drive_already_steers() -> void:
	var sim := _on_level_course()
	sim.nudge_pitch(1.0)
	var once := sim.steered_pitch()

	sim.nudge_pitch(1.0)
	sim.nudge_heading(-1.0)

	assert_float(once).is_greater(sim.course_pitch())
	assert_float(sim.steered_pitch() - once).is_equal_approx(once - sim.course_pitch(), 0.001)
	assert_float(sim.deviation_heading()).is_equal_approx(-sim.nudge_degrees(), 0.001)


## However large the number sent, a nudge is one nudge: only its direction
## counts, so no one command points the Drive at a dive, level or a climb.
func test_a_nudge_is_one_small_step_whatever_is_sent() -> void:
	var gentle := _on_level_course()
	var shoved := _on_level_course()

	gentle.nudge_pitch(-1.0)
	shoved.nudge_pitch(-90.0)
	gentle.nudge_heading(1.0)
	shoved.nudge_heading(180.0)

	assert_float(shoved.steered_pitch()).is_equal(gentle.steered_pitch())
	assert_float(shoved.steered_heading()).is_equal(gentle.steered_heading())
	assert_float(absf(gentle.deviation_pitch())).is_equal_approx(gentle.nudge_degrees(), 0.001)
	# One nudge up from level still steers nearer level than a climb.
	assert_float(absf(gentle.steered_pitch() - gentle.course_pitch())) \
			.is_less(absf(gentle.steered_pitch() - -90.0))


func test_no_drive_command_sets_what_it_steers_for_outright() -> void:
	var sim := _on_level_course()

	assert_bool(sim.has_method("override_course")).is_false()
	for method in sim.get_method_list():
		var name: String = method.name
		if not name.begins_with("_") and (name.contains("override") or name.contains("nudge")):
			assert_array((method.args as Array).filter(func(a: Dictionary) -> bool: return a.name.contains("degrees"))).is_empty()


func test_the_deviation_reads_zero_while_the_drive_follows_the_course() -> void:
	var sim := _on_level_course()
	sim.set_course(40.0, 20.0)
	DiveTestKit.run(sim, 100.0)

	assert_float(sim.deviation_pitch()).is_equal(0.0)
	assert_float(sim.deviation_heading()).is_equal(0.0)


## Pitch as the simulation signs it (+ diving), heading + to the right.
func test_the_deviation_is_how_far_the_nudges_have_taken_the_drive_off_the_course() -> void:
	var sim := _on_level_course()

	sim.nudge_pitch(-1.0)
	sim.nudge_pitch(-1.0)
	sim.nudge_heading(1.0)

	assert_float(sim.deviation_pitch()).is_equal_approx(-2.0 * sim.nudge_degrees(), 0.001)
	assert_float(sim.deviation_heading()).is_equal_approx(sim.nudge_degrees(), 0.001)
	assert_float(sim.steered_pitch() - sim.course_pitch()).is_equal_approx(sim.deviation_pitch(), 0.001)
	assert_float(sim.course_pitch()).is_equal(0.0)


func test_the_heading_deviation_is_the_short_way_round_the_compass() -> void:
	var sim := _on_level_course()
	sim.set_course(350.0, 0.0)

	sim.nudge_heading(1.0)
	sim.nudge_heading(1.0)

	assert_float(sim.deviation_heading()).is_equal_approx(2.0 * sim.nudge_degrees(), 0.001)


func test_nudging_back_onto_the_course_ends_the_override() -> void:
	var sim := _on_level_course()
	sim.nudge_pitch(1.0)
	sim.nudge_heading(1.0)
	assert_bool(sim.overriding()).is_true()

	sim.nudge_heading(-1.0)
	sim.nudge_pitch(-1.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.deviation_pitch()).is_equal(0.0)


func test_a_course_plotted_onto_what_the_drive_steers_for_ends_the_override() -> void:
	var sim := _on_level_course()
	sim.nudge_pitch(1.0)
	sim.nudge_heading(1.0)

	sim.set_course(sim.steered_heading() + 10.0, sim.steered_pitch())
	var still_off := sim.overriding()
	var off_by := sim.deviation_heading()
	sim.set_course(sim.steered_heading(), sim.steered_pitch())

	assert_bool(still_off).is_true()
	assert_float(off_by).is_equal_approx(-10.0, 0.001)
	assert_bool(sim.overriding()).is_false()


## Straight up or down the heading means nothing, so it is no deviation, and
## a heading nudge there turns nothing.
func test_steering_straight_down_a_heading_nudge_is_no_deviation() -> void:
	var sim := _diving()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)

	sim.nudge_heading(1.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.deviation_heading()).is_equal(0.0)


func test_an_override_lasts_until_the_drives_autopilot_is_engaged() -> void:
	var sim := _on_level_course()
	DiveTestKit.nudge(sim, 90.0, 0.0)
	DiveTestKit.run(sim, 6000.0)
	sim.set_attended(DiveSimulation.STATION_DRIVE, false)
	DiveTestKit.run(sim, 60.0)
	assert_bool(sim.overriding()).is_true()

	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	DiveTestKit.run(sim, 20000.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.deviation_heading()).is_equal(0.0)
	assert_float(sim.steered_heading()).is_equal(sim.course_heading())
	assert_float(sim.heading_degrees()).is_equal_approx(0.0, 0.01)


func test_the_drive_can_give_up_its_override_and_return_to_the_course() -> void:
	var sim := _on_level_course()
	DiveTestKit.nudge(sim, 90.0, 30.0)
	DiveTestKit.run(sim, 600.0)

	sim.end_override()
	DiveTestKit.run(sim, 6000.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.deviation_pitch()).is_equal(0.0)
	assert_float(sim.pitch()).is_equal_approx(0.0, 0.01)
	assert_float(wrapf(sim.heading_degrees(), -180.0, 180.0)).is_equal_approx(0.0, 0.01)


func test_the_crew_must_be_at_the_drive_to_nudge_it_off_the_course() -> void:
	var sim := _diving()

	sim.nudge_pitch(-1.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.steered_pitch()).is_equal(sim.course_pitch())
	assert_float(sim.deviation_pitch()).is_equal(0.0)
