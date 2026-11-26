## Infers Boundaries from Navigation's point cloud alone, as a multibeam
## survey builds a seabed from its soundings: the ground is gridded into
## square cells; in each, the points are split into layers by height (a gap
## means another surface), and a plane is fitted to each layer with enough
## points. A patch's confidence follows how many points support it and how
## confident they are. It is given points and nothing else, so it can only
## ever show what the scan returned (design record: "Topology is honest").
class_name BoundaryFit
extends RefCounted

## Side in metres of a cell of ground, and so of a patch. ADR 0001: tuned for
## play, small enough that a surface follows the points, large enough that a
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
## the surface slopes, in square metres. Layered ground lies near level unless
## the points show otherwise. ADR 0001: tuned.
const _LEVEL_PULL_M2 := 20.0


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
		var centre := (Vector2(key) + Vector2(0.5, 0.5)) * _CELL_M
		var layer: Array = []
		for point: ScanPoint in cell:
			if not layer.is_empty() and point.position.y - layer.back().position.y > _LAYER_GAP_M:
				_add_patch(patches, layer, centre)
				layer = []
			layer.append(point)
		_add_patch(patches, layer, centre)
	return patches


## Fits a plane to one layer of a cell's points and adds its patch, if enough
## points support it. The plane is a weighted least-squares fit of height
## against ground position, each point weighted by its confidence, pulled
## toward level by _LEVEL_PULL_M2.
static func _add_patch(patches: Array[BoundaryPatch], layer: Array, centre: Vector2) -> void:
	if layer.size() < _MIN_SUPPORT:
		return
	var weight := 0.0
	var mean := Vector3.ZERO
	var returned := 0.0
	for point: ScanPoint in layer:
		var w := maxf(point.confidence, 0.001)
		weight += w
		mean += point.position * w
		returned += point.returned_at * w
	mean /= weight
	returned /= weight
	var sxx := 0.0
	var sxz := 0.0
	var szz := 0.0
	var sxy := 0.0
	var szy := 0.0
	for point: ScanPoint in layer:
		var w := maxf(point.confidence, 0.001)
		var d := point.position - mean
		sxx += w * d.x * d.x
		sxz += w * d.x * d.z
		szz += w * d.z * d.z
		sxy += w * d.x * d.y
		szy += w * d.z * d.y
	sxx += _LEVEL_PULL_M2 * weight
	szz += _LEVEL_PULL_M2 * weight
	var det := sxx * szz - sxz * sxz
	# Height rises by slope.x a metre eastward (+x), slope.y a metre along +z.
	var slope := Vector2((sxy * szz - szy * sxz) / det, (szy * sxx - sxy * sxz) / det)
	var height := mean.y + slope.x * (centre.x - mean.x) + slope.y * (centre.y - mean.z)
	var normal := Vector3(-slope.x, 1.0, -slope.y).normalized()
	var confidence := weight / (weight + _HALF_SURE)
	patches.append(BoundaryPatch.new(Vector3(centre.x, height, centre.y), normal, _CELL_M,
			layer.size(), confidence, returned))
