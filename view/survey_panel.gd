## The Bore Station's survey readout: one bar per recorded stretch, newest on
## the right. Bar height is the stretch's quality; bar colour is the composition
## it recorded, so a Boundary shows as a change of colour. Stretches recorded
## while Quiet Ship shuttered the Bore are outlined and marked "Q". Drawn on the
## Bore Station's own screen (habitat.gd `_bore_instrument`) and in the debug
## overlay. Its colours are StationTheme's, but for the rock's own
## (ColumnLook), which are a picture of the world.
class_name SurveyPanel
extends Control

## How many of the most recent stretches are shown.
const SHOWN_STRETCHES := 30
const BAR_GAP_PX := 2.0
const HEADER_PX := 60.0
## Outline and "Q" over stretches recorded with the Bore shuttered (Quiet
## Ship): a caution, since shuttering costs the record its quality.
const SHUTTERED_COLOUR := StationTheme.CAUTION_COLOUR

var sim: DiveSimulation
## How much larger than its plain size (the debug overlay's) the panel's text
## and spacing are drawn: above 1 on a Station screen, to be read from the
## Arm's hold.
var zoom := 1.0
## The Station whose screen shows it (the simulation's name): drawn every
## frame while the crew is there, every ScreenPace.UNWATCHED_S while not.
## Empty (the debug overlay): every frame.
var watched_at := &""
var _pace := ScreenPace.new()


func _process(delta: float) -> void:
	if _pace.due_at(delta, sim, watched_at):
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_pace.hurry()


## What the crew can point at: the survey, the whole panel
## (StationScreen.instrument_readings()).
func readings() -> Dictionary:
	return {&"survey": Rect2(Vector2.ZERO, size)}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), StationTheme.SCREEN_COLOUR)
	if sim == null:
		return
	var font := get_theme_default_font()
	var z := zoom
	var survey := sim.survey()
	draw_string(font, Vector2(8.0, 18.0) * z, "SURVEY", HORIZONTAL_ALIGNMENT_LEFT,
			-1, roundi(14 * z), StationTheme.LEGEND_COLOUR)
	draw_string(font, Vector2(8.0, 36.0) * z, _summary(survey), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0 * z, roundi(12 * z), StationTheme.NOW_COLOUR)
	draw_string(font, Vector2(8.0, 52.0) * z, _value_line(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0 * z, roundi(12 * z), StationTheme.NOW_COLOUR)

	var chart := Rect2(8.0 * z, HEADER_PX * z, size.x - 16.0 * z, size.y - (HEADER_PX + 8.0) * z)
	draw_rect(chart, StationTheme.faded(StationTheme.RULE_COLOUR, 0.35))
	var bar_w := chart.size.x / SHOWN_STRETCHES
	var shown := survey.slice(maxi(0, survey.size() - SHOWN_STRETCHES))
	for i in shown.size():
		var stretch: SurveyStretch = shown[i]
		var bar_h := chart.size.y * stretch.quality
		var bar := Rect2(chart.position.x + i * bar_w, chart.end.y - bar_h,
				bar_w - BAR_GAP_PX, bar_h)
		draw_rect(bar, ColumnLook.blended_colour(stretch.composition))
		if stretch.shuttered:
			# Quiet Ship shuttered the Bore for part of this stretch.
			draw_rect(Rect2(bar.position.x, chart.position.y, bar.size.x, chart.size.y),
					SHUTTERED_COLOUR, false, 1.0)
			draw_string(font, Vector2(bar.position.x, chart.position.y + 12.0 * z), "Q",
					HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, roundi(10 * z), SHUTTERED_COLOUR)
	if sim.shuttered():
		draw_string(font, Vector2(chart.end.x - 120.0 * z, 18.0 * z), "SHUTTERED",
				HORIZONTAL_ALIGNMENT_RIGHT, 120.0 * z, roundi(12 * z), SHUTTERED_COLOUR)
	# Full-quality line.
	draw_line(chart.position, Vector2(chart.end.x, chart.position.y), StationTheme.LEGEND_COLOUR, 1.0)


func _summary(survey: Array[SurveyStretch]) -> String:
	if survey.is_empty():
		return "Recording first stretch..."
	var total_quality := 0.0
	for stretch in survey:
		total_quality += stretch.quality
	# No Medium names: the crew know the rock by its look in the Bore.
	var latest: SurveyStretch = survey.back()
	return "%d stretches  quality %d%%  last %d%%" % [
		survey.size(),
		roundi(100.0 * total_quality / survey.size()),
		roundi(100.0 * latest.quality),
	]


## The survey's value so far, and how many features of interest went into it.
func _value_line() -> String:
	var recorded := sim.found_features().filter(
			func(f: ColumnFeature) -> bool: return f.is_recorded()).size()
	return "value %d  features %d" % [roundi(sim.survey_value()), recorded]
