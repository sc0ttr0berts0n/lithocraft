## The picture of a key, from the vendored prompts (assets/prompts, Xelu's
## CC0 pack). A key with no picture of its own is a blank key with its glyph
## written on it, so any key the key map binds can be shown.
class_name KeyPrompt
extends RefCounted

const _DIR := "res://assets/prompts/keyboard/"
const _BLANK := _DIR + "Blank_White_Normal.png"
## The pack's name for a key where it is not Godot's.
const _FILE_NAMES := {
	KEY_ESCAPE: "Esc",
	KEY_KP_ENTER: "Enter",
	KeyMap.MOUSE: "Mouse_Simple",
}


## The key's picture: its own, or the blank key.
static func texture(code: int) -> Texture2D:
	var own := _own_path(code)
	return load(own if ResourceLoader.exists(own) else _BLANK) as Texture2D


## What to write on the blank key: "" when the key has its own picture.
static func glyph(code: int) -> String:
	return "" if ResourceLoader.exists(_own_path(code)) else KeyMap.name_of(code)


static func _own_path(code: int) -> String:
	var name: String = _FILE_NAMES.get(code, OS.get_keycode_string(code).replace(" ", "_"))
	return "%s%s_Key_Light.png" % [_DIR, name]
