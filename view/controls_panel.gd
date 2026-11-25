## The F1 controls: every binding on the key map, place by place (the keys
## that work anywhere first), each as its key prompts and what it does. A menu
## the crew opens, hidden by default; built from the key map, so it cannot
## disagree with the keys.
class_name ControlsPanel
extends PanelContainer

## Size of a key prompt and of the words, in pixels.
const KEY_PX := 26
const FONT_SIZE := 15
const HEADING_SIZE := 17

## Each place's heading, by its name on the key map. Set before _ready.
var titles := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.02, 0.04, 0.05, 0.88)
	backing.set_content_margin_all(14)
	add_theme_stylebox_override(&"panel", backing)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 28)
	columns.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columns)
	# Two columns, a place never split between them.
	var total := KeyMap.bindings().size() + KeyMap.places().size()
	var column := _column(columns)
	var lines := 0
	for where in KeyMap.places():
		var here := KeyMap.bindings_at(where)
		if lines > 0 and lines + here.size() > total / 2.0 + 1.0 and columns.get_child_count() < 2:
			column = _column(columns)
			lines = 0
		var heading := _words(titles.get(where, String(where).capitalize()), HEADING_SIZE)
		heading.add_theme_color_override(&"font_color", Color("ffd0b0"))
		column.add_child(heading)
		for binding in here:
			column.add_child(_row(binding))
		lines += here.size() + 1


func _column(columns: HBoxContainer) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(column)
	return column


## One binding: its key prompts, then what it does.
func _row(binding: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for code: int in KeyPrompt.distinct(binding.keys):
		var key := TextureRect.new()
		key.texture = KeyPrompt.texture(code)
		key.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		key.custom_minimum_size = Vector2(KEY_PX, KEY_PX)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var glyph := KeyPrompt.glyph(code)
		if not glyph.is_empty():
			var mark := _words(glyph, FONT_SIZE)
			mark.add_theme_color_override(&"font_color", Color.BLACK)
			mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			key.add_child(mark)
		row.add_child(key)
	row.add_child(_words(binding.does, FONT_SIZE))
	return row


func _words(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
