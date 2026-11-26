## The Reactor Station's display: the plasma as waveforms, for the Shift.
## Rendered in this SubViewport so a Station screen can show it as a texture.
##
## The Shift dial's two channels, like an airliner radio's active and standby
## frequencies, each a lane of a few seconds of wave scrolling right to left:
##   ACTIVE  - the wobble the load excites now (Reactor hue) with the opposing
##             wave the Reactor is tuned to drive (white), and faint, what the
##             plasma does: flat when tuned, beating once a Boundary changes
##             the load. MATCH: the active tuning against the wobble now
##             (DiveSimulation.shift_match()).
##   STANDBY - the staged tuning (white) against the wobble expected in the
##             Medium ahead (DiveSimulation.wobble_ahead()), and its MATCH
##             (DiveSimulation.standby_match()), once the Boundary-approaching
##             call comes; before it, the standby wave alone and MATCH "—".
##             Pretune it until the two lie on each other, then swap it in
##             (the Shift) as the Head crosses.
## Along the bottom, the window for the Shift: a bar that shrinks while it is
## open and turns red once it has closed. Its full width is a fresh Head's
## window; what a worn Head has lost of it is struck through in red at the
## right end, so the narrower window shows before a Shift is ever due.
##
## Reads only the simulation.
class_name PlasmaDisplay
extends SubViewport

## Seconds of wave across the display.
const SPAN_S := 3.0
const BACKGROUND := Color(0.03, 0.02, 0.02)
const COUNTER := Color(0.95, 0.95, 0.95)
const LATE := Color(1.0, 0.2, 0.15)

var sim: DiveSimulation
var hue := Color("ff7a45")

var _canvas := _Canvas.new()


## A channel's MATCH as its meter reads it: a percentage, or "—" for NAN
## (STANDBY before the Boundary-approaching call).
static func match_text(matched: float) -> String:
	if is_nan(matched):
		return "MATCH —"
	return "MATCH %d%%" % roundi(matched * 100.0)


func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	disable_3d = true
	_canvas.display = self
	_canvas.size = Vector2(size)
	add_child(_canvas)


class _Canvas extends Control:
	var display: PlasmaDisplay
	var _time := 0.0
	## The longest window seen (a fresh Head's: every dive starts with one),
	## so the bar shows the share of it left and what wear has taken.
	var _window_full := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PlasmaDisplay.BACKGROUND)
		var sim := display.sim
		if sim == null:
			return
		var font := ThemeDB.fallback_font
		var h := size.y
		var w := size.x
		var lane := h * 0.36
		var top := Rect2(0.0, 0.0, w, lane)
		var bottom := Rect2(0.0, lane, w, lane)
		var load_hz := sim.plasma_frequency()
		var hue := display.hue
		if sim.plasma_lost():
			draw_string(font, Vector2(16, h * 0.5), "PLASMA LOST", HORIZONTAL_ALIGNMENT_LEFT,
					-1, 48, PlasmaDisplay.LATE)
			return
		_lane(top, "ACTIVE", load_hz, sim.plasma_tuning(), sim.shift_match(sim.plasma_tuning()))
		_lane(bottom, "STANDBY", sim.wobble_ahead(), sim.standby_tuning(), sim.standby_match())
		draw_line(Vector2(0, lane), Vector2(w, lane), Color(1, 1, 1, 0.15), 1.0)
		# The window for the Shift.
		var bar := Rect2(8.0, h * 0.78, w - 16.0, h * 0.14)
		_window_full = maxf(_window_full, sim.shift_window_length())
		var kept := sim.shift_window_length() / _window_full if _window_full > 0.0 else 1.0
		if kept < 0.999:
			var worn := Rect2(bar.position + Vector2(bar.size.x * kept, 0.0),
					Vector2(bar.size.x * (1.0 - kept), bar.size.y))
			draw_rect(worn, Color(PlasmaDisplay.LATE, 0.25))
			draw_line(worn.position, worn.end, PlasmaDisplay.LATE, 2.0)
			draw_line(worn.position + Vector2(0, worn.size.y), worn.position + Vector2(worn.size.x, 0),
					PlasmaDisplay.LATE, 2.0)
			draw_string(font, worn.position + Vector2(4, -6), "WORN",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PlasmaDisplay.LATE)
		bar.size.x *= kept
		if sim.shift_due():
			var left := sim.shift_window()
			if left > 0.0:
				draw_rect(Rect2(bar.position, Vector2(bar.size.x * left / sim.shift_window_length(),
						bar.size.y)), hue)
				draw_string(font, bar.position + Vector2(4, bar.size.y - 6), "SHIFT  %.1f s" % left,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PlasmaDisplay.BACKGROUND)
			else:
				draw_rect(bar, PlasmaDisplay.LATE)
				draw_string(font, bar.position + Vector2(4, bar.size.y - 6), "SHIFT LATE",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 24, PlasmaDisplay.BACKGROUND)
		else:
			draw_rect(bar, Color(hue, 0.35), false, 2.0)
			draw_string(font, bar.position + Vector2(4, bar.size.y - 6), "steady",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(hue, 0.6))

	## One channel's lane: the wobble at `wobble_hz` (NAN for none known: the
	## tuning's wave alone) with the opposing wave at `tuning_hz` over it,
	## faint under them what the plasma would do, and the channel's `matched`
	## at the right ("—" for NAN).
	func _lane(lane: Rect2, title: String, wobble_hz: float, tuning_hz: float, matched: float) -> void:
		var hue := display.hue
		if not is_nan(wobble_hz):
			_trace(lane, func(t: float) -> float:
				return 0.5 * (sin(TAU * wobble_hz * t) - sin(TAU * tuning_hz * t)),
					Color(PlasmaDisplay.COUNTER, 0.25), 2.0)
			_trace(lane, func(t: float) -> float: return sin(TAU * wobble_hz * t) * 0.8, hue, 3.0)
		_trace(lane, func(t: float) -> float: return sin(TAU * tuning_hz * t) * 0.8,
				PlasmaDisplay.COUNTER, 2.0)
		var font := ThemeDB.fallback_font
		draw_string(font, lane.position + Vector2(8, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				PlasmaDisplay.COUNTER)
		var meter := Rect2(lane.position + Vector2(lane.size.x - 168.0, 8.0), Vector2(160.0, 22.0))
		draw_rect(meter, PlasmaDisplay.BACKGROUND)
		if not is_nan(matched):
			draw_rect(Rect2(meter.position, Vector2(meter.size.x * matched, meter.size.y)),
					Color(hue, 0.85))
		draw_rect(meter, PlasmaDisplay.COUNTER, false, 2.0)
		draw_string(font, meter.position + Vector2(4, meter.size.y - 4),
				PlasmaDisplay.match_text(matched), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				PlasmaDisplay.COUNTER)

	## Draws wave(t) for t over the last SPAN_S seconds, newest at the right,
	## scaled from -1..1 to the lane.
	func _trace(lane: Rect2, wave: Callable, colour: Color, width: float) -> void:
		var points := PackedVector2Array()
		var steps := 160
		for i in steps + 1:
			var x := lane.size.x * i / steps
			var t := _time - PlasmaDisplay.SPAN_S * (1.0 - float(i) / steps)
			var y: float = clampf(wave.call(t), -1.0, 1.0)
			points.append(Vector2(x, lane.position.y + lane.size.y * (0.5 - 0.42 * y)))
		draw_polyline(points, colour, width, true)
