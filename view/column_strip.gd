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
## Where round the Column every feature's middle lies, 0..1 of the strip's
## width, for a strip wrapped round the Column: the Habitat turns them to the
## Bore Station. -1 on a flat strip, where each keeps a place of its own.
@export var features_face := -1.0

var sim: DiveSimulation

var _rng := RandomNumberGenerator.new()
## The grains of each band in view, built once and drawn each frame as one
## mesh (band index -> {medium, points, colours, indices}, in the band's own
## pixels): a band keeps its grains for as long as it is in the strip. What
## they were built for is in _built_for; a change of size or scale drops them.
var _bands := {}
var _built_for := []


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
	var built_for := [width, pixels_per_metre, cell_m, grain_m]
	if built_for != _built_for:
		_built_for = built_for
		_bands.clear()
	for k: int in _bands.keys():
		if k < first or k > last:
			_bands.erase(k)
	for k in range(first, last + 1):
		var along := k * cell_m
		var bottom := height - (bottom_at - along) * pixels_per_metre
		var rect := Rect2(0.0, bottom - cell_px, width, cell_px)
		if sim.column_absent(sim.distance() - along - cell_m * 0.5):
			continue  # A Glide melted the Column here: nothing to draw.
		var medium := sim.column_at(sim.distance() - along - cell_m * 0.5)
		draw_rect(rect, ColumnLook.matrix_colour(medium))
		_draw_grains(k, rect, medium)
		draw_set_transform(Vector2.ZERO)
	_draw_features(bottom_at, visible_m)
	if show_readout:
		_draw_ruler(bottom_at, height)
		var font := get_theme_default_font()
		draw_string(font, Vector2(6.0, 16.0), "TAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		draw_string(font, Vector2(6.0, height - 6.0), "HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.7, 0.85, 1.0, 0.6), false, 2.0)


## Grains in one band: same places and minerals every frame for that band,
## drawn as one mesh moved to where the band is now. Leaves the draw transform
## at the band.
func _draw_grains(k: int, rect: Rect2, medium: Medium) -> void:
	var band: Dictionary = _bands.get(k, {})
	if band.is_empty() or band.medium != medium:
		band = _grains(k, rect.size, medium)
		_bands[k] = band
	if (band.indices as PackedInt32Array).is_empty():
		return
	draw_set_transform(rect.position)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), band.indices, band.points, band.colours)


## The grains of band k of this Medium, in a band this size in pixels: each a
## rectangle of two triangles, later ones over earlier.
func _grains(k: int, band_px: Vector2, medium: Medium) -> Dictionary:
	_rng.seed = hash(k)
	var grain_px := grain_m * pixels_per_metre
	var count := roundi(GRAIN_COVER * (1.0 - medium.porosity) * band_px.x * band_px.y / (grain_px.x * grain_px.y))
	var points := PackedVector2Array()
	var colours := PackedColorArray()
	var indices := PackedInt32Array()
	for i in count:
		var at := Vector2(_rng.randf() * band_px.x, _rng.randf() * band_px.y)
		var roll := _rng.randf()
		var colour: Color
		# A share of the speckle equal to the porosity is open pore.
		if _rng.randf() < medium.porosity:
			colour = ColumnLook.PORE_COLOUR
		else:
			colour = ColumnLook.mineral_colour(ColumnLook.grain_mineral(medium.composition, roll))
		var corner := points.size()
		points.append_array([at, at + Vector2(grain_px.x, 0.0), at + grain_px, at + Vector2(0.0, grain_px.y)])
		colours.append_array([colour, colour, colour, colour])
		indices.append_array([corner, corner + 1, corner + 2, corner, corner + 2, corner + 3])
	return {medium = medium, points = points, colours = colours, indices = indices}


## Features of interest pinned to their place along the path, so they slide
## past with the Column, with the Bore Station's marks round them. Features
## still in the Column outside the vessel are drawn too: the Column keeps them.
func _draw_features(bottom_at: float, visible_m: float) -> void:
	var observed := sim.observed_feature()
	for feature in sim.found_features():
		if sim.column_absent(sim.distance() - feature.at):
			continue
		var reach := feature.size_m * 2.0
		if feature.at < bottom_at - visible_m - reach or feature.at > bottom_at + reach:
			continue
		var box := feature_box(feature)
		# A box hanging over an edge of a wrapped strip carries on at the other
		# edge: the two are one line round the Column.
		var shifts := [0.0]
		if box.position.x < 0.0:
			shifts.append(size.x)
		if box.end.x > size.x:
			shifts.append(-size.x)
		for shift in shifts:
			draw_set_transform(Vector2(shift, 0.0))
			FeatureLook.draw(self, feature, box, pixels_per_metre)
			FeatureLook.draw_marks(self, feature, box, feature.id == observed)
		draw_set_transform(Vector2.ZERO)


## The rectangle the strip draws a feature in now, in the strip's own pixels:
## its middle on the row of the place the simulation gives it along the path
## (ColumnFeature.at), turned to features_face round the Column.
func feature_box(feature: ColumnFeature) -> Rect2:
	var behind_bottom := sim.distance() - behind_head_m - feature.at
	return FeatureLook.bounds(feature, size.x, size.y - behind_bottom * pixels_per_metre,
			pixels_per_metre, features_face)


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
