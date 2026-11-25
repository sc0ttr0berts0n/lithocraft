## The Bore Station's survey readout: one bar per recorded stretch, newest on
## the right. Bar height is the stretch's quality; bar colour is the composition
## it recorded, so a Boundary shows as a change of colour. Stretches recorded
## while Quiet Ship shuttered the Bore are outlined and marked "Q". Drawn on the
## Bore Station's own screen (habitat.gd `_bore_display`) and in the debug
## overlay.
class_name SurveyPanel
extends Control

## How many of the most recent stretches are shown.
const SHOWN_STRETCHES := 30
const BAR_GAP_PX := 2.0
const HEADER_PX := 60.0
## Outline and "Q" over stretches recorded with the Bore shuttered (Quiet Ship).
const SHUTTERED_COLOUR := Color(0.55, 0.8, 1.0, 0.8)

var sim: DiveSimulation


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.1, 0.9))
	if sim == null:
		return
	var font := get_theme_default_font()
	var survey := sim.survey()
	draw_string(font, Vector2(8.0, 18.0), "BORE STATION: survey", HORIZONTAL_ALIGNMENT_LEFT,
			-1, 14, Color(0.7, 0.85, 1.0))
	draw_string(font, Vector2(8.0, 36.0), _summary(survey), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0, 12, Color.WHITE)
	draw_string(font, Vector2(8.0, 52.0), _value_line(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0, 12, FeatureLook.RECORDED_COLOUR)

	var chart := Rect2(8.0, HEADER_PX, size.x - 16.0, size.y - HEADER_PX - 8.0)
	draw_rect(chart, Color(0.15, 0.16, 0.18))
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
			draw_string(font, Vector2(bar.position.x, chart.position.y + 12.0), "Q",
					HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 10, SHUTTERED_COLOUR)
	if sim.shuttered():
		draw_string(font, Vector2(chart.end.x - 90.0, 18.0), "SHUTTERED",
				HORIZONTAL_ALIGNMENT_RIGHT, 82.0, 12, SHUTTERED_COLOUR)
	# Full-quality line.
	draw_line(chart.position, Vector2(chart.end.x, chart.position.y), Color(1, 1, 1, 0.4), 1.0)


func _summary(survey: Array[SurveyStretch]) -> String:
	if survey.is_empty():
		return "Recording first stretch..."
	var total_quality := 0.0
	for stretch in survey:
		total_quality += stretch.quality
	# No Medium names: the crew know the rock by its look in the Bore.
	var latest: SurveyStretch = survey.back()
	return "%d stretches  mean quality %d%%  last %d%%" % [
		survey.size(),
		roundi(100.0 * total_quality / survey.size()),
		roundi(100.0 * latest.quality),
	]


## The survey's value so far, and how many features of interest went into it.
func _value_line() -> String:
	var recorded := sim.found_features().filter(
			func(f: ColumnFeature) -> bool: return f.is_recorded()).size()
	return "value %d  (features recorded: %d)" % [roundi(sim.survey_value()), recorded]
