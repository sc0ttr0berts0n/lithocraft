## The frame every Station screen shares: Controls and Containers in this
## SubViewport under the one StationTheme, shown on the Station's screen as a
## texture (GimballedStation). Top to bottom:
##
##   header strip  the Station's name, its autopilot's state, its Caution
##                 lamps; laid out the same on every Station
##   body          the Station's own instrument: whatever Control the Station
##                 puts there (set_instrument()), or live pictures side by
##                 side (show_pictures()); it takes all the room the rest
##                 leaves, and is absent on a Station with no instrument yet
##   status        the Station's readings as lines of text, each in the
##                 colour of what it means (show_lines()); the text shrinks
##                 until every line is whole, never cut off
##   footer        one line every Station shows alike (the time rate)
##
## A Station comes to look its own by its instrument; the name in the header
## is the fallback. Nothing here reads the simulation: the Habitat hands the
## frame what to show.
class_name StationScreen
extends SubViewport

## The screen in its own pixels: the shape of GimballedStation.SCREEN_SIZE.
const SIZE := Vector2i(800, 480)
## The header strip's and the footer's least heights, the margin beside the
## status lines, and the gap between the frame's parts.
const HEADER_PX := 52.0
const FOOTER_PX := 30.0
const MARGIN_PX := 14.0
const GAP_PX := 6.0
## The most of the room under the header that the status lines may take from
## an instrument; past it their text shrinks instead.
const STATUS_MOST := 0.45
## The smallest the status text may shrink to.
const FONT_SIZE_LEAST := 8

var _root := PanelContainer.new()
var _header := PanelContainer.new()
var _name := Label.new()
var _autopilot := Label.new()
var _lamps := HFlowContainer.new()
var _body := Control.new()
var _status := VBoxContainer.new()
var _status_margin := MarginContainer.new()
var _status_font_size := StationTheme.FONT_SIZE
var _footer := Label.new()
var _footer_row := MarginContainer.new()
## The live pictures in the body, left to right, if show_pictures() put any.
var _pictures: Array[TextureRect] = []
## The status lines as last shown: each [text, meaning].
var _lines: Array = []


func _init() -> void:
	size = SIZE
	disable_3d = true
	transparent_bg = false
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_root.theme = StationTheme.theme()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", int(GAP_PX))
	_root.add_child(column)

	_header.theme_type_variation = StationTheme.HEADER
	_header.custom_minimum_size.y = HEADER_PX
	column.add_child(_header)
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override(&"separation", 18)
	_header.add_child(strip)
	_name.theme_type_variation = StationTheme.HEADER_TEXT
	strip.add_child(_name)
	_autopilot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	strip.add_child(_autopilot)
	_lamps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lamps.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lamps.alignment = FlowContainer.ALIGNMENT_END
	_lamps.add_theme_constant_override(&"h_separation", 8)
	_lamps.add_theme_constant_override(&"v_separation", 4)
	strip.add_child(_lamps)

	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.clip_contents = true
	_body.visible = false
	column.add_child(_body)

	# With no instrument the status lines have the room; under one they take
	# only what they need (set_instrument()).
	_status_margin.add_theme_constant_override(&"margin_left", int(MARGIN_PX))
	_status_margin.add_theme_constant_override(&"margin_right", int(MARGIN_PX))
	_status_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_status_margin)
	_status_margin.add_child(_status)

	_footer.theme_type_variation = StationTheme.variation(StationTheme.LEGEND)
	_footer.add_theme_font_size_override(&"font_size", StationTheme.FONT_SIZE_SMALL)
	_footer.custom_minimum_size.y = FOOTER_PX
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_footer.clip_text = true
	_footer_row.add_theme_constant_override(&"margin_left", int(MARGIN_PX))
	_footer_row.add_theme_constant_override(&"margin_right", int(MARGIN_PX))
	_footer_row.add_child(_footer)
	_footer_row.visible = false
	column.add_child(_footer_row)
	set_autopilot("", StationTheme.NOW)


# --- What the Station shows ----------------------------------------------

## The Station's name, at the left of the header strip.
func set_station_name(station_name: String) -> void:
	_name.text = station_name


## The autopilot's state beside the name, in the colour of what it means
## (green engaged, amber as it lets go, white off).
func set_autopilot(caption: String, meaning: StringName) -> void:
	_autopilot.text = caption
	_autopilot.theme_type_variation = StationTheme.variation(meaning)


## The Station's Caution lamps at the right of the header strip, left to
## right: each {label, lit}, as CautionLamps.of() gives them. A lamp is drawn
## lit or not, so each keeps its place.
func show_lamps(lamps: Array[Dictionary]) -> void:
	while _lamps.get_child_count() > lamps.size():
		var spare := _lamps.get_child(_lamps.get_child_count() - 1)
		_lamps.remove_child(spare)
		spare.queue_free()
	while _lamps.get_child_count() < lamps.size():
		var lamp := PanelContainer.new()
		lamp.add_child(Label.new())
		_lamps.add_child(lamp)
	for i in lamps.size():
		var lamp := _lamps.get_child(i) as PanelContainer
		var label := lamp.get_child(0) as Label
		label.text = lamps[i].label
		lamp.theme_type_variation = StationTheme.LAMP_LIT if lamps[i].lit else StationTheme.LAMP_UNLIT
		label.theme_type_variation = StationTheme.LAMP_LIT_TEXT if lamps[i].lit \
				else StationTheme.LAMP_UNLIT_TEXT


## Puts the Station's own instrument in the body: any Control, which is made
## to fill the body and is resized with it (lay it out by its own size, or
## build it of Containers). It should draw only in StationTheme's colours.
## Replaces what was there.
func set_instrument(instrument: Control) -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_pictures = []
	_body.add_child(instrument)
	instrument.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_body.visible = true
	_status_margin.size_flags_vertical = Control.SIZE_FILL
	_fit_status()


## Puts live pictures (a SubViewport's texture each) in the body side by
## side, the first on the left, sharing it equally; each keeps its shape,
## centred in its share. For an instrument that is drawn in a viewport of
## its own (a 3D display, or one not yet moved onto Controls).
func show_pictures(textures: Array[Texture2D]) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", int(GAP_PX))
	set_instrument(row)
	for texture in textures:
		var picture := TextureRect.new()
		picture.texture = texture
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(picture)
		_pictures.append(picture)


## The Station's readings as lines of text under its instrument. Each line
## is a String (white: what is happening now) or [text, meaning] with a
## meaning of StationTheme (StationTheme.CAUTION ...) or StationTheme.LEGEND.
func show_lines(lines: Array) -> void:
	_lines = []
	for line: Variant in lines:
		_lines.append([line, StationTheme.NOW] if line is String else [str(line[0]), line[1]])
	while _status.get_child_count() > _lines.size():
		var spare := _status.get_child(_status.get_child_count() - 1)
		_status.remove_child(spare)
		spare.queue_free()
	while _status.get_child_count() < _lines.size():
		var label := Label.new()
		label.clip_text = true
		_status.add_child(label)
	for i in _lines.size():
		var label := _status.get_child(i) as Label
		label.text = _lines[i][0]
		label.theme_type_variation = StationTheme.variation(_lines[i][1])
	_fit_status()


## One line every Station shows alike, at the bottom; "" for none.
func set_footer(text: String) -> void:
	if text == _footer.text:
		return
	_footer.text = text
	_footer_row.visible = not text.is_empty()
	_fit_status()


# --- What is on it, for pointing and for checks ---------------------------

## The header strip's words: the name, then the autopilot's caption.
func header_text() -> String:
	return "%s   %s" % [_name.text, _autopilot.text]


## The text readings top to bottom: the header strip, each status line, then
## the footer if there is one.
func texts() -> PackedStringArray:
	var all := PackedStringArray([header_text()])
	for line in _lines:
		all.append(line[0])
	if _footer_row.visible:
		all.append(_footer.text)
	return all


## Where each of texts() lies on the screen, in its pixels. Laid out by the
## Containers, so only once the screen is in the tree and a frame has passed.
func text_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = [_header.get_global_rect()]
	for label in _status.get_children():
		rects.append((label as Control).get_global_rect())
	if _footer_row.visible:
		rects.append(_footer.get_global_rect())
	return rects


## How many live pictures the body shows.
func picture_count() -> int:
	return _pictures.size()


## Where picture `index` is drawn on the screen, in its pixels: its share of
## the body, less the bars left by keeping its shape.
func picture_rect(index: int) -> Rect2:
	var picture := _pictures[index]
	var room := picture.get_global_rect()
	var shape := picture.texture.get_size() if picture.texture else Vector2.ZERO
	if shape.x <= 0.0 or shape.y <= 0.0 or room.size.x <= 0.0 or room.size.y <= 0.0:
		return room
	var drawn := shape * minf(room.size.x / shape.x, room.size.y / shape.y)
	return Rect2(room.position + (room.size - drawn) / 2.0, drawn)


## The readings inside the Station's instrument, in the order its Controls
## come: each {name, rect}, the rectangle in the screen's pixels. An
## instrument put in the body by set_instrument(), or any Control inside it,
## names its readings with a method `readings() -> Dictionary`,
## {name: Rect2 in its own pixels}: one for each thing on it the crew can
## point at (ThermalGauge.readings() is the example). Laid out by the
## Containers, so only once the screen is in the tree and a frame has passed.
func instrument_readings() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for control: Control in _body.find_children("*", "Control", true, false):
		if not control.has_method(&"readings") or not control.is_visible_in_tree():
			continue
		var named: Dictionary = control.call(&"readings")
		var from := control.get_global_rect().position
		for reading: StringName in named:
			var rect: Rect2 = named[reading]
			found.append({name = reading, rect = Rect2(from + rect.position, rect.size)})
	return found


## The body's place on the screen, in its pixels: an instrument's room.
func body_rect() -> Rect2:
	return _body.get_global_rect()


## The lamps' labels left to right, and those of them lit.
func lamp_labels() -> PackedStringArray:
	return _lamp_labels(false)


func lit_lamps() -> PackedStringArray:
	return _lamp_labels(true)


## The font size the status lines are written at now.
func status_font_size() -> int:
	return _status_font_size


## Every Control of the frame, for checks that walk it.
func root() -> Control:
	return _root


# --- Inside ---------------------------------------------------------------


func _lamp_labels(only_lit: bool) -> PackedStringArray:
	var labels := PackedStringArray()
	for lamp in _lamps.get_children():
		if not only_lit or (lamp as Control).theme_type_variation == StationTheme.LAMP_LIT:
			labels.append((lamp.get_child(0) as Label).text)
	return labels


## Shrinks the status text until every line is whole inside the room it has:
## all that the header and footer leave on a screen with no instrument,
## STATUS_MOST of it under one.
func _fit_status() -> void:
	var room := Vector2(SIZE.x - 2.0 * MARGIN_PX, status_room(_body.visible, _footer_row.visible))
	var texts := PackedStringArray()
	for line in _lines:
		texts.append(line[0])
	_status_font_size = fitting_font_size("\n".join(texts), ThemeDB.fallback_font,
			StationTheme.FONT_SIZE, room)
	for label in _status.get_children():
		(label as Label).add_theme_font_size_override(&"font_size", _status_font_size)


## The height the status lines may fill, in pixels.
static func status_room(with_instrument: bool, with_footer: bool) -> float:
	var under_header := _under_header(with_footer)
	return (under_header - GAP_PX) * STATUS_MOST if with_instrument else under_header


## The room an instrument has in the body, in pixels, over this many status
## lines at their full size: what to size a picture's viewport to
## (show_pictures()), so it is drawn dot for dot. With more lines, or longer
## ones, the body is laid out a little larger or smaller and the picture is
## scaled to it.
static func body_size(lines: int, with_footer := true) -> Vector2:
	var status := minf(lines * ThemeDB.fallback_font.get_height(StationTheme.FONT_SIZE),
			status_room(true, with_footer))
	return Vector2(SIZE.x, _under_header(with_footer) - GAP_PX - status)


## The height under the header strip, less the footer's, in pixels.
static func _under_header(with_footer: bool) -> float:
	var room := SIZE.y - HEADER_PX - GAP_PX
	return room - FOOTER_PX - GAP_PX if with_footer else room


## The largest font size, up to largest, at which text (its lines one under
## another) fits inside box, in font pixels. Never below FONT_SIZE_LEAST.
static func fitting_font_size(text: String, font: Font, largest: int, box: Vector2) -> int:
	var font_size := largest
	while font_size > FONT_SIZE_LEAST:
		var block := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		if block.x <= box.x and block.y <= box.y:
			break
		font_size -= 1
	return font_size
