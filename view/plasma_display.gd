## The Reactor Station's instrument, in the body of its screen's frame
## (habitat.gd `_build_stations`): the Shift dial's two channels, and one
## question answered at a glance for each, is the Residual inside the Band.
##
## Two lanes, ACTIVE over STANDBY, like an airliner radio's active and standby
## frequencies. Each reads left to right as a sum:
##
##   the names   the lane's name (cyan and marked TUNING on the one the
##               Reactor's controls tune, with a cyan bar down its edge), then
##               its two waves by name in their own colours with their
##               numbers: the WOBBLE (white: what is happening; STANDBY's is
##               the WOBBLE GUESS, the scan's) and the COUNTER-WAVE (cyan:
##               what the crew has selected), and the verdict in words.
##   the waves   the Wobble and the Counter-wave drawn over one another.
##               STANDBY's Wobble is the scan's guess, a sum of sines: the
##               true Wobble a little off, and spurious sines that fade as the
##               Boundary ahead is better scanned. Over the plot, where the
##               lane's Wobble comes from and how sure the scan is.
##   the sum     the RESIDUAL, the two summed, drawn bold against the BAND, a
##               green strip about the middle line: white inside it, amber
##               once it reaches outside. Flat when the cancelling is perfect,
##               a wave of one size when the amplitude is off, one that swells
##               and fades when the frequency is off.
##
## STANDBY's Residual is PREDICTED: its number is the Counter-wave against the
## guess's true part, and the plus-or-minus beside it is the scan's spurious
## sines, which stay in the line drawn as a ripple no tuning removes. So a
## poor scan cannot draw a flat line, and the verdict does not call it safe.
##
## Under the lanes: the Boundary countdown with its plus-or-minus and a track
## the Boundary comes down toward NOW, giving way to "BOUNDARY CROSSED" until
## the Residual is back inside the Band; the Band beside what it has narrowed
## from (a fresh Head's with the hull cool, also the faint lines in each sum);
## and the Head's wear. The Caution lamps are in the Station's header strip
## (CautionLamps).
##
## Every wave is the simulation's own (DiveSimulation.wobble_wave(),
## counter_wave(), residual_wave()) on the dive's clock, and the Band is
## band() at the Residual's own scale, so the picture is what wears the Head
## and a still of it is the dive at that moment. It reads only the simulation
## and keeps no state. Its writing is Labels under the Theme; its colours are
## StationTheme's.
class_name PlasmaDisplay
extends Control

## Seconds of wave across a plot, the newest at the right: long enough for a
## slow beat to be seen swelling and fading.
const SPAN_S := 6.0
## The value drawn at the edge of a waves plot: a little more than the
## biggest Wobble.
const WAVE_SCALE := 1.25
## The value drawn at the edge of a Residual plot. Smaller than WAVE_SCALE,
## so the Band is wide enough to judge by; a Residual past it is pinned to
## the edge, far outside the Band either way.
const RESIDUAL_SCALE := 0.5
## The seconds the countdown's track runs from NOW at its left.
const TRACK_S := 120.0
## The mark on the lane the Reactor's controls tune.
const TUNING := "TUNING"

## The lanes, top to bottom: the channel and the name written on it.
const _LANES := [[DiveSimulation.CHANNEL_ACTIVE, "ACTIVE"], [DiveSimulation.CHANNEL_STANDBY, "STANDBY"]]
## Points along a drawn wave.
const _STEPS := 240
## The layout, in the screen's pixels: the strip under the lanes, the names'
## column, the row of writing over a plot, a row of the names' column, and
## the margins.
const _FOOT_PX := 50.0
const _NAMES_PX := 318.0
const _HEAD_ROW_PX := 24.0
const _ROW_PX := 24.0
const _EDGE_PX := 12.0
const _GAP_PX := 10.0
## The share of the plots' width the waves plot takes; the Residual's has
## the rest.
const _WAVES_SHARE := 0.4

var sim: DiveSimulation

## Each lane's writing, by channel: {name, tuning, wobble, wobble_numbers,
## counter, counter_numbers, verdict, source, residual, band}.
var _lanes := {}
var _boundary := Label.new()
var _swap := Label.new()
var _now := Label.new()
var _far := Label.new()
var _band := Label.new()
var _wear := Label.new()
var _lost := Label.new()
## How often it brings itself up to the simulation: every frame while the
## crew is at the Reactor, a few times a second while they are not.
var _pace := ScreenPace.new()


# --- What it reads, as words --------------------------------------------------

## A wave's frequency and amplitude, or a dash for one there is no scan of.
static func wave_text(frequency: float, amplitude: float) -> String:
	if is_nan(frequency):
		return "—"
	return "%.2f Hz x%.2f" % [frequency, amplitude]


## ACTIVE's Residual at its fullest, over its plot; none while no Wobble
## reaches the plasma (a Glide, and the idle after it: NAN).
static func residual_text(residual: float) -> String:
	if is_nan(residual):
		return "RESIDUAL —"
	return "RESIDUAL %.2f" % residual


## STANDBY's predicted Residual over its plot: the Counter-wave against the
## guess's true part, plus or minus the scan's spurious sines (`spurious`,
## their amplitudes summed), which the line drawn keeps as a ripple. A dash
## with no scan (NAN).
static func predicted_text(residual: float, spurious: float) -> String:
	if is_nan(residual):
		return "PREDICTED —"
	if roundi(spurious * 100.0) == 0:
		return "PREDICTED %.2f" % residual
	return "PREDICTED %.2f ±%.2f" % [residual, spurious]


## How sure the scan is of its guess of the Wobble ahead (`confidence`, 0 to
## 1), or that there is no scan (a NAN frequency).
static func sure_text(frequency: float, confidence: float) -> String:
	if is_nan(frequency):
		return "NO SCAN AHEAD"
	return "GUESS SURE %d%%" % roundi(confidence * 100.0)


## A lane's verdict as [words, meaning]: whether its Residual at its fullest
## is inside the Band. A `predicted` one (STANDBY's) is only as true as the
## scan: with no scan (NAN) there is none, and while the scan's spurious
## sines could take it outside the Band it is not called inside.
static func verdict(residual: float, band: float, spurious: float, predicted: bool) -> Array:
	if not predicted and is_nan(residual):
		return ["NO WOBBLE ON THE PLASMA", StationTheme.LEGEND]
	if not predicted:
		return ["RESIDUAL OUT OF THE BAND", StationTheme.CAUTION] if residual > band \
				else ["RESIDUAL INSIDE THE BAND", StationTheme.NOW]
	if is_nan(residual):
		return ["NO SCAN: NO PREDICTION", StationTheme.LEGEND]
	if residual > band:
		return ["PREDICTED OUT OF THE BAND", StationTheme.CAUTION]
	if residual + spurious > band:
		return ["IN BAND IF THE SCAN IS RIGHT", StationTheme.NOW]
	return ["PREDICTED INSIDE THE BAND", StationTheme.NOW]


## The Boundary countdown: the best figure and its plus-or-minus in seconds,
## or beyond `cap` seconds (INF: the scan cannot say better).
static func countdown_text(seconds: float, doubt: float, cap: float) -> String:
	if is_inf(seconds):
		return "BOUNDARY > %d min" % roundi(cap / 60.0)
	return "BOUNDARY IN %d s ±%d" % [roundi(seconds), ceili(doubt)]


## The Band beside the widest it can be.
static func band_text(band: float, widest: float) -> String:
	return "BAND %.2f OF %.2f" % [band, widest]


## Where along the countdown's track a Boundary `seconds` off stands: 0 at
## NOW, 1 at TRACK_S and beyond.
static func track_place(seconds: float) -> float:
	return clampf(seconds / TRACK_S, 0.0, 1.0)


## The height on the screen of a wave's `value` in `plot`, with `full_scale`
## at the plot's top edge and its negative at the bottom; a value beyond is
## pinned to the edge.
static func value_y(plot: Rect2, value: float, full_scale: float) -> float:
	return plot.get_center().y - plot.size.y / 2.0 * clampf(value / full_scale, -1.0, 1.0)


# --- What it shows, read from the simulation ----------------------------------

## Under the lanes: the countdown, or that the Boundary is crossed, from the
## crossing until the Residual is back inside the Band.
func boundary_text() -> String:
	if sim.settling_in():
		return "BOUNDARY CROSSED"
	return countdown_text(sim.boundary_countdown(), sim.boundary_countdown_doubt(),
			sim.boundary_countdown_cap())


## Under that, once crossed: the key that swaps STANDBY in. "" before.
func swap_text() -> String:
	return "PRESS %s TO SWAP STANDBY IN" % KeyMap.label(&"shift") if sim.settling_in() else ""


func boundary_meaning() -> StringName:
	return StationTheme.CAUTION if sim.settling_in() else StationTheme.NOW


func wear_text() -> String:
	return "HEAD WEAR %d%%" % roundi(sim.head_wear() * 100.0)


## The Band as a share of the widest it can be.
func band_share() -> float:
	return sim.band() / sim.band_widest()


## Where lane `index` lies: the lanes share the height over the foot.
func lane_rect(index: int) -> Rect2:
	var height := (size.y - _FOOT_PX) / _LANES.size()
	return Rect2(0.0, height * index, size.x, height)


## Where a channel's Wobble and Counter-wave are drawn.
func waves_plot(channel: StringName) -> Rect2:
	var room := _plots(channel)
	return Rect2(room.position, Vector2((room.size.x - _GAP_PX) * _WAVES_SHARE, room.size.y))


## Where a channel's Residual is drawn against the Band.
func residual_plot(channel: StringName) -> Rect2:
	var room := _plots(channel)
	var from := waves_plot(channel).end.x + _GAP_PX
	return Rect2(from, room.position.y, room.end.x - from, room.size.y)


## The drawn Band's top and bottom edges in a channel's Residual plot, as
## Vector2(top, bottom): band() either side of the middle line, at the
## Residual's scale.
func band_edges(channel: StringName) -> Vector2:
	var plot := residual_plot(channel)
	return Vector2(value_y(plot, sim.band(), RESIDUAL_SCALE), value_y(plot, -sim.band(), RESIDUAL_SCALE))


## A channel's Residual as it is drawn, oldest to newest; empty when the
## simulation has none to give (STANDBY with no scan).
func residual_points(channel: StringName) -> PackedVector2Array:
	return _line(residual_plot(channel), _waves(channel).residual, RESIDUAL_SCALE)


## The words on a channel's lane that are showing.
func lane_texts(channel: StringName) -> PackedStringArray:
	return _showing(_lanes[channel].values())


## Every word on the instrument that is showing.
func texts() -> PackedStringArray:
	return _showing(labels())


## Every Label of the instrument, showing or not.
func labels() -> Array[Label]:
	var all: Array[Label] = [_boundary, _swap, _now, _far, _band, _wear, _lost]
	for lane: Dictionary in _lanes.values():
		for label: Label in lane.values():
			all.append(label)
	return all


## What the crew can point at on the instrument, each a rectangle in its own
## pixels (StationScreen.instrument_readings()): each channel's lane, then
## the foot's three parts.
func readings() -> Dictionary:
	var foot := _foot_parts()
	return {
		&"active": lane_rect(_index(DiveSimulation.CHANNEL_ACTIVE)),
		&"standby": lane_rect(_index(DiveSimulation.CHANNEL_STANDBY)),
		&"boundary_countdown": foot[0],
		&"band": foot[1],
		&"head_wear": foot[2],
	}


## Brings the writing up to the simulation, and asks for the waves to be
## drawn anew: every frame while the crew is at the Reactor, and at least
## every ScreenPace.UNWATCHED_S while they are not (_process()).
func refresh() -> void:
	if sim == null or _lanes.is_empty():
		return
	_write()
	_place()
	queue_redraw()


# --- Inside -------------------------------------------------------------------

func _init() -> void:
	theme = StationTheme.theme()
	clip_contents = true
	for lane: Array in _LANES:
		var writing := {}
		for part: StringName in [&"name", &"tuning", &"wobble", &"wobble_numbers", &"counter",
				&"counter_numbers", &"verdict", &"source", &"residual", &"band"]:
			writing[part] = _label(StationTheme.FONT_SIZE if part == &"name" else StationTheme.FONT_SIZE_SMALL)
		writing.name.text = lane[1]
		writing.tuning.text = TUNING
		writing.counter.text = "COUNTER-WAVE"
		writing.band.text = "BAND"
		_lanes[lane[0]] = writing
	for label: Label in [_boundary, _swap, _now, _far, _band, _wear]:
		_own(label, StationTheme.FONT_SIZE_SMALL)
	_now.text = "NOW"
	_far.text = "%d min" % roundi(TRACK_S / 60.0)
	_own(_lost, StationTheme.FONT_SIZE_HEADER)
	_lost.text = "PLASMA LOST"
	_lost.visible = false


func _process(delta: float) -> void:
	if _pace.due_at(delta, sim, DiveSimulation.STATION_REACTOR):
		refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_pace.hurry()


func _label(font_size: int) -> Label:
	return _own(Label.new(), font_size)


func _own(label: Label, font_size: int) -> Label:
	label.add_theme_font_size_override(&"font_size", font_size)
	add_child(label)
	return label


func _showing(of: Array) -> PackedStringArray:
	var words := PackedStringArray()
	for label: Label in of:
		if label.visible and not label.text.is_empty():
			words.append(label.text)
	return words


func _mean(label: Label, meaning: StringName) -> void:
	label.theme_type_variation = StationTheme.variation(meaning)


## The room a channel's two plots share: right of the names, under the row
## of writing over them.
func _plots(channel: StringName) -> Rect2:
	var lane := lane_rect(_index(channel))
	return Rect2(_NAMES_PX, lane.position.y + _HEAD_ROW_PX,
			lane.size.x - _NAMES_PX - _EDGE_PX, lane.size.y - _HEAD_ROW_PX - 6.0)


func _index(channel: StringName) -> int:
	for i in _LANES.size():
		if _LANES[i][0] == channel:
			return i
	return 0


## The foot's three parts, left to right: the countdown, the Band, the wear.
func _foot_parts() -> Array[Rect2]:
	var top := size.y - _FOOT_PX + 2.0
	var high := _FOOT_PX - 2.0
	var wide := size.x - 2.0 * _EDGE_PX
	var band_from := _EDGE_PX + wide * 0.49
	var wear_from := _EDGE_PX + wide * 0.77
	return [Rect2(_EDGE_PX, top, band_from - _EDGE_PX - 2.0 * _GAP_PX, high),
			Rect2(band_from, top, wear_from - band_from - 2.0 * _GAP_PX, high),
			Rect2(wear_from, top, size.x - _EDGE_PX - wear_from, high)]


## The bar under a foot part's writing.
func _foot_bar(part: Rect2) -> Rect2:
	return Rect2(part.position.x, part.position.y + _ROW_PX + 4.0, part.size.x, 10.0)


## The countdown's track: between NOW and the far end's name.
func _track() -> Rect2:
	var bar := _foot_bar(_foot_parts()[0])
	var from := bar.position.x + _now.get_minimum_size().x + 8.0
	var to := bar.end.x - _far.get_minimum_size().x - 8.0
	return Rect2(from, bar.position.y, to - from, bar.size.y)


## The words, from the simulation.
func _write() -> void:
	var lost := sim.plasma_lost()
	var band := sim.band()
	_lost.visible = lost
	_mean(_lost, StationTheme.WARNING)
	for label: Label in [_boundary, _swap, _now, _far, _band]:
		label.visible = not lost
	_boundary.text = boundary_text()
	_mean(_boundary, boundary_meaning())
	_swap.text = swap_text()
	_mean(_swap, boundary_meaning())
	var tracked := not lost and not sim.settling_in()
	_now.visible = tracked
	_far.visible = tracked
	_mean(_now, StationTheme.LEGEND)
	_mean(_far, StationTheme.LEGEND)
	_band.text = band_text(band, sim.band_widest())
	_mean(_band, StationTheme.ENGAGED)
	_wear.text = wear_text()
	_mean(_wear, StationTheme.CAUTION if DiveSimulation.CAUSE_WORN in sim.steadiness_causes()
			else StationTheme.NOW)
	for lane: Array in _LANES:
		var channel: StringName = lane[0]
		var writing: Dictionary = _lanes[channel]
		for label: Label in writing.values():
			label.visible = not lost
		if lost:
			continue
		var standby := channel == DiveSimulation.CHANNEL_STANDBY
		var selected := sim.selected_channel() == channel
		var residual := sim.residual(channel)
		var spurious := sim.wobble_ahead_spurious() if standby else 0.0
		_mean(writing.name, StationTheme.SELECTED if selected else StationTheme.NOW)
		writing.tuning.visible = selected
		_mean(writing.tuning, StationTheme.SELECTED)
		writing.wobble.text = "WOBBLE GUESS" if standby else "WOBBLE"
		writing.wobble_numbers.text = wave_text(sim.wobble_ahead_frequency(),
				sim.wobble_ahead_amplitude()) if standby else ""
		_mean(writing.counter, StationTheme.SELECTED)
		writing.counter_numbers.text = wave_text(sim.counter_wave_frequency(channel),
				sim.counter_wave_amplitude(channel))
		_mean(writing.counter_numbers, StationTheme.SELECTED)
		var said := verdict(residual, band, spurious, standby)
		writing.verdict.text = said[0]
		_mean(writing.verdict, said[1])
		if standby:
			writing.source.text = sure_text(sim.wobble_ahead_frequency(), sim.wobble_ahead_confidence())
		else:
			writing.source.text = "ON THE HEAD NOW"
		_mean(writing.source, StationTheme.LEGEND)
		writing.residual.text = predicted_text(residual, spurious) if standby else residual_text(residual)
		_mean(writing.residual, StationTheme.CAUTION if _outside(residual, band) else StationTheme.NOW)
		_mean(writing.band, StationTheme.ENGAGED)


## Puts every word in its place, by the instrument's size now.
func _place() -> void:
	for lane: Array in _LANES:
		var channel: StringName = lane[0]
		var writing: Dictionary = _lanes[channel]
		var rect := lane_rect(_index(channel))
		var left := _EDGE_PX + 4.0
		var right := _NAMES_PX - _GAP_PX
		var name_high: float = writing.name.get_minimum_size().y
		var row_high: float = writing.wobble.get_minimum_size().y
		# The three rows under the name share what the lane has left, a row
		# never further below the last than a row's own height.
		var under := rect.position.y + name_high - 5.0
		var row := minf(row_high, (rect.end.y - under - row_high) / 2.0)
		var y := under
		writing.name.position = Vector2(left, rect.position.y)
		writing.tuning.position = Vector2(left + writing.name.get_minimum_size().x + 14.0,
				rect.position.y + name_high - writing.tuning.get_minimum_size().y - 2.0)
		writing.wobble.position = Vector2(left, y)
		_right(writing.wobble_numbers, right, y)
		writing.counter.position = Vector2(left, y + row)
		_right(writing.counter_numbers, right, y + row)
		writing.verdict.position = Vector2(left, y + 2.0 * row)
		var waves := waves_plot(channel)
		var sum := residual_plot(channel)
		var over := rect.position.y
		writing.source.position = Vector2(waves.position.x, over)
		writing.residual.position = Vector2(sum.position.x, over)
		_right(writing.band, sum.end.x, over)
	var parts := _foot_parts()
	_boundary.position = parts[0].position
	_swap.position = parts[0].position + Vector2(0.0, _ROW_PX - 4.0)
	_band.position = parts[1].position
	_wear.position = parts[2].position
	var bar := _foot_bar(parts[0])
	var beside := bar.get_center().y - _now.get_minimum_size().y / 2.0
	_now.position = Vector2(bar.position.x, beside)
	_right(_far, bar.end.x, beside)
	_lost.position = (size - _lost.get_minimum_size()) / 2.0


## Places a Label with its right end at `x`.
func _right(label: Label, x: float, y: float) -> void:
	label.position = Vector2(x - label.get_minimum_size().x, y)


## Whether a Residual reaches outside the Band (never, while unknown).
func _outside(residual: float, band: float) -> bool:
	return not is_nan(residual) and residual > band


## A channel's three waves from SPAN_S seconds ago to now, one point for
## each of _STEPS (DiveSimulation.waves()).
func _waves(channel: StringName) -> Dictionary:
	return sim.waves(channel, SPAN_S, _STEPS)


## One wave's `values` across `plot`, oldest at the left; empty for a wave the
## simulation cannot give (NAN).
func _line(plot: Rect2, values: PackedFloat64Array, full_scale: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var last := values.size() - 1
	for i in values.size():
		if is_nan(values[i]):
			return PackedVector2Array()
		points.append(Vector2(plot.position.x + plot.size.x * float(i) / last,
				value_y(plot, values[i], full_scale)))
	return points


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), StationTheme.SCREEN_COLOUR)
	if sim == null:
		return
	var foot := size.y - _FOOT_PX
	draw_line(Vector2(0.0, foot), Vector2(size.x, foot), StationTheme.RULE_COLOUR, 2.0)
	_draw_wear(_foot_bar(_foot_parts()[2]))
	if sim.plasma_lost():
		return
	for i in _LANES.size():
		_draw_lane(i)
	_draw_track()
	_draw_band_bar(_foot_bar(_foot_parts()[1]))


## One channel's lane: its edge (cyan on the one being tuned), its waves, and
## its Residual against the Band.
func _draw_lane(index: int) -> void:
	var channel: StringName = _LANES[index][0]
	var lane := lane_rect(index)
	if index > 0:
		draw_line(lane.position, Vector2(lane.end.x, lane.position.y), StationTheme.RULE_COLOUR, 1.0)
	if sim.selected_channel() == channel:
		draw_rect(Rect2(lane.position.x, lane.position.y + 3.0, 6.0, lane.size.y - 6.0),
				StationTheme.SELECTED_COLOUR)

	var traced := _waves(channel)
	var waves := waves_plot(channel)
	_draw_plot(waves)
	_draw_wave(_line(waves, traced.wobble, WAVE_SCALE), StationTheme.NOW_COLOUR, 2.0)
	_draw_wave(_line(waves, traced.counter, WAVE_SCALE), StationTheme.SELECTED_COLOUR, 2.0)

	var sum := residual_plot(channel)
	_draw_plot(sum)
	var edges := band_edges(channel)
	draw_rect(Rect2(sum.position.x, edges.x, sum.size.x, edges.y - edges.x),
			StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.22))
	for edge: float in [edges.x, edges.y]:
		draw_line(Vector2(sum.position.x, edge), Vector2(sum.end.x, edge),
				StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.8), 1.5)
	# What the Band has narrowed from: a fresh Head's, the hull cool.
	if band_share() < 0.97:
		for sign: float in [1.0, -1.0]:
			var widest := value_y(sum, sign * sim.band_widest(), RESIDUAL_SCALE)
			draw_dashed_line(Vector2(sum.position.x, widest), Vector2(sum.end.x, widest),
					StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.45), 1.0, 6.0)
	var residual := sim.residual(channel)
	_draw_wave(_line(sum, traced.residual, RESIDUAL_SCALE), StationTheme.CAUTION_COLOUR if _outside(residual, sim.band())
			else StationTheme.NOW_COLOUR, 3.5)


## A plot's frame and its middle line.
func _draw_plot(plot: Rect2) -> void:
	draw_rect(plot, StationTheme.faded(StationTheme.RULE_COLOUR, 0.25))
	draw_rect(plot, StationTheme.RULE_COLOUR, false, 1.0)
	var mid := plot.get_center().y
	draw_line(Vector2(plot.position.x, mid), Vector2(plot.end.x, mid),
			StationTheme.faded(StationTheme.RULE_COLOUR, 0.8), 1.0)


func _draw_wave(points: PackedVector2Array, colour: Color, width: float) -> void:
	if points.size() > 1:
		draw_polyline(points, colour, width, true)


## The countdown's track: NOW at its left, the Boundary coming down it, with
## its plus-or-minus as a span either side. Not drawn once crossed.
func _draw_track() -> void:
	if sim.settling_in():
		return
	var track := _track()
	var mid := track.get_center().y
	draw_line(Vector2(track.position.x, mid), Vector2(track.end.x, mid), StationTheme.RULE_COLOUR, 2.0)
	for i in 5:
		var x := track.position.x + track.size.x * i / 4.0
		draw_line(Vector2(x, mid - 4.0), Vector2(x, mid + 4.0), StationTheme.RULE_COLOUR, 2.0)
	var seconds := sim.boundary_countdown()
	if is_inf(seconds):
		return
	var at := track.position.x + track.size.x * track_place(seconds)
	var doubt := sim.boundary_countdown_doubt()
	var from := track.position.x + track.size.x * track_place(seconds - doubt)
	var to := track.position.x + track.size.x * track_place(seconds + doubt)
	draw_rect(Rect2(from, mid - 3.0, to - from, 6.0), StationTheme.faded(StationTheme.NOW_COLOUR, 0.45))
	draw_rect(Rect2(at - 2.0, track.position.y - 2.0, 4.0, track.size.y + 4.0), StationTheme.NOW_COLOUR)


## The Band as a bar: filled to its share of the widest it can be.
func _draw_band_bar(bar: Rect2) -> void:
	draw_rect(bar, StationTheme.RULE_COLOUR, false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(band_share(), 0.0, 1.0), bar.size.y)),
			StationTheme.faded(StationTheme.ENGAGED_COLOUR, 0.8))


## The Head's wear as a bar: filled as it wears.
func _draw_wear(bar: Rect2) -> void:
	draw_rect(bar, StationTheme.RULE_COLOUR, false, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(sim.head_wear(), 0.0, 1.0), bar.size.y)),
			StationTheme.colour(StationTheme.CAUTION if DiveSimulation.CAUSE_WORN in sim.steadiness_causes()
			else StationTheme.NOW))
