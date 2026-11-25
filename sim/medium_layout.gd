## Which Medium lies at each point underground. Queried, never rendered.
## For now the Media are horizontal layers, so only depth matters.
class_name MediumLayout
extends RefCounted

## Depth in metres of the top of each layer, shallowest first. Starts at 0.
var _tops: Array[float] = []
## The Medium of each layer, matching _tops.
var _media: Array[Medium] = []
## Features of interest: [[depth_m, ColumnFeature template], ...], shallowest first.
var _features: Array = []


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
	var layout := MediumLayout.layered([
		[0.0, Medium.sand()],
		[100.0, Medium.sandstone()],
		[600.0, Medium.granite()],
	])
	# Features of interest from time to time, each a kind that forms in the
	# Medium it lies in. Spacing is tuned for play (ADR 0001); the seed fixes
	# them so every first dive meets the same ones.
	var kinds := {
		&"sand": [ColumnFeature.fulgurite],
		&"sandstone": [ColumnFeature.petrified_wood, ColumnFeature.iron_concretions],
		&"granite": [ColumnFeature.quartz_vein, ColumnFeature.pegmatite],
	}
	var rng := RandomNumberGenerator.new()
	rng.seed = 14
	var features := []
	var depth := 25.0
	while depth < 4000.0:
		var choices: Array = kinds[layout.medium_at(depth).name]
		var make: Callable = choices[rng.randi() % choices.size()]
		features.append([depth, make.call()])
		depth += rng.randf_range(30.0, 120.0)
	return layout.with_features(features)


## Adds features of interest: [[depth_m, ColumnFeature], ...]. Returns this
## layout, so it chains onto uniform() and layered().
func with_features(features: Array) -> MediumLayout:
	_features.append_array(features)
	_features.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return self


## The feature templates lying between two depths (either order), each as
## [depth_m, ColumnFeature]. A feature exactly at a depth counts once: it lies
## between a and b when it is past a and up to b.
func features_between(a: float, b: float) -> Array:
	var result := []
	for entry in _features:
		var d: float = entry[0]
		if (a < d and d <= b) or (b <= d and d < a):
			result.append(entry)
	return result


## The Medium at the given depth in metres below the surface. Above the
## surface counts as the top layer.
func medium_at(depth: float) -> Medium:
	var index := _tops.bsearch(depth, false) - 1
	return _media[maxi(index, 0)]
