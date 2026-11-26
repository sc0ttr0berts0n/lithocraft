## The picture of a key, from the vendored prompts (assets/prompts, Xelu's
## CC0 pack). A key with no picture of its own is a blank key with its glyph
## written on it, so any key the key map binds can be shown.
class_name KeyPrompt
extends RefCounted

const _DIR := "res://assets/prompts/keyboard/"
const _BLANK := _DIR + "Blank_White_Normal.png"
## The pack's name for a key where it is not Godot's. The numpad's keys share
## the main keys' pictures; the debug menu draws them as a numpad.
const _FILE_NAMES := {
	KEY_ESCAPE: "Esc",
	KEY_KP_ENTER: "Enter",
	KeyMap.MOUSE: "Mouse_Simple",
	KEY_KP_0: "0",
	KEY_KP_1: "1",
	KEY_KP_2: "2",
	KEY_KP_3: "3",
	KEY_KP_4: "4",
	KEY_KP_5: "5",
	KEY_KP_6: "6",
	KEY_KP_7: "7",
	KEY_KP_8: "8",
	KEY_KP_9: "9",
	KEY_KP_ADD: "Plus",
	KEY_KP_SUBTRACT: "Minus",
	KEY_KP_MULTIPLY: "Asterisk",
	KEY_NUMLOCK: "Num_Lock",
	# The pack's "Slash" is drawn as a backslash, so numpad / and . are blank
	# keys with their glyphs.
}


## The key's picture: its own, or the blank key. `tall`: the pack's
## two-row-high picture, where it has one (the numpad's + and Enter); it is
## square like the rest, the tall key drawn half its width.
static func texture(code: int, tall := false) -> Texture2D:
	var own := _own_path(code)
	if tall:
		var high := own.replace("_Key_Light", "_Tall_Key_Light")
		if ResourceLoader.exists(high):
			return load(high) as Texture2D
	return load(own if ResourceLoader.exists(own) else _BLANK) as Texture2D


## What to write on the blank key: "" when the key has its own picture. A
## numpad key's glyph drops the "Num" its name carries.
static func glyph(code: int) -> String:
	if ResourceLoader.exists(_own_path(code)):
		return ""
	return KeyMap.name_of(code).trim_prefix("Num ")


## The keys to draw for a binding: one of each picture, so Enter and keypad
## Enter show as one prompt.
static func distinct(codes: Array) -> Array:
	var shown := []
	var seen := {}
	for code: int in codes:
		var look := "%s|%s" % [texture(code).resource_path, glyph(code)]
		if not seen.has(look):
			seen[look] = true
			shown.append(code)
	return shown


## The key drawn for a screen-space menu: its picture filling `size`
## (keeping its shape), with its glyph on a blank key.
static func rect(code: int, size: Vector2, font_size: int, tall := false) -> TextureRect:
	var key := TextureRect.new()
	key.texture = texture(code, tall)
	key.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key.custom_minimum_size = size
	key.size = size
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := glyph(code)
	if not mark.is_empty():
		var label := Label.new()
		label.text = mark
		label.add_theme_font_size_override(&"font_size", font_size)
		label.add_theme_color_override(&"font_color", Color.BLACK)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key.add_child(label)
	return key


static func _own_path(code: int) -> String:
	var name: String = _FILE_NAMES.get(code, OS.get_keycode_string(code).replace(" ", "_"))
	return "%s%s_Key_Light.png" % [_DIR, name]
