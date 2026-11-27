## A sheet of the screenshot tool (tools/screenshot/shot.sh --sheet): a list
## of named shots taken in one run and tiled into one PNG, each tile under a
## label with its name. parse() reads the tool's arguments and the list they
## name, of() a list's text, and lay_out() says where each tile and label go.
##
## The list is a plain text file, one shot to a line:
##
##     # the Reactor before and after the first Boundary
##     cold: --look Reactor --time 0
##     lit: --look Reactor --time 120 --do "0 set_power 1"
##
## A line is "<name>: <arguments>", the arguments those one shot takes
## (ShotPlan; no --out), quoted as on a command line. Blank lines and lines
## starting with # are skipped. Tiles go in the order of the lines.
class_name ShotSheet
extends RefCounted

## How wide a tile is on the sheet, in pixels, unless --tile says: a shot is
## scaled down to it (never up), keeping its shape. Wide enough that the text
## on a Station's screen still reads.
const TILE_WIDTH := 768
## How many tiles go side by side unless --columns says.
const COLUMNS := 2
## The strip over each tile that holds its label, and the space round every
## tile and label, in pixels.
const LABEL_HEIGHT := 30
const GAP := 8

## Why the arguments or the list make no sheet; empty when they do. A fault
## in one shot names it.
var error := ""
## The shots in the order of their lines: each {name = the label, arguments =
## the line's arguments as written, plan = their ShotPlan}.
var shots: Array[Dictionary] = []
var out := ""
var tile_width := TILE_WIDTH
var columns := COLUMNS
## The size of one tile on the sheet, set by lay_out().
var tile := Vector2i.ZERO


## The sheet the tool's arguments ask for: --sheet <list file> and --out
## <file.png>, with --tile <width> and --columns <count> if given. Its
## `error` says why if they ask for none.
static func parse(arguments: PackedStringArray) -> ShotSheet:
	var values := {}
	var i := 0
	while i < arguments.size():
		var flag := arguments[i]
		if not flag in ["--sheet", "--out", "--tile", "--columns"]:
			return _failed("a sheet takes --sheet, --out, --tile and --columns; "
					+ "'%s' goes on a line of the list" % flag)
		if i + 1 >= arguments.size():
			return _failed("%s needs a value" % flag)
		values[flag] = arguments[i + 1]
		i += 2
	for flag: String in ["--tile", "--columns"]:
		var value: String = values.get(flag, "1")
		if not value.is_valid_int() or value.to_int() < 1:
			return _failed("%s needs a whole number, 1 or more, got '%s'" % [flag, value])
	var path: String = values.get("--sheet", "")
	if not values.has("--out"):
		return _failed("--out is needed: where the PNG goes")
	if not FileAccess.file_exists(path):
		return _failed("no list of shots at '%s'" % path)
	var sheet := of(FileAccess.get_file_as_string(path))
	sheet.out = values["--out"]
	if values.has("--tile"):
		sheet.tile_width = (values["--tile"] as String).to_int()
	if values.has("--columns"):
		sheet.columns = (values["--columns"] as String).to_int()
	return sheet


## The sheet a list's text asks for; its `error` says why if it asks for none.
static func of(text: String) -> ShotSheet:
	var sheet := ShotSheet.new()
	var number := 0
	for raw in text.split("\n"):
		number += 1
		var line := raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var colon := line.find(":")
		var name := line.substr(0, maxi(colon, 0)).strip_edges()
		if name.is_empty():
			sheet.error = "line %d needs \"<name>: <arguments>\", got \"%s\"" % [number, line]
			return sheet
		var why := sheet._add(name, line.substr(colon + 1).strip_edges())
		if not why.is_empty():
			sheet.error = "shot '%s' (line %d): %s" % [name, number, why]
			return sheet
	if sheet.shots.is_empty():
		sheet.error = "the list names no shots"
	return sheet


## Sets the size of a tile from the size of a shot, in pixels: scaled down to
## tile_width, never up, keeping its shape. Call before the rectangles below.
func lay_out(shot_size: Vector2i) -> void:
	var width := mini(tile_width, shot_size.x)
	tile = Vector2i(width, roundi(float(shot_size.y) * width / shot_size.x))


## Where a shot's tile goes on the sheet, by its place in `shots`.
func tile_rect(index: int) -> Rect2i:
	var across := index % columns
	var down := index / columns
	return Rect2i(GAP + across * (tile.x + GAP),
			GAP + LABEL_HEIGHT + down * (tile.y + LABEL_HEIGHT + GAP), tile.x, tile.y)


## Where its label goes: the strip resting on its tile.
func label_rect(index: int) -> Rect2i:
	var under := tile_rect(index)
	return Rect2i(under.position.x, under.position.y - LABEL_HEIGHT, under.size.x, LABEL_HEIGHT)


## The size of the whole sheet: no wider than its shots need.
func size() -> Vector2i:
	var last := tile_rect(shots.size() - 1)
	var widest := tile_rect(mini(columns, shots.size()) - 1)
	return Vector2i(widest.end.x + GAP, last.end.y + GAP)


## Files one line's shot; returns why it makes none, or "".
func _add(name: String, arguments: String) -> String:
	for shot in shots:
		if shot.name == name:
			return "there is a shot of that name already"
	var words := PackedStringArray()
	var why := _split(arguments, words)
	if not why.is_empty():
		return why
	if "--out" in words:
		return "a sheet's shot takes no --out: the sheet is the one PNG"
	var plan := ShotPlan.parse(words + PackedStringArray(["--out", "sheet"]))
	if not plan.error.is_empty():
		return plan.error
	shots.append({name = name, arguments = arguments, plan = plan})
	return ""


## Splits a line's arguments into `words` as a command line would: at spaces,
## but not inside single or double quotes, which are dropped. Returns why it
## could not, or "".
static func _split(text: String, words: PackedStringArray) -> String:
	var word := ""
	var started := false
	var quote := ""
	for character in text:
		if not quote.is_empty():
			if character == quote:
				quote = ""
			else:
				word += character
		elif character == "\"" or character == "'":
			quote = character
			started = true
		elif character == " " or character == "\t":
			if started:
				words.append(word)
			word = ""
			started = false
		else:
			word += character
			started = true
	if not quote.is_empty():
		return "a %s quote is never closed" % quote
	if started:
		words.append(word)
	return ""


static func _failed(why: String) -> ShotSheet:
	var sheet := ShotSheet.new()
	sheet.error = why
	return sheet
