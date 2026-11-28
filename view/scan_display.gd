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
## control's names for the rocks it expects; a strip under the views names
## the Sweep's range and progress over the Beam's width, each on a line of
## its own (tool_labels()); Navigation's status lines say what lies beyond
## the Boundary ahead (rock_label()). No word on the display overlaps
## another, a scale's mark, the vessel's marker or the aim's (ScanLabels,
## label_boxes()).
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
## A point of surface control's survey (ScanPoint.surveyed): a small open
## cross of the legend's grey, this many pixels across and this opaque,
## fainter than any of the vessel's own echoes and never filled, so the crew
## sees where its own scan has replaced the survey; a cross, not a square,
## so it still reads apart from an echo's filled square where the screen is
## seen small (#151).
const SURVEY_PX := 6.0
const SURVEY_ALPHA := 0.5
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
## The Glide's bar (_draw_glide()): its width and how opaque, in pixels, and
## half the bar across its end.
const GLIDE_PX := 7.0
const GLIDE_ALPHA := 0.55
const GLIDE_END_PX := 10.0
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
## short slant of ROCK_TICK_PX, so it still differs from a dot. Told apart
## where the screen is seen small (#151): each stroke slants across the band
## (ROCK_SLANT, a share of its depth), and each mark of stipple is a cluster
## of ROCK_CLUSTER dots spread through the band, so softer rock has as much
## weight as harder; both are drawn over the points, which would hide dots.
const ROCK_BAND_PX := 16.0
const ROCK_SAME := 0.05
const ROCK_DEGREES: Array[float] = [0.15, 0.4]
const ROCK_MARKS: Array[int] = [3, 5, 7]
const ROCK_ALPHA := 0.8
const ROCK_LEAST_ALPHA := 0.3
const ROCK_TICK_PX := 6.0
const ROCK_DOT_PX := 3.0
const ROCK_SLANT := 0.6
const ROCK_CLUSTER := 3
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
## The strip under the views for the tools' labels (#151): a line each, the
## Sweep's over the Beam's, this many pixels apart, so neither ever lies over
## the scan, a scale or another label; the smallest their font may shrink to
## in a pane too narrow for the longest whole.
const TOOL_LINE_PX := 22.0
const TOOL_STRIP_PX := 2.0 * TOOL_LINE_PX + 4.0
const FONT_SIZE_LEAST := 12
## How far a rock's name may be moved further into the rock, in lines, to
## clear a label already there; and the room kept clear round the vessel's
## marker, pixels.
const EXPECTED_SHIFTS := 3
const MARKER_CLEAR_PX := 3.0

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


## The Beam's width and cone, written on the bottom line of the strip under
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


## The Sweep's range and how far it has got, written on the strip under
## every view, on the line over the Beam's: "SWEEP 200 m  45%  1:06 left"
## while one runs, else its range, how long it would take and the key that
## starts it.
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
## drawn in: the whole display between the caption and the tools' strip.
func single_pane() -> Vector2:
	return Vector2(size.x, size.y - CAPTION_PX - TOOL_STRIP_PX)


## The tools' labels on the strip under the views, top line first, each
## [text, colour]: the Sweep's (green while it runs), then the Beam's.
func tool_labels() -> Array:
	return [[sweep_label(), SWEEP_COLOUR if sim.sweep_running() else StationTheme.SELECTED_COLOUR],
			[beam_label(), StationTheme.SELECTED_COLOUR]]


## The words over the panes, laid out (#151): the caption in the strip over
## them, and each tool's label on its own line of the strip under them, so
## each keeps one place whatever the view shows. All at the small font, or
## smaller only as the display is too narrow for the longest whole.
func over_labels() -> ScanLabels:
	var texts := PackedStringArray([caption()])
	var colours: Array[Color] = [StationTheme.LEGEND_COLOUR]
	for label: Array in tool_labels():
		texts.append(label[0])
		colours.append(label[1])
	var labels := ScanLabels.new(Rect2(Vector2.ZERO, Vector2(size)), FONT_SIZE)
	var points := FONT_SIZE
	for text in texts:
		while points > FONT_SIZE_LEAST and labels.width(text, points) > size.x - 12.0:
			points -= 1
	var strip := size.y - TOOL_STRIP_PX + 2.0 + points * ScanLabels.CAP_SHARE
	var places: Array[Vector2] = [Vector2(6.0, CAPTION_PX - 8.0), Vector2(8.0, strip),
			Vector2(8.0, strip + TOOL_LINE_PX)]
	for i in texts.size():
		labels.place(texts[i], [places[i]], colours[i], points)
	return labels


## Every word on the display as laid out now, in the display's pixels
## (#151): `labels`, each [text, box]; `tools`, the tools' labels' boxes;
## `markers`, the vessel's and the aim's marks that words are kept off; and
## `panes`, each pane's rectangle.
func label_boxes() -> Dictionary:
	_lay_out_panes()
	var over := over_labels()
	var words := []
	var tools: Array[Rect2] = []
	var markers: Array[Rect2] = []
	var panes: Array[Rect2] = []
	for i in over.boxes().size():
		words.append([over.texts()[i], over.boxes()[i]])
		if i > 0:
			tools.append(over.boxes()[i])
	for index in _panes.size():
		var pane := _panes[index]
		if not pane.visible:
			continue
		panes.append(Rect2(pane.position, pane.size))
		var laid := _pane_labels(index, pane.size, _frame(index, pane.size))
		for i in laid.boxes().size():
			words.append([laid.texts()[i], Rect2(laid.boxes()[i].position + pane.position, laid.boxes()[i].size)])
		for marker in laid.markers():
			markers.append(Rect2(marker.position + pane.position, marker.size))
	return {labels = words, tools = tools, markers = markers, panes = panes}


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
	var whole := Rect2(Vector2(0.0, CAPTION_PX), single_pane())
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


## The caption, the tools' strip (over_labels()), and a rule round each pane.
func _draw_over() -> void:
	over_labels().draw(_over)
	for pane in _panes:
		if pane.visible:
			_over.draw_rect(Rect2(pane.position, pane.size).grow(-1.0), StationTheme.RULE_COLOUR, false, 2.0)


func _draw_pane(canvas: Control, index: int) -> void:
	var area := canvas.size
	# Nothing to draw in until the panes are laid out.
	if sim == null or area.x < 2.0 * CAPTION_PX or area.y < 2.0 * CAPTION_PX:
		return
	var frame := _frame(index, area)
	var place: Callable = frame.place
	match sim.scan_view():
		DiveSimulation.SCAN_VIEW_FORWARD_SCOPE:
			_draw_scope_marks(canvas, frame.vessel, frame.scale, place)
		DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
			_draw_grid(canvas, frame.vessel, frame.scale, index == 1)
		DiveSimulation.SCAN_VIEW_WORLD_UP:
			_draw_world_marks(canvas, place)
	_draw_scan(canvas, place, frame.heading_m)
	_pane_labels(index, area, frame).draw(canvas)


## How one pane of the view shown draws the world, in a pane this big:
## `place` (a place from the Head, metres, to the pane's pixels), `vessel`
## (where the Head is drawn), `scale` (pixels per metre) and `heading_m`
## (the heading line's length, metres).
func _frame(index: int, area: Vector2) -> Dictionary:
	var bearing := sim.heading_degrees()
	var heading := sim.heading()
	var heading_m := HEADING_M
	var vessel := area * WORLD_VESSEL_AT
	var scale := minf(area.x / WORLD_SPAN_M, area.y * (1.0 - WORLD_VESSEL_AT.y) / WORLD_BELOW_M)
	var place := func(offset: Vector3) -> Vector2:
		return vessel + world_up_place(offset, bearing) * scale
	match sim.scan_view():
		DiveSimulation.SCAN_VIEW_FORWARD_SCOPE:
			vessel = Vector2(area.x * 0.5, area.y * SCOPE_VESSEL_AT)
			scale = scope_scale(area, _scope.x)
			heading_m = _scope.x * SCOPE_HEADING_SHARE
			place = func(offset: Vector3) -> Vector2:
				return vessel + scope_place(offset, heading, bearing) * scale
		DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
			scale = area.y * (1.0 - PAIR_VESSEL_AT.y) / PAIR_BELOW_M
			if index == 0:
				vessel = Vector2(area.x * PAIR_VESSEL_AT.x, area.y * 0.5)
				place = func(offset: Vector3) -> Vector2:
					return vessel + plan_place(offset, bearing) * scale
			else:
				vessel = Vector2(area.x * PAIR_VESSEL_AT.x, area.y * PAIR_VESSEL_AT.y)
				place = func(offset: Vector3) -> Vector2:
					return vessel + section_place(offset, bearing) * scale
	return {place = place, vessel = vessel, scale = scale, heading_m = heading_m}


## The words in one pane, each clear of the others and of the vessel's and
## the aim's marks (ScanLabels), placed in the order they matter: the pane's
## title, the scale's numbers (so a view never loses its scale), surface
## control's names for the rocks, then the targets' names. `frame` is _frame() of the pane.
func _pane_labels(index: int, area: Vector2, frame: Dictionary) -> ScanLabels:
	var labels := ScanLabels.new(Rect2(Vector2.ZERO, area), FONT_SIZE)
	var place: Callable = frame.place
	var vessel: Vector2 = frame.vessel
	var around := Vector2.ONE * (VESSEL_PX + MARKER_CLEAR_PX)
	labels.block(Rect2(vessel - around, around * 2.0))
	var aim := _aim_at(place)
	if aim.is_finite():
		around = Vector2.ONE * (AIM_MARK_PX + MARKER_CLEAR_PX)
		labels.block(Rect2(aim - around, around * 2.0))
	var legend := StationTheme.LEGEND_COLOUR
	var top := FONT_SIZE + 4.0
	match sim.scan_view():
		DiveSimulation.SCAN_VIEW_FORWARD_SCOPE:
			var ahead := "AHEAD  m"
			labels.place(ahead, [Vector2(vessel.x + 8.0, top), Vector2(vessel.x - 8.0 - labels.width(ahead), top)],
					legend)
		DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
			# At the top left, else wherever its corners are clear of the vessel.
			var title := "PLAN" if index == 0 else "SECTION"
			var right := area.x - labels.width(title) - 6.0
			labels.place(title, [Vector2(8.0, top), Vector2(right, top), Vector2(8.0, area.y - 6.0),
					Vector2(right, area.y - 6.0)], legend)
	match sim.scan_view():
		DiveSimulation.SCAN_VIEW_FORWARD_SCOPE:
			_scope_scale_labels(labels, vessel, frame.scale, place, area)
		DiveSimulation.SCAN_VIEW_PLAN_AND_SECTION:
			if index == 1:
				_section_scale_labels(labels, vessel, frame.scale, area)
		DiveSimulation.SCAN_VIEW_WORLD_UP:
			_world_scale_labels(labels, place)
	_expected_labels(labels, place, area)
	_target_labels(labels, place)
	return labels


## What every view shows, through its own `place` (a place from the Head, in
## metres, to the pane's pixels): the Inferred Boundaries, the points, the
## Course, the projected path and the vessel, in that order, so the vessel
## and what the crew has selected are never under the rock; the Beam's cone
## and the Sweep's progress first, under everything; the rock beyond each
## Boundary over the points, which would hide its dots. The vessel's heading
## line is `heading_m` long. The words are the pane's own (_pane_labels()).
func _draw_scan(canvas: Control, place: Callable, heading_m := HEADING_M) -> void:
	var head := sim.head_position()
	_draw_beam(canvas, place)
	_draw_sweep(canvas, place)
	_draw_targets(canvas, place)
	var rock_band := _rock_band(place)
	var outlines: Array[PackedVector2Array] = []
	var sure: Array[float] = []
	for patch in _patches:
		var sureness := patch.confidence * exp(-sim.patch_age(patch) / FADE_S)
		var corners := PackedVector2Array()
		for corner in patch.corners():
			corners.append(place.call(corner - head))
		outlines.append(corners.duplicate())
		sure.append(sureness)
		if _face(corners) >= SURFACE_LEAST_FACE_PX:
			canvas.draw_colored_polygon(corners, StationTheme.faded(SURFACE_COLOUR, SURFACE_MOST_ALPHA * sureness))
		corners.append(corners[0])
		canvas.draw_polyline(corners, StationTheme.faded(SURFACE_COLOUR,
				SURFACE_EDGE_ALPHA * maxf(sureness, POINT_LEAST_ALPHA)), 1.5)

	var within := Rect2(Vector2.ZERO, canvas.size).grow(POINT_PX.y)
	var crosses := PackedVector2Array()
	var arm := SURVEY_PX * 0.5
	for point in _points:
		var at: Vector2 = place.call(point.position - head)
		if not within.has_point(at):
			continue
		if point.surveyed:
			crosses.append_array([at - Vector2(arm, arm), at + Vector2(arm, arm),
					at + Vector2(-arm, arm), at + Vector2(arm, -arm)])
			continue
		var colour := DOUBTFUL.lerp(CERTAIN, point.confidence)
		colour.a = maxf(lerpf(POINT_ALPHA.x, POINT_ALPHA.y, point.confidence)
				* exp(-sim.point_age(point) / FADE_S), POINT_LEAST_ALPHA)
		var side := roundf(lerpf(POINT_PX.x, POINT_PX.y, point.confidence))
		canvas.draw_rect(Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), colour)
	if not crosses.is_empty():
		canvas.draw_multiline(crosses, StationTheme.faded(DOUBTFUL, SURVEY_ALPHA), 1.0)
	for i in _patches.size():
		_draw_rock_beyond(canvas, _patches[i], outlines[i], sure[i], rock_band)

	var vessel: Vector2 = place.call(Vector3.ZERO)
	_draw_aim(canvas, place)
	_dashes(canvas, vessel, place.call(sim.course_direction() * COURSE_M), COURSE_COLOUR)
	var coming := PackedVector2Array()
	for step in _projected:
		coming.append(place.call(step - head))
	if coming.size() > 1:
		canvas.draw_polyline(coming, StationTheme.PROJECTED_PATH_COLOUR, 2.5)
	_draw_glide(canvas, place)
	_draw_vessel(canvas, vessel, place.call(sim.heading() * heading_m))


## The Glide (ticket #123): the one plotted, a broad cyan bar along the Course
## from the Head as far as it runs, or the running one's range left, a broad
## green bar to its end; each with a bar across its end. Nothing with neither.
func _draw_glide(canvas: Control, place: Callable) -> void:
	var to := Vector3.ZERO
	var colour := StationTheme.SELECTED_COLOUR
	if sim.gliding():
		to = sim.glide_end() - sim.head_position()
		colour = StationTheme.ENGAGED_COLOUR
	elif sim.glide_plotted() > 0.0:
		to = sim.course_direction() * sim.glide_plotted()
	if to.is_zero_approx():
		return
	var from: Vector2 = place.call(Vector3.ZERO)
	var end: Vector2 = place.call(to)
	canvas.draw_line(from, end, StationTheme.faded(colour, GLIDE_ALPHA), GLIDE_PX)
	var across := (end - from).orthogonal().normalized() * GLIDE_END_PX
	canvas.draw_line(end - across, end + across, colour, 2.0)


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
	var at := _aim_at(place)
	if not at.is_finite():
		return
	var r := AIM_MARK_PX
	canvas.draw_polyline(PackedVector2Array([at + Vector2(0.0, -r), at + Vector2(r, 0.0),
			at + Vector2(0.0, r), at + Vector2(-r, 0.0), at + Vector2(0.0, -r)]), BEAM_COLOUR, 2.0)


## Where the aim's marker is drawn through a view's `place`, or
## Vector2.INF while the Beam is dead ahead and none is.
func _aim_at(place: Callable) -> Vector2:
	if sim.beam_aim() == Vector2.ZERO:
		return Vector2.INF
	var vessel: Vector2 = place.call(Vector3.ZERO)
	var along: Vector2 = (place.call(sim.beam_axis() * sim.beam_reach()) as Vector2) - vessel
	if along.length() <= AIM_MARK_PX:
		return vessel
	return vessel + along.normalized() * minf(AIM_MARK_AT_PX, along.length())


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
## middle, a faint rim at its edge; its name beside it is _target_labels().
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


## Each target's name beside its region (_draw_targets()): to its right,
## else its left, above or below it, else over its middle, wherever is first
## clear of the pane's other words.
func _target_labels(labels: ScanLabels, place: Callable) -> void:
	var head := sim.head_position()
	for region in _regions:
		var rim := region_outline(region, head, place, TARGET_SHARES[0])
		if rim.size() < 3:
			continue
		var around := Rect2(rim[0], Vector2.ZERO)
		for corner in rim:
			around = around.expand(corner)
		var text := "TARGET %s" % region.label
		var wide := labels.width(text)
		var middle := around.get_center()
		var baseline := middle.y + FONT_SIZE * 0.35
		labels.place(text, [Vector2(around.end.x + 6.0, baseline), Vector2(around.position.x - 6.0 - wide, baseline),
				Vector2(middle.x - wide * 0.5, around.position.y - 6.0),
				Vector2(middle.x - wide * 0.5, around.end.y + FONT_SIZE), Vector2(middle.x - wide * 0.5, baseline)],
				TARGET_COLOUR)


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
## spacing, the fan's centre line, and a plumb line to where down is, a tick
## mark on each ring it crosses. Their words: _scope_scale_labels().
func _draw_scope_marks(canvas: Control, vessel: Vector2, scale: float, place: Callable) -> void:
	var tick_m := _scope.y
	for ring in range(1, ceili(canvas.size.length() / (tick_m * scale))):
		canvas.draw_arc(vessel, ring * tick_m * scale, 0.0, TAU, 96, StationTheme.RULE_COLOUR, 1.5)
	canvas.draw_line(Vector2(vessel.x, 0.0), Vector2(vessel.x, canvas.size.y), StationTheme.RULE_COLOUR, 1.0)
	var down := _scope_down(vessel, place)
	if down == Vector2.ZERO:
		return
	var reach := (_scope.x - tick_m * 0.5) * scale
	canvas.draw_line(vessel, vessel + down * reach, StationTheme.LEGEND_COLOUR, 1.0)
	var square := Vector2(-down.y, down.x)
	for tick in range(1, floori(reach / (tick_m * scale)) + 1):
		canvas.draw_line(vessel + down * tick * tick_m * scale - square * 5.0,
				vessel + down * tick * tick_m * scale + square * 5.0, StationTheme.LEGEND_COLOUR, 1.5)


## Which way straight down lies on the forward scope from the vessel's
## marker, a unit on the screen, or nothing.
static func _scope_down(vessel: Vector2, place: Callable) -> Vector2:
	var down: Vector2 = (place.call(Vector3.DOWN) as Vector2) - vessel
	return down.normalized() if down.length() > 0.0 else Vector2.ZERO


## The forward scope's numbers: each second ring's range, beside the vessel's
## row (under it, else over it), and DOWN at the plumb line's end.
func _scope_scale_labels(labels: ScanLabels, vessel: Vector2, scale: float, place: Callable, area: Vector2) -> void:
	var legend := StationTheme.LEGEND_COLOUR
	var tick_m := _scope.y
	var down := _scope_down(vessel, place)
	if down != Vector2.ZERO:
		var end := vessel + down * (_scope.x - tick_m * 0.5) * scale
		var wide := labels.width("DOWN")
		labels.place("DOWN", [end + Vector2(-wide - 8.0, 6.0), end + Vector2(8.0, 6.0),
				end + Vector2(-wide - 8.0, -6.0), end + Vector2(8.0, FONT_SIZE)], legend)
	# Every second ring's range, or every fourth (eighth...) where they would
	# crowd, so the numbers stay apart enough to read.
	var every := 2
	while every * tick_m * scale < labels.width("%d" % roundi(_scope.x)) + 3.0 * FONT_SIZE / 2.0:
		every *= 2
	for ring in range(every, ceili(area.length() / (tick_m * scale)), every):
		var x := vessel.x + ring * tick_m * scale
		if x >= area.x:
			break
		var text := "%d" % roundi(ring * tick_m)
		var left := x - labels.width(text) - 4.0
		labels.place(text, [Vector2(left, vessel.y + FONT_SIZE), Vector2(left, vessel.y - 6.0),
				Vector2(left, vessel.y - 8.0 - FONT_SIZE)], legend)


## The pair's grid: a line every TICK_M ahead and behind the Head, the same
## in the plan and the section so the eye carries between them; in the
## section a line at every TICK_M of depth, and the surface. Their words:
## _section_scale_labels().
func _draw_grid(canvas: Control, vessel: Vector2, scale: float, section: bool) -> void:
	var faint := StationTheme.RULE_COLOUR
	var steps := ceili(canvas.size.x / (TICK_M * scale)) + 1
	for i in range(-steps, steps + 1):
		var x := vessel.x + i * TICK_M * scale
		canvas.draw_line(Vector2(x, 0.0), Vector2(x, canvas.size.y), faint, 2.0 if i == 0 else 1.0)
	if not section:
		canvas.draw_line(Vector2(0.0, vessel.y), Vector2(canvas.size.x, vessel.y), faint, 1.0)
		return
	for line: Vector2 in _depth_lines(vessel, scale, canvas.size):
		if line.x == 0.0:
			canvas.draw_rect(Rect2(0.0, 0.0, canvas.size.x, line.y), StationTheme.SURFACEWARD_COLOUR)
			canvas.draw_line(Vector2(0.0, line.y), Vector2(canvas.size.x, line.y), StationTheme.LEGEND_COLOUR, 2.0)
		else:
			canvas.draw_line(Vector2(0.0, line.y), Vector2(canvas.size.x, line.y), faint, 1.0)


## The section's depth lines in a pane this big: each Vector2(its depth,
## metres, where it is down the pane), every TICK_M from the surface.
func _depth_lines(vessel: Vector2, scale: float, area: Vector2) -> Array[Vector2]:
	var depth := -sim.head_position().y
	var first := floori((depth - vessel.y / scale) / TICK_M)
	var lines: Array[Vector2] = []
	for line in range(maxi(first, 0), first + ceili(area.y / (TICK_M * scale)) + 2):
		lines.append(Vector2(line * TICK_M, vessel.y + (line * TICK_M - depth) * scale))
	return lines


## The section's words: each second depth line's depth at the left, just
## over it, and "surface" at the right over the surface line, else under it.
func _section_scale_labels(labels: ScanLabels, vessel: Vector2, scale: float, area: Vector2) -> void:
	var legend := StationTheme.LEGEND_COLOUR
	for line: Vector2 in _depth_lines(vessel, scale, area):
		if line.x == 0.0:
			var right := area.x - labels.width("surface") - 6.0
			labels.place("surface", [Vector2(right, line.y - 5.0), Vector2(right, line.y + FONT_SIZE)], legend)
		elif roundi(line.x / TICK_M) % 2 == 0:
			labels.place("%d m" % roundi(line.x), [Vector2(8.0, line.y - 4.0)], legend)


## The world-up view's marks: a level ring round the vessel with north on it
## (it goes round as the compass heading does), and a plumb line under the
## vessel with a tick every TICK_M, to read depth by and to show which way is
## down. Their words: _world_scale_labels().
func _draw_world_marks(canvas: Control, place: Callable) -> void:
	var ring := PackedVector2Array()
	for i in 65:
		var angle := TAU * i / 64.0
		ring.append(place.call(Vector3(sin(angle), 0.0, -cos(angle)) * WORLD_RING_M))
	canvas.draw_polyline(ring, StationTheme.RULE_COLOUR, 1.5)
	var north: Vector2 = place.call(Vector3.FORWARD * WORLD_RING_M)
	canvas.draw_line(place.call(Vector3.FORWARD * WORLD_RING_M * 0.85), north, StationTheme.LEGEND_COLOUR, 2.0)
	var vessel: Vector2 = place.call(Vector3.ZERO)
	var foot: Vector2 = place.call(Vector3.DOWN * WORLD_PLUMB_M)
	canvas.draw_line(vessel, foot, StationTheme.LEGEND_COLOUR, 1.0)
	for tick in range(1, floori(WORLD_PLUMB_M / TICK_M) + 1):
		var at: Vector2 = place.call(Vector3.DOWN * tick * TICK_M)
		canvas.draw_line(at - Vector2(6.0, 0.0), at + Vector2(6.0, 0.0), StationTheme.LEGEND_COLOUR, 1.5)


## The world-up view's words: N beyond the ring's north tick, and each second
## tick's depth below the vessel beside the plumb line, right of it, else
## left.
func _world_scale_labels(labels: ScanLabels, place: Callable) -> void:
	var legend := StationTheme.LEGEND_COLOUR
	# Beyond the north tick, else as near it either side as clears the vessel.
	var north: Vector2 = place.call(Vector3.FORWARD * WORLD_RING_M * 1.15)
	var places := []
	for x: float in [-5.0, 4.0, -14.0, 13.0, -23.0, 22.0, -32.0]:
		places.append(north + Vector2(x, 7.0))
		places.append(north + Vector2(x, 18.0))
	labels.place("N", places, legend)
	for tick in range(2, floori(WORLD_PLUMB_M / TICK_M) + 1, 2):
		var at: Vector2 = place.call(Vector3.DOWN * tick * TICK_M)
		var text := "+%d m" % roundi(tick * TICK_M)
		labels.place(text, [at + Vector2(10.0, 6.0), at + Vector2(-10.0 - labels.width(text), 6.0)], legend)


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
	# Across the band: strokes slant this way, a cluster's dots spread both.
	var across := Vector2(ROCK_DOT_PX, ROCK_DOT_PX) if end_on else shift.orthogonal().normalized() * ROCK_DOT_PX
	var lines := PackedVector2Array()
	for i in marks:
		var along := (i + 0.5) / marks
		var at: Vector2 = corners[0].lerp(corners[2], along) if i % 2 == 0 else corners[1].lerp(corners[3], along)
		if hatched:
			lines.append(at)
			lines.append(at + (Vector2(ROCK_TICK_PX, -ROCK_TICK_PX) * 0.7 if end_on
					else shift + across.normalized() * shift.length() * ROCK_SLANT))
			continue
		# A cluster of dots a mark, spread through the band and either side,
		# so the stipple carries as much weight as a stroke and stays open where
		# patches lie side by side.
		for d in ROCK_CLUSTER:
			# Staggered mark by mark, so the dots never line up into rows.
			var share := (d + (0.25 if i % 2 == 0 else 0.75)) / ROCK_CLUSTER
			var side := across * (1.0 if (i + d) % 2 == 0 else -1.0)
			var dot := at + (Vector2(ROCK_TICK_PX * share, 0.0) + side * 0.5 if end_on else shift * share + side)
			lines.append(dot)
			lines.append(dot + Vector2(ROCK_DOT_PX, 0.0))
	canvas.draw_multiline(lines, colour, 1.5 if hatched else ROCK_DOT_PX)


## Surface control's names for the rocks it expects, each at the right of
## the pane at the depth it surveyed (straight under or over the Head), just
## into the rock below, or as little further into it as clears the pane's
## words already placed (EXPECTED_SHIFTS lines at most): the legend's grey
## while a guess, white once the Column has shown it (expected_label()),
## shortened in a narrow pane. Not in the plan, which shows no depth.
func _expected_labels(labels: ScanLabels, place: Callable, area: Vector2) -> void:
	var band := _rock_band(place)
	if band == Vector2.ZERO:
		return
	var into := band.normalized()
	var step := signf(into.y) if into.y != 0.0 else 1.0
	var head := sim.head_position()
	for expected in sim.expected_rocks():
		var at: Vector2 = place.call(Vector3(0.0, -expected.depth - head.y, 0.0))
		# Just into the rock below the Boundary, whichever way down goes.
		var line := at + into * (FONT_SIZE * 0.5 + 4.0)
		var text := expected_label(expected)
		if labels.width(text) > area.x * 0.6:
			text = expected_label(expected, true)
		var left := maxf(2.0, area.x - labels.width(text) - 5.0)
		# At the right, else at the left; only then back over the Boundary.
		var places := []
		for shift: int in range(EXPECTED_SHIFTS + 1) + range(-1, -EXPECTED_SHIFTS - 1, -1):
			for x: float in [left, 8.0]:
				places.append(Vector2(x, line.y + FONT_SIZE * 0.5 - 2.0 + step * shift * FONT_SIZE))
		labels.place(text, places, CERTAIN if expected.confirmed else DOUBTFUL)
