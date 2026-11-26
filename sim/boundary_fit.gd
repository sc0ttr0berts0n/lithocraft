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
## span, no further.
static func _add_patch(patches: Array[BoundaryPatch], layer: Array) -> void:
	if layer.size() < _MIN_SUPPORT:
		return
	var weights: Array[float] = []
	var weight := 0.0
	var mean := Vector3.ZERO
	var returned := 0.0
	var low: Vector3 = layer[0].position
	var high: Vector3 = low
	for point: ScanPoint in layer:
		var w := maxf(point.confidence, 0.001)
		weights.append(w)
		weight += w
		mean += point.position * w
		returned += point.returned_at * w
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
			layer.size(), weight / (weight + _HALF_SURE), returned))
