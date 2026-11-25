# Navigation plots the Course, the Drive steers toward it. Tested at the
# simulation's interface: a Course from Navigation, the Drive's steering
# effort and override in; the path, heading, pitch and heat out.
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


func test_a_course_out_of_range_is_kept_to_real_headings_and_pitches() -> void:
	var sim := _diving()

	sim.set_course(-45.0, 200.0)

	assert_float(sim.course_heading()).is_equal(315.0)
	assert_float(sim.course_pitch()).is_equal(90.0)


func test_an_unattended_drive_turns_the_lithocraft_toward_the_course() -> void:
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


func test_an_unattended_drive_follows_the_course_more_gently_than_one_steering_hard() -> void:
	var hard := _diving()
	hard.set_attended(DiveSimulation.STATION_DRIVE, true)
	hard.set_steering_effort(1.0)
	var unattended := _diving()

	var steered := _turn_onto_level_course(hard)
	var followed := _turn_onto_level_course(unattended)

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


func test_an_attended_drive_can_steer_away_from_the_course() -> void:
	var sim := _on_level_course()

	sim.override_course(90.0, 0.0)
	DiveTestKit.run(sim, 6000.0)

	assert_bool(sim.overriding()).is_true()
	assert_float(sim.course_heading()).is_equal(0.0)
	assert_float(sim.steered_heading()).is_equal(90.0)
	assert_float(sim.heading_degrees()).is_equal_approx(90.0, 0.01)


func test_an_override_lasts_only_while_the_drive_is_attended() -> void:
	var sim := _on_level_course()
	sim.override_course(90.0, 0.0)
	DiveTestKit.run(sim, 6000.0)

	sim.set_attended(DiveSimulation.STATION_DRIVE, false)
	DiveTestKit.run(sim, 6000.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.steered_heading()).is_equal(sim.course_heading())
	assert_float(sim.heading_degrees()).is_equal_approx(0.0, 0.01)


func test_the_drive_can_give_up_its_override_and_return_to_the_course() -> void:
	var sim := _on_level_course()
	sim.override_course(90.0, 30.0)
	DiveTestKit.run(sim, 600.0)

	sim.end_override()
	DiveTestKit.run(sim, 6000.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.pitch()).is_equal_approx(0.0, 0.01)
	assert_float(wrapf(sim.heading_degrees(), -180.0, 180.0)).is_equal_approx(0.0, 0.01)


func test_an_unattended_drive_cannot_override_the_course() -> void:
	var sim := _diving()

	sim.override_course(90.0, 0.0)

	assert_bool(sim.overriding()).is_false()
	assert_float(sim.steered_pitch()).is_equal(sim.course_pitch())
