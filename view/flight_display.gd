## The Drive Station's display: a primary flight display, laid out as an
## airliner's is. Rendered in this SubViewport so the Drive's screen can show
## it as a texture.
##
##   attitude  the attitude ball (AttitudeBall): a sphere fixed to the world,
##             marked in pitch and heading, seen along where the Head points,
##             so the vessel's mark is fixed at its middle; the surface's
##             half above the horizon, the rock's below, the surface's way up
##             at every pitch, straight up and down included. On it the
##             Course's cross, what the Drive steers for hollow when off it,
##             and, while the Drive steers straight up or down
##             (steers_straight_up_or_down()), the lean (lean(), the way the
##             next pitch nudge tilts) as a hollow arrow from the pole. A mark
##             behind the ball is pinned to its rim on its side. Its corners
##             state the pitch, the Course's pitch and the lean ("LEAN 030");
##             its foot the deviation ("OFF COURSE" over "30 deg up"), or
##             FOLLOWS THE COURSE in green.
##   speed     a tape of speed() in m/s, faster up.
##   depth     where altitude goes: a tape of depth() in metres, deeper down,
##             and under it how fast the depth changes (speed along the pitch).
##   heading   a tape of heading_degrees() along the foot, with the Course's
##             bug at course_heading().
##   power     the Drive's set point against actual, as shares of the
##             Reactor's full output (PowerLine), STARVED when short.
##   grip      how much of the Drive's power grips the wall, and the slip.
##   steering  the throttle, the steering effort and how hard the Head steers.
## While the Drive is nudged off the Course, what it steers toward instead
## shows hollow beside the Course's marks, in the same cyan (both are what the
## crew has selected), and the ball's foot states the deviation in
## CourseDeviation's words, as Navigation's screen does. The vessel's own mark
## and readings are white, scales and titles the legend's grey, a starved
## Drive or slipping grip amber (StationTheme). A mark off its tape is pinned
## to the end nearer it (FlightTape.pinned()), so it always shows which way
## the Course lies.
##
## Reads only the simulation. INSTRUMENTS is its layout; the Habitat hands
## instrument_shares() to GimballedStation.show_display() so each instrument
## is a reading the centre dot can point at.
class_name FlightDisplay
extends SubViewport

## The display's size in pixels: about the shape of the body of the Drive's
## screen (StationScreen.body_size()), which shows it scaled to fit.
const SIZE := Vector2i(1024, 485)
## Each instrument's place on the display, in pixels.
const INSTRUMENTS := {
	&"speed": Rect2(36, 30, 112, 346),
	&"attitude": Rect2(166, 24, 444, 352),
	&"depth": Rect2(628, 30, 124, 346),
	&"heading": Rect2(166, 400, 444, 74),
	&"power": Rect2(778, 24, 230, 146),
	&"grip": Rect2(778, 182, 230, 130),
	&"steering": Rect2(778, 324, 230, 150),
}
## What each tape shows across its length, and its ticks and labels.
const SPEED_SPAN := 3.0
const SPEED_TICK := 0.1
const SPEED_LABEL := 0.5
const DEPTH_SPAN := 120.0
const DEPTH_TICK := 10.0
const DEPTH_LABEL := 50.0
const HEADING_SPAN := 80.0
const HEADING_TICK := 5.0
const HEADING_LABEL := 10.0
## The attitude ball's circles of pitch every PITCH_RUNG degrees, labelled
## every BALL_LABEL; its headings every BALL_MERIDIAN, labelled in a ring
## BALL_RING degrees above the middle.
const PITCH_RUNG := 10.0
const BALL_LABEL := 30.0
const BALL_MERIDIAN := 30.0
const BALL_RING := 40.0
## How far from the pole the lean's arrow reaches along its meridian, degrees.
const LEAN_ARROW := 30.0
## The half width of a mark on the ball (the Course's cross), in pixels.
const MARK_RADIUS := 15.0
## The height of the foot under the ball, which states the deviation in two
## rows, in pixels.
const FOOT := 72.0
## The smallest size the deviation's figures shrink to so they fit whole.
const FONT_LEAST := 16

# Its colours are StationTheme's, by the Theme's own names: the sky toward
# the surface and the rock below the horizon as backdrops; scales, their
# numbers and the rules round each instrument as legends; the vessel's own
# mark and readings white (now); the Course and the Drive's nudges off it
# cyan (selected); a starved Drive and slipping grip amber (cautions); grip
# holding green (working).

const FONT_SMALL := 24
const FONT := 28
const FONT_LARGE := 34

var sim: DiveSimulation
## Drawn every frame while the crew is at the Drive, every
## ScreenPace.UNWATCHED_S while not.
var _pace := ScreenPace.new()

var _canvas := _Canvas.new()


func _ready() -> void:
	size = SIZE
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	disable_3d = true
	_canvas.display = self
	_canvas.size = Vector2(SIZE)
	add_child(_canvas)


## The instruments' places as shares of the display (0 to 1 across and down),
## as GimballedStation.show_display() takes them.
static func instrument_shares() -> Dictionary:
	var shares := {}
	for name: StringName in INSTRUMENTS:
		var rect: Rect2 = INSTRUMENTS[name]
		shares[name] = Rect2(rect.position / Vector2(SIZE), rect.size / Vector2(SIZE))
	return shares


## The foot under the attitude ball, in the attitude's box.
static func foot(box: Rect2) -> Rect2:
	return Rect2(Vector2(box.position.x, box.end.y - FOOT), Vector2(box.size.x, FOOT))


## The attitude ball's radius in pixels: as large as the box over its foot
## allows, its corners left for the figures beside it.
static func ball_radius(box: Rect2) -> float:
	return minf(box.size.x, box.size.y - FOOT - 8.0) / 2.0


## The attitude ball's middle, in pixels: centred over the foot.
static func ball_centre(box: Rect2) -> Vector2:
	return Vector2(box.get_center().x, box.position.y + (box.size.y - FOOT) / 2.0)


## The largest font size, FONT down to FONT_LEAST, at which text fits whole
## in width pixels, so a long deviation is never cut off.
static func fitting_size(text: String, width: float) -> int:
	var font := ThemeDB.fallback_font
	var size := FONT
	while size > FONT_LEAST and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	return size


## The ball's bottom right figure in a Glide: how far off its line the vessel
## is, `off_m` metres, green within the sheath's slack (`slack_m`), amber
## touching its wall and wearing, red half way to hard against it (`contact`,
## DiveSimulation.glide_contact()). [legend, value, colour].
static func glide_line_figure(off_m: float, slack_m: float, contact: float) -> Array:
	var colour := StationTheme.ENGAGED_COLOUR
	if contact >= 0.5:
		colour = StationTheme.WARNING_COLOUR
	elif off_m > slack_m:
		colour = StationTheme.CAUTION_COLOUR
	return ["OFF LINE", "%.1f m" % off_m, colour]


class _Canvas extends Control:
	## How far the Head's pitch or heading may move, degrees, before the
	## ball's circles and labels are worked out again.
	const BALL_SNAP := 0.05

	var display: FlightDisplay
	# The ball's picture (_ball_picture()) and the pitch, heading and radius
	# it was worked out for.
	var _ball_key := Vector3(INF, INF, INF)
	var _surface := PackedVector2Array()
	## Each [polyline, colour, width].
	var _lines: Array[Array] = []
	## Each [where, text].
	var _labels: Array[Array] = []

	func _process(delta: float) -> void:
		if display._pace.due_at(delta, display.sim, DiveSimulation.STATION_DRIVE):
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), StationTheme.SCREEN_COLOUR)
		var sim := display.sim
		if sim == null:
			return
		_attitude(sim, FlightDisplay.INSTRUMENTS[&"attitude"])
		_speed(sim, FlightDisplay.INSTRUMENTS[&"speed"])
		_depth(sim, FlightDisplay.INSTRUMENTS[&"depth"])
		_heading(sim, FlightDisplay.INSTRUMENTS[&"heading"])
		_power(sim, FlightDisplay.INSTRUMENTS[&"power"])
		_grip(sim, FlightDisplay.INSTRUMENTS[&"grip"])
		_steering(sim, FlightDisplay.INSTRUMENTS[&"steering"])

	## The attitude ball, its four corner figures and its foot.
	func _attitude(sim: DiveSimulation, box: Rect2) -> void:
		var ball := AttitudeBall.new(sim.pitch(), sim.heading_degrees())
		var centre := FlightDisplay.ball_centre(box)
		var radius := FlightDisplay.ball_radius(box)
		_ball(ball, centre, radius)
		# The Course; over it, what the Drive steers toward instead, hollow.
		var steered := _on_ball(ball, centre, radius, sim.steered_heading(), sim.steered_pitch())
		_cross(_on_ball(ball, centre, radius, sim.course_heading(), sim.course_pitch()),
				StationTheme.SELECTED_COLOUR, true)
		if sim.overriding():
			_cross(steered, StationTheme.SELECTED_COLOUR, false)
		if sim.steers_straight_up_or_down():
			_lean(ball, centre, radius, steered, sim)
		var gliding := sim.gliding()
		if gliding:
			var aim := sim.glide_aim()
			_line_to_hold(_on_ball(ball, centre, radius, aim.x, aim.y))
		_vessel_mark(centre)
		var foot := FlightDisplay.foot(box)
		var top := box.position.y + 26.0
		var bottom := foot.position.y - 36.0
		_figure(box, false, top, "PITCH", "%+.0f" % sim.pitch(), StationTheme.NOW_COLOUR)
		_figure(box, true, top, "COURSE", "%+.0f" % sim.course_pitch(), StationTheme.SELECTED_COLOUR)
		if sim.steers_straight_up_or_down():
			_figure(box, false, bottom, "LEAN", "%03d" % roundi(sim.lean()), StationTheme.SELECTED_COLOUR)
		if gliding:
			var figure := FlightDisplay.glide_line_figure(sim.glide_off_line().length(),
					sim.glide_slack(), sim.glide_contact())
			_figure(box, true, bottom, figure[0], figure[1], figure[2])
		_foot(sim, foot)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	## The ball itself: the rock and the surface either side of the horizon,
	## pitch circles every PITCH_RUNG (labelled every BALL_LABEL along the
	## Head's own meridian), headings every BALL_MERIDIAN (labelled in a ring
	## BALL_RING above the middle), and its rim.
	func _ball(ball: AttitudeBall, centre: Vector2, radius: float) -> void:
		var key := Vector3(snappedf(ball.pitch, BALL_SNAP), snappedf(ball.heading, BALL_SNAP), radius)
		if key != _ball_key:
			_ball_key = key
			_ball_picture(AttitudeBall.new(key.x, key.y), centre, radius)
		draw_circle(centre, radius, StationTheme.ROCKWARD_COLOUR)
		if _surface.size() >= 3:
			draw_colored_polygon(_surface, StationTheme.SURFACEWARD_COLOUR)
		for line: Array in _lines:
			draw_polyline(line[0], line[1], line[2], true)
		var font := ThemeDB.fallback_font
		for label: Array in _labels:
			draw_string(font, label[0], label[1], HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT_SMALL,
					StationTheme.LEGEND_COLOUR)
		draw_arc(centre, radius, 0.0, TAU, 96, StationTheme.RULE_COLOUR, 3.0, true)

	## Works out the ball's picture for the Head's pitch and heading, kept
	## until they change by BALL_SNAP: the surface's part, the circles and
	## the labels.
	func _ball_picture(ball: AttitudeBall, centre: Vector2, radius: float) -> void:
		_surface = _scaled(ball.surfaceward(), centre, radius)
		_lines.clear()
		_labels.clear()
		var faint := StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.35)
		var clear := StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.7)
		var rung := FlightDisplay.PITCH_RUNG
		for i in range(roundi(-90.0 / rung) + 1, roundi(90.0 / rung)):
			var at_pitch := i * rung
			var labelled := is_zero_approx(fmod(at_pitch, FlightDisplay.BALL_LABEL))
			var colour := StationTheme.LEGEND_COLOUR if i == 0 else (clear if labelled else faint)
			for run in ball.parallel(at_pitch):
				_lines.append([_scaled(run, centre, radius), colour, 2.0 if labelled else 1.0])
		var step := FlightDisplay.BALL_MERIDIAN
		for i in roundi(360.0 / step):
			for run in ball.meridian(i * step):
				_lines.append([_scaled(run, centre, radius), faint, 1.0])
		# Pitch labels where each labelled circle crosses the Head's meridian,
		# ahead of the Head if they can; heading labels in a ring above the
		# middle (round the pole when steep). None lies on another or on the
		# vessel's mark.
		var taken: Array[Rect2] = [Rect2(centre - Vector2(84, 22), Vector2(168, 44))]
		for i in range(1, roundi(90.0 / FlightDisplay.BALL_LABEL)):
			for at_pitch: float in [i * FlightDisplay.BALL_LABEL, -i * FlightDisplay.BALL_LABEL]:
				for side: float in [0.0, 180.0]:
					if ball.facing(ball.heading + side, at_pitch).z > 0.15:
						var at := centre + ball.place(ball.heading + side, at_pitch) * radius
						_label(at + Vector2(6, 0), "%+d" % roundi(at_pitch), taken)
						break
		var ring := clampf(ball.pitch - FlightDisplay.BALL_RING, -50.0, 50.0)
		for i in roundi(360.0 / step):
			if ball.facing(i * step, ring).z > 0.25:
				var at := centre + ball.place(i * step, ring) * radius
				_label(at - Vector2(22, 0), "%03d" % roundi(i * step), taken)

	## A label on the ball, its left end at at and centred on it upright,
	## unless it would lie on a place already taken; it then takes its own.
	func _label(at: Vector2, text: String, taken: Array[Rect2]) -> void:
		var room := Rect2(at - Vector2(0, 13), ThemeDB.fallback_font.get_string_size(text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT_SMALL) * Vector2(1, 0) + Vector2(0, 26))
		for other in taken:
			if other.intersects(room):
				return
		taken.append(room)
		_labels.append([at + Vector2(0, 9), text])

	## Places on the unit disc as pixels on the ball.
	static func _scaled(points: PackedVector2Array, centre: Vector2, radius: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		out.resize(points.size())
		for i in points.size():
			out[i] = centre + points[i] * radius
		return out

	## Where a mark for a direction is drawn on the ball, in pixels: at its
	## place, or pinned to the rim when behind, kept whole inside the rim.
	static func _on_ball(ball: AttitudeBall, centre: Vector2, radius: float, at_heading: float,
			at_pitch: float) -> Vector2:
		var inside := (radius - FlightDisplay.MARK_RADIUS - 2.0) / radius
		return centre + ball.place(at_heading, at_pitch).limit_length(inside) * radius

	## The lean, while the Drive steers straight up or down: a hollow arrow
	## from what it steers for along the lean's meridian, the way a pitch
	## nudge tilts it.
	func _lean(ball: AttitudeBall, centre: Vector2, radius: float, steered: Vector2, sim: DiveSimulation) -> void:
		var away := (90.0 - FlightDisplay.LEAN_ARROW) * signf(sim.steered_pitch())
		var tip := _on_ball(ball, centre, radius, sim.lean(), away)
		var along := tip - steered
		if along.length() < FlightDisplay.MARK_RADIUS * 2.0:
			# Both pinned to the rim, or nearly on top: point round the rim.
			along = (steered - centre).normalized().orthogonal() * FlightDisplay.MARK_RADIUS * 3.0
			tip = steered + along
		var ahead := along.normalized()
		var colour := StationTheme.SELECTED_COLOUR
		draw_line(steered + ahead * (FlightDisplay.MARK_RADIUS + 4.0), tip - ahead * 14.0, colour, 2.0, true)
		var side := ahead.orthogonal() * 10.0
		draw_polyline(PackedVector2Array([tip, tip - ahead * 18.0 + side, tip - ahead * 18.0 - side, tip]),
				colour, 2.0, true)

	## The line to hold in a Glide (DiveSimulation.glide_aim()): a hollow cyan
	## diamond with a tick either side, as the Course is cyan; bringing the
	## vessel's mark onto it rejoins the line.
	func _line_to_hold(at: Vector2) -> void:
		var r := FlightDisplay.MARK_RADIUS
		var colour := StationTheme.SELECTED_COLOUR
		draw_polyline(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r),
				at + Vector2(-r, 0), at + Vector2(0, -r)]), colour, 3.0, true)
		draw_line(at + Vector2(r + 4.0, 0), at + Vector2(r * 2.0 + 4.0, 0), colour, 3.0)
		draw_line(at - Vector2(r + 4.0, 0), at - Vector2(r * 2.0 + 4.0, 0), colour, 3.0)

	## The vessel's mark, fixed at the ball's middle: where the Head points.
	func _vessel_mark(mid: Vector2) -> void:
		var mark := StationTheme.NOW_COLOUR
		draw_line(mid + Vector2(-78, 0), mid + Vector2(-26, 0), mark, 6.0)
		draw_line(mid + Vector2(-26, -3), mid + Vector2(-26, 16), mark, 6.0)
		draw_line(mid + Vector2(26, 0), mid + Vector2(78, 0), mark, 6.0)
		draw_line(mid + Vector2(26, -3), mid + Vector2(26, 16), mark, 6.0)
		draw_rect(Rect2(mid - Vector2(5, 5), Vector2(10, 10)), mark)

	## A figure in a corner beside the ball, left or right: its legend, its
	## baseline at y, over its value.
	func _figure(box: Rect2, right: bool, top: float, legend: String, value: String, colour: Color) -> void:
		var font := ThemeDB.fallback_font
		var align := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
		var x := box.position.x + 10.0
		var width := box.size.x - 20.0
		draw_string(font, Vector2(x, top), legend, align, width, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		draw_string(font, Vector2(x, top + 30.0), value, align, width, FlightDisplay.FONT, colour)

	## The deviation under the ball, in CourseDeviation's words beside the
	## hollow mark, its figures shrunk only if they would not fit whole.
	func _foot(sim: DiveSimulation, foot: Rect2) -> void:
		var font := ThemeDB.fallback_font
		draw_rect(foot, StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.08))
		draw_line(foot.position, Vector2(foot.end.x, foot.position.y), StationTheme.RULE_COLOUR, 2.0)
		if not sim.overriding():
			draw_string(font, foot.position + Vector2(12, 30), "FOLLOWS THE COURSE", HORIZONTAL_ALIGNMENT_LEFT,
					-1, FlightDisplay.FONT_SMALL, StationTheme.ENGAGED_COLOUR)
			return
		_cross(foot.position + Vector2(26, 20), StationTheme.SELECTED_COLOUR, false)
		draw_string(font, foot.position + Vector2(52, 30), "OFF COURSE", HORIZONTAL_ALIGNMENT_LEFT, -1,
				FlightDisplay.FONT_SMALL, StationTheme.SELECTED_COLOUR)
		var words := CourseDeviation.of(sim)
		var width := foot.size.x - 24.0
		var fitted := FlightDisplay.fitting_size(words, width)
		draw_string(font, foot.position + Vector2(12, foot.size.y - 10), words, HORIZONTAL_ALIGNMENT_LEFT,
				width, fitted, StationTheme.SELECTED_COLOUR)

	## The Course's cross on the ball, or hollow what the Drive steers for
	## off it.
	func _cross(at: Vector2, colour: Color, filled: bool) -> void:
		var r := FlightDisplay.MARK_RADIUS
		var diamond := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r),
				at + Vector2(-r, 0), at + Vector2(0, -r)])
		draw_polyline(diamond, colour, 4.0 if filled else 2.0)
		if filled:
			draw_line(at + Vector2(-r * 1.8, 0), at + Vector2(r * 1.8, 0), colour, 2.0)
			draw_line(at + Vector2(0, -r * 1.8), at + Vector2(0, r * 1.8), colour, 2.0)

	func _speed(sim: DiveSimulation, box: Rect2) -> void:
		var tape := FlightTape.new(FlightDisplay.SPEED_SPAN, box.size.y)
		_vertical_tape(box, tape, sim.speed(), -1.0, FlightDisplay.SPEED_TICK, FlightDisplay.SPEED_LABEL,
				0.0, "%.1f", "SPEED")
		_readout(box, "%.2f" % sim.speed(), "m/s")

	func _depth(sim: DiveSimulation, box: Rect2) -> void:
		var tape := FlightTape.new(FlightDisplay.DEPTH_SPAN, box.size.y)
		_vertical_tape(box, tape, sim.depth(), 1.0, FlightDisplay.DEPTH_TICK, FlightDisplay.DEPTH_LABEL,
				-INF, "%d", "DEPTH")
		_readout(box, "%.1f" % sim.depth(), "m")
		# How fast the depth changes: the speed along the pitch.
		var sinking := sim.speed() * sin(deg_to_rad(sim.pitch()))
		draw_string(ThemeDB.fallback_font, Vector2(box.position.x - 10, box.end.y + 26), "%s %.2f m/s" % [
				"down" if sinking >= 0.0 else "up", absf(sinking)], HORIZONTAL_ALIGNMENT_CENTER,
				box.size.x + 20, FlightDisplay.FONT_SMALL, StationTheme.NOW_COLOUR)

	## A vertical tape with reading at its middle; growing is -1 for values
	## that grow up the screen, 1 for down. Ticks below lowest are left off.
	func _vertical_tape(box: Rect2, tape: FlightTape, reading: float, growing: float, tick: float,
			label: float, lowest: float, format: String, title: String) -> void:
		var font := ThemeDB.fallback_font
		draw_rect(box, StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.08))
		var mid := box.get_center()
		for value in tape.ticks(reading, tick, lowest):
			var y := mid.y + growing * tape.place(value, reading)
			var labelled := absf(value / label - roundf(value / label)) < 0.001
			draw_line(Vector2(box.end.x - (22.0 if labelled else 12.0), y), Vector2(box.end.x, y),
					StationTheme.LEGEND_COLOUR, 2.0)
			if labelled and y > box.position.y + 16.0 and y < box.end.y - 8.0:
				draw_string(font, Vector2(box.position.x + 6, y + 8), format % value,
						HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)
		draw_string(font, box.position + Vector2(0, -6), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x,
				FlightDisplay.FONT_SMALL, StationTheme.RULE_COLOUR)

	## The reading in a box at a tape's middle.
	func _readout(box: Rect2, value: String, unit: String) -> void:
		var font := ThemeDB.fallback_font
		var window := Rect2(box.position.x - 6, box.get_center().y - 24, box.size.x + 12, 48)
		draw_rect(window, StationTheme.SCREEN_COLOUR)
		draw_rect(window, StationTheme.NOW_COLOUR, false, 3.0)
		draw_string(font, window.position + Vector2(6, 36), value, HORIZONTAL_ALIGNMENT_LEFT,
				window.size.x - 12, FlightDisplay.FONT_LARGE, StationTheme.NOW_COLOUR)
		draw_string(font, window.position + Vector2(6, 36), unit, HORIZONTAL_ALIGNMENT_RIGHT,
				window.size.x - 12, FlightDisplay.FONT_SMALL, StationTheme.NOW_COLOUR)

	func _heading(sim: DiveSimulation, box: Rect2) -> void:
		var font := ThemeDB.fallback_font
		var tape := FlightTape.new(FlightDisplay.HEADING_SPAN, box.size.x, 360.0)
		var heading := sim.heading_degrees()
		var mid := box.get_center()
		draw_rect(box, StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.08))
		for value in tape.ticks(heading, FlightDisplay.HEADING_TICK):
			var x := mid.x + tape.place(value, heading)
			var labelled := is_zero_approx(fmod(value, FlightDisplay.HEADING_LABEL))
			draw_line(Vector2(x, box.position.y), Vector2(x, box.position.y + (16.0 if labelled else 9.0)),
					StationTheme.LEGEND_COLOUR, 2.0)
			if labelled:
				draw_string(font, Vector2(x - 30, box.position.y + 40), "%03d" % roundi(value),
						HORIZONTAL_ALIGNMENT_CENTER, 60, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		if sim.overriding():
			_bug(Vector2(mid.x + tape.pinned(sim.steered_heading(), heading), box.position.y), StationTheme.SELECTED_COLOUR, false)
		_bug(Vector2(mid.x + tape.pinned(sim.course_heading(), heading), box.position.y), StationTheme.SELECTED_COLOUR, true)
		# The heading itself, under a fixed pointer.
		draw_colored_polygon(PackedVector2Array([Vector2(mid.x, box.position.y + 2),
				Vector2(mid.x - 10, box.position.y - 14), Vector2(mid.x + 10, box.position.y - 14)]), StationTheme.NOW_COLOUR)
		var window := Rect2(mid.x - 46, box.end.y - 32, 92, 32)
		draw_rect(window, StationTheme.SCREEN_COLOUR)
		draw_rect(window, StationTheme.NOW_COLOUR, false, 3.0)
		draw_string(font, window.position + Vector2(0, 27), "%03d" % roundi(heading), HORIZONTAL_ALIGNMENT_CENTER,
				window.size.x, FlightDisplay.FONT, StationTheme.NOW_COLOUR)
		draw_string(font, Vector2(box.end.x - 178, box.end.y - 8), "COURSE %03d" % roundi(sim.course_heading()),
				HORIZONTAL_ALIGNMENT_RIGHT, 170, FlightDisplay.FONT_SMALL, StationTheme.SELECTED_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	## The Course's (or the override's) bug on the heading tape's edge.
	func _bug(at: Vector2, colour: Color, filled: bool) -> void:
		var points := PackedVector2Array([at + Vector2(-12, 0), at + Vector2(-12, 16), at + Vector2(-4, 16),
				at + Vector2(0, 8), at + Vector2(4, 16), at + Vector2(12, 16), at + Vector2(12, 0)])
		if filled:
			draw_colored_polygon(points, colour)
		else:
			points.append(points[0])
			draw_polyline(points, colour, 2.0)

	func _power(sim: DiveSimulation, box: Rect2) -> void:
		if sim.gliding():
			_glide_power(sim, box)
			return
		var font := ThemeDB.fallback_font
		var full := sim.reactor_full_output()
		var requested := sim.drive_request()
		var drawn := sim.drive_draw()
		var starved := PowerLine.starved(requested, drawn, full)
		_title(box, "POWER")
		var bar := Rect2(box.position + Vector2(10, 44), Vector2(box.size.x - 20, 30))
		draw_rect(bar, StationTheme.faded(StationTheme.LEGEND_COLOUR, 0.1))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(drawn / full, 0.0, 1.0), bar.size.y)),
				StationTheme.CAUTION_COLOUR if starved else StationTheme.NOW_COLOUR)
		var set_x := bar.position.x + bar.size.x * clampf(requested / full, 0.0, 1.0)
		draw_line(Vector2(set_x, bar.position.y - 6), Vector2(set_x, bar.end.y + 6), StationTheme.SELECTED_COLOUR, 4.0)
		draw_rect(bar, StationTheme.RULE_COLOUR, false, 2.0)
		draw_string(font, box.position + Vector2(10, 106), "set %d%%" % PowerLine.percent(requested, full),
				HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT, StationTheme.SELECTED_COLOUR)
		draw_string(font, box.position + Vector2(10, 136), "actual %d%%" % PowerLine.percent(drawn, full),
				HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT, StationTheme.CAUTION_COLOUR if starved else StationTheme.NOW_COLOUR)
		if starved:
			draw_string(font, box.position + Vector2(10, 28), "STARVED", HORIZONTAL_ALIGNMENT_RIGHT,
					box.size.x - 20, FlightDisplay.FONT_SMALL, StationTheme.CAUTION_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	## The power box in a Glide: the jet takes the Reactor's whole output,
	## many times the Crawl's full output, so it reads as that multiple, and
	## the throttle has no say.
	func _glide_power(sim: DiveSimulation, box: Rect2) -> void:
		var font := ThemeDB.fallback_font
		var times := sim.reactor_output() / sim.reactor_full_output()
		_title(box, "POWER")
		draw_string(font, box.position + Vector2(10, 28), "GLIDE", HORIZONTAL_ALIGNMENT_RIGHT,
				box.size.x - 20, FlightDisplay.FONT_SMALL, StationTheme.ENGAGED_COLOUR)
		draw_string(font, box.position + Vector2(10, 76), "jet x%d" % roundi(times),
				HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT, StationTheme.ENGAGED_COLOUR)
		draw_string(font, box.position + Vector2(10, 106), "of full output", HORIZONTAL_ALIGNMENT_LEFT, -1,
				FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		draw_string(font, box.position + Vector2(10, 136), "%d m left" % roundi(sim.glide_range_left()),
				HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT, StationTheme.NOW_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	func _grip(sim: DiveSimulation, box: Rect2) -> void:
		var font := ThemeDB.fallback_font
		var slip := clampf(sim.slip(), 0.0, 1.0)
		_title(box, "GRIP")
		var bar := Rect2(box.position + Vector2(10, 44), Vector2(box.size.x - 20, 30))
		var held := bar.size.x * (1.0 - slip)
		draw_rect(Rect2(bar.position, Vector2(held, bar.size.y)), StationTheme.NOW_COLOUR)
		draw_rect(Rect2(bar.position + Vector2(held, 0), Vector2(bar.size.x - held, bar.size.y)), StationTheme.CAUTION_COLOUR)
		draw_rect(bar, StationTheme.RULE_COLOUR, false, 2.0)
		if slip > 0.0:
			draw_string(font, box.position + Vector2(10, 104), "SLIPPING %d%%" % roundi(slip * 100.0),
					HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT, StationTheme.CAUTION_COLOUR)
			draw_string(font, box.position + Vector2(10, 126), "ease off %s" % KeyMap.label(&"power_step", 1),
					HORIZONTAL_ALIGNMENT_LEFT, -1, FlightDisplay.FONT_SMALL, StationTheme.CAUTION_COLOUR)
		else:
			draw_string(font, box.position + Vector2(10, 104), "holding", HORIZONTAL_ALIGNMENT_LEFT, -1,
					FlightDisplay.FONT, StationTheme.ENGAGED_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	func _steering(sim: DiveSimulation, box: Rect2) -> void:
		_title(box, "DRIVE")
		var rows := [["Throttle", sim.power()], ["Effort", sim.steering_effort()], ["Steer", sim.steering()]]
		for i in rows.size():
			_meter(Rect2(box.position + Vector2(10, 40 + i * 36), Vector2(box.size.x - 20, 30)),
					rows[i][0], rows[i][1])
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	## A labelled bar filled to share, its percentage at the right.
	func _meter(row: Rect2, label: String, share: float) -> void:
		var font := ThemeDB.fallback_font
		var bar := Rect2(row.position + Vector2(100, 6), Vector2(row.size.x - 164, row.size.y - 12))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(share, 0.0, 1.0), bar.size.y)), StationTheme.NOW_COLOUR)
		draw_rect(bar, StationTheme.RULE_COLOUR, false, 1.0)
		draw_string(font, row.position + Vector2(0, 23), label, HORIZONTAL_ALIGNMENT_LEFT, 98,
				FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		draw_string(font, row.position + Vector2(0, 23), "%d%%" % roundi(share * 100.0),
				HORIZONTAL_ALIGNMENT_RIGHT, row.size.x, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)

	func _title(box: Rect2, title: String) -> void:
		draw_string(ThemeDB.fallback_font, box.position + Vector2(10, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1,
				FlightDisplay.FONT_SMALL, StationTheme.RULE_COLOUR)
