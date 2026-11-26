## The F1 controls: every crew binding on the key map, place by place (the
## keys that work anywhere first; the debug menu's own keys left to it), each
## as its key prompts and what it does. A menu
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
	# The debug keys are not the crew's: the debug menu shows them, as a
	# numpad, and F1 only the key that opens it.
	var places := KeyMap.places().filter(func(w: StringName) -> bool: return w != KeyMap.DEBUG)
	# Two columns, a place never split between them.
	var total := places.size()
	for where in places:
		total += KeyMap.bindings_at(where).size()
	var column := _column(columns)
	var lines := 0
	for where: StringName in places:
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
		row.add_child(KeyPrompt.rect(code, Vector2(KEY_PX, KEY_PX), FONT_SIZE))
	row.add_child(_words(binding.does, FONT_SIZE))
	return row


func _words(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
