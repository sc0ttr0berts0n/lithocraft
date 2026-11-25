## The Column sliding through the Bore, drawn as a vertical strip: the Head end
## at the bottom, the Tail end at the top. Diving, fresh Column enters at the
## bottom and slides up toward the Tail.
##
## Every grain is pinned to its place along the path (DiveSimulation.distance()
## minus how far behind the Head it is), so the strip scrolls at exactly the
## simulation's speed() and a Boundary is seen to pass.
##
## Used twice: as the overlay readout, and inside a SubViewport as the texture
## of the Column in the Habitat's Bore (see habitat.gd), where the strip's
## width wraps round the Column and its height is the Bore's length.
class_name ColumnStrip
extends Control

## Of all the grains a band could hold, the share of its area they cover
## in solid rock. Porosity thins them out.
const GRAIN_COVER := 1.05

## Scale of the Column on the strip.
@export var pixels_per_metre := 40.0
## Height of one band of grains along the path, in metres.
@export var cell_m := 0.25
## Size of one drawn grain, in metres (across, along the path).
@export var grain_m := Vector2(0.175, 0.125)
## How far behind the Head the strip's bottom edge is, in metres. 0 for a view
## from the Head; the Habitat sits some way back along the vessel.
@export var behind_head_m := 0.0
## Ruler, end labels and frame: on for the overlay readout, off in the Bore.
@export var show_readout := true

var sim: DiveSimulation

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	clip_contents = true


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if sim == null:
		return
	var width := size.x
	var height := size.y
	# Path position of the strip's bottom edge.
	var bottom_at := sim.distance() - behind_head_m
	var visible_m := height / pixels_per_metre
	var cell_px := cell_m * pixels_per_metre
	# Bands are indexed by their fixed position along the path so they move
	# with the Column rather than with the screen.
	var first := floori((bottom_at - visible_m) / cell_m)
	var last := floori(bottom_at / cell_m)
	for k in range(first, last + 1):
		var along := k * cell_m
		var bottom := height - (bottom_at - along) * pixels_per_metre
		var rect := Rect2(0.0, bottom - cell_px, width, cell_px)
		var medium := sim.column_at(sim.distance() - along - cell_m * 0.5)
		draw_rect(rect, ColumnLook.matrix_colour(medium))
		_draw_grains(k, rect, medium)
	if show_readout:
		_draw_ruler(bottom_at, height)
		var font := get_theme_default_font()
		draw_string(font, Vector2(6.0, 16.0), "TAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		draw_string(font, Vector2(6.0, height - 6.0), "HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.7, 0.85, 1.0, 0.6), false, 2.0)


## Grains in one band: same places and minerals every frame for that band.
func _draw_grains(k: int, rect: Rect2, medium: Medium) -> void:
	_rng.seed = hash(k)
	var grain_px := grain_m * pixels_per_metre
	var band_area := rect.size.x * rect.size.y
	var count := roundi(GRAIN_COVER * (1.0 - medium.porosity) * band_area / (grain_px.x * grain_px.y))
	for i in count:
		var at := rect.position + Vector2(_rng.randf() * rect.size.x, _rng.randf() * rect.size.y)
		var roll := _rng.randf()
		var colour: Color
		# A share of the speckle equal to the porosity is open pore.
		if _rng.randf() < medium.porosity:
			colour = ColumnLook.PORE_COLOUR
		else:
			colour = ColumnLook.mineral_colour(ColumnLook.grain_mineral(medium.composition, roll))
		draw_rect(Rect2(at, grain_px), colour)


## Ticks every metre along the path, moving with the Column.
func _draw_ruler(bottom_at: float, height: float) -> void:
	var font := get_theme_default_font()
	var metre := floori(bottom_at)
	while (bottom_at - metre) * pixels_per_metre < height:
		var y := height - (bottom_at - metre) * pixels_per_metre
		var long := metre % 5 == 0
		draw_line(Vector2(size.x - (14.0 if long else 7.0), y), Vector2(size.x, y), Color.WHITE, 1.0)
		if long:
			draw_string(font, Vector2(size.x - 50.0, y - 2.0), "%d m" % metre,
					HORIZONTAL_ALIGNMENT_RIGHT, 34.0, 11, Color.WHITE)
		metre -= 1
