## Where the words go on Navigation's scan display (#151): each label is put
## at the first of its candidate places that lies wholly inside its area and
## clear of every label put before it and of every marker blocked out, or
## left out when none is clear. A pane places its labels in the order they
## matter (its title first, then its range, the rock's names, its other
## scale words, the targets' names), so a lesser label gives way to a greater and no two ever
## overlap. Each is drawn on a faint backdrop, so the points never hide it.
## Plain: knows nothing of the simulation or the views.
class_name ScanLabels
extends RefCounted

## Clear room kept round every label and marker, pixels.
const PAD_PX := 1.0
## How opaque a label's backdrop is.
const BACKDROP_ALPHA := 0.7
## A label's box, as shares of its font size: from its baseline up to the
## top of a capital, and in all down to the foot of a descender (the letters, not
## the font's line spacing, so lines a font size apart do not overlap).
const CAP_SHARE := 0.76
const LINE_SHARE := 1.0

var _within: Rect2
var _font_size: int
var _boxes: Array[Rect2] = []
var _texts := PackedStringArray()
var _colours: Array[Color] = []
var _sizes: Array[int] = []
var _markers: Array[Rect2] = []


## Labels inside `within` (the area's own pixels), written this size
## unless a label is given its own.
func _init(within: Rect2, font_size: int) -> void:
	_within = within
	_font_size = font_size


## How wide a label is, pixels.
func width(text: String, font_size := 0) -> float:
	return ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			font_size if font_size > 0 else _font_size).x


## The box a label covers written with its baseline starting at `at`.
func box_at(at: Vector2, text: String, font_size := 0) -> Rect2:
	var points := font_size if font_size > 0 else _font_size
	return Rect2(at.x, at.y - points * CAP_SHARE, width(text, points), points * LINE_SHARE)


## Keeps every label off this rectangle (a marker: the vessel, the aim).
func block(rect: Rect2) -> void:
	_markers.append(rect)


## Puts a label at the first of `candidates` (each where its baseline
## starts) that is inside the area and clear; true when one was.
func place(text: String, candidates: Array, colour: Color, font_size := 0) -> bool:
	for at: Vector2 in candidates:
		var box := box_at(at, text, font_size)
		if clear(box):
			_boxes.append(box)
			_texts.append(text)
			_colours.append(colour)
			_sizes.append(font_size if font_size > 0 else _font_size)
			return true
	return false


## True when a label's box lies wholly inside the area, off every marker and
## every label already placed.
func clear(box: Rect2) -> bool:
	if not _within.encloses(box):
		return false
	var padded := box.grow(PAD_PX)
	for other in _boxes:
		if padded.intersects(other):
			return false
	for marker in _markers:
		if padded.intersects(marker):
			return false
	return true


## The boxes of the labels placed, in the order placed.
func boxes() -> Array[Rect2]:
	return _boxes.duplicate()


## The labels placed, in the same order as boxes().
func texts() -> PackedStringArray:
	return _texts.duplicate()


## The markers labels are kept off.
func markers() -> Array[Rect2]:
	return _markers.duplicate()


## Draws every label placed, each on its backdrop.
func draw(canvas: CanvasItem) -> void:
	var font := ThemeDB.fallback_font
	var backdrop := StationTheme.faded(StationTheme.SCREEN_COLOUR, BACKDROP_ALPHA)
	for i in _boxes.size():
		canvas.draw_rect(_boxes[i].grow(PAD_PX), backdrop)
		canvas.draw_string(font, _boxes[i].position + Vector2(0.0, _sizes[i] * CAP_SHARE), _texts[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, _sizes[i], _colours[i])
