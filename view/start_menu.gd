## The start menu (the main scene): every Scenario (Scenario.all()) with what
## it asks. A number key, or a click on it, starts one in a fresh Habitat; the
## Habitat comes back here once a dive is over. Its keys are its own, not the
## key map's (view/key_map.gd is the Habitat's): 1 to 9 down the list, on the
## main keys or the keypad. Enter does nothing here, so the Enter that ended a
## dive cannot start the next one.
class_name StartMenu
extends Control

const HABITAT := preload("res://view/habitat.tscn")
const TITLE_FONT_SIZE := 44
const FONT_SIZE := 20
const WIDTH := 760.0

var _scenarios := Scenario.all()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var backing := ColorRect.new()
	backing.color = Color(0.03, 0.02, 0.02)
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = WIDTH
	list.add_theme_constant_override(&"separation", 14)
	centre.add_child(list)
	var title := Label.new()
	title.text = "Lithocraft"
	title.add_theme_font_size_override(&"font_size", TITLE_FONT_SIZE)
	title.add_theme_color_override(&"font_color", Color("ffd0b0"))
	list.add_child(title)
	for i in _scenarios.size():
		var button := Button.new()
		button.text = entry(i, _scenarios[i])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override(&"font_size", FONT_SIZE)
		button.pressed.connect(_start.bind(i))
		list.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := choice_for(key.keycode, _scenarios.size())
	if index >= 0:
		_start(index)


## The menu's line for the Scenario at `index`: its key, its title, and what
## it asks.
static func entry(index: int, scenario: Scenario) -> String:
	return "[%d]  %s\n%s" % [index + 1, scenario.title, scenario.summary]


## Which of `count` Scenarios this key chooses (1 the first, on the main keys
## or the keypad), or -1 for none.
static func choice_for(code: Key, count: int) -> int:
	for first in [KEY_1, KEY_KP_1]:
		var index: int = code - first
		if index >= 0 and index < mini(count, 9):
			return index
	return -1


## Starts the Scenario at `index` in a fresh Habitat, in place of the menu.
func _start(index: int) -> void:
	var habitat := HABITAT.instantiate()
	habitat.scenario = _scenarios[index]
	var tree := get_tree()
	tree.root.add_child(habitat)
	tree.current_scene = habitat
	queue_free()
