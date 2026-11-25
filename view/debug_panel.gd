## The numpad debug menu: the developer's shortcuts for testing a dive by
## hand, drawn as the numpad itself, each key's prompt with what it does
## beside it, read from the key map (KeyMap.DEBUG, and the keys that work
## anywhere, such as the one that opens it). A line of the state the keys
## change sits under it. Hidden by default and toggled with numpad minus
## (habitat.gd); its keys work only while it shows. Not crew controls: each
## key runs a DiveSimulation.debug_* command, or a view toggle. Reads the
## simulation only.
class_name DebugPanel
extends PanelContainer

## One numpad key's cell, in pixels, and the key prompt's side.
const CELL := Vector2(140, 58)
const KEY_PX := 36
const FONT_SIZE := 13
const STATUS_SIZE := 15
const TITLE_SIZE := 17
## The numpad, as [key, column, row, columns wide, rows high].
const LAYOUT := [
	[KEY_NUMLOCK, 0, 0, 1, 1], [KEY_KP_DIVIDE, 1, 0, 1, 1],
	[KEY_KP_MULTIPLY, 2, 0, 1, 1], [KEY_KP_SUBTRACT, 3, 0, 1, 1],
	[KEY_KP_7, 0, 1, 1, 1], [KEY_KP_8, 1, 1, 1, 1], [KEY_KP_9, 2, 1, 1, 1],
	[KEY_KP_ADD, 3, 1, 1, 2],
	[KEY_KP_4, 0, 2, 1, 1], [KEY_KP_5, 1, 2, 1, 1], [KEY_KP_6, 2, 2, 1, 1],
	[KEY_KP_1, 0, 3, 1, 1], [KEY_KP_2, 1, 3, 1, 1], [KEY_KP_3, 2, 3, 1, 1],
	[KEY_KP_ENTER, 3, 3, 1, 2],
	[KEY_KP_0, 0, 4, 2, 1], [KEY_KP_PERIOD, 2, 4, 1, 1],
]
## The numpad's three middle columns each work one thing, so their words are
## tinted to match the status line: the hull, the Head, where the dive is.
const COLUMN_INKS := [Color("ff9a8a"), Color("ffc070"), Color("8ccfff")]
const INK := Color("e8e8e8")
const ACCENT := Color("c890ff")
## How long a pressed key's cell stays lit, in seconds.
const FLASH_S := 0.3

var sim: DiveSimulation

var _status: Label
## Each key's cell backing (key code -> StyleBoxFlat) and seconds left lit.
var _backings := {}
var _lit := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color(0.03, 0.02, 0.06, 0.96)
	backing.border_color = ACCENT
	backing.set_border_width_all(2)
	backing.set_content_margin_all(12)
	add_theme_stylebox_override(&"panel", backing)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override(&"separation", 8)
	add_child(rows)
	rows.add_child(_title())
	rows.add_child(_numpad())
	_status = _words("", STATUS_SIZE, INK)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.x = CELL.x * 4
	rows.add_child(_status)


## Lights a key's cell for a moment, when the Habitat has run it.
func flash(code: int) -> void:
	if visible and _backings.has(code):
		_lit[code] = FLASH_S


func _process(delta: float) -> void:
	if not visible:
		return
	for code in _lit.keys():
		_lit[code] -= delta
		var glow := clampf(_lit[code] / FLASH_S, 0.0, 1.0)
		(_backings[code] as StyleBoxFlat).bg_color = _cell_colour(glow)
		if _lit[code] <= 0.0:
			_lit.erase(code)
	if sim:
		_status.text = _status_text()


func _title() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_words("DEBUG", TITLE_SIZE, ACCENT))
	var note := _words("  for testing a dive by hand, not crew controls", FONT_SIZE, INK.darkened(0.3))
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(note)
	row.add_child(_words("%s close" % KeyMap.label(&"debug_menu"), FONT_SIZE, INK.darkened(0.3)))
	return row


## The numpad: each key where it sits, its prompt and what it does.
func _numpad() -> Control:
	var pad := Control.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.custom_minimum_size = Vector2(CELL.x * 4, CELL.y * 5)
	for cell in LAYOUT:
		pad.add_child(_cell(cell[0], Vector2(cell[1], cell[2]), Vector2(cell[3], cell[4])))
	return pad


func _cell(code: int, at: Vector2, span: Vector2) -> Control:
	var size := CELL * span - Vector2(4, 4)
	var cell := Panel.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.position = CELL * at + Vector2(2, 2)
	cell.size = size
	var backing := StyleBoxFlat.new()
	backing.bg_color = _cell_colour(0.0)
	backing.set_corner_radius_all(4)
	cell.add_theme_stylebox_override(&"panel", backing)
	_backings[code] = backing
	# A tall key's picture is square with the key half its width: drawn
	# twice the size, centred where a normal key sits.
	var tall := span.y > 1.0
	var key_px := KEY_PX * (2.0 if tall else 1.0)
	var key := KeyPrompt.rect(code, Vector2(key_px, key_px), FONT_SIZE, tall)
	key.position = Vector2(4.0 + (KEY_PX - key_px) / 2.0, (size.y - key_px) / 2.0)
	cell.add_child(key)
	var binding := _binding_for(code)
	if binding.is_empty():
		cell.modulate.a = 0.35
		return cell
	var ink: Color = COLUMN_INKS[int(at.x)] if binding.where == KeyMap.DEBUG \
			and at.y >= 1.0 and at.y <= 3.0 and at.x < COLUMN_INKS.size() else INK
	var words := _words(binding.does, FONT_SIZE, ink)
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	words.position = Vector2(KEY_PX + 10, 0)
	words.size = Vector2(size.x - KEY_PX - 14, size.y)
	cell.add_child(words)
	return cell


## What a key does with the menu open: its debug binding, or else what it
## does anywhere (the key that closes the menu, numpad Enter); {} for none.
static func _binding_for(code: int) -> Dictionary:
	var found := KeyMap.find(code, [KeyMap.DEBUG])
	if found.is_empty():
		found = KeyMap.find(code, [KeyMap.ANYWHERE])
	return {} if found.is_empty() else KeyMap.binding(found.action)


## The state the keys change: the hull, the Head and the emergency store, then
## where the dive is. Always two lines, so the menu keeps its size.
func _status_text() -> String:
	var where := "Depth %.0f m  %s" % [sim.depth(), String(sim.medium().name).capitalize()]
	if sim.stranded():
		where += "  STRANDED, rescue in %d:%02d" % [int(sim.rescue_time()) / 60, int(sim.rescue_time()) % 60]
	elif sim.surfaced():
		where = "Surfaced"
	elif sim.dead():
		where = "Hull failed"
	return "Hull %d%%   Head wear %d%%   Emergency store %d%%\n%s" % [
		roundi(sim.hull_integrity() * 100.0), roundi(sim.head_wear() * 100.0),
		roundi(sim.emergency_store() / sim.emergency_store_capacity() * 100.0), where]


static func _cell_colour(glow: float) -> Color:
	return Color(0.1, 0.09, 0.14, 0.9).lerp(Color(0.45, 0.3, 0.7, 0.95), glow)


static func _words(text: String, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
