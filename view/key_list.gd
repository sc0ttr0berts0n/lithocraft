## A Station's key list, on the panel beside its screen: each binding's key
## prompts, then what it does. Controls and Containers in this SubViewport
## under the one StationTheme, as the screen's frame is (StationScreen).
##
## Never cut off: what a key does wraps onto as many lines as it needs, and
## the whole list shrinks, prompts and words together, until every row is on
## the panel.
class_name KeyList
extends SubViewport

## The panel in its own pixels, at the screen's scale (StationScreen.SIZE
## over GimballedStation.SCREEN_SIZE), for GimballedStation.KEYS_WIDTH.
const SIZE := Vector2i(320, 480)
const MARGIN_PX := 12.0
## The words' largest and smallest sizes; a key prompt's side, the gap
## between prompts and the gap between rows, each as a share of the words'
## size, so the list shrinks as one.
const FONT_SIZE := 26
const FONT_SIZE_LEAST := 8
const KEY_PER_FONT := 1.7
const KEY_GAP_PER_FONT := 0.1
const ROW_GAP_PER_FONT := 0.45

var _root := PanelContainer.new()
var _rows := VBoxContainer.new()


func _init() -> void:
	size = SIZE
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_root.theme = StationTheme.theme()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var margin := MarginContainer.new()
	for side: StringName in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, int(MARGIN_PX))
	_root.add_child(margin)
	_rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	margin.add_child(_rows)


## Shows these bindings top to bottom (KeyMap.bindings_at(<the Station>), so
## the list is the key map). Replaces what was shown.
func show_keys(bindings: Array[Dictionary]) -> void:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	var font_size := fitting_font_size(bindings)
	var key_px := roundf(font_size * KEY_PER_FONT)
	_rows.add_theme_constant_override(&"separation", roundi(font_size * ROW_GAP_PER_FONT))
	for binding in bindings:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", roundi(font_size * KEY_GAP_PER_FONT))
		for code: int in KeyPrompt.distinct(binding.keys):
			var key := KeyPrompt.rect(code, Vector2(key_px, key_px), roundi(font_size * 0.8))
			key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(key)
		var gap := Control.new()
		gap.custom_minimum_size.x = roundf(font_size * 0.3)
		row.add_child(gap)
		var does := Label.new()
		does.text = binding.does
		does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		does.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		does.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		does.add_theme_font_size_override(&"font_size", font_size)
		row.add_child(does)
		_rows.add_child(row)


## The largest size for the words, up to FONT_SIZE, at which every row of
## these bindings is on the panel, each wrapped to the room its prompts
## leave it.
static func fitting_font_size(bindings: Array[Dictionary]) -> int:
	var font := ThemeDB.fallback_font
	var room := Vector2(SIZE) - Vector2(MARGIN_PX, MARGIN_PX) * 2.0
	var font_size := FONT_SIZE
	while font_size > FONT_SIZE_LEAST:
		var key_px := roundf(font_size * KEY_PER_FONT)
		var key_gap := roundf(font_size * KEY_GAP_PER_FONT)
		var height := 0.0
		for binding in bindings:
			var prompts := KeyPrompt.distinct(binding.keys).size()
			var words_room := room.x - prompts * (key_px + key_gap) - roundf(font_size * 0.3) - key_gap
			var words := font.get_multiline_string_size(binding.does, HORIZONTAL_ALIGNMENT_LEFT,
					maxf(words_room, 1.0), font_size)
			# A margin of a line's worth of doubt in where the words wrap.
			height += maxf(key_px, words.y + font.get_height(font_size) * 0.25) \
					+ roundf(font_size * ROW_GAP_PER_FONT)
		if height <= room.y:
			break
		font_size -= 1
	return font_size


# --- What is on it, for checks --------------------------------------------

## Where each binding's row lies on the panel, in its pixels, top to bottom.
## Laid out by the Containers, so only once in the tree and a frame has passed.
func row_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for row in _rows.get_children():
		rects.append((row as Control).get_global_rect())
	return rects


## The Label of what each binding does, top to bottom.
func does_labels() -> Array[Label]:
	var labels: Array[Label] = []
	for row in _rows.get_children():
		labels.append(row.get_child(row.get_child_count() - 1) as Label)
	return labels


## Every Control of the list, for checks that walk it.
func root() -> Control:
	return _root
