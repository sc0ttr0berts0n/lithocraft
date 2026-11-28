## Navigation's scan display, beside the moving map: the point cloud, drawn
## as one of three candidate views the developer flips between with a debug
## key until one is picked (DiveSimulation.scan_view(), the forward scope
## when a dive starts). Each shows the same things from the same queries: the
## vessel, the Course (dashed cyan), the projected path (solid cyan), the
## Beam's cone at its width (faint cyan, out to its reach), a running Sweep's
## progress (green: the spiral swept so far and its leading edge), the points
## (surface control's survey hollow and fainter than the vessel's own) and
## the Inferred Boundaries, with the rock beyond each as the scan estimates
## it (a band hatched for harder rock, stippled for softer) and surface
## control's names for the rocks it expects; labels in the lower left name
## the Beam's width and the Sweep's range and progress; Navigation's
## status lines say what lies beyond the Boundary ahead (rock_label()).
## Aimed off the vessel's axis, the Beam's cone is drawn about its aim, with
## a small diamond (_draw_aim()) along it and the aim in the Beam's label.
## Each target the Orders name is a fuzzy cyan region where the scan has it
## (_draw_targets()), denser toward its middle and named as the Orders name
## it ("TARGET A"), narrowing as the points heard from it do.
##
##   forward scope     the vessel's own vertical plane with ahead up the
##                     screen and range rings about the Head, as a
##                     forward-looking sonar's fan; a plumb line shows where
##                     down is, and a turn bends the way it does on the map;
##                     its range steps (SCOPE_RANGES_M) to keep the nearest
##                     Inferred Boundary ahead in view, only on a pulse
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
## points(), point_age() and scan_revision() for the cloud; inferred_boundaries()
## and patch_age() for the surfaces fitted to it (and BoundaryFit.ahead() of
## them for the scope's range); beam_width(), beam_half_angle() and
## beam_reach(), beam_aim() and beam_axis() for the Beam's cone;
## sweep_running(), sweep_range(),
## sweep_progress(), sweep_time_left(), sweep_from_angle(),
## sweep_reached_angle(), sweep_axis() and sweep_origin() for the Sweep;
## rock_ahead(), rock_ahead_confidence() and expected_rocks() for the rock;
## head_position(), heading()
## and heading_degrees() for the vessel; course_direction() for the Course;
## projected_path() for where this turn takes the vessel; target_regions()
## for the targets, fetched with the points.
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
## A point of surface control's survey (ScanPoint.surveyed): a hollow square
## of the legend's grey, this many pixels on a side and this opaque, fainter
## than any of the vessel's own echoes and never filled, so the crew sees
## where its own scan has replaced the survey.
const SURVEY_PX := 5.0
const SURVEY_ALPHA := 0.45
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
## Range marks: a grid line or a tick of the plumb line every this many
## metres (the forward scope's rings go with its range, SCOPE_RANGES_M).
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
## The projected path is worked out afresh every this many frames: it changes
## slowly, and running the turn forward is not free. The picture is redrawn
## every REDRAW_FRAMES.
const PROJECTED_PATH_FRAMES := 15
const REDRAW_FRAMES := 2

## The forward scope: the ranges it steps between, the furthest it shows
## ahead, metres, each with its ring spacing, nearest first; the share of a
## range the nearest Inferred Boundary ahead may lie at before the scope steps
## out to the next; and how far down the pane the vessel sits (a share),
## leaving a little room behind it. With no Boundary ahead it shows the
## furthest. The vessel's heading line is a share of the range.
const SCOPE_RANGES_M: Array[Vector2] = [Vector2(60.0, 10.0), Vector2(120.0, 25.0), Vector2(260.0, 50.0)]
const SCOPE_KEEP_SHARE := 0.75
const SCOPE_VESSEL_AT := 0.84
const SCOPE_HEADING_SHARE := 0.12
## The Beam's cone: drawn faint, what the crew has selected; its edges reach
## to the Beam's reach.
const BEAM_COLOUR := StationTheme.SELECTED_COLOUR
const BEAM_ALPHA := 0.45
## The aim's marker, drawn only while the Beam is aimed off the vessel's
## axis: a hollow diamond this many pixels from the Head along the aim (at
## any view's scale), this many pixels from its centre to a point. Seen
## end-on, the aim is the diamond about the Head.
const AIM_MARK_AT_PX := 46.0
const AIM_MARK_PX := 7.0
## A running Sweep: green, a system at work; the spiral swept so far filled
## this faint, its leading edge this strong.
const SWEEP_COLOUR := StationTheme.ENGAGED_COLOUR
const SWEEP_FILL_ALPHA := 0.12
const SWEEP_EDGE_ALPHA := 0.8
## How opaque the backdrop under the labels in the lower left is.
const LABEL_BACKDROP_ALPHA := 0.85
## A target's region: cyan, what the crew aims for; drawn as nested outlines
## of the region scaled by these shares, each filled this faint, so it builds
## up toward the middle and fades out at its edge, with its outermost rim at
## this strength.
const TARGET_COLOUR := StationTheme.SELECTED_COLOUR
const TARGET_SHARES: Array[float] = [1.0, 0.8, 0.6, 0.4]
const TARGET_FILL_ALPHA := 0.08
const TARGET_RIM_ALPHA := 0.35
## How finely a region's ellipsoid is sampled for its outline on the screen:
## rings of latitude and points round each.
const TARGET_RINGS := 7
const TARGET_ROUND := 16
## The rock beyond each Inferred Boundary, as the scan estimates it against
## the rock on the Head's side (BoundaryPatch.beyond()): a band this many
## pixels deep, straight down or up the screen, on the far side of the patch
## (a fixed depth on the screen, so it reads at every range and scale), hatched with strokes through it
## where the rock beyond is harder and denser and stippled with dots where it
## is softer and more porous, as a geological section draws hard rock and
## sand; more marks the stronger the contrast (ROCK_MARKS, by ROCK_DEGREES),
## none under ROCK_SAME. Drawn in the points' colours, white as the patch is
## sure and the legend's grey as it is a guess, so it says nothing the
## colour language keeps for cautions; a stroke seen end-on (the plan) is a
## short slant of ROCK_TICK_PX, so it still differs from a dot.
const ROCK_BAND_PX := 16.0
const ROCK_SAME := 0.05
const ROCK_DEGREES: Array[float] = [0.15, 0.4]
const ROCK_MARKS: Array[int] = [3, 5, 7]
const ROCK_ALPHA := 0.8
const ROCK_LEAST_ALPHA := 0.3
const ROCK_TICK_PX := 6.0
const ROCK_DOT_PX := 3.0
## Surface control's names are written at the right of the pane, just into
## the rock below the Boundary, on a backdrop this opaque.
const EXPECTED_BACKDROP_ALPHA := 0.7
## The plan and section pair, side by side at one scale: the metres the
## section shows under the vessel, where the vessel sits across both and down
## the section (shares; in the plan it is half way down), and the plan's
## share of the width.
const PAIR_BELOW_M := 300.0
const PAIR_VESSEL_AT := Vector2(0.3, 0.2)
const PLAN_SHARE := 0.5
## The world-up view: the metres it shows across and under the vessel
## (whichever asks the smaller scale), where the vessel sits in it (shares),
## how far round from the vessel's right side toward its Tail
## the eye is, how far above level, degrees, and the radius of the level ring
## drawn round the vessel, metres.
const WORLD_SPAN_M := 460.0
const WORLD_BELOW_M := 250.0
const WORLD_VESSEL_AT := Vector2(0.42, 0.24)
const WORLD_ROUND_DEG := 12.0
const WORLD_ABOVE_DEG := 20.0
const WORLD_RING_M := 100.0
const WORLD_PLUMB_M := 200.0

const FONT_SIZE := StationTheme.FONT_SIZE_SMALL
const CAPTION_PX := 28.0

var sim: DiveSimulation

## The panes a view is drawn in (the pair uses both), each clipping what is
## drawn in it; and over them the caption and the panes' frames.
var _panes: Array[Control] = []
var _over := Control.new()
## The points drawn, refreshed only when the cloud changes (a pulse, or a
## batch of a Sweep's points), and the patches fitted to them.
var _points: Array[ScanPoint] = []
var _patches: Array[BoundaryPatch] = []
var _regions: Array[TargetRegion] = []
var _revision_shown := -1
## The forward scope's range and ring spacing, metres (one of
## SCOPE_RANGES_M), stepped only when the scan changes.
var _scope := SCOPE_RANGES_M[-1]
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
	if sim.scan_revision() != _revision_shown:
		_revision_shown = sim.scan_revision()
		_points = sim.points()
		_patches = sim.inferred_boundaries()
		_regions = sim.target_regions()
		_scope = scope_range(BoundaryFit.ahead(_patches, sim.head_position(), sim.heading()).x)
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


## The Beam's width and cone, written in the display's lower left corner over
## every view: "BEAM NARROW 30 deg", with its aim once it is aimed off the
## vessel's axis: "BEAM NARROW 30 deg  AIM R45 U15".
func beam_label() -> String:
	var label := "BEAM %s %d deg" % [String(sim.beam_width()).to_upper(), roundi(2.0 * sim.beam_half_angle())]
	return label if sim.beam_aim() == Vector2.ZERO else "%s  AIM %s" % [label, aim_words(sim.beam_aim())]


## The Beam's aim (DiveSimulation.beam_aim()) in words: how far to the
## vessel's right (R) or left (L), then toward its top (U) or underside (D),
## each left out when nothing; "AHEAD" when it is dead ahead.
static func aim_words(aim: Vector2) -> String:
	var words := PackedStringArray()
	if roundi(aim.x) != 0:
		words.append("%s%d" % ["R" if aim.x > 0.0 else "L", absi(roundi(aim.x))])
	if roundi(aim.y) != 0:
		words.append("%s%d" % ["U" if aim.y > 0.0 else "D", absi(roundi(aim.y))])
	return "AHEAD" if words.is_empty() else " ".join(words)


## The Sweep's range and how far it has got, written over every view above
## the Beam's label: "SWEEP 200 m  45%  1:06 left" while one runs, else its
## range, how long it would take and the key that starts it.
func sweep_label() -> String:
	if sim.sweep_running():
		return "SWEEP %d m  %d%%  %s left" % [roundi(sim.sweep_range()),
				floori(sim.sweep_progress() * 100.0), _minutes(sim.sweep_time_left())]
	return "SWEEP %d m  %s  %s start" % [roundi(sim.sweep_range()), _minutes(sim.sweep_duration()),
			KeyMap.label(&"sweep")]


## Seconds as minutes and seconds: "1:06".
static func _minutes(seconds: float) -> String:
	var whole := ceili(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


## The forward scope's range for an Inferred Boundary this many metres ahead
## along the heading (INF for none): the nearest of SCOPE_RANGES_M that holds
## it within SCOPE_KEEP_SHARE of its reach, or the furthest. Vector2(range,
## ring spacing), metres.
static func scope_range(boundary_ahead_m: float) -> Vector2:
	for scope in SCOPE_RANGES_M:
		if boundary_ahead_m <= scope.x * SCOPE_KEEP_SHARE:
			return scope
	return SCOPE_RANGES_M[-1]


## The forward scope's range shown now and its ring spacing, metres: changed
## only when the scan changes, never between pulses.
func scope_shown() -> Vector2:
	return _scope


## Pixels per metre on the forward scope, in a pane this big, at this range.
static func scope_scale(pane: Vector2, range_m: float) -> float:
	return (pane.y * SCOPE_VESSEL_AT - 22.0) / range_m


## The size of the pane a single-pane view (the forward scope, world-up) is
## drawn in: the whole display under the caption.
func single_pane() -> Vector2:
	return Vector2(size.x, size.y - CAPTION_PX)


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


## The caption, the Sweep's and the Beam's labels, and a rule round each pane.
func _draw_over() -> void:
	var font := ThemeDB.fallback_font
	_over.draw_string(font, Vector2(6.0, CAPTION_PX - 8.0), caption(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 12.0, FONT_SIZE, StationTheme.LEGEND_COLOUR)
	# The two labels on the screen's own backdrop, so the points never hide them.
	var labels := [[sweep_label(), SWEEP_COLOUR if sim.sweep_running() else StationTheme.SELECTED_COLOUR],
			[beam_label(), StationTheme.SELECTED_COLOUR]]
	var widest := 0.0
	for label: Array in labels:
		widest = maxf(widest, font.get_string_size(label[0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	var line := FONT_SIZE + 4.0
	_over.draw_rect(Rect2(4.0, size.y - 4.0 - line * labels.size(), widest + 8.0, line * labels.size()),
			StationTheme.faded(StationTheme.SCREEN_COLOUR, LABEL_BACKDROP_ALPHA))
	for i in labels.size():
		_over.draw_string(font, Vector2(8.0, size.y - 8.0 - line * (labels.size() - 1 - i)), labels[i][0],
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 16.0, FONT_SIZE, labels[i][1])
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
			var scale := scope_scale(area, _scope.x)
			var place := func(offset: Vector3) -> Vector2:
				return vessel + scope_place(offset, heading, bearing) * scale
			_draw_scope_marks(canvas, vessel, scale, place)
			_draw_scan(canvas, place, _scope.x * SCOPE_HEADING_SHARE)
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
			var scale := minf(area.x / WORLD_SPAN_M, area.y * (1.0 - WORLD_VESSEL_AT.y) / WORLD_BELOW_M)
			var place := func(offset: Vector3) -> Vector2:
				return vessel + world_up_place(offset, bearing) * scale
			_draw_world_marks(canvas, place)
			_draw_scan(canvas, place)


## What every view shows, through its own `place` (a place from the Head, in
## metres, to the pane's pixels): the Inferred Boundaries, the points, the
## Course, the projected path and the vessel, in that order, so the vessel
## and what the crew has selected are never under the rock; the Beam's cone
## and the Sweep's progress first, under everything. The vessel's heading line is `heading_m` long.
func _draw_scan(canvas: Control, place: Callable, heading_m := HEADING_M) -> void:
	var head := sim.head_position()
	_draw_beam(canvas, place)
	_draw_sweep(canvas, place)
	_draw_targets(canvas, place)
	var rock_band := _rock_band(place)
	for patch in _patches:
		var sureness := patch.confidence * exp(-sim.patch_age(patch) / FADE_S)
		var corners := PackedVector2Array()
		for corner in patch.corners():
			corners.append(place.call(corner - head))
		_draw_rock_beyond(canvas, patch, corners, sureness, rock_band)
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
		if point.surveyed:
			canvas.draw_rect(Rect2(at - Vector2.ONE * SURVEY_PX * 0.5, Vector2.ONE * SURVEY_PX),
					StationTheme.faded(DOUBTFUL, SURVEY_ALPHA), false, 1.0)
			continue
		var colour := DOUBTFUL.lerp(CERTAIN, point.confidence)
		colour.a = maxf(lerpf(POINT_ALPHA.x, POINT_ALPHA.y, point.confidence)
				* exp(-sim.point_age(point) / FADE_S), POINT_LEAST_ALPHA)
		var side := roundf(lerpf(POINT_PX.x, POINT_PX.y, point.confidence))
		canvas.draw_rect(Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), colour)
	_draw_expected(canvas, place, rock_band)

	var vessel: Vector2 = place.call(Vector3.ZERO)
	_draw_aim(canvas, place)
	_dashes(canvas, vessel, place.call(sim.course_direction() * COURSE_M), COURSE_COLOUR)
	var coming := PackedVector2Array()
	for step in _projected:
		coming.append(place.call(step - head))
	if coming.size() > 1:
		canvas.draw_polyline(coming, StationTheme.PROJECTED_PATH_COLOUR, 2.5)
	_draw_vessel(canvas, vessel, place.call(sim.heading() * heading_m))


## The Beam's cone at its width, as two fans from the Head out to its reach,
## about its aim (beam_axis()): one in the plane through the aim and the
## vessel's top (dead ahead, the vessel's vertical plane: the scope's and the
## section's), one square across it (the plan's), each its two edges and the
## arc between. What of a fan would lie behind the vessel, where nothing is
## sent, is drawn flat along square across it. Every view draws both through
## its own `place`; one seen edge-on is a line along the aim.
func _draw_beam(canvas: Control, place: Callable) -> void:
	var heading := sim.heading()
	var axis := sim.beam_axis()
	var half := deg_to_rad(sim.beam_half_angle())
	var reach := sim.beam_reach()
	var colour := StationTheme.faded(BEAM_COLOUR, BEAM_ALPHA)
	for square in aim_squares(heading, _right(sim.heading_degrees()), sim.beam_aim()):
		var fan := PackedVector2Array([place.call(Vector3.ZERO)])
		for i in 17:
			var angle := lerpf(-half, half, i / 16.0)
			var ray := axis * cos(angle) + square * sin(angle)
			if ray.dot(heading) < 0.0:
				ray = (ray - heading * ray.dot(heading)).normalized()
			fan.append(place.call(ray * reach))
		fan.append(fan[0])
		canvas.draw_polyline(fan, colour, 1.5)


## The two ways square to the Beam's aimed axis that a view draws its cone's
## fans along: [toward the vessel's top, toward its right], each turned as the
## aim (`aim` as DiveSimulation.beam_aim(), degrees) turns the axis, so dead
## ahead they are the vessel's top (its `right` turned square to `heading`)
## and its right.
static func aim_squares(heading: Vector3, right: Vector3, aim: Vector2) -> Array[Vector3]:
	var across := deg_to_rad(aim.x)
	var up := deg_to_rad(aim.y)
	var top := right.cross(heading).normalized()
	var swung := heading * cos(across) + right * sin(across)
	return [top * cos(up) - swung * sin(up), right * cos(across) - heading * sin(across)]


## The aim's marker while the Beam is aimed off the vessel's axis: a small
## hollow diamond a fixed few pixels from the Head along the aim, so it shows
## at any view's scale; seen end-on, round the Head itself. Nothing while it
## is dead ahead, where the vessel's own heading line says the same.
func _draw_aim(canvas: Control, place: Callable) -> void:
	if sim.beam_aim() == Vector2.ZERO:
		return
	var vessel: Vector2 = place.call(Vector3.ZERO)
	var along: Vector2 = (place.call(sim.beam_axis() * sim.beam_reach()) as Vector2) - vessel
	var at := vessel
	if along.length() > AIM_MARK_PX:
		at = vessel + along.normalized() * minf(AIM_MARK_AT_PX, along.length())
	var r := AIM_MARK_PX
	canvas.draw_polyline(PackedVector2Array([at + Vector2(0.0, -r), at + Vector2(r, 0.0),
			at + Vector2(0.0, r), at + Vector2(-r, 0.0), at + Vector2(0.0, -r)]), BEAM_COLOUR, 2.0)


## A running Sweep's progress, as the Beam's cone is drawn: in the plane of
## its axis and down (the scope's and the section's) and the plane square
## across it (the plan's), from where it began, the spiral swept so far as a
## faint band each side of its axis from where it started (the Beam's edge)
## out to where it has reached, at its range, and that reach as a strong
## leading edge, sweeping outward to square across as the Sweep goes on.
## Every view draws both through its own `place`; a band seen edge-on is not
## filled.
func _draw_sweep(canvas: Control, place: Callable) -> void:
	if not sim.sweep_running():
		return
	var head := sim.head_position()
	var from := sim.sweep_origin() - head
	var axis := sim.sweep_axis()
	var right := _right(sim.heading_degrees())
	var square_down := right.cross(axis)
	if square_down.length() < 0.01:
		square_down = Vector3.UP.cross(axis)
	var start := deg_to_rad(sim.sweep_from_angle())
	var reached := deg_to_rad(sim.sweep_reached_angle())
	var reach := sim.sweep_range()
	var fill := StationTheme.faded(SWEEP_COLOUR, SWEEP_FILL_ALPHA)
	var edge := StationTheme.faded(SWEEP_COLOUR, SWEEP_EDGE_ALPHA)
	var origin: Vector2 = place.call(from)
	for square: Vector3 in [square_down.normalized(), axis.cross(square_down).normalized()]:
		for side: float in [-1.0, 1.0]:
			var band := PackedVector2Array([origin])
			for i in 9:
				var angle := lerpf(start, reached, i / 8.0) * side
				band.append(place.call(from + (axis * cos(angle) + square * sin(angle)) * reach))
			if _face(band) >= SURFACE_LEAST_FACE_PX:
				canvas.draw_colored_polygon(band, fill)
			canvas.draw_line(origin, band[band.size() - 1], edge, 2.0)


## Each target's region (target_regions()) as the scan has it: a fuzzy cyan
## patch, the outline of its ellipsoid on the screen at each of
## TARGET_SHARES of its size filled faintly, so the fill builds toward the
## middle, a faint rim at its edge and its name beside it ("TARGET A").
## Under the points and the Inferred Boundaries, so the echoes heard from it
## show over it.
func _draw_targets(canvas: Control, place: Callable) -> void:
	var head := sim.head_position()
	for region in _regions:
		var rim := PackedVector2Array()
		for share in TARGET_SHARES:
			var outline := region_outline(region, head, place, share)
			if outline.size() < 3:
				continue
			canvas.draw_colored_polygon(outline, StationTheme.faded(TARGET_COLOUR, TARGET_FILL_ALPHA))
			if rim.is_empty():
				rim = outline
		if rim.is_empty():
			continue
		var closed := rim.duplicate()
		closed.append(rim[0])
		canvas.draw_polyline(closed, StationTheme.faded(TARGET_COLOUR, TARGET_RIM_ALPHA), 1.5)
		var right := rim[0]
		for corner in rim:
			if corner.x > right.x:
				right = corner
		canvas.draw_string(ThemeDB.fallback_font, right + Vector2(6.0, FONT_SIZE * 0.35),
				"TARGET %s" % region.label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TARGET_COLOUR)


## The outline on the screen of a target's region scaled to `share` of its
## size about its middle, through a view's `place` (a place from the Head at
## `head`, metres, to pixels): the convex hull of points sampled over its
## ellipsoid, so it is its true outline seen from any view; not closed.
static func region_outline(region: TargetRegion, head: Vector3, place: Callable, share: float) -> PackedVector2Array:
	var drawn := PackedVector2Array()
	for ring in TARGET_RINGS:
		var up := lerpf(-PI / 2.0, PI / 2.0, (ring + 0.5) / TARGET_RINGS)
		for i in TARGET_ROUND:
			var around := TAU * i / TARGET_ROUND
			var on := Vector3(cos(up) * cos(around), sin(up), cos(up) * sin(around))
			drawn.append(place.call(region.centre + on * region.half_size * share - head))
	var hull := Geometry2D.convex_hull(drawn)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	return hull


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


## The forward scope's marks: range rings about the Head at the range's ring
## spacing, each second one with its range, the fan's centre line, and a
## plumb line to where down is.
func _draw_scope_marks(canvas: Control, vessel: Vector2, scale: float, place: Callable) -> void:
	var tick_m := _scope.y
	for ring in range(1, ceili(canvas.size.length() / (tick_m * scale))):
		var range_m := ring * tick_m
		canvas.draw_arc(vessel, range_m * scale, 0.0, TAU, 96, StationTheme.RULE_COLOUR, 1.5)
		if ring % 2 == 0 and vessel.x + range_m * scale < canvas.size.x:
			_label(canvas, vessel + Vector2(range_m * scale - 40.0, FONT_SIZE), "%d" % roundi(range_m))
	canvas.draw_line(Vector2(vessel.x, 0.0), Vector2(vessel.x, canvas.size.y), StationTheme.RULE_COLOUR, 1.0)
	_label(canvas, Vector2(vessel.x + 8.0, FONT_SIZE + 4.0), "AHEAD  m")
	# Where straight down lies: a tick mark on each ring it crosses.
	var down: Vector2 = (place.call(Vector3.DOWN) as Vector2) - vessel
	if down.length() > 0.0:
		down = down.normalized()
		var reach := (_scope.x - tick_m * 0.5) * scale
		canvas.draw_line(vessel, vessel + down * reach, StationTheme.LEGEND_COLOUR, 1.0)
		var square := Vector2(-down.y, down.x)
		for tick in range(1, floori(reach / (tick_m * scale)) + 1):
			canvas.draw_line(vessel + down * tick * tick_m * scale - square * 5.0,
					vessel + down * tick * tick_m * scale + square * 5.0, StationTheme.LEGEND_COLOUR, 1.5)
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


# --- The rock beyond a Boundary (#122) ----------------------------------------
# What sound can know of the rock: harder or softer, denser or more porous,
# never its name (DiveSimulation.rock_ahead(), BoundaryPatch.contrast). A
# rock's name is written only as surface control's expectation, marked as
# one, until the Column has shown it (DiveSimulation.expected_rocks()).

## How strong a contrast is, 0 (much the same, or nothing said) to the
## number of ROCK_DEGREES it passes, plus one.
static func rock_degree(contrast: float) -> int:
	if is_nan(contrast) or absf(contrast) < ROCK_SAME:
		return 0
	var degree := 1
	for edge in ROCK_DEGREES:
		if absf(contrast) >= edge:
			degree += 1
	return degree


## The words for the rock beyond against the rock before, from its estimated
## contrast: "MUCH HARDER, DENSER", "A LITTLE SOFTER, MORE POROUS", "MUCH THE
## SAME"; "" when the scan says nothing of it.
static func rock_words(contrast: float) -> String:
	if is_nan(contrast):
		return ""
	var degree := rock_degree(contrast)
	if degree == 0:
		return "MUCH THE SAME"
	return "%s%s" % [["A LITTLE ", "", "MUCH "][degree - 1],
			"HARDER, DENSER" if contrast > 0.0 else "SOFTER, MORE POROUS"]


## True when the band beyond a patch is hatched with strokes (harder,
## denser rock), false when stippled with dots (softer, more porous) or not
## drawn at all.
static func rock_hatched(contrast: float) -> bool:
	return rock_degree(contrast) > 0 and contrast > 0.0


## How many marks the band beyond a patch of this contrast has: none for
## much the same.
static func rock_marks(contrast: float) -> int:
	var degree := rock_degree(contrast)
	return 0 if degree == 0 else ROCK_MARKS[degree - 1]


## Navigation's status line for the rock beyond the Inferred Boundary ahead
## (the Habitat shows it): "Beyond: MUCH HARDER, DENSER  64% sure", or that
## the scan shows no Boundary ahead, or nothing of the rock beyond it. In the
## same words as the bands drawn beyond every patch (rock_words()).
static func rock_label(of: DiveSimulation) -> String:
	var contrast := of.rock_ahead()
	if of.rock_ahead_confidence() <= 0.0:
		return "Beyond: no Boundary ahead in the scan"
	if is_nan(contrast):
		return "Beyond the Boundary ahead: the scan cannot say"
	return "Beyond: %s  %d%% sure" % [rock_words(contrast), roundi(of.rock_ahead_confidence() * 100.0)]


## Surface control's name for a rock it expects (one of
## DiveSimulation.expected_rocks()), written as a guess until the Column has
## shown it: "GRANITE EXPECTED" ("GRANITE?" when `short`, for a narrow pane),
## then "GRANITE". Written where surface control expects it, so its depth is
## the place it is written.
static func expected_label(expected: Dictionary, short := false) -> String:
	var rock := String(expected.name).to_upper()
	if expected.confirmed:
		return rock
	return rock + ("?" if short else " EXPECTED")


## The band beyond a patch on the screen: ROCK_BAND_PX the way straight down
## goes through `place`, or nothing in the plan, which looks straight down.
static func _rock_band(place: Callable) -> Vector2:
	var down := (place.call(Vector3.DOWN * 10.0) as Vector2) - (place.call(Vector3.ZERO) as Vector2)
	return Vector2.ZERO if down.length() < 1.0 else down.normalized() * ROCK_BAND_PX


## The band of rock beyond one patch, on the side away from the Head: strokes
## through it for harder rock, dots in it for softer (rock_hatched()), as
## many as rock_marks(), spread along the patch's two diagonals (`corners`,
## its four corners on the screen), as sure as the patch (`sureness`, faded
## with age). `band` is rock_band() for this view.
func _draw_rock_beyond(canvas: Control, patch: BoundaryPatch, corners: PackedVector2Array,
		sureness: float, band: Vector2) -> void:
	var head := sim.head_position()
	var beyond := patch.beyond(head)
	var marks := rock_marks(beyond)
	if marks == 0:
		return
	var within := Rect2(Vector2.ZERO, canvas.size).grow(ROCK_BAND_PX + ROCK_TICK_PX)
	if not (within.has_point(corners[0]) or within.has_point(corners[2])):
		return
	var shift := band if patch.normal.dot(head - patch.centre) >= 0.0 else -band
	var end_on := shift.length() < ROCK_TICK_PX
	var colour := DOUBTFUL.lerp(CERTAIN, sureness)
	colour.a = ROCK_ALPHA * maxf(sureness, ROCK_LEAST_ALPHA)
	var hatched := rock_hatched(beyond)
	var lines := PackedVector2Array()
	for i in marks:
		var along := (i + 0.5) / marks
		var at: Vector2 = corners[0].lerp(corners[2], along) if i % 2 == 0 else corners[1].lerp(corners[3], along)
		if hatched:
			lines.append(at)
			lines.append(at + (Vector2(ROCK_TICK_PX, -ROCK_TICK_PX) * 0.7 if end_on else shift))
			continue
		# One dot a mark, by turns nearer and further into the band, so the
		# stipple stays open where patches lie side by side.
		var share := 0.3 if i % 2 == 0 else 0.75
		var dot := at + (Vector2(ROCK_TICK_PX, ROCK_TICK_PX) * share if end_on else shift * share)
		lines.append(dot)
		lines.append(dot + Vector2(ROCK_DOT_PX, 0.0))
	canvas.draw_multiline(lines, colour, 1.5 if hatched else ROCK_DOT_PX)


## Surface control's names for the rocks it expects, each at the right of
## the pane at the depth it surveyed (straight under or over the Head), just
## into the rock below, on a backdrop so the points never hide it: the
## legend's grey while a guess, white once the Column has shown it
## (expected_label()). Not in the plan, which shows no depth (`band` is
## nothing there).
func _draw_expected(canvas: Control, place: Callable, band: Vector2) -> void:
	if band == Vector2.ZERO:
		return
	var head := sim.head_position()
	var font := ThemeDB.fallback_font
	for expected in sim.expected_rocks():
		var at: Vector2 = place.call(Vector3(0.0, -expected.depth - head.y, 0.0))
		# Just into the rock below the Boundary, whichever way down goes.
		var line := at + band.normalized() * (FONT_SIZE * 0.5 + 4.0)
		if line.y < FONT_SIZE or line.y > canvas.size.y - 4.0:
			continue
		var text := expected_label(expected)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
		if width > canvas.size.x * 0.6:
			text = expected_label(expected, true)
			width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
		var corner := Vector2(maxf(2.0, canvas.size.x - width - 8.0), line.y - FONT_SIZE * 0.5 - 2.0)
		canvas.draw_rect(Rect2(corner, Vector2(width + 6.0, FONT_SIZE + 4.0)),
				StationTheme.faded(StationTheme.SCREEN_COLOUR, EXPECTED_BACKDROP_ALPHA))
		canvas.draw_string(font, corner + Vector2(3.0, FONT_SIZE), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
				FONT_SIZE, CERTAIN if expected.confirmed else DOUBTFUL)
