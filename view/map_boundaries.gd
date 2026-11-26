## The Boundaries Navigation's moving map draws, inferred from the point cloud
## alone, never from the MediumLayout: the map shows what the crew has heard,
## not what is there.
##
## The rule is a simple honest one, for the map until the fitted surfaces of
## the point cloud (ticket #40) can replace it behind infer(): the echoes of a
## level Boundary pile up at one depth, so a Boundary is a depth where
## returns pile up. Points are binned by depth, weighted by their confidence;
## each run of bins dense enough is one Boundary, at its points' weighted
## mean depth, as sure as the confidence that supports it. It assumes level
## Boundaries, as the layouts have for now.
class_name MapBoundaries
extends RefCounted

## The height of a depth bin, metres: about the scatter of a sure point.
const BIN_M := 4.0
## The confidence a bin must gather to be part of a Boundary, and a Boundary
## to be drawn: a few sure points, so lone strays and doubtful echoes strewn
## through the rock make none.
const BIN_SUPPORT := 1.5
const LEAST_SUPPORT := 4.0


## A Boundary as the points show it.
class Boundary:
	extends RefCounted
	## Metres below the surface.
	var depth: float
	## The summed confidence of the points that show it: more, and surer,
	## points support it more.
	var support: float
	## The points that show it, so a view can span the ground they cover.
	var points: Array[ScanPoint]

	func _init(p_depth: float, p_support: float, p_points: Array[ScanPoint]) -> void:
		depth = p_depth
		support = p_support
		points = p_points


## The Boundaries the points show, shallowest first.
static func infer(points: Array[ScanPoint]) -> Array[Boundary]:
	var bins := {}
	for point in points:
		var bin := floori(-point.position.y / BIN_M)
		if not bins.has(bin):
			bins[bin] = {support = 0.0, points = [] as Array[ScanPoint]}
		bins[bin].support += point.confidence
		bins[bin].points.append(point)
	var found: Array[Boundary] = []
	var keys := bins.keys()
	keys.sort()
	var run: Array[ScanPoint] = []
	var last := 0
	for bin: int in keys:
		if bins[bin].support < BIN_SUPPORT:
			continue
		if not run.is_empty() and bin != last + 1:
			_close(run, found)
			run = []
		run.append_array(bins[bin].points)
		last = bin
	_close(run, found)
	return found


## Adds the run of points as a Boundary, if it is supported enough.
static func _close(run: Array[ScanPoint], found: Array[Boundary]) -> void:
	var support := 0.0
	var weighted := 0.0
	for point in run:
		support += point.confidence
		weighted += -point.position.y * point.confidence
	if support >= LEAST_SUPPORT:
		found.append(Boundary.new(weighted / support, support, run))
