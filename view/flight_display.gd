## The Drive Station's display: a primary flight display, laid out as an
## airliner's is. Rendered in this SubViewport so the Drive's screen can show
## it as a texture.
##
##   attitude  the pitch ladder, the vessel's mark fixed at its middle and the
##             ladder sliding with pitch(): toward the surface above the
##             horizon, the rock below, diving pitches (+) below it. The
##             Course's cross sits at the Course's pitch, and aside by how far
##             its heading takes it off the vessel's (FlightTape.sideways(),
##             less the steeper it is); chevrons mark its pitch at the
##             ladder's sides.
##   speed     a tape of speed() in m/s, faster up.
##   depth     where altitude goes: a tape of depth() in metres, deeper down,
##             and under it how fast the depth changes (speed along the pitch).
##   heading   a tape of heading_degrees() along the foot, with the Course's
##             bug at course_heading(). While the Drive steers straight up or
##             down (steers_straight_up_or_down()), the lean (lean(), the way
##             the next pitch nudge tilts) as a hollow cyan pointer over the
##             tape and "LEAN 090" at its left.
##   power     the Drive's set point against actual, as shares of the
##             Reactor's full output (PowerLine), STARVED when short.
##   grip      how much of the Drive's power grips the wall, and the slip.
##   steering  the throttle, the steering effort and how hard the Head steers.
## While the Drive is nudged off the Course, what it steers toward instead
## shows hollow beside the Course's marks, in the same cyan (both are what the
## crew has selected), and the attitude indicator's foot states the deviation
## in CourseDeviation's words, as Navigation's screen does: "OFF COURSE 30 deg
## up". The vessel's own mark and readings are white, scales and
## titles the legend's grey, a starved Drive or slipping grip amber
## (StationTheme). A mark off its scale
## is pinned to the end nearer it (FlightTape.pinned()), so it always shows
## which way the Course lies.
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
## Degrees of pitch across the attitude indicator's height; its width is at
## the same scale, so the Course's cross lies the way the Course does.
const PITCH_SPAN := 70.0
const PITCH_RUNG := 10.0

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


class _Canvas extends Control:
	## The height of the attitude indicator's top plate (its pitch and the
	## Course's), in pixels.
	const PLATE := 40.0

	var display: FlightDisplay

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

	func _attitude(sim: DiveSimulation, box: Rect2) -> void:
		var font := ThemeDB.fallback_font
		var ladder := FlightTape.new(FlightDisplay.PITCH_SPAN, box.size.y)
		var across := FlightTape.new(FlightDisplay.PITCH_SPAN * box.size.x / box.size.y, box.size.x)
		var mid := box.get_center()
		var pitch := sim.pitch()
		var heading := sim.heading_degrees()
		# The horizon may lie off the indicator, steep in a dive or a climb.
		var horizon := clampf(mid.y + ladder.place(0.0, pitch), box.position.y, box.end.y)
		draw_rect(Rect2(box.position, Vector2(box.size.x, horizon - box.position.y)),
				StationTheme.SURFACEWARD_COLOUR)
		draw_rect(Rect2(Vector2(box.position.x, horizon), Vector2(box.size.x, box.end.y - horizon)),
				StationTheme.ROCKWARD_COLOUR)
		if ladder.on_scale(0.0, pitch):
			draw_line(Vector2(box.position.x, horizon), Vector2(box.end.x, horizon), StationTheme.LEGEND_COLOUR, 2.0)
		for rung in ladder.ticks(pitch, FlightDisplay.PITCH_RUNG / 2.0, -90.0, 90.0):
			if is_zero_approx(rung):
				continue
			var y := mid.y + ladder.place(rung, pitch)
			if y < box.position.y + PLATE + 12.0 or y > box.end.y - 12.0:
				continue
			var labelled := is_zero_approx(fmod(rung, FlightDisplay.PITCH_RUNG))
			var half := 84.0 if labelled else 28.0
			draw_line(Vector2(mid.x - half, y), Vector2(mid.x + half, y), StationTheme.LEGEND_COLOUR, 2.0)
			if labelled:
				var label := "%+d" % roundi(rung)
				draw_string(font, Vector2(mid.x - half - 62.0, y + 8.0), label, HORIZONTAL_ALIGNMENT_RIGHT,
						56.0, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
				draw_string(font, Vector2(mid.x + half + 6.0, y + 8.0), label, HORIZONTAL_ALIGNMENT_LEFT,
						-1, FlightDisplay.FONT_SMALL, StationTheme.LEGEND_COLOUR)
		# The Course at its heading and pitch from the vessel's; over it, what
		# the Drive steers toward instead, hollow. Pinned marks stay clear of
		# the indicator's edges and its plate.
		var off_course := sim.overriding()
		var marks := box.grow_individual(-30.0, -(PLATE + 18.0), -30.0,
				-(PLATE + 18.0) if off_course else -18.0)
		var place := func(to_heading: float, to_pitch: float) -> Vector2:
			return (mid + Vector2(across.pinned(FlightTape.sideways(to_heading, to_pitch, heading), 0.0),
					ladder.pinned(to_pitch, pitch))).clamp(marks.position, marks.end)
		var course: Vector2 = place.call(sim.course_heading(), sim.course_pitch())
		_cross(course, StationTheme.SELECTED_COLOUR, true)
		_chevrons(box, course.y, StationTheme.SELECTED_COLOUR, true)
		if off_course:
			var steered: Vector2 = place.call(sim.steered_heading(), sim.steered_pitch())
			_cross(steered, StationTheme.SELECTED_COLOUR, false)
			_chevrons(box, steered.y, StationTheme.SELECTED_COLOUR, false)
		# The vessel's mark, fixed at the middle.
		var mark := StationTheme.NOW_COLOUR
		draw_line(mid + Vector2(-78, 0), mid + Vector2(-26, 0), mark, 6.0)
		draw_line(mid + Vector2(-26, -3), mid + Vector2(-26, 16), mark, 6.0)
		draw_line(mid + Vector2(26, 0), mid + Vector2(78, 0), mark, 6.0)
		draw_line(mid + Vector2(26, -3), mid + Vector2(26, 16), mark, 6.0)
		draw_rect(Rect2(mid - Vector2(5, 5), Vector2(10, 10)), mark)
		var plate := Rect2(box.position, Vector2(box.size.x, PLATE))
		draw_rect(plate, StationTheme.faded(StationTheme.SCREEN_COLOUR, 0.7))
		draw_string(font, box.position + Vector2(8, 30), "PITCH %+.0f" % pitch, HORIZONTAL_ALIGNMENT_LEFT,
				-1, FlightDisplay.FONT, mark)
		draw_string(font, box.position + Vector2(box.size.x - 228, 30), "COURSE %+.0f" % sim.course_pitch(),
				HORIZONTAL_ALIGNMENT_RIGHT, 220, FlightDisplay.FONT, StationTheme.SELECTED_COLOUR)
		if off_course:
			# The deviation, stated beside the hollow mark it is drawn with.
			var foot := Rect2(Vector2(box.position.x, box.end.y - PLATE), Vector2(box.size.x, PLATE))
			draw_rect(foot, StationTheme.faded(StationTheme.SCREEN_COLOUR, 0.7))
			_cross(foot.position + Vector2(26, PLATE / 2.0), StationTheme.SELECTED_COLOUR, false)
			draw_string(font, foot.position + Vector2(52, 30), "OFF COURSE  %s" % CourseDeviation.of(sim),
					HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 60, FlightDisplay.FONT, StationTheme.SELECTED_COLOUR)
		draw_rect(box, StationTheme.RULE_COLOUR, false, 2.0)

	## The Course's cross on the attitude indicator, or hollow what the Drive
	## steers for off it.
	func _cross(at: Vector2, colour: Color, filled: bool) -> void:
		var r := 15.0
		var diamond := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r),
				at + Vector2(-r, 0), at + Vector2(0, -r)])
		draw_polyline(diamond, colour, 4.0 if filled else 2.0)
		if filled:
			draw_line(at + Vector2(-r * 1.8, 0), at + Vector2(r * 1.8, 0), colour, 2.0)
			draw_line(at + Vector2(0, -r * 1.8), at + Vector2(0, r * 1.8), colour, 2.0)

	## Chevrons at a pitch on the ladder's two sides, pointing in.
	func _chevrons(box: Rect2, y: float, colour: Color, filled: bool) -> void:
		for side: float in [-1.0, 1.0]:
			var tip := Vector2(box.get_center().x + side * (box.size.x / 2.0 - 30.0), y)
			var back := tip + Vector2(side * 22.0, 0)
			var points := PackedVector2Array([tip, back + Vector2(0, -12), back + Vector2(0, 12)])
			if filled:
				draw_colored_polygon(points, colour)
			else:
				points.append(tip)
				draw_polyline(points, colour, 2.0)

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
		if sim.steers_straight_up_or_down():
			# The lean: the way the next pitch nudge tilts, hollow over the
			# heading's own pointer as the override's bug is beside the Course's.
			var lean := sim.lean()
			var tip := Vector2(clampf(mid.x + tape.pinned(lean, heading), box.position.x + 12, box.end.x - 12),
					box.position.y + 2)
			draw_polyline(PackedVector2Array([tip, tip + Vector2(-12, -18), tip + Vector2(12, -18), tip]),
					StationTheme.SELECTED_COLOUR, 2.0)
			draw_string(font, Vector2(box.position.x + 8, box.end.y - 8), "LEAN %03d" % roundi(lean),
					HORIZONTAL_ALIGNMENT_LEFT, 170, FlightDisplay.FONT_SMALL, StationTheme.SELECTED_COLOUR)
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
