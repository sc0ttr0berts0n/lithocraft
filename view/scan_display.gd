## Navigation's scan display, beside the moving map: the point cloud, drawn
## as one of three candidate views the developer flips between with a debug
## key until one is picked (DiveSimulation.scan_view(), the forward scope
## when a dive starts). Each shows the same things from the same queries: the
## vessel, the Course (dashed cyan), the projected path (solid cyan), the
## points and the Inferred Boundaries.
##
##   forward scope     the vessel's own vertical plane with ahead up the
##                     screen and range rings about the Head, as a
##                     forward-looking sonar's fan; a plumb line shows where
##                     down is, and a turn bends the way it does on the map
##   plan and section  a top-down view beside a side-on one, ahead to the
##                     right in both and at one scale; nothing in 3D
##   world-up 3D       the cloud seen from above the vessel's right side and
##                     a little behind, deeper always lower, turning only
##                     with the compass heading
##
## Every view is a flat drawing: a place in the world goes to a place on the
## screen by one plain function of where it lies from the Head and of the
## vessel's heading (scope_place(), plan_place(), section_place(),
## world_up_place()). So no view moves on its own: it changes only as the
## vessel's heading or path does, and the points stream past at exactly the
## simulation's speed. Drawn in 2D inside this SubViewport so a Station
## screen can show it as a texture.
##
## Reads only the simulation: scan_view() and scan_views() for the candidate;
## points(), point_age() and pulses_sent() for the cloud; inferred_boundaries()
## and patch_age() for the surfaces fitted to it; head_position(), heading()
## and heading_degrees() for the vessel; course_direction() for the Course;
## projected_path() for where this turn takes the vessel.
class_name ScanDisplay
extends SubViewport

## Each candidate's name on the screen.
const TITLES := {
	DiveSimulation.SCAN_VIEW_FORWARD_SCOPE: "FORWARD SCOPE",
	DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION: "PLAN + SECTION",
	DiveSimulation.SCAN_VIEW_WORLD_UP: "WORLD-UP 3D",
}
## Confidence colours: what is heard is what is happening now, white; a
## guess is the legend's grey, on its way to it. StationTheme's colours.
const DOUBTFUL := StationTheme.LEGEND_COLOUR
const CERTAIN := StationTheme.NOW_COLOUR
## A point on the screen: a square this many pixels on a side, a guess to a
## certainty, and how opaque (before it fades with age, never below the
## least, so an old echo still shows where it was).
const POINT_PX := Vector2(3.0, 6.0)
const POINT_ALPHA := Vector2(0.7, 1.0)
const POINT_LEAST_ALPHA := 0.3
## Seconds for a point to fade to about a third of its brightness: an old echo
## describes rock the vessel has since moved relative to.
const FADE_S := 90.0
## Inferred Boundary patches: their colour, how opaque a certain, fresh one's
## edge and face are (the face never solid, so points behind still show), and
## the least face, in square pixels, worth filling (seen edge-on a patch is
## only its edge).
const SURFACE_COLOUR := StationTheme.NOW_COLOUR
const SURFACE_EDGE_ALPHA := 0.9
const SURFACE_MOST_ALPHA := 0.3
const SURFACE_LEAST_FACE_PX := 12.0
## Range marks: a ring, a grid line or a tick of the plumb line every this
## many metres.
const TICK_M := 50.0
## The Course line: how far out it reaches, metres, its dashes in pixels, and
## its colour (cyan: what the crew has selected, apart from the vessel's
## white heading).
const COURSE_M := 300.0
const DASH_PX := 7.0
const COURSE_COLOUR := StationTheme.SELECTED_COLOUR
const VESSEL_COLOUR := StationTheme.NOW_COLOUR
## The vessel's heading line, metres, and its marker, pixels.
const HEADING_M := 45.0
const VESSEL_PX := 9.0
## The projected path, here and on the moving map: cyan, as what the crew has
## selected is (StationTheme).
const PROJECTED_PATH_COLOUR := StationTheme.SELECTED_COLOUR
## The projected path is worked out afresh every this many frames: it changes
## slowly, and running the turn forward is not free. The picture is redrawn
## every REDRAW_FRAMES.
const PROJECTED_PATH_FRAMES := 6
const REDRAW_FRAMES := 2

## The forward scope: the furthest range it shows ahead, metres, and how far
## down the pane the vessel sits (a share), leaving a little room behind it.
const SCOPE_RANGE_M := 260.0
const SCOPE_VESSEL_AT := 0.84
## The plan and section pair, side by side at one scale: the metres the
## section shows under the vessel, where the vessel sits across both and down
## the section (shares; in the plan it is half way down), and the plan's
## share of the width.
const PAIR_BELOW_M := 300.0
const PAIR_VESSEL_AT := Vector2(0.3, 0.2)
const PLAN_SHARE := 0.5
## The world-up view: the metres across it shows, where the vessel sits in
## it (shares), how far round from the vessel's right side toward its Tail
## the eye is, how far above level, degrees, and the radius of the level ring
## drawn round the vessel, metres.
const WORLD_SPAN_M := 460.0
const WORLD_VESSEL_AT := Vector2(0.42, 0.3)
const WORLD_ROUND_DEG := 12.0
const WORLD_ABOVE_DEG := 20.0
const WORLD_RING_M := 100.0
const WORLD_PLUMB_M := 300.0

const FONT_SIZE := StationTheme.FONT_SIZE_SMALL
const CAPTION_PX := 28.0

var sim: DiveSimulation

## The panes a view is drawn in (the pair uses both), each clipping what is
## drawn in it; and over them the caption and the panes' frames.
var _panes: Array[Control] = []
var _over := Control.new()
## The points drawn, refreshed only when a pulse changes the cloud, and the
## patches fitted to them.
var _points: Array[ScanPoint] = []
var _patches: Array[BoundaryPatch] = []
var _pulses_shown := -1
var _projected := PackedVector3Array()
var _frames_to_projection := 0
var _frames_to_redraw := 0


func _ready() -> void:
	disable_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var backing := ColorRect.new()
	backing.color = StationTheme.SCREEN_COLOUR
	backing.size = Vector2(size)
	add_child(backing)
	for i in 2:
		var pane := Control.new()
		pane.clip_contents = true
		add_child(pane)
		var canvas := Control.new()
		canvas.draw.connect(_draw_pane.bind(canvas, i))
		pane.add_child(canvas)
		_panes.append(pane)
	_over.size = Vector2(size)
	_over.draw.connect(_draw_over)
	add_child(_over)


func _process(_delta: float) -> void:
	if sim == null:
		return
	_frames_to_projection -= 1
	if _frames_to_projection <= 0:
		_frames_to_projection = PROJECTED_PATH_FRAMES
		_projected = sim.projected_path()
	if sim.pulses_sent() != _pulses_shown:
		_pulses_shown = sim.pulses_sent()
		_points = sim.points()
		_patches = sim.inferred_boundaries()
	_frames_to_redraw -= 1
	if _frames_to_redraw > 0:
		return
	_frames_to_redraw = REDRAW_FRAMES
	_lay_out_panes()
	for pane in _panes:
		pane.get_child(0).queue_redraw()
	_over.queue_redraw()


## The name a candidate view goes by on the screen.
static func title(view: StringName) -> String:
	return TITLES.get(view, "")


## The line over the picture: which candidate this is, of how many, and the
## debug key that flips to the next.
func caption() -> String:
	var views := sim.scan_views()
	return "%s  %d/%d  %s next" % [title(sim.scan_view()), views.find(sim.scan_view()) + 1,
			views.size(), KeyMap.label(&"scan_view")]


# --- Where a place in the world lies on the screen ---------------------------
# Each takes where the place lies from the Head (metres, the world frame) and
# gives where it is drawn from the vessel's marker: metres, x to the right of
# the screen, y down it.

## The forward scope: the vessel's vertical plane (the one through its
## heading and straight down) turned so ahead is up the screen. A place off
## that plane is drawn where it meets it square on, so a level surface is one
## line whatever the pitch. In a dive, onward along the compass heading is to
## the right, as on the moving map, so a turn bends the same way on both;
## down then swings round to the left as the vessel levels. `heading` is the
## way the Head points; `bearing_degrees` its compass heading.
static func scope_place(offset: Vector3, heading: Vector3, bearing_degrees: float) -> Vector2:
	var across := _right(bearing_degrees).cross(heading).normalized()
	return Vector2(offset.dot(across), -offset.dot(heading))


## The section: side-on from the vessel's right, distance ahead along the
## compass heading to the right, depth down.
static func section_place(offset: Vector3, bearing_degrees: float) -> Vector2:
	return Vector2(offset.dot(_onward(bearing_degrees)), -offset.y)


## The plan: from above, distance ahead along the compass heading to the
## right (as the section under it), the vessel's right down the screen.
static func plan_place(offset: Vector3, bearing_degrees: float) -> Vector2:
	return Vector2(offset.dot(_onward(bearing_degrees)), offset.dot(_right(bearing_degrees)))


## The world-up view: seen from above the vessel's right side and a little
## behind it, from far off (no perspective), up always up the screen. The eye
## goes round only with the compass heading.
static func world_up_place(offset: Vector3, bearing_degrees: float) -> Vector2:
	var around := deg_to_rad(WORLD_ROUND_DEG)
	var above := deg_to_rad(WORLD_ABOVE_DEG)
	var to_eye := (_right(bearing_degrees) * cos(around) - _onward(bearing_degrees) * sin(around)) * cos(above) \
			+ Vector3.UP * sin(above)
	var rightward := Vector3.UP.cross(to_eye).normalized()
	var upward := to_eye.cross(rightward)
	return Vector2(offset.dot(rightward), -offset.dot(upward))


## Level and along this compass heading (0 along -Z, 90 along +X).
static func _onward(bearing_degrees: float) -> Vector3:
	var bearing := deg_to_rad(bearing_degrees)
	return Vector3(sin(bearing), 0.0, -cos(bearing))


## Level and to the right of this compass heading.
static func _right(bearing_degrees: float) -> Vector3:
	var bearing := deg_to_rad(bearing_degrees)
	return Vector3(cos(bearing), 0.0, sin(bearing))


# --- Drawing -----------------------------------------------------------------

## Gives each pane its rectangle for the view shown: one pane under the
## caption, or for the pair the plan beside the section.
func _lay_out_panes() -> void:
	var whole := Rect2(0.0, CAPTION_PX, size.x, size.y - CAPTION_PX)
	var rects: Array[Rect2] = [whole, Rect2()]
	if sim.scan_view() == DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
		var plan := roundf(whole.size.x * PLAN_SHARE)
		rects[0] = Rect2(whole.position, Vector2(plan, whole.size.y))
		rects[1] = Rect2(whole.position + Vector2(plan, 0.0), Vector2(whole.size.x - plan, whole.size.y))
	for i in _panes.size():
		_panes[i].position = rects[i].position
		_panes[i].size = rects[i].size
		_panes[i].visible = rects[i].size.y > 0.0
		(_panes[i].get_child(0) as Control).size = rects[i].size


## The caption, and a rule round each pane.
func _draw_over() -> void:
	var font := ThemeDB.fallback_font
	_over.draw_string(font, Vector2(6.0, CAPTION_PX - 8.0), caption(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 12.0, FONT_SIZE, StationTheme.LEGEND_COLOUR)
	for pane in _panes:
		if pane.visible:
			_over.draw_rect(Rect2(pane.position, pane.size).grow(-1.0), StationTheme.RULE_COLOUR, false, 2.0)


func _draw_pane(canvas: Control, index: int) -> void:
	var area := canvas.size
	# Nothing to draw in until the panes are laid out.
	if sim == null or area.x < 2.0 * CAPTION_PX or area.y < 2.0 * CAPTION_PX:
		return
	var bearing := sim.heading_degrees()
	var heading := sim.heading()
	match sim.scan_view():
		DiveSimulation.SCAN_VIEW_FORWARD_SCOPE:
			var vessel := Vector2(area.x * 0.5, area.y * SCOPE_VESSEL_AT)
			var scale := (vessel.y - 22.0) / SCOPE_RANGE_M
			var place := func(offset: Vector3) -> Vector2:
				return vessel + scope_place(offset, heading, bearing) * scale
			_draw_scope_marks(canvas, vessel, scale, place)
			_draw_scan(canvas, place)
		DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
			var scale := area.y * (1.0 - PAIR_VESSEL_AT.y) / PAIR_BELOW_M
			if index == 0:
				var vessel := Vector2(area.x * PAIR_VESSEL_AT.x, area.y * 0.5)
				var place := func(offset: Vector3) -> Vector2:
					return vessel + plan_place(offset, bearing) * scale
				_draw_grid(canvas, vessel, scale, false)
				_label(canvas, Vector2(8.0, FONT_SIZE + 4.0), "PLAN")
				_draw_scan(canvas, place)
			else:
				var vessel := Vector2(area.x * PAIR_VESSEL_AT.x, area.y * PAIR_VESSEL_AT.y)
				var place := func(offset: Vector3) -> Vector2:
					return vessel + section_place(offset, bearing) * scale
				_draw_grid(canvas, vessel, scale, true)
				_label(canvas, Vector2(8.0, FONT_SIZE + 4.0), "SECTION")
				_draw_scan(canvas, place)
		DiveSimulation.SCAN_VIEW_WORLD_UP:
			var vessel := area * WORLD_VESSEL_AT
			var scale := area.x / WORLD_SPAN_M
			var place := func(offset: Vector3) -> Vector2:
				return vessel + world_up_place(offset, bearing) * scale
			_draw_world_marks(canvas, place)
			_draw_scan(canvas, place)


## What every view shows, through its own `place` (a place from the Head, in
## metres, to the pane's pixels): the Inferred Boundaries, the points, the
## Course, the projected path and the vessel, in that order, so the vessel
## and what the crew has selected are never under the rock.
func _draw_scan(canvas: Control, place: Callable) -> void:
	var head := sim.head_position()
	for patch in _patches:
		var sureness := patch.confidence * exp(-sim.patch_age(patch) / FADE_S)
		var corners := PackedVector2Array()
		for corner in patch.corners():
			corners.append(place.call(corner - head))
		if _face(corners) >= SURFACE_LEAST_FACE_PX:
			canvas.draw_colored_polygon(corners, StationTheme.faded(SURFACE_COLOUR, SURFACE_MOST_ALPHA * sureness))
		corners.append(corners[0])
		canvas.draw_polyline(corners, StationTheme.faded(SURFACE_COLOUR,
				SURFACE_EDGE_ALPHA * maxf(sureness, POINT_LEAST_ALPHA)), 1.5)

	var within := Rect2(Vector2.ZERO, canvas.size).grow(POINT_PX.y)
	for point in _points:
		var at: Vector2 = place.call(point.position - head)
		if not within.has_point(at):
			continue
		var colour := DOUBTFUL.lerp(CERTAIN, point.confidence)
		colour.a = maxf(lerpf(POINT_ALPHA.x, POINT_ALPHA.y, point.confidence)
				* exp(-sim.point_age(point) / FADE_S), POINT_LEAST_ALPHA)
		var side := roundf(lerpf(POINT_PX.x, POINT_PX.y, point.confidence))
		canvas.draw_rect(Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), colour)

	var vessel: Vector2 = place.call(Vector3.ZERO)
	_dashes(canvas, vessel, place.call(sim.course_direction() * COURSE_M), COURSE_COLOUR)
	var coming := PackedVector2Array()
	for step in _projected:
		coming.append(place.call(step - head))
	if coming.size() > 1:
		canvas.draw_polyline(coming, PROJECTED_PATH_COLOUR, 2.5)
	_draw_vessel(canvas, vessel, place.call(sim.heading() * HEADING_M))


## The vessel: its heading line and an arrowhead along it; seen end-on (the
## plan, diving straight down) a ring, since it points nowhere on the screen.
func _draw_vessel(canvas: Control, vessel: Vector2, heading_end: Vector2) -> void:
	var along := heading_end - vessel
	if along.length() < VESSEL_PX:
		canvas.draw_arc(vessel, VESSEL_PX * 0.7, 0.0, TAU, 20, VESSEL_COLOUR, 2.5)
		canvas.draw_circle(vessel, 2.0, VESSEL_COLOUR)
		return
	canvas.draw_line(vessel, heading_end, VESSEL_COLOUR, 2.0)
	var facing := along.normalized()
	var side := Vector2(-facing.y, facing.x)
	canvas.draw_colored_polygon(PackedVector2Array([vessel + facing * VESSEL_PX,
			vessel - facing * VESSEL_PX * 0.6 + side * VESSEL_PX * 0.6,
			vessel - facing * VESSEL_PX * 0.6 - side * VESSEL_PX * 0.6]), VESSEL_COLOUR)


## The forward scope's marks: range rings about the Head, each with its
## range, the fan's centre line, and a plumb line to where down is.
func _draw_scope_marks(canvas: Control, vessel: Vector2, scale: float, place: Callable) -> void:
	for ring in range(1, ceili(canvas.size.length() / (TICK_M * scale))):
		var range_m := ring * TICK_M
		canvas.draw_arc(vessel, range_m * scale, 0.0, TAU, 96, StationTheme.RULE_COLOUR, 1.5)
		if ring % 2 == 0 and vessel.x + range_m * scale < canvas.size.x:
			_label(canvas, vessel + Vector2(range_m * scale - 56.0, FONT_SIZE), "%d m" % roundi(range_m))
	canvas.draw_line(Vector2(vessel.x, 0.0), Vector2(vessel.x, canvas.size.y), StationTheme.RULE_COLOUR, 1.0)
	_label(canvas, Vector2(vessel.x + 8.0, FONT_SIZE + 4.0), "AHEAD")
	# Where straight down lies: a tick mark on each ring it crosses.
	var down: Vector2 = (place.call(Vector3.DOWN) as Vector2) - vessel
	if down.length() > 0.0:
		down = down.normalized()
		var reach := (SCOPE_RANGE_M - TICK_M * 0.5) * scale
		canvas.draw_line(vessel, vessel + down * reach, StationTheme.LEGEND_COLOUR, 1.0)
		var square := Vector2(-down.y, down.x)
		for tick in range(1, floori(reach / (TICK_M * scale)) + 1):
			canvas.draw_line(vessel + down * tick * TICK_M * scale - square * 5.0,
					vessel + down * tick * TICK_M * scale + square * 5.0, StationTheme.LEGEND_COLOUR, 1.5)
		var label_at := vessel + down * reach + Vector2(-66.0, 6.0)
		label_at.x = clampf(label_at.x, 6.0, canvas.size.x - 64.0)
		label_at.y = clampf(label_at.y, 2.0 * FONT_SIZE + 6.0, canvas.size.y - 6.0)
		_label(canvas, label_at, "DOWN")


## The pair's grid: a line every TICK_M ahead and behind the Head, the same
## in the plan and the section so the eye carries between them; in the
## section a line at every TICK_M of depth with its depth, and the surface.
func _draw_grid(canvas: Control, vessel: Vector2, scale: float, section: bool) -> void:
	var faint := StationTheme.RULE_COLOUR
	var steps := ceili(canvas.size.x / (TICK_M * scale)) + 1
	for i in range(-steps, steps + 1):
		var x := vessel.x + i * TICK_M * scale
		canvas.draw_line(Vector2(x, 0.0), Vector2(x, canvas.size.y), faint, 2.0 if i == 0 else 1.0)
	if not section:
		canvas.draw_line(Vector2(0.0, vessel.y), Vector2(canvas.size.x, vessel.y), faint, 1.0)
		return
	var depth := -sim.head_position().y
	var first := floori((depth - vessel.y / scale) / TICK_M)
	for line in range(maxi(first, 0), first + ceili(canvas.size.y / (TICK_M * scale)) + 2):
		var line_depth := line * TICK_M
		var y := vessel.y + (line_depth - depth) * scale
		if line == 0:
			canvas.draw_rect(Rect2(0.0, 0.0, canvas.size.x, y), StationTheme.SURFACEWARD_COLOUR)
			canvas.draw_line(Vector2(0.0, y), Vector2(canvas.size.x, y), StationTheme.LEGEND_COLOUR, 2.0)
			_label(canvas, Vector2(canvas.size.x - 84.0, y - 5.0), "surface")
			continue
		canvas.draw_line(Vector2(0.0, y), Vector2(canvas.size.x, y), faint, 1.0)
		if line % 2 == 0:
			_label(canvas, Vector2(8.0, y - 4.0), "%d m" % roundi(line_depth))


## The world-up view's marks: a level ring round the vessel with north on it
## (it goes round as the compass heading does), and a plumb line under the
## vessel with a tick every TICK_M, to read depth by and to show which way is
## down.
func _draw_world_marks(canvas: Control, place: Callable) -> void:
	var ring := PackedVector2Array()
	for i in 65:
		var angle := TAU * i / 64.0
		ring.append(place.call(Vector3(sin(angle), 0.0, -cos(angle)) * WORLD_RING_M))
	canvas.draw_polyline(ring, StationTheme.RULE_COLOUR, 1.5)
	var north: Vector2 = place.call(Vector3.FORWARD * WORLD_RING_M)
	canvas.draw_line(place.call(Vector3.FORWARD * WORLD_RING_M * 0.85), north, StationTheme.LEGEND_COLOUR, 2.0)
	_label(canvas, (place.call(Vector3.FORWARD * WORLD_RING_M * 1.15) as Vector2) + Vector2(-5.0, 7.0), "N")
	var vessel: Vector2 = place.call(Vector3.ZERO)
	var foot: Vector2 = place.call(Vector3.DOWN * WORLD_PLUMB_M)
	canvas.draw_line(vessel, foot, StationTheme.LEGEND_COLOUR, 1.0)
	for tick in range(1, floori(WORLD_PLUMB_M / TICK_M) + 1):
		var at: Vector2 = place.call(Vector3.DOWN * tick * TICK_M)
		canvas.draw_line(at - Vector2(6.0, 0.0), at + Vector2(6.0, 0.0), StationTheme.LEGEND_COLOUR, 1.5)
		if tick % 2 == 0:
			_label(canvas, at + Vector2(10.0, 6.0), "+%d m" % roundi(tick * TICK_M))
	_label(canvas, foot + Vector2(-22.0, FONT_SIZE + 2.0), "DOWN")


func _label(canvas: Control, at: Vector2, text: String) -> void:
	canvas.draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE,
			StationTheme.LEGEND_COLOUR)


## The area a four-cornered outline covers on the screen, square pixels.
static func _face(corners: PackedVector2Array) -> float:
	var twice := 0.0
	for i in corners.size():
		twice += corners[i].cross(corners[(i + 1) % corners.size()])
	return absf(twice) * 0.5


func _dashes(canvas: Control, from: Vector2, to: Vector2, colour: Color) -> void:
	var length := from.distance_to(to)
	for dash in ceili(length / (2.0 * DASH_PX)):
		var along := dash * 2.0 * DASH_PX
		canvas.draw_line(from.lerp(to, along / length), from.lerp(to, minf(along + DASH_PX, length) / length),
				colour, 2.0)
