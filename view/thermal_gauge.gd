## The Thermal Station's instrument, in the body of its screen's frame
## (habitat.gd `_build_stations`): the hull's temperature on a scale against
## what the hull bears, and where the heat is sent.
##
##   the gauge  a bar along a scale in kelvin, filled to the hull's
##              temperature (vessel_temperature()). The amber range starts at
##              hull_warning_temperature() and the red at
##              hull_damage_temperature(), the simulation's own thresholds:
##              in the amber the heat warning is on, in the red the hull
##              creeps. The bar and the number above it take the colour of
##              the range the hull is in.
##   the trend  an arrow from the hull's place on the scale to where it will
##              be in TREND_AHEAD_S at the rate it is changing now
##              (hull_warming_rate()), as an airliner's speed trend arrow
##              does; beside the number, a triangle up or down and RISING or
##              FALLING, a bar and STEADY when it is neither.
##   the split  one bar divided where the heat divides: out through the hull
##              on the left, into the Column on the right (heat_outward(),
##              heat_to_column()), with the crew's setting (heat_split()) as
##              a cyan mark under it. Starved pumps show as the division
##              standing short of the mark.
##
## It reads only the simulation and keeps no state: every frame is drawn from
## the queries, so it shows the same in a screenshot as in play. Its colours
## are StationTheme's.
class_name ThermalGauge
extends Control

## The cool end of the scale, in kelvin: below any rock the first dive meets.
const SCALE_FROM_K := 250.0
## How far past the temperature the hull bears the scale runs, as a share of
## the scale below it, so the red range has room and an overheating hull
## still moves along it.
const PAST_LIMIT := 0.3
## A marked temperature every this many kelvin along the scale.
const TICK_EVERY_K := 100.0
## The trend arrow reaches to where the hull will be this many seconds on.
const TREND_AHEAD_S := 30.0
## A hull changing slower than this, in kelvin per second, reads as steady.
const STEADY_K_PER_S := 0.05

## The plain height the gauge is laid out for, in pixels; a taller or
## shorter body scales it (within MOST_ZOOM and LEAST_ZOOM).
const PLAIN_HEIGHT := 206.0
const LEAST_ZOOM := 0.8
const MOST_ZOOM := 1.5
const MARGIN_PX := 16.0

var sim: DiveSimulation


func _process(_delta: float) -> void:
	queue_redraw()


# --- What it shows, read from the simulation --------------------------------

## The scale's ends in kelvin.
func scale_from() -> float:
	return SCALE_FROM_K


func scale_to() -> float:
	var bears := sim.hull_damage_temperature()
	return bears + (bears - SCALE_FROM_K) * PAST_LIMIT


## Where a temperature stands along the scale, 0 (its cool end) to 1; one off
## the scale is pinned to the nearer end.
func place(kelvin: float) -> float:
	return clampf(inverse_lerp(scale_from(), scale_to(), kelvin), 0.0, 1.0)


## The temperature at a place along the scale.
func kelvin_at(along: float) -> float:
	return lerpf(scale_from(), scale_to(), along)


## Where the hull stands along the scale now.
func needle() -> float:
	return place(sim.vessel_temperature())


## Where the amber range starts along the scale, and the red.
func caution_from() -> float:
	return place(sim.hull_warning_temperature())


func warning_from() -> float:
	return place(sim.hull_damage_temperature())


## What a hull at this temperature means, as StationTheme has it: a warning
## above what it bears (it creeps), a caution from the warning temperature,
## else simply what is happening now.
func range_of(kelvin: float) -> StringName:
	if kelvin > sim.hull_damage_temperature():
		return StationTheme.WARNING
	if kelvin >= sim.hull_warning_temperature():
		return StationTheme.CAUTION
	return StationTheme.NOW


## What the hull's temperature means now.
func meaning() -> StringName:
	return range_of(sim.vessel_temperature())


## Which way the hull is going: 1 rising, -1 falling, 0 steady.
func trend() -> int:
	var rate := sim.hull_warming_rate()
	return 0 if absf(rate) < STEADY_K_PER_S else signi(roundi(signf(rate)))


## Where along the scale the hull will be TREND_AHEAD_S on at the rate it is
## changing now: the trend arrow's tip. The needle itself while steady.
func trend_place() -> float:
	if trend() == 0:
		return needle()
	return place(sim.vessel_temperature() + sim.hull_warming_rate() * TREND_AHEAD_S)


## The share of the heat now going into the Column, 0 to 1; the rest goes out
## through the hull. With the Head dark nothing is made, and all the pumps
## carry goes into the Column.
func column_share() -> float:
	var made := sim.heat_produced()
	if made <= 0.0:
		return 1.0 if sim.heat_to_column() > 0.0 else 0.0
	return clampf(sim.heat_to_column() / made, 0.0, 1.0)


## The share of the heat the crew has set to go into the Column.
func split_set() -> float:
	return sim.heat_split()


# --- Where it draws ---------------------------------------------------------

## How much larger than its plain size the gauge is drawn, from its height.
func zoom() -> float:
	return clampf(size.y / PLAIN_HEIGHT, LEAST_ZOOM, MOST_ZOOM)


## The gauge's parts, top to bottom, each a rectangle in its own pixels: the
## readout (the number and the trend), the lane the trend arrow runs in, the
## scale's bar, its marks, the split's captions, its bar and the setting's
## mark under it.
func parts() -> Array[Rect2]:
	var z := zoom()
	var left := MARGIN_PX
	var wide := size.x - 2.0 * MARGIN_PX
	var heights := [44.0, 12.0, 26.0, 26.0, 26.0, 22.0, 26.0]
	var gaps := [2.0, 0.0, 0.0, 10.0, 2.0, 0.0, 0.0]
	var used := 0.0
	for i in heights.size():
		used += (heights[i] + gaps[i]) * z
	var y := maxf(0.0, (size.y - used) / 2.0)
	var rects: Array[Rect2] = []
	for i in heights.size():
		rects.append(Rect2(left, y, wide, heights[i] * z))
		y += (heights[i] + gaps[i]) * z
	return rects


## What the crew can point at on the gauge, each a rectangle in its own
## pixels (StationScreen.instrument_readings()): the hull's temperature (the
## readout, the trend, the scale and its marks) and the heat split.
func readings() -> Dictionary:
	var rects := parts()
	return {
		&"hull_temperature": rects[0].merge(rects[3]),
		&"heat_split": rects[4].merge(rects[6]),
	}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), StationTheme.SCREEN_COLOUR)
	if sim == null:
		return
	var font := get_theme_default_font()
	var rects := parts()
	_draw_readout(rects[0], font)
	_draw_trend_arrow(rects[1])
	_draw_scale(rects[2])
	_draw_marks(rects[3], font)
	_draw_split(rects[4], rects[5], rects[6], font)


## "HULL 534 K", the trend beside it, and the Medium round the hull at the
## right.
func _draw_readout(row: Rect2, font: Font) -> void:
	var z := zoom()
	var small := roundi(StationTheme.FONT_SIZE_SMALL * z)
	var large := roundi(38 * z)
	var base := row.end.y - 8.0 * z
	var colour := StationTheme.colour(meaning())
	var x := row.position.x
	draw_string(font, Vector2(x, base), "HULL", HORIZONTAL_ALIGNMENT_LEFT, -1, small,
			StationTheme.LEGEND_COLOUR)
	x += font.get_string_size("HULL", HORIZONTAL_ALIGNMENT_LEFT, -1, small).x + 10.0 * z
	var number := "%.0f K" % sim.vessel_temperature()
	draw_string(font, Vector2(x, base), number, HORIZONTAL_ALIGNMENT_LEFT, -1, large, colour)
	x += font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, large).x + 18.0 * z

	# The trend: a triangle up or down, a bar when steady, and the word.
	var going := trend()
	var mark := Vector2(x + 9.0 * z, base - 13.0 * z)
	var reach := 11.0 * z
	if going == 0:
		draw_rect(Rect2(mark.x - reach, mark.y - 2.0 * z, 2.0 * reach, 4.0 * z), colour)
	else:
		draw_colored_polygon(PackedVector2Array([mark + Vector2(0.0, -reach * going),
				mark + Vector2(reach, reach * going), mark + Vector2(-reach, reach * going)]), colour)
	x += 2.0 * reach + 8.0 * z
	var words := "STEADY"
	if going != 0:
		words = "%s %.1f K/s" % ["RISING" if going > 0 else "FALLING", absf(sim.hull_warming_rate())]
	draw_string(font, Vector2(x, base), words, HORIZONTAL_ALIGNMENT_LEFT, -1, small, colour)

	var medium := "Medium %.0f K" % sim.surroundings_temperature()
	draw_string(font, Vector2(row.position.x, base), medium, HORIZONTAL_ALIGNMENT_RIGHT, row.size.x,
			small, StationTheme.LEGEND_COLOUR)


## The trend arrow, in its lane over the bar: from the hull's place to where
## it is heading, in the colour of the range its tip lies in.
func _draw_trend_arrow(lane: Rect2) -> void:
	if trend() == 0:
		return
	var from := lane.position.x + lane.size.x * needle()
	var to := lane.position.x + lane.size.x * trend_place()
	var colour := StationTheme.colour(range_of(kelvin_at(trend_place())))
	var mid := lane.position.y + lane.size.y / 2.0
	var head := minf(lane.size.y, absf(to - from))
	var toward := signf(to - from)
	draw_line(Vector2(from, mid), Vector2(to - toward * head, mid), colour, maxf(3.0, lane.size.y / 3.0))
	draw_colored_polygon(PackedVector2Array([Vector2(to, mid),
			Vector2(to - toward * head, lane.position.y), Vector2(to - toward * head, lane.end.y)]), colour)


## The scale's bar: its ranges behind, filled to the hull's temperature, the
## needle at the fill's end.
func _draw_scale(bar: Rect2) -> void:
	var amber := bar.position.x + bar.size.x * caution_from()
	var red := bar.position.x + bar.size.x * warning_from()
	draw_rect(Rect2(bar.position.x, bar.position.y, amber - bar.position.x, bar.size.y),
			StationTheme.faded(StationTheme.RULE_COLOUR, 0.6))
	draw_rect(Rect2(amber, bar.position.y, red - amber, bar.size.y),
			StationTheme.faded(StationTheme.CAUTION_COLOUR, 0.3))
	draw_rect(Rect2(red, bar.position.y, bar.end.x - red, bar.size.y),
			StationTheme.faded(StationTheme.WARNING_COLOUR, 0.3))
	var at := bar.position.x + bar.size.x * needle()
	var inset := bar.size.y * 0.22
	draw_rect(Rect2(bar.position.x, bar.position.y + inset, at - bar.position.x, bar.size.y - 2.0 * inset),
			StationTheme.colour(meaning()))
	# The ranges' edges stay in sight over the fill.
	draw_line(Vector2(amber, bar.position.y), Vector2(amber, bar.end.y), StationTheme.CAUTION_COLOUR, 2.0)
	draw_line(Vector2(red, bar.position.y), Vector2(red, bar.end.y), StationTheme.WARNING_COLOUR, 2.0)
	draw_line(Vector2(at, bar.position.y - 3.0), Vector2(at, bar.end.y + 3.0), StationTheme.NOW_COLOUR, 4.0)


## Under the bar: a tick and its kelvin every TICK_EVERY_K, and the two
## thresholds named in their own colours, which a tick's number gives way to.
func _draw_marks(row: Rect2, font: Font) -> void:
	var z := zoom()
	var small := roundi(StationTheme.FONT_SIZE_SMALL * z)
	var base := row.position.y + 6.0 * z + font.get_ascent(small)
	var taken: Array[Rect2] = []
	var named := [
		[sim.hull_damage_temperature(), "%.0f BEARS" % sim.hull_damage_temperature(), StationTheme.WARNING_COLOUR, false],
		[sim.hull_warning_temperature(), "WARNS %.0f" % sim.hull_warning_temperature(), StationTheme.CAUTION_COLOUR, true],
	]
	for mark: Array in named:
		var x: float = row.position.x + row.size.x * place(mark[0])
		var width := font.get_string_size(mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
		# The warning's name ends at its edge, the limit's starts at its own,
		# so the two never run into each other however close the thresholds.
		var from := x - width - 4.0 * z if mark[3] else x + 4.0 * z
		draw_line(Vector2(x, row.position.y), Vector2(x, row.position.y + 8.0 * z), mark[2], 2.0)
		draw_string(font, Vector2(from, base), mark[1], HORIZONTAL_ALIGNMENT_LEFT, -1, small, mark[2])
		taken.append(Rect2(from, row.position.y, width, row.size.y).grow_individual(8.0 * z, 0.0, 8.0 * z, 0.0))
	var kelvin := ceilf(scale_from() / TICK_EVERY_K) * TICK_EVERY_K
	while kelvin <= scale_to():
		var x := row.position.x + row.size.x * place(kelvin)
		var text := "%.0f" % kelvin
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
		var from := clampf(x - width / 2.0, row.position.x, row.end.x - width)
		var box := Rect2(from, row.position.y, width, row.size.y)
		draw_line(Vector2(x, row.position.y), Vector2(x, row.position.y + 5.0 * z), StationTheme.LEGEND_COLOUR, 1.0)
		if not taken.any(func(other: Rect2) -> bool: return other.intersects(box)):
			draw_string(font, Vector2(from, base), text, HORIZONTAL_ALIGNMENT_LEFT, -1, small,
					StationTheme.LEGEND_COLOUR)
		kelvin += TICK_EVERY_K


## Where the heat is sent: one bar divided where the heat divides, out
## through the hull on the left and into the Column on the right, each with
## its amount over it, and the crew's setting marked under it in cyan.
func _draw_split(captions: Rect2, bar: Rect2, setting: Rect2, font: Font) -> void:
	var z := zoom()
	var small := roundi(StationTheme.FONT_SIZE_SMALL * z)
	var base := captions.position.y + font.get_ascent(small)
	draw_string(font, Vector2(captions.position.x, base), "OUT THROUGH HULL  %.2f" % maxf(sim.heat_outward(), 0.0),
			HORIZONTAL_ALIGNMENT_LEFT, -1, small, StationTheme.NOW_COLOUR)
	draw_string(font, Vector2(captions.position.x, base), "%.2f  INTO COLUMN" % sim.heat_to_column(),
			HORIZONTAL_ALIGNMENT_RIGHT, captions.size.x, small, StationTheme.NOW_COLOUR)
	draw_string(font, Vector2(captions.position.x, base), "HEAT", HORIZONTAL_ALIGNMENT_CENTER,
			captions.size.x, small, StationTheme.LEGEND_COLOUR)

	var divide := bar.position.x + bar.size.x * (1.0 - column_share())
	var gap := 3.0 * z
	draw_rect(bar, StationTheme.faded(StationTheme.RULE_COLOUR, 0.6))
	if divide - gap > bar.position.x:
		draw_rect(Rect2(bar.position.x, bar.position.y, divide - gap - bar.position.x, bar.size.y),
				StationTheme.NOW_COLOUR)
	if bar.end.x > divide + gap:
		draw_rect(Rect2(divide + gap, bar.position.y, bar.end.x - divide - gap, bar.size.y),
				StationTheme.faded(StationTheme.NOW_COLOUR, 0.45))

	# The setting: a mark under the bar where the crew has put the division.
	var set_at := bar.position.x + bar.size.x * (1.0 - split_set())
	var reach := 9.0 * z
	draw_line(Vector2(set_at, bar.position.y - 2.0), Vector2(set_at, bar.end.y), StationTheme.SELECTED_COLOUR, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(set_at, setting.position.y),
			Vector2(set_at + reach, setting.position.y + reach * 1.3),
			Vector2(set_at - reach, setting.position.y + reach * 1.3)]), StationTheme.SELECTED_COLOUR)
	var text := "SET %d%% INTO COLUMN" % roundi(split_set() * 100.0)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, small).x
	# Beside the mark, on whichever side has the room.
	var from := set_at - reach - 8.0 * z - width
	if from < setting.position.x:
		from = set_at + reach + 8.0 * z
	draw_string(font, Vector2(from, setting.position.y + font.get_ascent(small)), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, small, StationTheme.SELECTED_COLOUR)
