## The tunnel behind and the link to the surface: whether the tunnel is open or
## sealed, the porosity trend the Tail is heading into, how fast data goes up,
## what is still aboard and what has been paid. Drawn on the Bore Station's own
## screen (habitat.gd `_bore_instrument`) and in the debug overlay. The upload
## priority key cycles the priority at the Bore Station. Its colours are
## StationTheme's: the tunnel open is working (green), sealed or about to be
## a caution (amber), the priority the crew's choice (cyan).
##
## The porosity trend is the Column from the Head back past the Tail. The Tail
## leaves the tunnel behind it, so the Column between the Head and the Tail is
## exactly what the Tail will leave next: a dip below the seal line there is
## the point the tunnel will seal, coming toward the Tail at the vessel's speed.
class_name TunnelPanel
extends Control

## How far behind the Tail the trend is drawn, in metres: the porosity the
## tunnel was made in, for the trend's sake.
const BEHIND_TAIL_M := 30.0
const HEADER_PX := 94.0
## Porosity at the top of the graph.
const GRAPH_TOP_POROSITY := 0.5

const PRIORITY_NAMES := {
	DiveSimulation.UPLOAD_OLDEST_FIRST: "oldest first",
	DiveSimulation.UPLOAD_NEWEST_FIRST: "newest first",
	DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST: "most valuable first",
}

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


## What the crew can point at: the tunnel and the link, the whole panel
## (StationScreen.instrument_readings()).
func readings() -> Dictionary:
	return {&"tunnel": Rect2(Vector2.ZERO, size)}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), StationTheme.SCREEN_COLOUR)
	if sim == null:
		return
	var font := get_theme_default_font()
	var z := zoom
	var sealed := sim.tunnel_sealed()
	var wide := size.x - 16.0 * z
	draw_string(font, Vector2(8.0, 18.0) * z, "TUNNEL %s" % ("SEALED" if sealed else "OPEN"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(14 * z),
			StationTheme.CAUTION_COLOUR if sealed else StationTheme.ENGAGED_COLOUR)
	draw_string(font, Vector2(8.0, 36.0) * z, _link_line(), HORIZONTAL_ALIGNMENT_LEFT,
			wide, roundi(12 * z), StationTheme.NOW_COLOUR)
	draw_string(font, Vector2(8.0, 52.0) * z, _upload_line(), HORIZONTAL_ALIGNMENT_LEFT,
			wide, roundi(12 * z), StationTheme.NOW_COLOUR)
	draw_string(font, Vector2(8.0, 68.0) * z, _priority_line(), HORIZONTAL_ALIGNMENT_LEFT,
			wide, roundi(12 * z), StationTheme.SELECTED_COLOUR)
	var trend := _trend_line()
	draw_string(font, Vector2(8.0, 84.0) * z, trend[0], HORIZONTAL_ALIGNMENT_LEFT,
			wide, roundi(12 * z), trend[1])
	_draw_trend(Rect2(8.0 * z, HEADER_PX * z, wide, size.y - (HEADER_PX + 8.0) * z), font)


## Porosity of the Column against distance behind the Head: the Head at the
## left, the Tail marked, older tunnel to the right. The seal line across it.
func _draw_trend(graph: Rect2, font: Font) -> void:
	var z := zoom
	draw_rect(graph, StationTheme.faded(StationTheme.RULE_COLOUR, 0.35))
	var length := sim.vessel_length()
	var span := length + BEHIND_TAIL_M
	var to_x := func(behind: float) -> float: return graph.position.x + graph.size.x * behind / span
	var to_y := func(porosity: float) -> float:
		return graph.end.y - graph.size.y * clampf(porosity / GRAPH_TOP_POROSITY, 0.0, 1.0)

	var samples := int(graph.size.x / 2.0)
	var previous := Vector2.ZERO
	for i in samples + 1:
		var behind := span * i / samples
		var porosity := sim.column_at(behind).porosity
		var point := Vector2(to_x.call(behind), to_y.call(porosity))
		var dense := porosity < sim.seal_porosity()
		if i > 0:
			draw_line(previous, point,
					StationTheme.CAUTION_COLOUR if dense else StationTheme.NOW_COLOUR, 2.0)
		previous = point

	var seal_y: float = to_y.call(sim.seal_porosity())
	draw_line(Vector2(graph.position.x, seal_y), Vector2(graph.end.x, seal_y),
			StationTheme.faded(StationTheme.CAUTION_COLOUR, 0.6), 1.0)
	draw_string(font, Vector2(graph.end.x - 70.0 * z, seal_y - 3.0 * z), "seals below",
			HORIZONTAL_ALIGNMENT_RIGHT, 66.0 * z, roundi(10 * z), StationTheme.CAUTION_COLOUR)
	var tail_x: float = to_x.call(length)
	draw_line(Vector2(tail_x, graph.position.y), Vector2(tail_x, graph.end.y),
			StationTheme.LEGEND_COLOUR, 1.0)
	draw_string(font, Vector2(graph.position.x + 2.0 * z, graph.position.y + 12.0 * z), "Head",
			HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10 * z), StationTheme.LEGEND_COLOUR)
	draw_string(font, Vector2(tail_x + 3.0 * z, graph.position.y + 12.0 * z), "Tail",
			HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(10 * z), StationTheme.LEGEND_COLOUR)


func _link_line() -> String:
	var kind := "slow, through rock" if sim.tunnel_sealed() else "fast, up the tunnel"
	if not sim.uploading():
		return "Link STOPPED %s  (%s)" % [KeyMap.label(&"link"), kind]
	var store := "  on the store" if sim.on_emergency_store() else ""
	return "Link %s  %.2f m/s%s" % [kind, sim.link_rate(), store]


func _upload_line() -> String:
	# Stretches only: records of features go up the link too, but are counted
	# on the survey panel.
	var up := sim.uploaded_survey().filter(
			func(s: SurveyStretch) -> bool: return not s.is_feature_record()).size()
	var aboard := sim.unsold_survey().filter(
			func(s: SurveyStretch) -> bool: return not s.is_feature_record()).size()
	return "Aboard %d  up %d  paid %.0f" % [aboard, up, sim.paid()]


## Which waiting data goes up first: the crew's choice, and its key.
func _priority_line() -> String:
	return "%s %s" % [KeyMap.label(&"upload_priority"), PRIORITY_NAMES.get(sim.upload_priority(), "?")]


## Where the Tail meets dense Medium, as [words, colour]: the nearest point
## between the Head and the Tail whose porosity is below the seal line.
func _trend_line() -> Array:
	if sim.tunnel_sealed():
		return ["Sealed in", StationTheme.CAUTION_COLOUR]
	var length := sim.vessel_length()
	var behind := length
	while behind > 0.0:
		behind -= 0.25
		if sim.column_at(behind).porosity < sim.seal_porosity():
			return ["Tail in dense rock in %.1f m: will seal" % (length - behind), StationTheme.CAUTION_COLOUR]
	return ["Porosity holds to the Head", StationTheme.NOW_COLOUR]
