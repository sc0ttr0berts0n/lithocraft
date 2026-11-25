## How a feature of interest looks in the Column, drawn onto a ColumnStrip in
## metres so the same drawing serves the overlay readout and the Bore's
## texture. View-side only; the simulation never calls this. Placeholder art.
class_name FeatureLook
extends RefCounted

## Colour of the marks the Bore Station puts round a feature.
const OBSERVING_COLOUR := Color(0.45, 0.95, 1.0)
const RECORDED_COLOUR := Color(0.72, 1.0, 0.42)
## How wide each kind is across the Column, in metres.
const ACROSS_M := {
	&"fulgurite": 0.08,
	&"petrified_wood": 0.3,
	&"iron_concretions": 0.35,
	&"quartz_vein": 0.0, # A sheet: right round the Column.
	&"pegmatite": 0.55,
}


## Where round the Column a feature sits, 0..1 of the strip's width. Fixed
## per feature so it never jumps.
static func across_fraction(feature: ColumnFeature) -> float:
	return fposmod(hash(feature.id * 7919 + 13) / 1000.0, 1.0)


## The rectangle a feature covers on a strip: centre_y is the pixel row of its
## middle, ppm the strip's pixels per metre.
static func bounds(feature: ColumnFeature, width: float, centre_y: float, ppm: float) -> Rect2:
	var across: float = ACROSS_M.get(feature.kind, 0.3) * ppm
	var along := feature.size_m * ppm
	if across <= 0.0:
		return Rect2(0.0, centre_y - along * 2.0, width, along * 4.0)
	var x := across_fraction(feature) * maxf(width - across, 0.0)
	return Rect2(x, centre_y - along / 2.0, across, along)


## Draws the feature into its bounds on the canvas.
static func draw(canvas: CanvasItem, feature: ColumnFeature, box: Rect2, ppm: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(feature.id)
	match feature.kind:
		&"fulgurite": _fulgurite(canvas, box, ppm, rng)
		&"petrified_wood": _petrified_wood(canvas, box, ppm, rng)
		&"iron_concretions": _concretions(canvas, box, ppm, rng)
		&"quartz_vein": _quartz_vein(canvas, box, ppm, rng)
		&"pegmatite": _pegmatite(canvas, box, ppm, rng)
		_: canvas.draw_rect(box, Color(1, 0, 1))


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

## A glassy tube wandering along the path, dark with a pale rim.
static func _fulgurite(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array()
	var steps := 12
	for i in steps + 1:
		var y := box.position.y + box.size.y * i / steps
		var x := box.get_center().x + rng.randf_range(-0.5, 0.5) * box.size.x
		points.append(Vector2(x, y))
	var thick := maxf(0.04 * ppm, 2.0)
	canvas.draw_polyline(points, Color(0.85, 0.88, 0.8), thick * 1.6)
	canvas.draw_polyline(points, Color(0.2, 0.25, 0.22), thick)
	# A side branch or two.
	for b in 2:
		var from := points[rng.randi_range(2, steps - 2)]
		var to := from + Vector2(rng.randf_range(-1.0, 1.0) * 0.12 * ppm, rng.randf_range(0.04, 0.1) * ppm)
		canvas.draw_line(from, to, Color(0.2, 0.25, 0.22), thick * 0.6)


## A log turned to stone: banded brown and red along its length, knots across.
static func _petrified_wood(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	canvas.draw_rect(box, Color(0.42, 0.24, 0.16))
	var bands := 7
	for i in bands:
		var x := box.position.x + box.size.x * (i + 0.5) / bands
		var shade := Color(0.62, 0.32, 0.2) if i % 2 == 0 else Color(0.5, 0.42, 0.36)
		canvas.draw_line(Vector2(x, box.position.y), Vector2(x + rng.randf_range(-2.0, 2.0), box.end.y),
				shade, maxf(box.size.x / bands * 0.5, 1.0))
	for k in 2:
		var at := Vector2(box.get_center().x, box.position.y + box.size.y * rng.randf_range(0.2, 0.8))
		canvas.draw_circle(at, box.size.x * 0.18, Color(0.3, 0.16, 0.1))
		canvas.draw_circle(at, box.size.x * 0.08, Color(0.7, 0.45, 0.3))
	canvas.draw_rect(box, Color(0.25, 0.13, 0.08), false, 2.0)


## Iron oxide marbles: dark rusty balls with a pale highlight.
static func _concretions(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
	for i in 9:
		var r := rng.randf_range(0.02, 0.045) * ppm
		var at := box.position + Vector2(rng.randf() * box.size.x, rng.randf() * box.size.y)
		canvas.draw_circle(at, r, Color(0.28, 0.1, 0.05))
		canvas.draw_circle(at - Vector2(r, r) * 0.3, r * 0.35, Color(0.62, 0.3, 0.16))


## A sheet of white quartz crossing the Column at a slant: unwrapped round the
## Column, a slanted plane is a sine wave across the strip.
static func _quartz_vein(canvas: CanvasItem, box: Rect2, ppm: float, rng: RandomNumberGenerator) -> void:
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
		canvas.draw_circle(at, maxf(0.03 * ppm, 1.5), Color(0.5, 0.04, 0.1))
