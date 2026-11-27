# Holds the screenshot recipes (tools/screenshot/recipes/, one list of named
# shots per screen: docs/conventions/running-and-testing.md, "Ad-hoc checks")
# to the tool as it is now: every recipe must still make a sheet, so a renamed
# command, Station or Scenario fails here and not at the next review. What a
# tile shows needs a window and a reader, so that is the reviewer's to check.
extends GdUnitTestSuite

const RECIPES := "res://tools/screenshot/recipes"


func _recipes() -> PackedStringArray:
	var found := PackedStringArray()
	for file in DirAccess.get_files_at(RECIPES):
		if file.ends_with(".txt"):
			found.append(file)
	return found


func test_there_is_a_recipe_for_every_station_screen() -> void:
	var recipes := _recipes()

	for station: String in ["reactor", "thermal", "drive", "navigation"]:
		assert_bool(recipes.has(station + ".txt")).override_failure_message(
				"no recipe %s/%s.txt" % [RECIPES, station]).is_true()


func test_every_recipe_still_makes_a_sheet() -> void:
	for file in _recipes():
		var sheet := ShotSheet.of(FileAccess.get_file_as_string(RECIPES.path_join(file)))

		assert_str(sheet.error).override_failure_message(
				"%s: %s" % [file, sheet.error]).is_empty()


func test_a_recipe_names_each_of_its_tiles_once() -> void:
	for file in _recipes():
		var sheet := ShotSheet.of(FileAccess.get_file_as_string(RECIPES.path_join(file)))
		var names := sheet.shots.map(func(shot: Dictionary) -> String: return shot.name)
		var once := {}
		for name: String in names:
			once[name] = true

		assert_int(once.size()).override_failure_message(
				"%s names a tile twice" % file).is_equal(names.size())
