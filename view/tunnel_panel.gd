## The tunnel behind and the link to the surface: whether the tunnel is open or
## sealed, the porosity trend the Tail is heading into, how fast data goes up,
## what is still aboard and what has been paid. Stands in for the Bore
## Station's own screen in the Habitat until that Station has one.
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
const HEADER_PX := 78.0
## Porosity at the top of the graph.
const GRAPH_TOP_POROSITY := 0.5

const PRIORITY_NAMES := {
	DiveSimulation.UPLOAD_OLDEST_FIRST: "oldest first",
	DiveSimulation.UPLOAD_NEWEST_FIRST: "newest first",
	DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST: "most valuable first",
}

var sim: DiveSimulation


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.1, 0.9))
	if sim == null:
		return
	var font := get_theme_default_font()
	var sealed := sim.tunnel_sealed()
	draw_string(font, Vector2(8.0, 18.0), "TUNNEL: %s" % ("SEALED" if sealed else "OPEN"),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(1.0, 0.45, 0.3) if sealed else Color(0.5, 0.95, 0.6))
	draw_string(font, Vector2(8.0, 36.0), _link_line(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0, 12, Color.WHITE)
	draw_string(font, Vector2(8.0, 52.0), _upload_line(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0, 12, Color.WHITE)
	draw_string(font, Vector2(8.0, 68.0), _trend_line(), HORIZONTAL_ALIGNMENT_LEFT,
			size.x - 16.0, 12, Color(0.85, 0.85, 0.7))
	_draw_trend(Rect2(8.0, HEADER_PX, size.x - 16.0, size.y - HEADER_PX - 8.0), font)


## Porosity of the Column against distance behind the Head: the Head at the
## left, the Tail marked, older tunnel to the right. The seal line across it.
func _draw_trend(graph: Rect2, font: Font) -> void:
	draw_rect(graph, Color(0.15, 0.16, 0.18))
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
			draw_line(previous, point, Color(1.0, 0.45, 0.3) if dense else Color(0.5, 0.8, 1.0), 2.0)
		previous = point

	var seal_y: float = to_y.call(sim.seal_porosity())
	draw_line(Vector2(graph.position.x, seal_y), Vector2(graph.end.x, seal_y),
			Color(1.0, 0.45, 0.3, 0.6), 1.0)
	draw_string(font, Vector2(graph.end.x - 64.0, seal_y - 3.0), "seals below",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.45, 0.3, 0.8))
	var tail_x: float = to_x.call(length)
	draw_line(Vector2(tail_x, graph.position.y), Vector2(tail_x, graph.end.y),
			Color(1, 1, 1, 0.5), 1.0)
	draw_string(font, Vector2(graph.position.x + 2.0, graph.position.y + 12.0), "Head",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))
	draw_string(font, Vector2(tail_x + 3.0, graph.position.y + 12.0), "Tail",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.7))


func _link_line() -> String:
	var kind := "slow, sound through rock" if sim.tunnel_sealed() else "fast, light up the tunnel"
	return "Link: %s  %.2f m of survey/s" % [kind, sim.link_rate()]


func _upload_line() -> String:
	var aboard := sim.survey().size() - sim.uploaded_survey().size()
	return "Aboard %d  up %d  paid %.0f   [U] %s" % [
		aboard, sim.uploaded_survey().size(), sim.paid(),
		PRIORITY_NAMES.get(sim.upload_priority(), "?"),
	]


## Where the Tail meets dense Medium: the nearest point between the Head and
## the Tail whose porosity is below the seal line.
func _trend_line() -> String:
	if sim.tunnel_sealed():
		return "Sealed in: the link is sound through rock"
	var length := sim.vessel_length()
	var behind := length
	while behind > 0.0:
		behind -= 0.25
		if sim.column_at(behind).porosity < sim.seal_porosity():
			return "Tail reaches dense rock in %.1f m: the tunnel will seal" % (length - behind)
	return "Porosity holds above the seal line to the Head"
