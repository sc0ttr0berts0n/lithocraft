# The checklist panel (Tab, ticket #34): the Orders, the phase now running
# with its next step highlighted and its Station named, surface control's
# messages at the foot. Tested on the panel's text, read from a simulation.
extends GdUnitTestSuite

const _STATIONS := {
	DiveSimulation.STATION_REACTOR: "Reactor",
	DiveSimulation.STATION_THERMAL: "Thermal",
}


func test_tab_opens_the_checklist_and_f1_lists_it() -> void:
	var binding := KeyMap.binding(&"toggle_checklist")
	assert_array(binding.keys).contains([KEY_TAB])
	assert_str(binding.where).is_equal(KeyMap.ANYWHERE)
	assert_array(KeyMap.bindings_at(KeyMap.ANYWHERE).map(
			func(b: Dictionary) -> StringName: return b.action)).contains([&"toggle_checklist"])


func test_the_next_step_is_highlighted_with_its_station_and_key() -> void:
	var sim := Scenario.first_dive().start()
	sim.read_orders()
	sim.advance(0.1)
	var next := sim.next_step()
	assert_str(next.station).is_equal(DiveSimulation.STATION_REACTOR)
	var text := ChecklistPanel.text_of(sim, _STATIONS)
	var line := _line_with(text, next.text)
	assert_str(line).contains("[b]")
	assert_str(line).contains("Reactor")
	# The key's label, escaped so BBCode shows its brackets.
	assert_str(line).contains(KeyMap.label(next.action).replace("[", "[lb]"))
	# A step after it is neither highlighted nor the next.
	var later := _line_with(text, sim.checklist()[0].steps[2].text)
	assert_str(later).not_contains("[b]")


func test_every_colour_in_the_panel_is_the_themes() -> void:
	var sim := Scenario.first_dive().start()
	sim.read_orders()
	sim.advance(0.1)
	var found := RegEx.create_from_string("\\[color=#([0-9a-f]{6})\\]").search_all(
			ChecklistPanel.text_of(sim, _STATIONS))
	assert_int(found.size()).is_greater(0)
	for hit in found:
		assert_bool(StationTheme.has(Color.html(hit.get_string(1)))).override_failure_message(
				"#%s is not a Theme colour" % hit.get_string(1)).is_true()


func test_a_step_that_takes_two_controls_shows_the_keys_of_both() -> void:
	# The Shift drill's pretune: STANDBY may be off in frequency, in
	# amplitude or in both, so the step names both controls' keys.
	var sim := Scenario.shift_drill().start()
	sim.read_orders()
	sim.advance(0.1)
	var next := sim.next_step()
	assert_str(next.id).is_equal(&"pretune_standby")

	var line := _line_with(ChecklistPanel.text_of(sim, _STATIONS), next.text)

	for action: StringName in [&"tune_frequency", &"tune_amplitude"]:
		assert_str(line).contains(KeyMap.label(action).replace("[", "[lb]"))


func test_the_panel_shows_every_goal_and_surface_controls_messages() -> void:
	var sim := Scenario.first_dive().start()
	DiveTestKit.run(sim, 5.0)
	var text := ChecklistPanel.text_of(sim, _STATIONS)
	for goal in sim.orders():
		assert_str(text).contains(goal.text)
	assert_str(text).contains(sim.surface_messages()[0].left(30))


static func _line_with(text: String, words: String) -> String:
	for line in text.split("\n"):
		if line.contains(words):
			return line
	return ""
