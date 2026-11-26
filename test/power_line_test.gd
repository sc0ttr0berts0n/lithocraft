# A Station's power line: set point against actual, as shares of the
# Reactor's full output, and "starved" only when actual falls short of set.
extends GdUnitTestSuite


func test_set_and_actual_are_shares_of_the_reactor_s_full_output() -> void:
	assert_str(PowerLine.text(0.08, 0.03, 1.0)).is_equal("Power: set 8% · actual 3%: starved")
	assert_str(PowerLine.text(0.08, 0.03, 2.0)).is_equal("Power: set 4% · actual 2%: starved")


func test_a_station_given_all_it_asks_is_not_starved() -> void:
	assert_str(PowerLine.text(0.05, 0.05, 1.0)).is_equal("Power: set 5% · actual 5%")
	assert_bool(PowerLine.starved(0.05, 0.05, 1.0)).is_false()


func test_starved_appears_only_when_actual_is_below_set() -> void:
	for case in [[0.5, 0.2], [0.5, 0.49], [0.03, 0.0], [0.5, 0.5], [0.0, 0.0], [0.2, 0.2]]:
		var line := PowerLine.text(case[0], case[1], 1.0)
		assert_bool(line.ends_with(": starved")).is_equal(case[1] < case[0])
		assert_bool(PowerLine.starved(case[0], case[1], 1.0)).is_equal(case[1] < case[0])


func test_a_shortfall_too_small_to_show_is_not_called_starved() -> void:
	# Set and actual read the same, so the line must not contradict itself.
	assert_str(PowerLine.text(0.08, 0.0799, 1.0)).is_equal("Power: set 8% · actual 8%")
	assert_bool(PowerLine.starved(0.08, 0.0799, 1.0)).is_false()

