## Which Medium lies at each point underground. Queried, never rendered.
## For now the Media are horizontal layers, so only depth matters.
class_name MediumLayout
extends RefCounted

## Depth in metres of the top of each layer, shallowest first. Starts at 0.
var _tops: Array[float] = []
## The Medium of each layer, matching _tops.
var _media: Array[Medium] = []


## layers: [[top_depth_m, Medium], ...], shallowest first, the first at 0.
## Each layer runs down to the top of the next; the last has no bottom.
func _init(layers: Array) -> void:
	assert(not layers.is_empty(), "A layout needs at least one Medium")
	for layer in layers:
		_tops.append(float(layer[0]))
		_media.append(layer[1])


## A layout of one Medium at every depth.
static func uniform(medium: Medium) -> MediumLayout:
	return MediumLayout.new([[0.0, medium]])


## A layout of horizontal layers: [[top_depth_m, Medium], ...], shallowest first.
static func layered(layers: Array) -> MediumLayout:
	return MediumLayout.new(layers)


## The Earth desert of the first dive: sand, then sandstone, then granite.
## Layer depths are tuned for play (ADR 0001).
static func first_dive() -> MediumLayout:
	return MediumLayout.layered([
		[0.0, Medium.sand()],
		[100.0, Medium.sandstone()],
		[600.0, Medium.granite()],
	])


## The Medium at the given depth in metres below the surface. Above the
## surface counts as the top layer.
func medium_at(depth: float) -> Medium:
	var index := _tops.bsearch(depth, false) - 1
	return _media[maxi(index, 0)]
