## Infers Boundaries from Navigation's point cloud alone, as a multibeam
## survey builds a seabed from its soundings: the ground is gridded into
## square cells; in each, the points are split into layers by height (a gap
## means another surface), and a plane is fitted to each layer with enough
## points, covering the ground they span. A patch's confidence follows how many points support it and how
## confident they are. It is given points and nothing else, so it can only
## ever show what the scan returned (design record: "Topology is honest").
class_name BoundaryFit
extends RefCounted

## Side in metres of a cell of ground, and so the most a patch spans. ADR
## 0001: tuned for play, small enough that a surface follows the points, large enough that a
## pulse puts several points in each.
const _CELL_M := 16.0
## A vertical gap in metres between neighbouring points in a cell that starts
## another surface. ADR 0001: tuned; wider than a confident point's scatter,
## narrower than the Media's layers.
const _LAYER_GAP_M := 6.0
## The fewest points that make a surface: one or two points are an echo, not a
## surface. ADR 0001: tuned.
const _MIN_SUPPORT := 3
## How much supporting confidence (the sum of the points' confidences) makes a
## patch half sure. ADR 0001: tuned.
const _HALF_SURE := 4.0
## How strongly a fit leans toward level when its points barely say which way
## the surface slopes, in square metres: it weighs against the points' spread
## across the ground (about 21 m2 for points filling a cell), so a few points
## bunched together barely tilt it and a cell full of them sets its own slope.
## Layered ground lies near level unless the points show otherwise. ADR 0001:
## tuned.
const _LEVEL_PULL_M2 := 2.0
## The narrowest a patch is drawn across the ground, metres, so a patch of
## points in a line still shows. ADR 0001: tuned.
const _MIN_SIDE_M := 2.0
## How far past a patch's edge, across the ground, a line still counts as
## meeting it, metres (ahead()): patches cover only the ground their points
## span, so neighbours leave gaps. ADR 0001: tuned, half a cell.
const _AHEAD_REACH_M := 8.0
## The share of the surest patch's confidence that a nearer patch on the line
## needs to be taken for the Boundary ahead (ahead()): a few stray echoes
## short of a well-supported surface are not it. ADR 0001: tuned.
const _AHEAD_SHARE := 0.5
## Patches the line meets within this many metres beyond the nearest are
## taken for the same surface (ahead()). ADR 0001: tuned; wider than a
## tilted patch's error at its edge, narrower than the Media's layers.
const _AHEAD_SAME_M := 10.0


## The Inferred Boundary ahead of `origin` along `direction` (a unit vector),
## from these patches alone: Vector3(metres to it along the line, its
## confidence, the estimate of the rock beyond it against the rock before).
## Of the patches the line meets ahead, it is the nearest that is at least
## _AHEAD_SHARE as sure as the surest, with the like patches just beyond it:
## their mean distance, the confidence of the surest of them, and their
## estimates seen from the origin's side (BoundaryPatch.beyond()), weighted
## by confidence (NAN when none carries one). Vector3(INF, 0, NAN) when the
## line meets none. Patches nearer than `from` metres along the line are left
## out, as those behind the origin are.
static func ahead(patches: Array[BoundaryPatch], origin: Vector3, direction: Vector3,
		from := 0.0) -> Vector3:
	var hits: Array[Vector3] = []
	var surest := 0.0
	for patch in patches:
		var closing := patch.normal.dot(direction)
		if is_zero_approx(closing):
			continue
		var metres := patch.normal.dot(patch.centre - origin) / closing
		if metres < from:
			continue
		var off := origin + direction * metres - patch.centre
		if absf(off.x) > patch.size.x * 0.5 + _AHEAD_REACH_M \
				or absf(off.z) > patch.size.y * 0.5 + _AHEAD_REACH_M:
			continue
		hits.append(Vector3(metres, patch.confidence, -signf(closing) * patch.contrast))
		surest = maxf(surest, patch.confidence)
	var nearest := INF
	for hit in hits:
		if hit.y >= surest * _AHEAD_SHARE:
			nearest = minf(nearest, hit.x)
	if is_inf(nearest):
		return Vector3(INF, 0.0, NAN)
	# Neighbouring patches of the one surface each put it a little
	# differently: their mean, weighted by confidence, is the better figure.
	var weight := 0.0
	var metres := 0.0
	var confidence := 0.0
	var told := 0.0
	var beyond := 0.0
	for hit in hits:
		if hit.y >= surest * _AHEAD_SHARE and hit.x - nearest <= _AHEAD_SAME_M:
			weight += hit.y
			metres += hit.x * hit.y
			confidence = maxf(confidence, hit.y)
			if not is_nan(hit.z):
				told += hit.y
				beyond += hit.z * hit.y
	return Vector3(metres / weight, confidence, beyond / told if told > 0.0 else NAN)


## How far along the line from `origin` along `direction` (a unit vector) the
## scan has shown the rock, from these patches alone: metres to the furthest
## Inferred Boundary the line meets ahead, each surface found in turn by
## ahead() and passed; 0 when it meets none. An echo from that far means the
## rock on the way to it was sounded; beyond it nothing is shown. Its cost is
## ahead()'s once for each surface along the line.
static func furthest(patches: Array[BoundaryPatch], origin: Vector3, direction: Vector3) -> float:
	var reached := 0.0
	var found := ahead(patches, origin, direction)
	while not is_inf(found.x):
		reached = maxf(reached, found.x)
		found = ahead(patches, origin, direction, found.x + _AHEAD_SAME_M)
	return reached


## The patches the points imply, in no order. No points, no patches.
static func fit(points: Array[ScanPoint]) -> Array[BoundaryPatch]:
	var cells := {}
	for point in points:
		var key := Vector2i(floori(point.position.x / _CELL_M), floori(point.position.z / _CELL_M))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(point)
	var patches: Array[BoundaryPatch] = []
	for key: Vector2i in cells:
		var cell: Array = cells[key]
		cell.sort_custom(func(a: ScanPoint, b: ScanPoint) -> bool: return a.position.y < b.position.y)
		var layer: Array = []
		for point: ScanPoint in cell:
			if not layer.is_empty() and point.position.y - layer.back().position.y > _LAYER_GAP_M:
				_add_patch(patches, layer)
				layer = []
			layer.append(point)
		_add_patch(patches, layer)
	return patches


## Fits a plane to one layer of a cell's points and adds its patch, if enough
## points support it. The plane is a weighted least-squares fit of height
## against ground position, each point weighted by its confidence, pulled
## toward level by _LEVEL_PULL_M2. The patch covers the ground its points
## span, no further, and carries their contrasts' mean, weighted the same
## way (BoundaryPatch.contrast).
static func _add_patch(patches: Array[BoundaryPatch], layer: Array) -> void:
	if layer.size() < _MIN_SUPPORT:
		return
	var weights: Array[float] = []
	var weight := 0.0
	var mean := Vector3.ZERO
	var returned := 0.0
	var told := 0.0
	var contrast := 0.0
	var low: Vector3 = layer[0].position
	var high: Vector3 = low
	for point: ScanPoint in layer:
		var w := maxf(point.confidence, 0.001)
		weights.append(w)
		weight += w
		mean += point.position * w
		returned += point.returned_at * w
		if not is_nan(point.contrast):
			told += w
			contrast += point.contrast * w
		low = low.min(point.position)
		high = high.max(point.position)
	mean /= weight
	returned /= weight
	var sxx := 0.0
	var sxz := 0.0
	var szz := 0.0
	var sxy := 0.0
	var szy := 0.0
	for i in layer.size():
		var w := weights[i]
		var d: Vector3 = layer[i].position - mean
		sxx += w * d.x * d.x
		sxz += w * d.x * d.z
		szz += w * d.z * d.z
		sxy += w * d.x * d.y
		szy += w * d.z * d.y
	sxx += _LEVEL_PULL_M2 * weight
	szz += _LEVEL_PULL_M2 * weight
	var det := sxx * szz - sxz * sxz
	# Height rises by rise_x a metre along +x and rise_z a metre along +z.
	var rise_x := (sxy * szz - szy * sxz) / det
	var rise_z := (szy * sxx - sxy * sxz) / det
	var middle := (low + high) * 0.5
	middle.y = mean.y + rise_x * (middle.x - mean.x) + rise_z * (middle.z - mean.z)
	var size := Vector2(maxf(high.x - low.x, _MIN_SIDE_M), maxf(high.z - low.z, _MIN_SIDE_M))
	patches.append(BoundaryPatch.new(middle, Vector3(-rise_x, 1.0, -rise_z).normalized(), size,
			layer.size(), weight / (weight + _HALF_SURE), returned,
			contrast / told if told > 0.0 else NAN))
