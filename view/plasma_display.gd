## The Reactor Station's display: the Shift dial's two channels as waves.
## Rendered in this SubViewport so a Station screen can show it as a texture.
## Plain for now (three lines and the Band per lane); the Reactor screen's
## composition is its own ticket.
##
## Two lanes, like an airliner radio's active and standby frequencies, each a
## few seconds of wave scrolling right to left:
##   ACTIVE  - the Wobble the Medium puts on the plasma now (Reactor hue),
##             the Counter-wave ACTIVE drives against it (white, thin), and
##             the Residual, the two summed (bold): flat when the cancelling
##             is perfect, a small steady wave when the amplitude is off,
##             slow beats when the frequency is off.
##   STANDBY - the Wobble expected in the Medium ahead, STANDBY's Counter-wave
##             and the Residual it would leave, once the Boundary-approaching
##             call comes; before it, the Counter-wave alone and "RESIDUAL —".
## Behind each lane's waves lies the Band, a strip about the centre line: the
## Residual the Head bears. A Residual that leaves it is drawn in red. The
## lane the Reactor's controls tune is marked. Along the bottom, the Caution
## lamps: one per cause pulling the plasma's steadiness down.
##
## Reads only the simulation.
class_name PlasmaDisplay
extends SubViewport

## Seconds of wave across the display.
const SPAN_S := 3.0
## The wave value drawn at a lane's edge: a little more than the biggest
## Wobble, so a Residual of two waves adding still mostly fits.
const FULL_SCALE := 1.6
const BACKGROUND := Color(0.03, 0.02, 0.02)
const COUNTER := Color(0.95, 0.95, 0.95)
const LATE := Color(1.0, 0.2, 0.15)
const CAUTION := Color(1.0, 0.7, 0.1)
## The Caution lamps, in the order drawn: each cause and its label.
const LAMPS := [
	[DiveSimulation.CAUSE_WORN, "HEAD WORN"],
	[DiveSimulation.CAUSE_HOT, "HOT"],
	[DiveSimulation.CAUSE_OUT_OF_BAND, "OUT OF BAND"],
]

var sim: DiveSimulation
var hue := Color("ff7a45")

var _canvas := _Canvas.new()


## A channel's Residual against the Band as its lane reads it, or "—" for
## NAN (STANDBY before the Boundary-approaching call).
static func residual_text(residual: float, band: float) -> String:
	if is_nan(residual):
		return "RESIDUAL —"
	return "RESIDUAL %.2f  BAND %.2f" % [residual, band]


## A channel's Counter-wave as its lane reads it.
static func counter_wave_text(frequency: float, amplitude: float) -> String:
	return "%.2f Hz  x%.2f" % [frequency, amplitude]


func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	disable_3d = true
	_canvas.display = self
	_canvas.size = Vector2(size)
	add_child(_canvas)


class _Canvas extends Control:
	var display: PlasmaDisplay

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PlasmaDisplay.BACKGROUND)
		var sim := display.sim
		if sim == null:
			return
		var font := ThemeDB.fallback_font
		var h := size.y
		var w := size.x
		var lane := h * 0.42
		if sim.plasma_lost():
			draw_string(font, Vector2(16, h * 0.5), "PLASMA LOST", HORIZONTAL_ALIGNMENT_LEFT,
					-1, 48, PlasmaDisplay.LATE)
			return
		_lane(Rect2(0.0, 0.0, w, lane), "ACTIVE", DiveSimulation.CHANNEL_ACTIVE)
		_lane(Rect2(0.0, lane, w, lane), "STANDBY", DiveSimulation.CHANNEL_STANDBY)
		draw_line(Vector2(0, lane), Vector2(w, lane), Color(1, 1, 1, 0.15), 1.0)
		# The Caution lamps: lit while their cause pulls the steadiness down.
		var causes := sim.steadiness_causes()
		var lamp_w := (w - 16.0) / PlasmaDisplay.LAMPS.size()
		for i in PlasmaDisplay.LAMPS.size():
			var lit: bool = PlasmaDisplay.LAMPS[i][0] in causes
			var box := Rect2(8.0 + lamp_w * i, h * 0.855, lamp_w - 8.0, h * 0.125)
			if lit:
				draw_rect(box, PlasmaDisplay.CAUTION)
			draw_rect(box, Color(PlasmaDisplay.CAUTION, 1.0 if lit else 0.3), false, 2.0)
			draw_string(font, box.position + Vector2(8, box.size.y - 9), PlasmaDisplay.LAMPS[i][1],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
					PlasmaDisplay.BACKGROUND if lit else Color(PlasmaDisplay.CAUTION, 0.3))

	## One channel's lane: the Band, then its Wobble, its Counter-wave and its
	## Residual, with its name, its Counter-wave's settings and its Residual
	## against the Band written over them.
	func _lane(lane: Rect2, title: String, channel: StringName) -> void:
		var sim := display.sim
		var hue := display.hue
		var residual := sim.residual(channel)
		var band := sim.band()
		var half := lane.size.y * 0.5 * band / PlasmaDisplay.FULL_SCALE
		var mid := lane.position.y + lane.size.y * 0.5
		draw_rect(Rect2(0.0, mid - half, lane.size.x, 2.0 * half), Color(hue, 0.18))
		for edge in [mid - half, mid + half]:
			draw_line(Vector2(0.0, edge), Vector2(lane.size.x, edge), Color(hue, 0.5), 1.0)
		if not is_nan(residual):
			_trace(lane, func(t: float) -> float: return sim.wobble_wave(channel, t), Color(hue, 0.8), 2.0)
		_trace(lane, func(t: float) -> float: return sim.counter_wave(channel, t),
				Color(PlasmaDisplay.COUNTER, 0.45), 1.5)
		var outside := not is_nan(residual) and residual > band
		if not is_nan(residual):
			_trace(lane, func(t: float) -> float: return sim.residual_wave(channel, t),
					PlasmaDisplay.LATE if outside else PlasmaDisplay.COUNTER, 4.0)
		var font := ThemeDB.fallback_font
		var selected := sim.selected_channel() == channel
		draw_string(font, lane.position + Vector2(8, 26),
				"%s%s   %s" % ["> " if selected else "  ", title, PlasmaDisplay.counter_wave_text(
						sim.counter_wave_frequency(channel), sim.counter_wave_amplitude(channel))],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
				PlasmaDisplay.COUNTER if selected else Color(PlasmaDisplay.COUNTER, 0.6))
		draw_string(font, lane.position + Vector2(8, lane.size.y - 8),
				PlasmaDisplay.residual_text(residual, band), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				PlasmaDisplay.LATE if outside else PlasmaDisplay.COUNTER)

	## Draws wave(t) for t from SPAN_S seconds ago to now, newest at the
	## right, scaled so FULL_SCALE reaches the lane's edge.
	func _trace(lane: Rect2, wave: Callable, colour: Color, width: float) -> void:
		var points := PackedVector2Array()
		var steps := 160
		for i in steps + 1:
			var x := lane.size.x * i / steps
			var t := -PlasmaDisplay.SPAN_S * (1.0 - float(i) / steps)
			var y: float = clampf(wave.call(t) / PlasmaDisplay.FULL_SCALE, -1.0, 1.0)
			points.append(Vector2(x, lane.position.y + lane.size.y * (0.5 - 0.5 * y)))
		draw_polyline(points, colour, width, true)
