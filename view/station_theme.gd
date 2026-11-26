## The one Theme every Station screen shares, and its colour language, an
## airliner's: a colour says what kind of thing a reading is, the same on
## every screen, so an unfamiliar screen can be read by colour. Real basis:
## Airbus's flight-deck colour philosophy.
##
##   white  NOW       what is happening now: a measured value, the vessel
##   cyan   SELECTED  what the crew has selected or aims for: the Course, a
##                    setting, a target
##   green  ENGAGED   engaged and working: an autopilot on, a system doing
##                    its job
##   amber  CAUTION   a caution: something is pulling a system down and wants
##                    attention (a lit Caution lamp)
##   red    WARNING   a warning: what is about to kill the crew
##
## Beside the five there are only the screen's own neutrals, which say
## nothing: its background, the grey of a legend (a title, a unit, a scale)
## and the darker grey of a rule or an unlit lamp; and two backdrops for a
## picture of the world (toward the surface, toward the rock).
##
## This is the only script that writes a Station screen's colours
## (station_theme_test.gd fails any other that does). A screen built of
## Controls takes them from theme() by type variation; one that draws itself
## reads the constants.
class_name StationTheme
extends RefCounted

## The five meanings, as show_lines() and variation() take them.
const NOW := &"now"
const SELECTED := &"selected"
const ENGAGED := &"engaged"
const CAUTION := &"caution"
const WARNING := &"warning"
const MEANINGS: Array[StringName] = [NOW, SELECTED, ENGAGED, CAUTION, WARNING]
## A legend: a title, a unit, a scale. Not a meaning: it says nothing changes.
const LEGEND := &"legend"

const NOW_COLOUR := Color("f2f5f7")
const SELECTED_COLOUR := Color("35d4ff")
const ENGAGED_COLOUR := Color("3fe36c")
const CAUTION_COLOUR := Color("ffb000")
const WARNING_COLOUR := Color("ff3b30")

## The screen's neutrals.
const SCREEN_COLOUR := Color("05080a")
const LEGEND_COLOUR := Color("93a1ad")
const RULE_COLOUR := Color("3c4852")
## Backdrops of a picture of the world: toward the surface, toward the rock.
const SURFACEWARD_COLOUR := Color("1d3a55")
const ROCKWARD_COLOUR := Color("4a3220")

## Text sizes on a Station screen, in its own pixels (StationScreen.SIZE).
const FONT_SIZE := 26
const FONT_SIZE_HEADER := 30
const FONT_SIZE_SMALL := 20

## Type variations beyond the meanings': the header strip's panel, a Caution
## lamp lit and unlit (a PanelContainer and the Label in it), and a rule.
const HEADER := &"StationHeader"
const LAMP_LIT := &"CautionLampLit"
const LAMP_UNLIT := &"CautionLampUnlit"
const LAMP_LIT_TEXT := &"CautionLampLitText"
const LAMP_UNLIT_TEXT := &"CautionLampUnlitText"
const HEADER_TEXT := &"StationHeaderText"

static var _theme: Theme


## The colour of a meaning (or of LEGEND).
static func colour(meaning: StringName) -> Color:
	match meaning:
		SELECTED: return SELECTED_COLOUR
		ENGAGED: return ENGAGED_COLOUR
		CAUTION: return CAUTION_COLOUR
		WARNING: return WARNING_COLOUR
		LEGEND: return LEGEND_COLOUR
	return NOW_COLOUR


## The Label type variation that writes in a meaning's colour (or LEGEND's).
static func variation(meaning: StringName) -> StringName:
	return StringName("Station" + String(meaning).capitalize())


## A Theme colour made fainter: the same colour, so the same meaning.
static func faded(of: Color, alpha: float) -> Color:
	return Color(of.r, of.g, of.b, of.a * alpha)


## Whether a colour is one of the Theme's, at any alpha.
static func has(candidate: Color) -> bool:
	for own: Color in [NOW_COLOUR, SELECTED_COLOUR, ENGAGED_COLOUR, CAUTION_COLOUR, WARNING_COLOUR,
			SCREEN_COLOUR, LEGEND_COLOUR, RULE_COLOUR, SURFACEWARD_COLOUR, ROCKWARD_COLOUR]:
		if is_equal_approx(own.r, candidate.r) and is_equal_approx(own.g, candidate.g) \
				and is_equal_approx(own.b, candidate.b):
			return true
	return false


## The Theme itself, built once: set it on the root Control of a screen and
## everything under it follows.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_color(&"font_color", &"Label", NOW_COLOUR)
	t.set_constant(&"line_spacing", &"Label", 0)
	for meaning: StringName in MEANINGS + [LEGEND]:
		t.set_type_variation(variation(meaning), &"Label")
		t.set_color(&"font_color", variation(meaning), colour(meaning))

	t.set_stylebox(&"panel", &"PanelContainer", _box(SCREEN_COLOUR, SCREEN_COLOUR, 0, 0))
	t.set_stylebox(&"panel", &"Panel", _box(SCREEN_COLOUR, SCREEN_COLOUR, 0, 0))
	t.set_constant(&"separation", &"VBoxContainer", 0)
	t.set_constant(&"separation", &"HBoxContainer", 10)

	# The header strip: a rule under it.
	t.set_type_variation(HEADER, &"PanelContainer")
	var header := _box(SCREEN_COLOUR, RULE_COLOUR, 0, 12)
	header.border_width_bottom = 2
	header.content_margin_top = 4
	header.content_margin_bottom = 4
	t.set_stylebox(&"panel", HEADER, header)
	t.set_type_variation(HEADER_TEXT, &"Label")
	t.set_font_size(&"font_size", HEADER_TEXT, FONT_SIZE_HEADER)
	t.set_color(&"font_color", HEADER_TEXT, NOW_COLOUR)

	# A Caution lamp: amber with dark lettering while lit, a dark outline with
	# its label still readable while not.
	t.set_type_variation(LAMP_LIT, &"PanelContainer")
	t.set_stylebox(&"panel", LAMP_LIT, _box(CAUTION_COLOUR, CAUTION_COLOUR, 2, 8))
	t.set_type_variation(LAMP_UNLIT, &"PanelContainer")
	t.set_stylebox(&"panel", LAMP_UNLIT, _box(SCREEN_COLOUR, RULE_COLOUR, 2, 8))
	t.set_type_variation(LAMP_LIT_TEXT, &"Label")
	t.set_color(&"font_color", LAMP_LIT_TEXT, SCREEN_COLOUR)
	t.set_font_size(&"font_size", LAMP_LIT_TEXT, FONT_SIZE_SMALL)
	t.set_type_variation(LAMP_UNLIT_TEXT, &"Label")
	t.set_color(&"font_color", LAMP_UNLIT_TEXT, RULE_COLOUR)
	t.set_font_size(&"font_size", LAMP_UNLIT_TEXT, FONT_SIZE_SMALL)
	_theme = t
	return t


static func _box(fill: Color, border: Color, border_px: int, margin_x: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_px)
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box
