## The Reactor Station's display: the Shift dial's two channels as waves.
## Rendered in this SubViewport so a Station screen can show it as a texture.
## Plain for now (three lines and the Band per lane); the Reactor screen's
## composition is its own ticket.
##
## Two lanes, like an airliner radio's active and standby frequencies, each a
## few seconds of wave scrolling right to left:
##   ACTIVE  - the Wobble the Medium puts on the plasma now (white: what is
##             happening), the Counter-wave ACTIVE drives against it (cyan:
##             what the crew has selected), and the Residual, the two summed
##             (bold): flat when the cancelling is perfect, a small steady
##             wave when the amplitude is off, slow beats when the frequency
##             is off.
##   STANDBY - the scan's guess of the Wobble in the Medium ahead (a sum of
##             sines: the true Wobble, a little off, and spurious sines that
##             fade as the Boundary ahead is better scanned), STANDBY's
##             Counter-wave and the Residual it is predicted to leave. With
##             no scan of the Boundary ahead: spurious sines, the Counter-wave
##             alone and "RESIDUAL —". The lane also writes the guess with how
##             sure it is, and the countdown to the Boundary with its
##             plus-or-minus ("> 5 min" when the scan cannot say).
## Behind each lane's waves lies the Band, a strip about the centre line: the
## Residual the Head bears. A Residual that reaches outside it is drawn in
## amber, a caution. The lane the Reactor's controls tune is written in cyan
## and marked. The Caution lamps are in the Station's header strip
## (CautionLamps). Colours are StationTheme's.
##
## The waves are the simulation's own (DiveSimulation.wobble_wave(),
## counter_wave(), residual_wave()), on the dive's clock, so the picture is
## what wears the Head and a still of it is the dive at that moment. Reads
## only the simulation.
class_name PlasmaDisplay
extends SubViewport

## Seconds of wave across the display.
const SPAN_S := 3.0
## The wave value drawn at a lane's edge: a little more than the biggest
## Wobble, so a Residual of two waves adding still mostly fits.
const FULL_SCALE := 1.6
const BACKGROUND := StationTheme.SCREEN_COLOUR
## The Wobble: what is happening now. The Counter-wave: what the crew has
## selected. A Residual outside the Band: a caution.
const WOBBLE := StationTheme.NOW_COLOUR
const COUNTER := StationTheme.SELECTED_COLOUR
const OUTSIDE := StationTheme.CAUTION_COLOUR

var sim: DiveSimulation

var _canvas := _Canvas.new()


## A channel's Residual against the Band as its lane reads it, or "—" for
## NAN (STANDBY with no scan of the Boundary ahead).
static func residual_text(residual: float, band: float) -> String:
	if is_nan(residual):
		return "RESIDUAL —"
	return "RESIDUAL %.2f  BAND %.2f" % [residual, band]


## The scan's guess of the Wobble ahead as STANDBY's lane reads it: its true
## component's frequency and amplitude and how sure the scan is of them
## (`confidence`, 0 to 1), or that there is no scan (NAN).
static func guess_text(frequency: float, amplitude: float, confidence: float) -> String:
	if is_nan(frequency):
		return "GUESS —  NO SCAN"
	return "GUESS %.2f Hz  x%.2f  SURE %d%%" % [frequency, amplitude, roundi(confidence * 100.0)]


## The Boundary countdown as STANDBY's lane reads it: the best figure and its
## plus-or-minus in seconds, or beyond `cap` seconds (INF: the scan cannot
## say better).
static func countdown_text(seconds: float, doubt: float, cap: float) -> String:
	if is_inf(seconds):
		return "BOUNDARY > %d min" % roundi(cap / 60.0)
	return "BOUNDARY %d s ±%d" % [roundi(seconds), ceili(doubt)]


## A channel's name and its Counter-wave as its lane reads them, marked when
## it is the one the Reactor's controls tune.
static func channel_text(title: String, selected: bool, frequency: float, amplitude: float) -> String:
	return "%s%s  %.2f Hz  x%.2f" % ["> " if selected else "", title, frequency, amplitude]


func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	disable_3d = true
	_canvas.display = self
	_canvas.size = Vector2(size)
	add_child(_canvas)


class _Canvas extends Control:
	## The three lines of a lane.
	enum { _WOBBLE, _COUNTER_WAVE, _RESIDUAL }
	## The lanes, top to bottom: the channel and the name written on it.
	const _LANES := [[DiveSimulation.CHANNEL_ACTIVE, "ACTIVE"], [DiveSimulation.CHANNEL_STANDBY, "STANDBY"]]

	var display: PlasmaDisplay
	## Each lane's two lines of writing: its channel and Counter-wave above
	## the waves, its Residual against the Band below them.
	var _channel_lines: Array[Label] = []
	var _residual_lines: Array[Label] = []
	## STANDBY's lane alone: the scan's guess, and the Boundary countdown.
	var _guess := Label.new()
	var _countdown := Label.new()
	var _lost := Label.new()

	func _ready() -> void:
		theme = StationTheme.theme()
		for i in _LANES.size():
			var lane := _lane_rect(i)
			for lines: Array[Label] in [_channel_lines, _residual_lines]:
				var label := Label.new()
				label.add_theme_font_size_override(&"font_size", StationTheme.FONT_SIZE_SMALL)
				add_child(label)
				lines.append(label)
			_channel_lines[i].position = lane.position + Vector2(8.0, 2.0)
			_residual_lines[i].position = lane.position \
					+ Vector2(8.0, lane.size.y - StationTheme.FONT_SIZE_SMALL - 10.0)
		var standby := _lane_rect(_LANES.size() - 1)
		for label: Label in [_guess, _countdown]:
			label.add_theme_font_size_override(&"font_size", StationTheme.FONT_SIZE_SMALL)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.size = Vector2(standby.size.x * 0.5, 0.0)
			add_child(label)
		_guess.position = Vector2(standby.size.x * 0.5 - 8.0, _channel_lines[-1].position.y)
		_countdown.position = Vector2(standby.size.x * 0.5 - 8.0, _residual_lines[-1].position.y)
		_lost.text = "PLASMA LOST"
		_lost.theme_type_variation = StationTheme.variation(StationTheme.WARNING)
		_lost.add_theme_font_size_override(&"font_size", StationTheme.FONT_SIZE_HEADER)
		_lost.position = Vector2(16.0, size.y * 0.4)
		_lost.visible = false
		add_child(_lost)

	func _process(_delta: float) -> void:
		var sim := display.sim
		if sim != null:
			_write(sim)
		queue_redraw()

	## Where lane `index` lies: the lanes share the display's height.
	func _lane_rect(index: int) -> Rect2:
		var height := size.y / _LANES.size()
		return Rect2(0.0, height * index, size.x, height)

	## The lanes' writing, from the simulation.
	func _write(sim: DiveSimulation) -> void:
		var lost := sim.plasma_lost()
		_lost.visible = lost
		_guess.visible = not lost
		_countdown.visible = not lost
		_guess.text = PlasmaDisplay.guess_text(sim.wobble_ahead_frequency(),
				sim.wobble_ahead_amplitude(), sim.wobble_ahead_confidence())
		_guess.theme_type_variation = StationTheme.variation(StationTheme.NOW)
		_countdown.text = PlasmaDisplay.countdown_text(sim.boundary_countdown(),
				sim.boundary_countdown_doubt(), sim.boundary_countdown_cap())
		_countdown.theme_type_variation = StationTheme.variation(StationTheme.NOW)
		for i in _LANES.size():
			var channel: StringName = _LANES[i][0]
			var selected := sim.selected_channel() == channel
			var residual := sim.residual(channel)
			_channel_lines[i].visible = not lost
			_residual_lines[i].visible = not lost
			_channel_lines[i].text = PlasmaDisplay.channel_text(_LANES[i][1], selected,
					sim.counter_wave_frequency(channel), sim.counter_wave_amplitude(channel))
			_channel_lines[i].theme_type_variation = StationTheme.variation(
					StationTheme.SELECTED if selected else StationTheme.LEGEND)
			_residual_lines[i].text = PlasmaDisplay.residual_text(residual, sim.band())
			_residual_lines[i].theme_type_variation = StationTheme.variation(
					StationTheme.CAUTION if _outside(residual, sim.band()) else StationTheme.NOW)

	## Whether a Residual reaches outside the Band (never, while unknown).
	func _outside(residual: float, band: float) -> bool:
		return not is_nan(residual) and residual > band

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), PlasmaDisplay.BACKGROUND)
		var sim := display.sim
		if sim == null or sim.plasma_lost():
			return
		for i in _LANES.size():
			_lane(_lane_rect(i), _LANES[i][0])
		for i in range(1, _LANES.size()):
			var top := _lane_rect(i).position.y
			draw_line(Vector2(0.0, top), Vector2(size.x, top), StationTheme.RULE_COLOUR, 1.0)

	## One channel's lane: the Band, then its Wobble, its Counter-wave and its
	## Residual.
	func _lane(lane: Rect2, channel: StringName) -> void:
		var sim := display.sim
		var residual := sim.residual(channel)
		var band := sim.band()
		var half := lane.size.y * 0.5 * band / PlasmaDisplay.FULL_SCALE
		var mid := lane.position.y + lane.size.y * 0.5
		draw_rect(Rect2(0.0, mid - half, lane.size.x, 2.0 * half),
				StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.15))
		for edge: float in [mid - half, mid + half]:
			draw_line(Vector2(0.0, edge), Vector2(lane.size.x, edge),
					StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.6), 1.0)
		# STANDBY's Wobble is the scan's guess: drawn even with no scan, when
		# it is spurious sines only.
		_trace(lane, channel, _WOBBLE, StationTheme.faded(PlasmaDisplay.WOBBLE, 0.55), 2.0)
		_trace(lane, channel, _COUNTER_WAVE, StationTheme.faded(PlasmaDisplay.COUNTER, 0.7), 2.0)
		if not is_nan(residual):
			_trace(lane, channel, _RESIDUAL,
					PlasmaDisplay.OUTSIDE if _outside(residual, band) else PlasmaDisplay.WOBBLE, 4.0)

	## Draws one of a channel's three waves (_WOBBLE, _COUNTER_WAVE or
	## _RESIDUAL) from SPAN_S seconds ago to now, newest at the right, scaled
	## so FULL_SCALE reaches the lane's edge. A wave the simulation cannot
	## give (NAN) is not drawn.
	func _trace(lane: Rect2, channel: StringName, wave: int, colour: Color, width: float) -> void:
		var sim := display.sim
		var points := PackedVector2Array()
		var steps := 160
		for i in steps + 1:
			var x := lane.size.x * i / steps
			var t := -PlasmaDisplay.SPAN_S * (1.0 - float(i) / steps)
			var value := 0.0
			match wave:
				_WOBBLE: value = sim.wobble_wave(channel, t)
				_COUNTER_WAVE: value = sim.counter_wave(channel, t)
				_RESIDUAL: value = sim.residual_wave(channel, t)
			if is_nan(value):
				return
			var y := clampf(value / PlasmaDisplay.FULL_SCALE, -1.0, 1.0)
			points.append(Vector2(x, lane.position.y + lane.size.y * (0.5 - 0.5 * y)))
		draw_polyline(points, colour, width, true)
