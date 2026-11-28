## How a feature of interest looks in the Column, drawn onto a ColumnStrip in
## metres so the same drawing serves the overlay readout and the Bore's
## texture. View-side only; the simulation never calls this. Placeholder art.
class_name FeatureLook
extends RefCounted

## Colour of the marks the Bore Station puts round a feature.
const OBSERVING_COLOUR := Color(0.45, 0.95, 1.0)
const RECORDED_COLOUR := Color(0.72, 1.0, 0.42)
## The look of each kind of feature: how wide it is across the Column, in
## metres (0 for a sheet that goes right round it), and the function below
## that paints it. A kind a layout holds must be here: feature_look_test
## fails on one that is not. Sizes are tuned to be seen from across the
## Habitat (ADR 0001).
const LOOKS := {
	&"fulgurite": {across = 0.3, paint = &"_fulgurite"},
	&"petrified_wood": {across = 0.5, paint = &"_petrified_wood"},
	&"iron_concretions": {across = 0.8, paint = &"_concretions"},
	&"quartz_vein": {across = 0.0, paint = &"_quartz_vein"},
	&"pegmatite": {across = 0.6, paint = &"_pegmatite"},
	# A target's body: far wider than the Column, so it fills it all round.
	&"hematite_breccia": {across = 12.0, paint = &"_breccia"},
}
## How wide a kind with no look is drawn, so a missing one is plain to see.
const UNKNOWN_ACROSS_M := 0.3


## True when this kind of feature has a look of its own in the Column.
static func has_look(kind: StringName) -> bool:
	return LOOKS.has(kind) and FeatureLook.new().has_method(LOOKS[kind].paint)


## Where round the Column a feature sits when nothing says which side it
## faces, 0..1 of the strip's width. Fixed per feature so it never jumps.
static func across_fraction(feature: ColumnFeature) -> float:
	return fposmod(hash(feature.id * 7919 + 13) / 1000.0, 1.0)


## The rectangle a feature covers on a strip: centre_y is the pixel row of its
## middle, ppm the strip's pixels per metre. `facing` is where round the
## Column its middle lies, 0..1 of the strip's width; the box may then hang
## over an edge of the strip, which is the same line round the Column as the
## other edge. Left out, each feature keeps a place of its own inside the strip.
static func bounds(feature: ColumnFeature, width: float, centre_y: float, ppm: float,
		facing := -1.0) -> Rect2:
	var across_m: float = LOOKS[feature.kind].across if LOOKS.has(feature.kind) else UNKNOWN_ACROSS_M
	var across := across_m * ppm
	var along := feature.size_m * ppm
	if across <= 0.0:
		return Rect2(0.0, centre_y - along * 2.0, width, along * 4.0)
	var x := across_fraction(feature) * maxf(width - across, 0.0)
	if facing >= 0.0:
		x = fposmod(facing, 1.0) * width - across / 2.0
	return Rect2(x, centre_y - along / 2.0, across, along)


## Draws the feature into its bounds on the canvas.
static func draw(canvas: CanvasItem, feature: ColumnFeature, box: Rect2, ppm: float) -> void:
	if not has_look(feature.kind):
		canvas.draw_rect(box, Color(1, 0, 1))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(feature.id)
	FeatureLook.new().call(LOOKS[feature.kind].paint, canvas, box, ppm, rng)


## The Bore Station's marks round a feature: corner brackets while observing,
## a solid frame once recorded, a progress bar beside it while recording.
static func draw_marks(canvas: CanvasItem, feature: ColumnFeature, box: Rect2,
		observing: bool) -> void:
	var frame := box.grow(4.0)
	if feature.is_recorded():
		canvas.draw_rect(frame, RECORDED_COLOUR, false, 3.0)
		return
	if not observing and feature.recorded <= 0.0:
		return
	var colour := OBSERVING_COLOUR if observing else OBSERVING_COLOUR.darkened(0.5)
	var arm := minf(14.0, minf(frame.size.x, frame.size.y) / 2.0)
	for corner in [frame.position, Vector2(frame.end.x, frame.position.y),
			frame.end, Vector2(frame.position.x, frame.end.y)]:
		var sx := 1.0 if corner.x == frame.position.x else -1.0
		var sy := 1.0 if corner.y == frame.position.y else -1.0
		canvas.draw_line(corner, corner + Vector2(arm * sx, 0.0), colour, 3.0)
		canvas.draw_line(corner, corner + Vector2(0.0, arm * sy), colour, 3.0)
	# Progress up the side of the frame.
	var bar := Rect2(frame.end.x + 4.0, frame.position.y, 6.0, frame.size.y)
	canvas.draw_rect(bar, Color(0, 0, 0, 0.6))
	var filled := bar.size.y * feature.recorded
	canvas.draw_rect(Rect2(bar.position.x, bar.end.y - filled, bar.size.x, filled), colour)


# --- Kinds ----------------------------------------------------------------

## A glassy tube wandering along the path: a pale sleeve of sintered sand
## round a dark glass core, with a side branch or two.
static func _fulgurite(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		var y := box.position.y + box.size.y * i / steps
		var x := box.get_center().x + rng.randf_range(-0.3, 0.3) * box.size.x
		points.append(Vector2(x, y))
	var core := maxf(0.05 * ppm, 2.0)
	var glass := Color(0.1, 0.16, 0.15)
	var sleeve := Color(0.93, 0.95, 0.9)
	var branches: Array[PackedVector2Array] = []
	for b in 2:
		var from := points[rng.randi_range(2, steps - 2)]
		var side := -1.0 if b == 0 else 1.0
		branches.append(PackedVector2Array([from, from + Vector2(
				side * rng.randf_range(0.08, 0.14) * ppm, rng.randf_range(0.06, 0.12) * ppm)]))
	for branch in branches:
		canvas.draw_polyline(branch, sleeve, core * 1.6)
	canvas.draw_polyline(points, sleeve, core * 2.4)
	for branch in branches:
		canvas.draw_polyline(branch, glass, core * 0.6)
	canvas.draw_polyline(points, glass, core)
	canvas.draw_polyline(points, Color(0.45, 0.62, 0.58), maxf(core * 0.25, 1.0))


## A fossil trunk the Column cuts across at a slant, so its section is a
## tall oval: growth rings in agate reds and creams round an off-centre
## heart, inside a rind of bark, with pale quartz in the cracks that ran out
## from the heart as it dried.
static func _petrified_wood(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	var radii := box.size / 2.0
	var bark := Color(0.5, 0.24, 0.12)
	_oval(canvas, box.get_center(), radii, bark)
	var shades := [Color(0.82, 0.38, 0.16), Color(0.93, 0.76, 0.52), Color(0.66, 0.2, 0.1)]
	var heart := box.get_center() + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12)) * box.size
	var rings := 6
	for i in rings:
		# From the bark inward, each ring a little nearer the heart.
		var inward := float(i) / rings
		var share := 0.88 * (1.0 - inward)
		_oval(canvas, box.get_center().lerp(heart, inward), radii * share, shades[i % shades.size()])
	for crack in 3:
		var along := Vector2.from_angle(rng.randf() * TAU)
		canvas.draw_line(heart, heart + along * radii * rng.randf_range(0.5, 0.8),
				Color(0.97, 0.95, 0.9), maxf(0.012 * ppm, 1.5))
	_oval(canvas, heart, radii * 0.06, bark)


## A filled oval.
static func _oval(canvas: CanvasItem, centre: Vector2, radii: Vector2, colour: Color) -> void:
	var rim := PackedVector2Array()
	for s in 32:
		var a := TAU * s / 32.0
		rim.append(centre + Vector2(cos(a), sin(a)) * radii)
	canvas.draw_colored_polygon(rim, colour)


## Iron oxide marbles: rusty balls, each with a dark shell and a glint, in a
## patch of sandstone bleached pale where its iron was drawn off to make them.
static func _concretions(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	var patch := PackedVector2Array()
	for s in 20:
		var a := TAU * s / 20.0
		patch.append(box.get_center() + Vector2(cos(a), sin(a)) * box.size / 2.0
				* rng.randf_range(0.88, 1.0))
	canvas.draw_colored_polygon(patch, Color(0.96, 0.93, 0.85))
	# Marbles on a loose grid, so they spread over the patch without piling up.
	var columns := 4
	var rows := 2
	for i in columns * rows:
		var middle := Vector2((i % columns + 0.5) / columns, (i / columns + 0.5) / rows)
		var jitter := Vector2(rng.randf_range(-0.2, 0.2) / columns, rng.randf_range(-0.2, 0.2) / rows)
		# Pulled in toward the middle, to keep inside the rounded patch.
		var at := box.get_center() + (middle + jitter - Vector2(0.5, 0.5)) * box.size * 0.72
		var r := rng.randf_range(0.04, 0.075) * ppm
		canvas.draw_circle(at, r, Color(0.3, 0.1, 0.05))
		canvas.draw_circle(at, r * 0.8, Color(0.62, 0.2, 0.07))
		canvas.draw_circle(at - Vector2(r, r) * 0.28, r * 0.25, Color(0.95, 0.62, 0.36))


## A sheet of white quartz crossing the Column at a slant: unwrapped round the
## Column, a slanted plane is a sine wave across the strip.
static func _quartz_vein(canvas: CanvasItem, box: Rect2, _ppm: float, rng: RandomNumberGenerator) -> void:
	var thick := maxf(box.size.y / 4.0, 3.0)
	var amp := box.size.y / 2.0 - thick / 2.0
	var phase := rng.randf() * TAU
	var points := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var x := box.position.x + box.size.x * i / steps
		points.append(Vector2(x, box.get_center().y + amp * sin(TAU * i / steps + phase)))
	canvas.draw_polyline(points, Color(0.97, 0.97, 0.95), thick)
	canvas.draw_polyline(points, Color(0.8, 0.82, 0.85), maxf(thick * 0.3, 1.0))


## Giant crystals: a pale pocket of big feldspar and milky quartz, with black
## tourmaline blades and dark red garnets, far coarser than the granite round it.
static func _pegmatite(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	var pocket := PackedVector2Array()
	for s in 14:
		var a := TAU * s / 14.0
		var wobble := rng.randf_range(0.8, 1.0)
		pocket.append(box.get_center() + Vector2(cos(a), sin(a)) * box.size / 2.0 * wobble)
	canvas.draw_colored_polygon(pocket, Color(0.96, 0.93, 0.88))
	var colours := [Color(1.0, 0.82, 0.74), Color(0.9, 0.9, 0.92), Color(0.98, 0.7, 0.6)]
	for i in 8:
		var centre := box.get_center() + Vector2(rng.randf_range(-0.3, 0.3) * box.size.x,
				rng.randf_range(-0.3, 0.3) * box.size.y)
		var r := rng.randf_range(0.06, 0.11) * ppm
		var corners := PackedVector2Array()
		var sides := rng.randi_range(4, 6)
		var turn := rng.randf() * TAU
		for s in sides:
			var a := turn + TAU * s / sides
			corners.append(centre + Vector2(cos(a), sin(a) * 0.7) * r)
		canvas.draw_colored_polygon(corners, colours[i % colours.size()])
		corners.append(corners[0])
		canvas.draw_polyline(corners, Color(0.45, 0.38, 0.35), 1.5)
	for t in 3:
		var from := box.get_center() + Vector2(rng.randf_range(-0.3, 0.3) * box.size.x,
				rng.randf_range(-0.3, 0.3) * box.size.y)
		var blade := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.1, 0.18) * ppm
		canvas.draw_line(from, from + blade, Color(0.06, 0.06, 0.07), maxf(0.025 * ppm, 2.0))
	for g in 4:
		var at := box.get_center() + Vector2(rng.randf_range(-0.35, 0.35) * box.size.x,
				rng.randf_range(-0.35, 0.35) * box.size.y)
		var r := maxf(0.03 * ppm, 1.5)
		canvas.draw_circle(at, r, Color(0.5, 0.04, 0.1))


## Hematite breccia, the first slice's target: granite shattered and cemented
## by iron oxide. Wider than the Column, so it fills it all round over the
## length the cut passed through: a dark steel-grey and red-brown matrix of
## hematite holding angular clasts of the pale granite, with glints of
## specular hematite and brassy specks of copper sulphide.
static func _breccia(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	canvas.draw_rect(box, Color(0.22, 0.17, 0.17))
	# Red-brown earthy hematite in streaks through the steel-grey.
	for i in 10:
		var at := box.position + Vector2(rng.randf(), rng.randf()) * box.size
		var r := Vector2(rng.randf_range(0.2, 0.5), rng.randf_range(0.1, 0.3)) * ppm
		_oval(canvas, at, r, Color(0.45, 0.14, 0.09, 0.8))
	# Angular clasts of granite on a loose grid, so they spread without piling up.
	var columns := maxi(roundi(box.size.x / (0.45 * ppm)), 1)
	var rows := maxi(roundi(box.size.y / (0.45 * ppm)), 1)
	for i in columns * rows:
		if rng.randf() < 0.35:
			continue
		var middle := box.position + Vector2((i % columns + rng.randf_range(0.2, 0.8)) / columns,
				(i / columns + rng.randf_range(0.2, 0.8)) / rows) * box.size
		var r := rng.randf_range(0.06, 0.16) * ppm
		var corners := PackedVector2Array()
		var sides := rng.randi_range(3, 5)
		var turn := rng.randf() * TAU
		for s in sides:
			var a := turn + TAU * s / sides + rng.randf_range(-0.3, 0.3)
			corners.append(middle + Vector2(cos(a), sin(a)) * r * rng.randf_range(0.6, 1.0))
		var granite := Color(0.86, 0.74, 0.7) if rng.randf() < 0.6 else Color(0.7, 0.66, 0.64)
		canvas.draw_colored_polygon(corners, granite)
	for g in 14:
		var at := box.position + Vector2(rng.randf(), rng.randf()) * box.size
		canvas.draw_circle(at, maxf(0.012 * ppm, 1.0), Color(0.75, 0.78, 0.82))
	for g in 6:
		var at := box.position + Vector2(rng.randf(), rng.randf()) * box.size
		canvas.draw_circle(at, maxf(0.018 * ppm, 1.2), Color(0.85, 0.7, 0.2))
