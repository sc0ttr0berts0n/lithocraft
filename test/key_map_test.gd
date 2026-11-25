# Tests at the key map's seam: the one list of keys that the Habitat's input,
# each Station's screen and the F1 controls all read. What a key does where
# the crew stands is what the map says is shown there, so screen and input
# cannot disagree. Plain data, no scene.
extends GdUnitTestSuite

const STATIONS_IN_USE: Array[StringName] = [
	DiveSimulation.STATION_REACTOR,
	DiveSimulation.STATION_DRIVE,
	DiveSimulation.STATION_THERMAL,
	DiveSimulation.STATION_NAVIGATION,
	DiveSimulation.STATION_BORE,
]


func test_every_station_in_use_has_keys_to_show() -> void:
	for station in STATIONS_IN_USE:
		assert_bool(KeyMap.bindings_at(station).is_empty()).override_failure_message(
				"%s has no keys" % station).is_false()


func test_a_key_pressed_at_a_station_does_what_its_screen_shows() -> void:
	for station in STATIONS_IN_USE:
		for binding in KeyMap.bindings_at(station):
			for i in binding.keys.size():
				var found := KeyMap.find(binding.keys[i], [KeyMap.ANYWHERE, station])
				assert_str(String(found.get(&"action", &""))).override_failure_message(
						"%s at %s runs %s, not %s" % [KeyMap.name_of(binding.keys[i]), station,
						found.get(&"action", &"nothing"), binding.action]).is_equal(String(binding.action))
				assert_int(found.index).is_equal(i)


func test_a_key_shown_anywhere_works_anywhere() -> void:
	for binding in KeyMap.bindings_at(KeyMap.ANYWHERE):
		if binding.held:
			continue
		for i in binding.keys.size():
			for station in STATIONS_IN_USE:
				var found := KeyMap.find(binding.keys[i], [KeyMap.ANYWHERE, station])
				assert_str(String(found.get(&"action", &""))).override_failure_message(
						"%s at %s is taken by the Station" % [KeyMap.name_of(binding.keys[i]), station]
						).is_equal(String(binding.action))


func test_a_station_key_does_nothing_away_from_its_station() -> void:
	for binding in KeyMap.bindings_at(DiveSimulation.STATION_REACTOR):
		for code in binding.keys:
			var found := KeyMap.find(code, [KeyMap.ANYWHERE, DiveSimulation.STATION_BORE])
			assert_str(String(found.get(&"action", &""))).is_not_equal(String(binding.action))


func test_held_keys_are_read_while_held_not_run_on_a_press() -> void:
	var walk: Dictionary = KeyMap.binding(&"walk")
	assert_bool(walk.held).is_true()
	for code in walk.keys:
		assert_str(String(KeyMap.find(code, [KeyMap.ANYWHERE]).get(&"action", &""))).is_not_equal("walk")


func test_the_habitat_runs_every_action_on_the_map() -> void:
	var methods := {}
	for method in (load("res://view/habitat.gd") as Script).get_script_method_list():
		methods[method.name] = true
	for binding in KeyMap.bindings():
		if binding.held:
			continue
		assert_bool(methods.has("_key_%s" % binding.action)).override_failure_message(
				"habitat.gd has no _key_%s" % binding.action).is_true()


func test_every_key_on_the_map_has_a_prompt() -> void:
	for binding in KeyMap.bindings():
		for code in binding.keys:
			assert_object(KeyPrompt.texture(code)).override_failure_message(
					"no prompt for %s" % KeyMap.name_of(code)).is_not_null()


func test_a_key_without_its_own_picture_shows_its_glyph_on_a_blank() -> void:
	assert_str(KeyPrompt.glyph(KEY_PERIOD)).is_equal(".")
	assert_str(KeyPrompt.glyph(KEY_COMMA)).is_equal(",")
	assert_object(KeyPrompt.texture(KEY_PERIOD)).is_equal(KeyPrompt.texture(KEY_COMMA))
	assert_str(KeyPrompt.glyph(KEY_T)).is_empty()
	assert_object(KeyPrompt.texture(KEY_T)).is_not_equal(KeyPrompt.texture(KEY_G))


func test_two_keys_that_look_the_same_are_shown_once() -> void:
	assert_int(KeyPrompt.distinct([KEY_ENTER, KEY_KP_ENTER]).size()).is_equal(1)
	assert_int(KeyPrompt.distinct([KEY_T, KEY_G]).size()).is_equal(2)
	assert_int(KeyPrompt.distinct([KEY_PERIOD, KEY_COMMA]).size()).is_equal(2)


func test_a_label_names_every_key_of_its_action() -> void:
	var label := KeyMap.label(&"shift_dial")
	for code in KeyMap.binding(&"shift_dial").keys:
		assert_str(label).contains(KeyMap.name_of(code))


func test_a_label_for_one_key_names_only_that_key() -> void:
	var keys: Array = KeyMap.binding(&"power_step").keys
	var label := KeyMap.label(&"power_step", 0)
	assert_str(label).contains(KeyMap.name_of(keys[0]))
	assert_str(label).not_contains(KeyMap.name_of(keys[1]))


func test_the_debug_menu_opens_from_anywhere() -> void:
	assert_str(String(KeyMap.binding(&"debug_menu").where)).is_equal(String(KeyMap.ANYWHERE))
	assert_bool(KeyMap.bindings_at(KeyMap.DEBUG).is_empty()).is_false()


func test_a_debug_key_does_what_the_debug_menu_shows_wherever_the_crew_stands() -> void:
	for binding in KeyMap.bindings_at(KeyMap.DEBUG):
		for i in binding.keys.size():
			for station in STATIONS_IN_USE:
				var found := KeyMap.find(binding.keys[i], [KeyMap.ANYWHERE, station, KeyMap.DEBUG])
				assert_str(String(found.get(&"action", &""))).override_failure_message(
						"%s in the debug menu at %s runs %s" % [KeyMap.name_of(binding.keys[i]),
						station, found.get(&"action", &"nothing")]).is_equal(String(binding.action))


func test_debug_keys_do_nothing_while_the_debug_menu_is_closed() -> void:
	var everywhere: Array = [KeyMap.ANYWHERE]
	everywhere.append_array(STATIONS_IN_USE)
	for binding in KeyMap.bindings_at(KeyMap.DEBUG):
		for code in binding.keys:
			assert_str(String(KeyMap.find(code, everywhere).get(&"action", &""))).is_not_equal(
					String(binding.action))


func test_the_numpad_keys_show_as_numpad_prompts() -> void:
	assert_str(KeyPrompt.glyph(KEY_KP_7)).is_empty()
	assert_str(KeyPrompt.glyph(KEY_KP_SUBTRACT)).is_empty()
	assert_str(KeyPrompt.glyph(KEY_KP_PERIOD)).is_equal(".")
	assert_object(KeyPrompt.texture(KEY_KP_ADD, true)).is_not_equal(KeyPrompt.texture(KEY_KP_ADD))
	assert_str(KeyMap.label(&"debug_menu")).contains("Num")


func test_no_two_keys_at_one_place_clash() -> void:
	for where in KeyMap.places():
		var seen := {}
		for binding in KeyMap.bindings_at(where):
			if binding.held:
				continue
			for code in binding.keys:
				assert_bool(seen.has(code)).override_failure_message("%s twice at %s" % [
						KeyMap.name_of(code), where]).is_false()
				seen[code] = true
