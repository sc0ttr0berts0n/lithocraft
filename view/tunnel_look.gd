## How the tunnel behind is drawn wherever it is shown (ticket #127): its
## glass, rough and sealed stretches told apart in the Theme's colours, from
## DiveSimulation.tunnel_walls(). Glass, the Crawl's smooth lining, is a
## plain line in the colour of what is happening (white); rough, a Glide's
## lumpy wall in porous rock, the same white drawn beaded, lumpy as the wall
## is; sealed, closed rock with no tunnel left, the legend's grey.
##
## A view keeps its copy of the walls (TunnelLook.new()), reads them again only
## when tunnel_wall_count() changes, and runs the newest piece on to the
## Tail, which has left the tunnel behind it up to there.
class_name TunnelLook
extends RefCounted

## What each wall is called where a view names it.
const WORDS := {
	DiveSimulation.TUNNEL_GLASS: "glass",
	DiveSimulation.TUNNEL_ROUGH: "rough",
	DiveSimulation.TUNNEL_SEALED: "sealed",
}
## The beads of a rough wall: their radius and spacing along the line, pixels.
const BEAD_PX := 2.6
const BEAD_GAP_PX := 10.0

var _walls: Array[Dictionary] = []
var _count := -1


## The tunnel's pieces now, {from, to, wall} by path distance, oldest first,
## the newest run on to the Tail (`tail_at`, path distance). Reads the
## simulation's list again only when its count has changed.
func pieces(sim: DiveSimulation) -> Array[Dictionary]:
	if sim.tunnel_wall_count() != _count:
		_count = sim.tunnel_wall_count()
		_walls = sim.tunnel_walls()
	var out: Array[Dictionary] = []
	for piece in _walls:
		out.append(piece.duplicate())
	var tail_at := sim.distance() - sim.vessel_length()
	if not out.is_empty() and out.back().to < tail_at:
		out.back().to = tail_at
	return out


## The wall at this path distance among `pieces`, or &"" outside them (ahead
## of the Tail: the vessel, not yet tunnel).
static func wall_at(pieces: Array[Dictionary], distance: float) -> StringName:
	for piece in pieces:
		if distance >= piece.from and distance <= piece.to:
			return piece.wall
	return &""


## The colour a wall is drawn in: Theme colours only.
static func colour(wall: StringName) -> Color:
	return StationTheme.LEGEND_COLOUR if wall == DiveSimulation.TUNNEL_SEALED else StationTheme.NOW_COLOUR


## Draws a stretch of tunnel on `canvas` from `from` to `to` as its wall is
## drawn, `width` pixels wide.
static func draw(canvas: CanvasItem, from: Vector2, to: Vector2, wall: StringName, width: float) -> void:
	var tint := colour(wall)
	if wall != DiveSimulation.TUNNEL_ROUGH:
		canvas.draw_line(from, to, tint, width)
		return
	canvas.draw_line(from, to, StationTheme.faded(tint, 0.5), width)
	var length := from.distance_to(to)
	var along := 0.0
	while along <= length:
		canvas.draw_circle(from.lerp(to, along / maxf(length, 0.001)), BEAD_PX, tint)
		along += BEAD_GAP_PX
