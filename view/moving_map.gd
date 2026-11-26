## Navigation's moving map, beside the point cloud: a side-on cross-section
## of the whole dive, depth down the screen against distance across it, at
## one scale both ways so the path's shape is true. It shows the surface, the
## path behind (the remembered path, a perfect record), the Course ahead, the
## Inferred Boundaries (fitted to the point cloud alone; never the layout)
## and the Orders' target depth. Drawn in 2D inside this SubViewport
## so a Station screen can show it as a texture.
##
## Across is distance over the ground along the track, unrolled: the path's
## turns in heading are straightened out, as a profile along a route is. A
## patch of an Inferred Boundary is placed across by how far ahead of the
## Head its corners lie along the heading now.
##
## Reads only the simulation: remembered_path(), head_position(), heading(),
## heading_degrees(), course_direction(), target_depth() and
## inferred_boundaries().
class_name MovingMap
extends SubViewport

## Seconds between redraws: the map moves slowly at its scale.
const REDRAW_S := 0.25
## The least depth the map spans, metres, so the dive's start is not drawn
## absurdly large; the spans it steps through as the dive grows, so the scale
## holds while the dive grows a little; and the room it keeps beyond what it
## shows, as a share.
const LEAST_SPAN_M := 150.0
const SPANS_M: Array[float] = [100.0, 200.0, 300.0, 500.0, 750.0, 1000.0, 1500.0, 2000.0,
		3000.0, 5000.0, 7500.0]
const HEADROOM := 1.1
## Depth ticks: the steps they may come in, and the most on the map.
const TICKS_M: Array[float] = [25.0, 50.0, 100.0, 200.0, 250.0, 500.0, 1000.0, 2000.0, 2500.0, 5000.0]
const MOST_TICKS := 5
## The drawing area's margins in pixels: room on the left for the depth
## labels, above for the sky and the surface's label.
const MARGIN_LEFT := 44.0
const MARGIN_TOP := 18.0
const MARGIN_RIGHT := 8.0
const MARGIN_BOTTOM := 6.0
const FONT_SIZE := 13
const DASH_PX := 6.0

const BACKGROUND := Color(0.01, 0.015, 0.025)
const SKY := Color(0.05, 0.07, 0.1)
const SURFACE_COLOUR := Color(0.85, 0.72, 0.5)
const TICK_COLOUR := Color(0.45, 0.55, 0.65)
const TARGET_COLOUR := Color(0.55, 1.0, 0.55)

var sim: DiveSimulation

var _canvas := Control.new()
var _until_redraw := 0.0


func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_canvas.size = Vector2(size)
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)


func _process(delta: float) -> void:
	if sim == null:
		return
	_until_redraw -= delta
	if _until_redraw > 0.0:
		return
	_until_redraw = REDRAW_S
	_canvas.queue_redraw()


## The path unrolled into the cross-section: each (metres along the path,
## depth) of the remembered path as (metres across, depth), across growing by
## each piece's run over the ground.
static func profile(path: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(path.size())
	var across := 0.0
	for i in path.size():
		if i > 0:
			var along := path[i].x - path[i - 1].x
			var down := path[i].y - path[i - 1].y
			across += sqrt(maxf(along * along - down * down, 0.0))
		out[i] = Vector2(across, path[i].y)
	return out


## Where a world position lies across the map: the Head's place across
## (head_across) plus how far ahead of the Head it lies along the compass
## heading (degrees, 0 along -Z, 90 along +X).
static func across(position: Vector3, head: Vector3, head_across: float, heading_degrees: float) -> float:
	var bearing := deg_to_rad(heading_degrees)
	var ahead := Vector3(sin(bearing), 0.0, -cos(bearing))
	return head_across + (position - head).dot(ahead)


## A patch of an Inferred Boundary seen side-on: its ends on the map, each
## (metres across, depth), the nearer first. Its corners are placed across
## as across() places them, and the patch runs between the nearest and the
## furthest, so a sloping patch is drawn sloping.
static func side_on(patch: BoundaryPatch, head: Vector3, head_across: float,
		heading_degrees: float) -> PackedVector2Array:
	var near := Vector2(INF, 0.0)
	var far := Vector2(-INF, 0.0)
	for corner in patch.corners():
		var x := across(corner, head, head_across, heading_degrees)
		if x < near.x:
			near = Vector2(x, -corner.y)
		if x > far.x:
			far = Vector2(x, -corner.y)
	return PackedVector2Array([near, far])


## The depth the map spans to show this much (metres, or the depth matching
## the width across it): a step of SPANS_M with room to spare.
static func span_for(needed: float) -> float:
	var wanted := maxf(needed, LEAST_SPAN_M) * HEADROOM
	for span in SPANS_M:
		if span >= wanted:
			return span
	var span: float = SPANS_M.back()
	while span < wanted:
		span *= 2.0
	return span


func _draw_map() -> void:
	var whole := Vector2(size)
	var area := Rect2(MARGIN_LEFT, MARGIN_TOP, whole.x - MARGIN_LEFT - MARGIN_RIGHT,
			whole.y - MARGIN_TOP - MARGIN_BOTTOM)
	_canvas.draw_rect(Rect2(Vector2.ZERO, whole), BACKGROUND)
	_canvas.draw_rect(Rect2(0.0, 0.0, whole.x, MARGIN_TOP), SKY)

	var path := profile(sim.remembered_path())
	var head_across := path[path.size() - 1].x
	var patches := sim.inferred_boundaries()
	var sides: Array[PackedVector2Array] = []
	for patch in patches:
		sides.append(side_on(patch, sim.head_position(), head_across, sim.heading_degrees()))
	var target := sim.target_depth()

	# Fit the whole dive: the path, the Boundaries heard (some lie behind
	# where it began), the target.
	var deepest := 0.0
	var leftmost := 0.0
	var widest := 0.0
	for p in path:
		deepest = maxf(deepest, p.y)
		widest = maxf(widest, p.x)
	for side in sides:
		deepest = maxf(deepest, maxf(side[0].y, side[1].y))
		leftmost = minf(leftmost, side[0].x)
		widest = maxf(widest, side[1].x)
	if not is_nan(target):
		deepest = maxf(deepest, target)
	var span := span_for(maxf(deepest, (widest - leftmost) * area.size.y / area.size.x))
	var scale := area.size.y / span
	var at := func(across_m: float, depth_m: float) -> Vector2:
		return area.position + Vector2(across_m - leftmost, depth_m) * scale

	_draw_ticks(area, span, scale)
	var font := ThemeDB.fallback_font
	_canvas.draw_line(Vector2(area.position.x, area.position.y), Vector2(area.end.x, area.position.y),
			SURFACE_COLOUR, 2.0)
	_canvas.draw_string(font, Vector2(area.end.x - 60.0, area.position.y - 4.0), "surface",
			HORIZONTAL_ALIGNMENT_RIGHT, 60.0, FONT_SIZE, SURFACE_COLOUR)

	if not is_nan(target):
		var y: float = at.call(0.0, target).y
		_dashes(Vector2(area.position.x, y), Vector2(area.end.x, y), TARGET_COLOUR)
		_canvas.draw_string(font, Vector2(area.end.x - 120.0, y - 3.0), "target %d m" % roundi(target),
				HORIZONTAL_ALIGNMENT_RIGHT, 120.0, FONT_SIZE, TARGET_COLOUR)

	# Over the target: a Boundary heard at the target depth shows. As sure
	# as its patch; the map keeps what was heard, so it does not fade.
	for i in patches.size():
		var sureness := patches[i].confidence
		var colour := ScanDisplay.DOUBTFUL.lerp(ScanDisplay.CERTAIN, sureness)
		colour.a = lerpf(0.3, 1.0, sureness)
		var from: Vector2 = at.call(sides[i][0].x, sides[i][0].y)
		var to: Vector2 = at.call(sides[i][1].x, sides[i][1].y)
		_canvas.draw_line(from, Vector2(maxf(to.x, from.x + 2.0), to.y), colour, 2.0)

	var drawn := PackedVector2Array()
	for p in path:
		drawn.append(at.call(p.x, p.y))
	if drawn.size() > 1:
		_canvas.draw_polyline(drawn, ScanDisplay.VESSEL_COLOUR, 2.0)

	var vessel: Vector2 = drawn[drawn.size() - 1]
	_dashes(vessel, _to_edge(vessel, _side_on(sim.course_direction()), area), ScanDisplay.COURSE_COLOUR)
	var facing := _side_on(sim.heading())
	var side := Vector2(-facing.y, facing.x)
	_canvas.draw_colored_polygon(PackedVector2Array([vessel + facing * 7.0,
			vessel - facing * 4.0 + side * 4.0, vessel - facing * 4.0 - side * 4.0]), ScanDisplay.VESSEL_COLOUR)


## A world direction as the map draws it, unit length: across by its run
## over the ground (always onward, as the track is unrolled), down by depth.
static func _side_on(direction: Vector3) -> Vector2:
	return Vector2(Vector2(direction.x, direction.z).length(), -direction.y).normalized()


func _draw_ticks(area: Rect2, span: float, scale: float) -> void:
	var step: float = TICKS_M.back()
	for t in TICKS_M:
		if span / t <= MOST_TICKS:
			step = t
			break
	var font := ThemeDB.fallback_font
	var depth := step
	while depth < span:
		var y := area.position.y + depth * scale
		_canvas.draw_line(Vector2(area.position.x - 4.0, y), Vector2(area.position.x, y), TICK_COLOUR, 1.0)
		_canvas.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), Color(TICK_COLOUR, 0.12), 1.0)
		_canvas.draw_string(font, Vector2(0.0, y + FONT_SIZE * 0.35), "%d m" % roundi(depth),
				HORIZONTAL_ALIGNMENT_RIGHT, area.position.x - 6.0, FONT_SIZE, TICK_COLOUR)
		depth += step


## Where a ray from inside the area leaves it.
static func _to_edge(from: Vector2, way: Vector2, area: Rect2) -> Vector2:
	var reach := INF
	if way.x > 0.0:
		reach = minf(reach, (area.end.x - from.x) / way.x)
	elif way.x < 0.0:
		reach = minf(reach, (area.position.x - from.x) / way.x)
	if way.y > 0.0:
		reach = minf(reach, (area.end.y - from.y) / way.y)
	elif way.y < 0.0:
		reach = minf(reach, (area.position.y - from.y) / way.y)
	return from + way * maxf(reach, 0.0)


func _dashes(from: Vector2, to: Vector2, colour: Color) -> void:
	var length := from.distance_to(to)
	var along := 0.0
	while along < length:
		_canvas.draw_line(from.lerp(to, along / length), from.lerp(to, minf(along + DASH_PX, length) / length),
				colour, 1.5)
		along += 2.0 * DASH_PX
