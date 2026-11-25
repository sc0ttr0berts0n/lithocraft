## The Column sliding through the Bore, drawn as a vertical strip: the Head at
## the bottom, the Tail at the top. Diving, fresh Column enters at the Head and
## slides up toward the Tail.
##
## Every grain is pinned to its place along the path (DiveSimulation.distance()
## minus how far behind the Head it is), so the strip scrolls at exactly the
## simulation's speed() and a Boundary is seen to pass. Placeholder for the
## Habitat's Bore (ticket #3), which should read the Column the same way.
class_name ColumnStrip
extends Control

## Screen scale of the Column. The ruler ticks mark every metre.
const PIXELS_PER_METRE := 40.0
## Height of one band of grains along the path, in metres.
const CELL_M := 0.25
## Grains drawn in a band of solid rock; scaled down by porosity, so loose
## sand shows its pores and matrix while granite is packed crystal.
const GRAINS_PER_SOLID_CELL := 48
const GRAIN_PX := Vector2(7.0, 5.0)

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
	var distance := sim.distance()
	var visible_m := height / PIXELS_PER_METRE
	# Bands are indexed by their fixed position along the path so they move
	# with the Column rather than with the screen.
	var first := floori((distance - visible_m) / CELL_M)
	var last := floori(distance / CELL_M)
	for k in range(first, last + 1):
		var along := k * CELL_M
		var behind_head := distance - along
		var bottom := height - (behind_head * PIXELS_PER_METRE)
		var rect := Rect2(0.0, bottom - CELL_M * PIXELS_PER_METRE, width, CELL_M * PIXELS_PER_METRE)
		var medium := sim.column_at(behind_head - CELL_M * 0.5)
		draw_rect(rect, ColumnLook.matrix_colour(medium))
		_draw_grains(k, rect, medium)
	_draw_ruler(distance, height)
	var font := get_theme_default_font()
	draw_string(font, Vector2(6.0, 16.0), "TAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_string(font, Vector2(6.0, height - 6.0), "HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.7, 0.85, 1.0, 0.6), false, 2.0)


## Grains in one band: same places and minerals every frame for that band.
func _draw_grains(k: int, rect: Rect2, medium: Medium) -> void:
	_rng.seed = hash(k)
	for i in roundi(GRAINS_PER_SOLID_CELL * (1.0 - medium.porosity)):
		var at := rect.position + Vector2(_rng.randf() * rect.size.x, _rng.randf() * rect.size.y)
		var roll := _rng.randf()
		var colour: Color
		# A share of the speckle equal to the porosity is open pore.
		if _rng.randf() < medium.porosity:
			colour = ColumnLook.PORE_COLOUR
		else:
			colour = ColumnLook.mineral_colour(ColumnLook.grain_mineral(medium.composition, roll))
		draw_rect(Rect2(at, GRAIN_PX), colour)


## Ticks every metre along the path, moving with the Column.
func _draw_ruler(distance: float, height: float) -> void:
	var font := get_theme_default_font()
	var metre := floori(distance)
	while (distance - metre) * PIXELS_PER_METRE < height:
		var y := height - (distance - metre) * PIXELS_PER_METRE
		var long := metre % 5 == 0
		draw_line(Vector2(size.x - (14.0 if long else 7.0), y), Vector2(size.x, y), Color.WHITE, 1.0)
		if long:
			draw_string(font, Vector2(size.x - 50.0, y - 2.0), "%d m" % metre,
					HORIZONTAL_ALIGNMENT_RIGHT, 34.0, 11, Color.WHITE)
		metre -= 1
