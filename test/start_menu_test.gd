# The start menu (ticket #35): it lists every Scenario, and a number key
# chooses one, in the order listed. View logic, tested directly.
extends GdUnitTestSuite


func test_the_menu_lists_every_scenario_by_title_and_what_it_asks() -> void:
	var all := Scenario.all()
	for i in all.size():
		var line := StartMenu.entry(i, all[i])
		assert_str(line).contains(all[i].title)
		assert_str(line).contains(all[i].summary)
		assert_str(line).contains(str(i + 1))


func test_number_keys_choose_the_scenarios_in_the_order_listed() -> void:
	var count := Scenario.all().size()
	assert_int(StartMenu.choice_for(KEY_1, count)).is_equal(0)
	assert_int(StartMenu.choice_for(KEY_KP_1, count)).is_equal(0)
	assert_int(StartMenu.choice_for((KEY_1 + count - 1) as Key, count)).is_equal(count - 1)


func test_keys_that_name_no_scenario_choose_none() -> void:
	var count := Scenario.all().size()
	assert_int(StartMenu.choice_for((KEY_1 + count) as Key, count)).is_equal(-1)
	assert_int(StartMenu.choice_for(KEY_0, count)).is_equal(-1)
	assert_int(StartMenu.choice_for(KEY_ENTER, count)).is_equal(-1)
