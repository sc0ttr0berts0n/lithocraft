# The deviation as the screens state it (ticket #65): the Drive's screen and
# Navigation's say the same thing of the same dive, in the same words, and
# nothing while the Drive follows the Course. The words are plain static code
# (CourseDeviation), tested directly; the screens through a staged Habitat.
extends GdUnitTestSuite


## A Habitat staged as a screenshot's is, the crew seated at the Drive.
func _staged(commands: Array) -> Node:
	var args := ["--look", "Drive", "--time", "3", "--out", "unused.png"]
	for command: String in commands:
		args.append_array(["--do", command])
	var habitat := DiveTestKit.staged_shot(self, args)
	await DiveTestKit.laid_out(self)
	return habitat


## Everything written on the screen of the Station with this name.
func _written(habitat: Node, station_name: String) -> String:
	return "\n".join(DiveTestKit.station(habitat, station_name).screen().texts())


func test_no_deviation_is_no_words() -> void:
	assert_str(CourseDeviation.text(0.0, 0.0)).is_empty()


func test_a_deviation_is_said_as_up_or_down_and_left_or_right() -> void:
	assert_str(CourseDeviation.text(-30.0, 0.0)).is_equal("30 deg up")
	assert_str(CourseDeviation.text(15.0, 0.0)).is_equal("15 deg down")
	assert_str(CourseDeviation.text(0.0, -45.0)).is_equal("45 deg left")
	assert_str(CourseDeviation.text(-30.0, 15.0)).is_equal("30 deg up, 15 deg right")


func test_following_the_course_neither_screen_says_the_drive_is_off_it() -> void:
	var habitat := await _staged(["0 set_power 1"])

	assert_str(CourseDeviation.of(habitat.simulation())).is_empty()
	assert_str(_written(habitat, "Drive")).contains("Following the Course")
	assert_str(_written(habitat, "Drive").to_lower()).not_contains("off course")
	assert_str(_written(habitat, "Navigation").to_lower()).not_contains("off the course")


func test_nudged_off_the_course_both_screens_state_the_same_deviation() -> void:
	var habitat := await _staged(["0 set_power 1", "1 nudge_pitch -1", "1 nudge_pitch -1", "2 nudge_heading 1"])

	var deviation := CourseDeviation.of(habitat.simulation())
	assert_str(deviation).contains("up").contains("right")
	assert_str(_written(habitat, "Drive")).contains("off Course: " + deviation)
	assert_str(_written(habitat, "Navigation")).contains("Drive is off the Course by " + deviation)


func test_both_screens_write_the_same_course() -> void:
	var habitat := await _staged(["0 set_course 30 60", "1 nudge_pitch -1"])

	var sim: DiveSimulation = habitat.simulation()
	var course := "Course %03.0f  %+.0f deg" % [sim.course_heading(), sim.course_pitch()]
	assert_str(_written(habitat, "Drive")).contains(course)
	assert_str(_written(habitat, "Navigation")).contains(course)
