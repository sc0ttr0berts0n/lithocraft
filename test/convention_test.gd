# Convention checks that read the source (ticket #80): rules with a fixed
# shape that a review once had to find by reading. Each test names the
# convention file that states its rule. The ticket's other rule, that every
# crew command is in the Checklist's intention list, is in scenario_test.gd.
#
# Every allow-list is here, each entry with its reason. An entry nothing
# uses any more fails its test, so the lists cannot outlive their causes.
extends GdUnitTestSuite

# --- Tests of the game never call debug commands ----------------------------
# docs/conventions/debug-commands.md, docs/conventions/running-and-testing.md.

## Suites allowed any debug command, each with why.
const DEBUG_SUITES := {
	"test/debug_command_test.gd": "tests each debug command itself",
	"test/convention_test.gd": "this suite: its allow-list names them",
}

## The debug commands other suites use today, by file and command, each with
## why. A new one is a finding: reach the state through the crew's commands
## (DiveTestKit.lose_plasma(), strand(), wear_head_gently()) instead.
const DEBUG_CALLS := {
	"test/autopilot_test.gd": {
		"debug_surface": "ends the dive at once so new_dive() can be tested; what is asserted is the new dive, not the surfacing",
	},
	"test/moving_map_test.gd": {
		"debug_surface": "ends the dive at once so new_dive() can be tested; what is asserted is the new dive, not the surfacing",
	},
	"test/scan_display_test.gd": {
		"debug_next_scan_view": "the only command that picks the scan view; it sets nothing of the dive",
	},
	"test/self_destruct_test.gd": {
		"debug_lose_plasma": "loses the plasma while self-destruct has the Stations off the crew, when no crew command can",
	},
	"test/screenshot_test.gd": {
		"debug_skip": "tests that the screenshot tool's --do sends a debug command by name",
		"debug_surface": "tests that the screenshot tool's --do sends a debug command, and fails the shot when one is refused",
	},
}


func test_no_test_of_the_game_calls_a_debug_command() -> void:
	var commands := _debug_commands()
	assert_int(commands.size()).is_greater(5)
	var token := RegEx.create_from_string("(\\.)?\\bdebug_\\w+(\\s*\\()?")
	var findings: Array[String] = []
	var used := {}
	var read := 0
	for path in _scripts("test"):
		read += 1
		if DEBUG_SUITES.has(path):
			used[path] = true
			continue
		var lines := _lines(path)
		for n in lines.size():
			for found in token.search_all(_code(lines[n])):
				var name := found.get_string().trim_prefix(".").split("(")[0].strip_edges()
				var called := found.get_string(1) != "" and found.get_string(2) != ""
				if not (called or name in commands):
					continue
				if (DEBUG_CALLS.get(path, {}) as Dictionary).has(name):
					used["%s %s" % [path, name]] = true
				else:
					findings.append("%s:%d calls %s" % [path, n + 1, name])
	assert_int(read).is_greater(20)
	assert_array(findings).override_failure_message(
			"A test of the game calls a debug command (docs/conventions/debug-commands.md):\n  "
			+ "\n  ".join(findings)).is_empty()
	var stale: Array[String] = []
	for path: String in DEBUG_SUITES:
		if not used.has(path):
			stale.append(path)
	for path: String in DEBUG_CALLS:
		for name: String in DEBUG_CALLS[path]:
			if not used.has("%s %s" % [path, name]):
				stale.append("%s %s" % [path, name])
	assert_array(stale).override_failure_message(
			"Allowed debug calls that no test makes any more; take them off the list:\n  "
			+ "\n  ".join(stale)).is_empty()


## DiveSimulation's debug commands, by reflection.
static func _debug_commands() -> Array[String]:
	var found: Array[String] = []
	for method in (DiveSimulation as Script).get_script_method_list():
		if String(method.name).begins_with("debug_"):
			found.append(String(method.name))
	return found


# --- Avoided GLOSSARY terms stay out of the code ----------------------------
# GLOSSARY.md (each term's "_Avoid_" line), docs/conventions/layout.md.
#
# The matching rule. Every line of sim/ and view/ (identifiers, comments and
# the words on screen alike) is cut into words: identifiers split at
# underscores and at capitals, lower-cased, a plural or third-person "s"
# dropped ("trims" is "trim"). Godot's own class names and GODOT_NAMES are
# skipped, and so are the glossary's own terms ("Quiet Ship" is not "Ship").
# An avoided word then found whole, or an avoided phrase found in order, is a
# finding. Avoided words the glossary qualifies ("warning (for a caution)")
# cannot be told by the word alone: QUALIFIED says what is done about each.

## Avoided words not checked, each with why: words the code needs in their
## plain sense, or that are Godot's or GDScript's own.
const LEFT_OUT := {
	"drill": "the glossary's own word for a practice Scenario (the Shift drill)",
	"bit": "plain English (every bit of heat), and bits of sound",
	"window": "plain English and Godot's Window; a reading's box on a display",
	"environment": "Godot's Environment and its properties",
	"material": "Godot's materials (material_override)",
	"sample": "plain sense: samples of a curve or a wave (_SAMPLES)",
	"resource": "Godot's Resource and resource_path",
	"interface": "the simulation's interface, CLAUDE.md's own name for the seam",
	"preset": "Godot's anchor presets (set_anchors_preset)",
	"current": "plain English and Godot's make_current()",
	"live": "plain English: alive, in force",
	"next": "plain English: the next step, the next Boundary (next_step())",
	"noise": "the vessel's own sound in the scan is noise in the plain, real sense",
	"signal": "GDScript's keyword, and signals in the plain sense",
	"match": "GDScript's keyword",
	"error": "plain English, and Godot's push_error; the guess's error is not a Residual",
	"margin": "Godot's content margins, and a margin in the plain sense",
	"path": "the path the Head has cut, the projected path, and file paths",
	"offset": "plain geometry: a place's offset from the Head",
	"trend": "the hull's trend and the porosity trend are readings of their own",
	"countdown": "the Boundary countdown is the interface's name (boundary_countdown())",
	"level": "plain English: horizontal, and a level of something",
	"flag": "Godot's size flags",
	"panel": "the view's screen-space panels (ChecklistPanel) and Godot's Panel",
	"cooling": "plain sense: what Thermal's pumps do",
	"all round": "plain English: sparks from all round the ring",
}

## Avoided words the glossary qualifies, so the word alone is no breach, each
## with what is done about it.
const QUALIFIED := {
	"real boundary": "not checked: only wrong for what the scan shows",
	"dial": "not checked: only wrong alone, and the Shift dial is a term",
	"tuning": "not checked: only wrong for the wave itself; tuning is what the crew does",
	"heading": "not checked: only wrong for the plotted target; a heading is half of every Course",
	"override": "not checked: only wrong for the amount; the Drive's override is the interface's name",
	"flight plan": "not checked: no code names one yet",
	"worm drive": "not checked as a phrase: \"worm\" alone is avoided, so it is found anyway",
	"warp": "not checked: only wrong for the Glide; warp is to be travel between planets",
	"ultrasound": "not checked: only wrong for the tool",
	"feature of interest": "not checked: only wrong for a Target; a thing seen in the Column is one",
	"warning": "checked by its own rule: a name that says warning given a caution, or the other way (_WARNING_FOR_A_CAUTION)",
}

## Godot's own names holding an avoided word, which the code must spell as
## Godot does. Godot's class names need no entry.
const GODOT_NAMES: Array[String] = ["trim_prefix", "trim_suffix", "inverse_lerp", "affine_inverse"]

## Avoided words used in another sense than the one the glossary avoids, by
## file and word, each with why.
const OTHER_SENSES := {
	"sim/column_feature.gd": {
		"tube": "a fulgurite is a glass tube; not the Bore",
	},
	"sim/dive_simulation.gd": {
		"unattended": "nobody at a Station (set_attended()); not a name for the autopilot",
		"selector": "the kind of command select_channel() is (a selector, not a setting); not a name for the Shift dial",
		"inverse": "says what the Counter-wave is, the Wobble's inverse in the mathematical sense; not its name",
		"restart": "of Thermal's pumps on the emergency store; not the Relight",
	},
	"sim/plasma.gd": {
		"inverse": "says what the Counter-wave is, the Wobble's inverse in the mathematical sense; not its name",
	},
	"view/arm.gd": {
		"seat": "what the Arm does to the crew member (seat()); not a name for a Station",
	},
	"view/bore_glass.gd": {
		"tube": "the shape of the Bore's glass wall, a tube of glass; not a name for the Bore",
		"cylinder": "the mesh the glass is drawn on; not a name for the Bore",
	},
	"view/crew_member.gd": {
		"cylinder": "plain geometry: the shape the crew member may stand in; not the Bore",
	},
	"view/feature_look.gd": {
		"tube": "a fulgurite is a glass tube; not the Bore",
		"core": "a fulgurite's glass core; not the Bore or the Column",
	},
	"view/flight_display.gd": {
		"primary": "the real instrument's name, a primary flight display; not the ACTIVE channel",
	},
	"view/flight_tape.gd": {
		"primary": "the real instrument's name, a primary flight display; not the ACTIVE channel",
	},
	"view/habitat.gd": {
		"primary": "the real instrument's name, a primary flight display; not the ACTIVE channel",
		"seat": "what the Arm does to the crew member (seat_at()); not a name for a Station",
		"tube": "the shape of the mesh the Column is drawn on (_column_tube()); not a name for the Bore",
		"cylinder": "Godot's cylinder meshes; not the Bore",
		"ink": "the colour of an end cap's lettering; not Feedstock",
	},
	"view/hull_groans.gd": {
		"ship": "real basis: a ship's hull groans under load; not the Lithocraft",
	},
	"view/plasma_display.gd": {
		"prediction": "the words on STANDBY's lane for the predicted Residual; not the projected path",
	},
	"view/scan_display.gd": {
		"sonar": "real basis: a forward-looking sonar's fan; not a name for Navigation",
	},
	"view/station_theme.gd": {
		"deck": "real basis: Airbus's flight-deck colour philosophy; not the Habitat",
	},
}

## "Warning (for a caution)": a declaration or assignment whose name says one
## and whose value says the other, as `const WARN := StationTheme.CAUTION_COLOUR` did.
const _WARNING_FOR_A_CAUTION := "(?i)\\b\\w*warn\\w*\\s*(:\\s*[\\w.]+\\s*)?:?=(?!=).*caution|\\b\\w*caution\\w*\\s*(:\\s*[\\w.]+\\s*)?:?=(?!=).*warn"


func test_no_avoided_glossary_term_is_used_in_the_simulation_or_the_view() -> void:
	var glossary := _glossary()
	var avoided: Dictionary = glossary.avoided
	assert_int(avoided.size()).is_greater(60)
	for word: String in ["helm", "trim", "ship", "tutorial"]:
		assert_bool(avoided.has(word)).override_failure_message("GLOSSARY.md no longer avoids %s" % word).is_true()
	# Every decision not to check a word is still about a word the glossary avoids.
	for word: String in LEFT_OUT:
		assert_bool(avoided.has(word)).override_failure_message(
				"LEFT_OUT holds \"%s\", which GLOSSARY.md does not avoid" % word).is_true()
	assert_array(glossary.qualified).override_failure_message(
			"GLOSSARY.md's qualified avoided words and QUALIFIED differ: decide what to do about each"
			).contains_exactly_in_any_order(QUALIFIED.keys())

	var warning := RegEx.create_from_string(_WARNING_FOR_A_CAUTION)
	var words := {}
	var findings: Array[String] = []
	var used := {}
	var read := 0
	for path in _scripts("sim") + _scripts("view"):
		read += 1
		var lines := _lines(path)
		var before := " "
		for n in lines.size():
			if warning.search(_code(lines[n])) != null:
				findings.append("%s:%d gives a caution a warning's name, or a warning a caution's (avoid \"warning\" for a caution): %s"
						% [path, n + 1, lines[n].strip_edges()])
			var whole := _words(lines[n], words)
			var text := whole
			for term: String in glossary.terms:
				text = text.replace(" %s " % term, " | ")
				# A term a comment breaks across two lines ("Quiet" / "Ship").
				var cut := term.find(" ")
				while cut >= 0:
					if before.ends_with(" %s " % term.left(cut)) and text.begins_with(" %s " % term.substr(cut + 1)):
						text = " | " + text.substr(term.length() - cut + 1)
					cut = term.find(" ", cut + 1)
			before = whole
			for word: String in avoided:
				if LEFT_OUT.has(word) or not text.contains(" %s " % word):
					continue
				if (OTHER_SENSES.get(path, {}) as Dictionary).has(word):
					used["%s %s" % [path, word]] = true
				else:
					findings.append("%s:%d uses \"%s\" (GLOSSARY.md avoids it for %s): %s"
							% [path, n + 1, word, avoided[word], lines[n].strip_edges()])
	assert_int(read).is_greater(40)
	assert_array(findings).override_failure_message(
			"Avoided GLOSSARY terms in the code:\n  " + "\n  ".join(findings)).is_empty()
	var stale: Array[String] = []
	for path: String in OTHER_SENSES:
		for word: String in OTHER_SENSES[path]:
			if not used.has("%s %s" % [path, word]):
				stale.append("%s %s" % [path, word])
	assert_array(stale).override_failure_message(
			"Allowed uses of avoided words that are no longer there; take them off the list:\n  "
			+ "\n  ".join(stale)).is_empty()


## GLOSSARY.md as the check reads it, every word in the form _words() gives:
## `avoided` (each unqualified avoided word or phrase, to the term it is
## avoided for), `qualified` (the avoided words that carry a qualifier in
## brackets) and `terms` (the glossary's own terms of more than one word).
static func _glossary() -> Dictionary:
	var avoided := {}
	var qualified: Array[String] = []
	var terms: Array[String] = []
	var term := ""
	var cache := {}
	var entry := RegEx.create_from_string("[^,(]+(\\([^)]*\\))?")
	for line in FileAccess.get_file_as_string("res://GLOSSARY.md").split("\n"):
		if line.begins_with("**"):
			term = line.get_slice("**", 1)
			var plain := _words(term.to_lower(), cache).strip_edges()
			if plain.contains(" "):
				terms.append(plain)
		elif line.begins_with("_Avoid_:"):
			for found in entry.search_all(line.trim_prefix("_Avoid_:")):
				var word := _words(found.get_string().get_slice("(", 0).to_lower(), cache).strip_edges()
				if word == "":
					continue
				if found.get_string(1) != "":
					qualified.append(word)
				elif not avoided.has(word):
					avoided[word] = term
	return {avoided = avoided, qualified = qualified, terms = terms}


## A line as the words it is made of, each between spaces: identifiers split
## at underscores and capitals, lower-cased, a final "s" dropped. Godot's own
## names (and anything not a word) become "|", so no phrase is found across
## them. `cache` holds each identifier's words between calls.
static func _words(line: String, cache: Dictionary) -> String:
	var text := " "
	var from := 0
	for found in _IDENTIFIER.search_all(line):
		if line.substr(from, found.get_start() - from).replace("#", "").replace("-", "").strip_edges() != "":
			text += "| "
		from = found.get_end()
		var identifier := found.get_string()
		if not cache.has(identifier):
			cache[identifier] = _words_of(identifier)
		text += cache[identifier]
	return text


static var _IDENTIFIER := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
static var _HUMP := RegEx.create_from_string("[A-Z]+(?![a-z])|[A-Z]?[a-z]+")


static func _words_of(identifier: String) -> String:
	if identifier in GODOT_NAMES or ClassDB.class_exists(identifier):
		return "| "
	var text := ""
	for found in _HUMP.search_all(identifier):
		var word := found.get_string().to_lower()
		if word.length() > 3 and word.ends_with("s") and not word.ends_with("ss"):
			word = word.left(-1)
		text += word + " "
	return text


# --- Scan-side code never names the layout ----------------------------------
# docs/conventions/scan.md.

## The scan side: what makes, fits, reads or draws scan points and patches.
## None may name the layout, so what the crew is shown of the rock ahead is
## only ever what the scan found.
const SCAN_SIDE: Array[String] = [
	"sim/scan_point.gd", "sim/boundary_patch.gd", "sim/boundary_fit.gd",
	"sim/look_ahead.gd", "sim/wobble_guess.gd", "sim/target_region.gd",
	"view/scan_display.gd", "view/moving_map.gd",
]

## Files that take scan points or patches and may still name the layout, each
## with why.
const SCAN_AND_LAYOUT := {
	"sim/dive_simulation.gd": "owns the layout: it makes the points by sounding it, and hands the scan side points and patches alone",
}

## What naming the layout looks like; a target's body (TargetBody) is the
## layout's truth too.
const LAYOUT_NAMES: Array[String] = ["MediumLayout", "_layout", "medium_at", "boundary_depth", "next_meet",
		"TargetBody"]

## What taking scan points or patches looks like, in code.
const _TAKES_THE_SCAN := "\\b(ScanPoint|BoundaryPatch|BoundaryFit|TargetRegion)\\b|\\bpoints\\(\\)|\\binferred_boundaries\\(\\)|\\btarget_regions\\(\\)"


func test_scan_side_code_never_names_the_layout() -> void:
	var takes := RegEx.create_from_string(_TAKES_THE_SCAN)
	var findings: Array[String] = []
	var listed := {}
	for path in _scripts("sim") + _scripts("view"):
		var lines := _lines(path)
		if path in SCAN_SIDE or SCAN_AND_LAYOUT.has(path):
			listed[path] = true
		else:
			for n in lines.size():
				if takes.search(_code(lines[n])) != null:
					findings.append("%s:%d takes scan points or patches, so the file goes on SCAN_SIDE: %s"
							% [path, n + 1, lines[n].strip_edges()])
					break
		if path in SCAN_SIDE:
			for n in lines.size():
				for name in LAYOUT_NAMES:
					if lines[n].contains(name):
						findings.append("%s:%d names %s" % [path, n + 1, name])
	assert_array(findings).override_failure_message(
			"Scan-side code and the layout (docs/conventions/scan.md):\n  " + "\n  ".join(findings)).is_empty()
	assert_array(listed.keys()).override_failure_message("A listed scan-side file is gone; take it off the list") \
			.contains_exactly_in_any_order(SCAN_SIDE + SCAN_AND_LAYOUT.keys())


# --- Reading the source ------------------------------------------------------

## Every script under res://<folder>, as "folder/file.gd", in a fixed order.
static func _scripts(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at("res://" + folder):
		if file.ends_with(".gd"):
			found.append("%s/%s" % [folder, file])
	for inner in DirAccess.get_directories_at("res://" + folder):
		found.append_array(_scripts("%s/%s" % [folder, inner]))
	found.sort()
	return found


static func _lines(path: String) -> PackedStringArray:
	return FileAccess.get_file_as_string("res://" + path).split("\n")


## A line without its comment.
static func _code(line: String) -> String:
	return line.split("#")[0]
