# The Station screens' one Theme and colour language (StationTheme): five
# colours, each with one meaning, and the check that no Station screen uses
# a colour from anywhere else.
extends GdUnitTestSuite

## Scripts in view/ that draw nothing on a Station screen: the room, the
## crew, the Arm, the Bore's Column, and the screen-space menus and debug
## views. Every other script in view/ is checked, so a new screen or
## instrument is checked without being listed anywhere.
const NOT_ON_A_SCREEN: Array[String] = [
	"station_theme.gd",  # the one place the colours are written
	"habitat.gd", "gimballed_station.gd", "gimbal.gd", "crew_member.gd", "arm.gd", "arm_view.gd",
	"hull_feel.gd", "hull_groans.gd", "slip_sound.gd",
	"column_look.gd", "column_strip.gd", "feature_look.gd", "bore_glass.gd",
	"start_menu.gd", "outcome_screen.gd", "checklist_panel.gd", "controls_panel.gd",
	"debug_panel.gd", "dive_view.gd", "key_prompt.gd", "key_map.gd",
]


func test_each_meaning_has_its_own_colour() -> void:
	var seen := {}
	for meaning in StationTheme.MEANINGS:
		var colour := StationTheme.colour(meaning)
		assert_bool(seen.has(colour)).override_failure_message("%s shares a colour" % meaning).is_false()
		seen[colour] = true
	assert_int(seen.size()).is_equal(5)


func test_the_theme_gives_a_label_each_meaning_by_its_type_variation() -> void:
	var theme := StationTheme.theme()
	for meaning in StationTheme.MEANINGS:
		var label: Label = auto_free(Label.new())
		label.theme = theme
		label.theme_type_variation = StationTheme.variation(meaning)
		add_child(label)

		assert_that(label.get_theme_color(&"font_color")).is_equal(StationTheme.colour(meaning))


func test_a_label_with_no_variation_reads_as_what_is_happening_now() -> void:
	var label: Label = auto_free(Label.new())
	label.theme = StationTheme.theme()
	add_child(label)

	assert_that(label.get_theme_color(&"font_color")).is_equal(StationTheme.colour(StationTheme.NOW))


func test_a_colour_is_of_the_theme_whatever_its_alpha_and_no_other_is() -> void:
	assert_bool(StationTheme.has(StationTheme.CAUTION_COLOUR)).is_true()
	assert_bool(StationTheme.has(StationTheme.faded(StationTheme.CAUTION_COLOUR, 0.3))).is_true()
	assert_bool(StationTheme.has(Color("ff7a45"))).is_false()


## The convention check: a script drawn on a Station screen writes no colour
## of its own. It takes every colour from StationTheme (or, for a picture of
## the rock itself, from ColumnLook), so the five colours keep their meanings.
func test_no_station_screen_script_writes_a_colour_outside_the_theme() -> void:
	var literal := RegEx.create_from_string("\\bColor\\s*\\(|\\bColor\\.|\\bColor8\\s*\\(")
	var checked := 0
	for file in DirAccess.get_files_at("res://view"):
		if not file.ends_with(".gd") or file in NOT_ON_A_SCREEN:
			continue
		checked += 1
		var lines := FileAccess.get_file_as_string("res://view/" + file).split("\n")
		for n in lines.size():
			var code := lines[n].split("#")[0]
			assert_bool(literal.search(code) == null).override_failure_message(
					"view/%s:%d writes a colour outside StationTheme: %s" % [file, n + 1, lines[n].strip_edges()]
			).is_true()
	assert_int(checked).is_greater(5)
