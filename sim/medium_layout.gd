## Which Medium lies at each place underground. Queried, never rendered.
## The Media are layers, each Boundary between them a surface: generally flat,
## but gently wavy where a layout asks for it (with_waviness()), so its depth
## varies with place. Real basis: bedding planes are laid down flat and then
## gently folded. Anything that asks where a Boundary is asks where a ray or a
## path meets it (meets()), and which Medium lies at a place asks with the place
## (medium_at_point()), never with a depth alone.
class_name MediumLayout
extends RefCounted

## Metres a level line is followed when looking for the next Boundary it meets
## (next_meet()): a level line never leaves a depth, so it is cut off here.
## Tuned for play (ADR 0001): far beyond what any scan reaches.
const _LEVEL_REACH_M := 5000.0
## The fewest samples per shortest wavelength a line is checked at for meeting
## a wavy surface (meets()); between samples the crossing is narrowed by
## halving. Fine enough that a line at any slant meets each fold it crosses.
const _SAMPLES_PER_WAVELENGTH := 8.0
## How closely a crossing of a wavy surface is narrowed down, metres.
const _MEET_PRECISION_M := 0.001
## How many plane waves are summed into each wavy Boundary.
const _WAVES_PER_BOUNDARY := 3

## The first dive's Boundaries depart from their mean depth by at most this
## many metres, in folds this long (the shortest; the longest are twice it),
## seeded so every first dive meets the same surfaces. Tuned for play (ADR
## 0001): small beside the spacing of its Boundaries, gentle enough to read as
## flat bedding, large enough that where a dive crosses matters.
const _FIRST_DIVE_WAVE_M := 6.0
const _FIRST_DIVE_WAVELENGTH_M := 250.0
const _FIRST_DIVE_WAVE_SEED := 116

## Mean depth in metres of the top of each layer, shallowest first. Starts at 0.
var _tops: Array[float] = []
## The Medium of each layer, matching _tops.
var _media: Array[Medium] = []
## Features of interest: [[depth_m, ColumnFeature template], ...], shallowest first.
var _features: Array = []
## Targets: bodies in the rock surface control's survey has seen and cannot
## identify (TargetBody), in the order placed.
var _targets: Array[TargetBody] = []
## Each Boundary's waves (for _tops[i + 1]): Vector4(wavenumber along x,
## wavenumber along z, phase, metres of amplitude). Empty for a flat one.
var _waves: Array = []
## The most each Boundary departs from its mean depth, metres.
var _amplitudes: PackedFloat64Array = PackedFloat64Array()
## The step in metres a line is sampled at for meeting a wavy surface.
var _sample_m := INF


## layers: [[top_depth_m, Medium], ...], shallowest first, the first at 0.
## Each layer runs down to the top of the next; the last has no bottom.
## Every Boundary is flat until with_waviness() folds it.
func _init(layers: Array) -> void:
	assert(not layers.is_empty(), "A layout needs at least one Medium")
	for layer in layers:
		_tops.append(float(layer[0]))
		_media.append(layer[1])
	for i in _tops.size() - 1:
		_waves.append([])
		_amplitudes.append(0.0)


## A layout of one Medium at every depth.
static func uniform(medium: Medium) -> MediumLayout:
	return MediumLayout.new([[0.0, medium]])


## A layout of flat layers: [[top_depth_m, Medium], ...], shallowest first.
static func layered(layers: Array) -> MediumLayout:
	return MediumLayout.new(layers)


## The Earth desert of the first dive: sand, then sandstone, then granite,
## their Boundaries gently wavy.
## Layer depths are tuned for play (ADR 0001).
static func first_dive() -> MediumLayout:
	var layout := MediumLayout.layered([
		[0.0, Medium.sand()],
		[100.0, Medium.sandstone()],
		[600.0, Medium.granite()],
	]).with_waviness(_FIRST_DIVE_WAVE_M, _FIRST_DIVE_WAVELENGTH_M, _FIRST_DIVE_WAVE_SEED)
	# Features of interest from time to time, each a kind that forms in the
	# Medium it lies in. Spacing is tuned for play (ADR 0001); the seed fixes
	# them so every first dive meets the same ones. None lies within a fold of
	# a Boundary, where the Medium at its depth depends on the place.
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
		if not layout._within_a_fold(depth):
			features.append([depth, make.call()])
		depth += rng.randf_range(30.0, 120.0)
	return layout.with_features(features)


## Folds every Boundary gently: its depth departs from its mean by at most
## `amplitude_m`, as a sum of a few plane waves of random direction and phase,
## their wavelengths from `wavelength_m` to twice it, fixed by `seed` so the
## same layout always has the same surfaces. The amplitude must be under half
## the spacing of the Boundaries (and under the shallowest's depth), so no
## Boundary crosses another or the surface. Returns this layout, so it chains
## onto layered().
func with_waviness(amplitude_m: float, wavelength_m: float, seed: int) -> MediumLayout:
	assert(amplitude_m >= 0.0 and wavelength_m > 0.0, "Waviness needs a size")
	for i in range(1, _tops.size()):
		assert(2.0 * amplitude_m < _tops[i] - _tops[i - 1],
				"A Boundary's folds must be small beside the spacing of Boundaries")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in _waves.size():
		var weights: Array[float] = []
		var total := 0.0
		for k in _WAVES_PER_BOUNDARY:
			weights.append(rng.randf_range(0.5, 1.0))
			total += weights[k]
		var waves := []
		for k in _WAVES_PER_BOUNDARY:
			var turn := rng.randf() * TAU
			var wavenumber := TAU / (wavelength_m * rng.randf_range(1.0, 2.0))
			waves.append(Vector4(cos(turn) * wavenumber, sin(turn) * wavenumber,
					rng.randf() * TAU, amplitude_m * weights[k] / total))
		_waves[i] = waves if amplitude_m > 0.0 else []
		_amplitudes[i] = amplitude_m
	if amplitude_m > 0.0:
		_sample_m = minf(_sample_m, wavelength_m / _SAMPLES_PER_WAVELENGTH)
	return self


## Adds features of interest: [[depth_m, ColumnFeature], ...]. Returns this
## layout, so it chains onto uniform() and layered().
func with_features(features: Array) -> MediumLayout:
	_features.append_array(features)
	_features.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return self


## Places targets in the rock: bodies with a place and a size (TargetBody),
## each with a label of its own. Returns this layout, so it chains onto
## layered() and with_waviness(). A Scenario places its targets here, and
## names them in its Orders (Scenario.identify_target()).
func with_targets(targets: Array[TargetBody]) -> MediumLayout:
	_targets.append_array(targets)
	return self


## Every target in the layout, in the order placed.
func targets() -> Array[TargetBody]:
	return _targets.duplicate()


## Every feature template in the layout, each as [depth_m, ColumnFeature],
## shallowest first.
func features() -> Array:
	return _features.duplicate()


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


## Mean depths in metres of every Boundary (where one Medium gives way to the
## next), shallowest first. A flat Boundary lies at its mean depth everywhere;
## where a wavy one lies at a place is boundary_depth_at().
func boundary_depths() -> Array[float]:
	return _tops.slice(1)


## Depth in metres of Boundary `index` (as in boundary_depths()) under the
## world place (x, z): its mean depth plus its folds there.
func boundary_depth_at(index: int, x: float, z: float) -> float:
	var depth := _tops[index + 1]
	for wave: Vector4 in _waves[index]:
		depth += wave.w * sin(wave.x * x + wave.y * z + wave.z)
	return depth


## The most Boundary `index` departs from its mean depth anywhere, metres: 0
## for a flat one.
func boundary_amplitude(index: int) -> float:
	return _amplitudes[index]


## The Medium of the layer that holds this depth with every Boundary at its
## mean depth: which layer a depth names, exact everywhere in a flat layout.
## Above the surface counts as the top layer. Where the vessel or a point is,
## ask medium_at_point().
func medium_at(depth: float) -> Medium:
	var index := _tops.bsearch(depth, false) - 1
	return _media[maxi(index, 0)]


## The Medium at a world place (metres, +Y up, so depth is -y). A place on a
## Boundary belongs to the Medium below it. Above the surface counts as the
## top layer.
func medium_at_point(place: Vector3) -> Medium:
	var depth := -place.y
	var layer := 0
	while layer < _waves.size() and boundary_depth_at(layer, place.x, place.z) <= depth:
		layer += 1
	return _media[layer]


## Where the straight piece of path from `from` to `to` (world places) meets
## the Boundaries: [[metres from `from`, Boundary index, Medium before,
## Medium after], ...], nearest first, one entry for each time it passes
## through a surface. Only Boundaries whose folds reach the piece's depths
## are looked at, and a wavy one only over the stretch of the piece inside
## its folds, so a long piece costs no more than a short one beyond that.
func meets(from: Vector3, to: Vector3) -> Array:
	var length := from.distance_to(to)
	var found := []
	if length <= 0.0:
		return found
	var depth_from := -from.y
	var depth_to := -to.y
	for index in _waves.size():
		var mean := _tops[index + 1]
		if _waves[index].is_empty():
			# A flat surface is met where the piece reaches its depth.
			var deeper := depth_to >= mean
			if (depth_from >= mean) != deeper:
				found.append([_share_at_depth(depth_from, depth_to, mean) * length, index,
						_media[index + (0 if deeper else 1)], _media[index + (1 if deeper else 0)]])
			continue
		var reach := _amplitudes[index]
		var lo := clampf(_share_at_depth(depth_from, depth_to, mean - reach), 0.0, 1.0)
		var hi := clampf(_share_at_depth(depth_from, depth_to, mean + reach), 0.0, 1.0)
		if lo > hi:
			var swap := lo
			lo = hi
			hi = swap
		if is_equal_approx(depth_from, depth_to):
			if absf(depth_from - mean) > reach:
				continue
			lo = 0.0
			hi = 1.0
		var samples := maxi(1, ceili((hi - lo) * length / _sample_m))
		var share := lo
		var below := _below(index, from.lerp(to, share))
		for s in samples:
			var next := lerpf(lo, hi, float(s + 1) / samples)
			var next_below := _below(index, from.lerp(to, next))
			if next_below != below:
				var met := _narrow(index, from, to, share, next, below, length)
				var deeper := next_below
				found.append([met * length, index,
						_media[index + (0 if deeper else 1)], _media[index + (1 if deeper else 0)]])
			share = next
			below = next_below
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return found


## The first Boundary the line from `origin` along `direction` (a unit
## vector) meets, however far, as one entry of meets() ([metres, index,
## Medium before, Medium after]), or [] for none. A level line is followed
## _LEVEL_REACH_M.
func next_meet(origin: Vector3, direction: Vector3) -> Array:
	if _waves.is_empty():
		return []
	var down := -direction.y
	var reach := _LEVEL_REACH_M
	if absf(down) > 1e-6:
		var deepest := _tops[_tops.size() - 1] + _amplitudes[_amplitudes.size() - 1]
		var end := deepest + 1.0 if down > 0.0 else -1.0
		reach = (end - (-origin.y)) / down
		if reach <= 0.0:
			return []
	var found := meets(origin, origin + direction * reach)
	return [] if found.is_empty() else found[0]


## Whether this depth lies within the folds of any Boundary, where the Medium
## at it depends on the place.
func _within_a_fold(depth: float) -> bool:
	for index in _waves.size():
		if absf(depth - _tops[index + 1]) <= _amplitudes[index]:
			return true
	return false


## Whether a place lies at or below Boundary `index`.
func _below(index: int, place: Vector3) -> bool:
	return -place.y >= boundary_depth_at(index, place.x, place.z)


## The share along a piece from depth a to depth b at which it is at `depth`
## (INF either way when the piece is level).
static func _share_at_depth(a: float, b: float, depth: float) -> float:
	if is_equal_approx(a, b):
		return INF if depth > a else -INF
	return (depth - a) / (b - a)


## Narrows down by halving where between shares `lo` and `hi` of the piece
## from `from` to `to` (its length `length` metres) it passes through wavy
## Boundary `index`, `lo` being on the side given by `lo_below`. Returns the
## share.
func _narrow(index: int, from: Vector3, to: Vector3, lo: float, hi: float,
		lo_below: bool, length: float) -> float:
	while (hi - lo) * length > _MEET_PRECISION_M:
		var mid := (lo + hi) * 0.5
		if _below(index, from.lerp(to, mid)) == lo_below:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5
