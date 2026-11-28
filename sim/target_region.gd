## Where a target is, as far as the scan knows: an ellipsoid of the world, its
## middle and its half-extents along the world's x, y and z. Plain data, the
## scan side's alone: it is made from the Orders' fuzzy place (surface
## control's survey, DiveSimulation.start_surveyed()) and narrowed by points
## (narrowed()), and never from the layout or the body itself, so it is only
## as true as the points are.
class_name TargetRegion
extends RefCounted

## The scan's points heard from the body are taken as lying on the part of
## its surface facing the vessel, spread evenly: a spread of one standard
## deviation is this share of the half-width they cover (the square root of
## three, for an even spread).
const _SPREAD_TO_HALF_WIDTH := 1.7320508
## How far a point strays from where its echo came from, as a share of its
## range for each part of doubt (1 - confidence): the scan's own measure of
## its accuracy, so the region is never drawn tighter than its points can say.
## Tuned for play (ADR 0001).
const _STRAY_SHARE := 0.08
## The weight of points (their confidences summed) at which the estimate from
## the points counts as much as the Orders' place: fewer and fainter points
## narrow the region less. Tuned for play (ADR 0001).
const _HALF_SURE_WEIGHT := 8.0

## How the Orders name it, as the target's label (e.g. &"A").
var label: StringName
## Its middle, metres in the world frame (DiveSimulation.head_position()).
var centre: Vector3
## Its half-extents along the world's x, y and z, metres.
var half_size: Vector3
## The weight of points it was narrowed by: their confidences summed. 0 for
## the Orders' place alone.
var support := 0.0


func _init(p_label: StringName, p_centre: Vector3, p_half_size: Vector3, p_support := 0.0) -> void:
	label = p_label
	centre = p_centre
	half_size = p_half_size
	support = p_support


## How much of the world it covers, cubic metres: smaller as it narrows.
func volume() -> float:
	return 4.0 / 3.0 * PI * half_size.x * half_size.y * half_size.z


## True when this world place lies inside it.
func holds(place: Vector3) -> bool:
	return ((place - centre) / half_size).length_squared() <= 1.0


## The region as the vessel's own points narrow `report` (the Orders' place):
## the points inside the report are taken as the body's, its near surface,
## each as sure as its confidence. Their weighted middle is where the body is;
## their spread across shows how wide it is, and the body is taken to be about
## as deep as it is wide behind them, so the region round them is that wide
## every way, plus how far the points may stray. The fewer and fainter the
## points, the more the report still counts (_HALF_SURE_WEIGHT); it never
## grows past the report. Surface control's own points are not the vessel's
## and narrow nothing. Points alone, so it never sees the layout or the body:
## points inside the report from anything else narrow it just the same.
static func narrowed(report: TargetRegion, points: Array[ScanPoint]) -> TargetRegion:
	var weight := 0.0
	var sum := Vector3.ZERO
	var sum_squares := Vector3.ZERO
	var stray := 0.0
	for point in points:
		if point.surveyed or not report.holds(point.position):
			continue
		var w := point.confidence
		weight += w
		sum += point.position * w
		sum_squares += point.position * point.position * w
		stray += point.range * (1.0 - point.confidence) * _STRAY_SHARE * w
	if weight <= 0.0:
		return TargetRegion.new(report.label, report.centre, report.half_size)
	var middle := sum / weight
	var spread := (sum_squares / weight - middle * middle).max(Vector3.ZERO)
	spread = Vector3(sqrt(spread.x), sqrt(spread.y), sqrt(spread.z))
	var widest := maxf(spread.x, maxf(spread.y, spread.z)) * _SPREAD_TO_HALF_WIDTH + stray / weight
	var sure := weight / (weight + _HALF_SURE_WEIGHT)
	var half := report.half_size.lerp(Vector3.ONE * widest, sure).min(report.half_size)
	return TargetRegion.new(report.label, report.centre.lerp(middle, sure), half, weight)
