## A target's body: something in the rock that surface control's survey has
## seen and cannot identify, with a place and a size in three dimensions.
## Plain data, the world's truth as the layout is (MediumLayout.with_targets()
## places it): the simulation sounds it (its surface returns echoes to every
## tool) and finds it in the Column when the Head cuts into it. The scan side
## never reads it: it learns of a target only from the Orders' fuzzy place
## and from points (TargetRegion).
##
## It is a body in its host rock, not a Medium: cutting through it leaves the
## Wobble the host's, and it reaches the Bore Station as a feature of
## interest of its own kind (ColumnFeature.target names it).
class_name TargetBody
extends RefCounted

## How the Orders and the scan name it, e.g. &"A".
var label: StringName
## What it turns out to be once it is in the Column (ColumnFeature.kind); the
## crew cannot know it before.
var kind: StringName
## Where its middle lies, metres in the world frame (+Y up, so depth is -y).
var centre: Vector3
## Its half-extents along the world's x, y and z, metres: an ellipsoid.
var half_size: Vector3
## How stiff and dense its rock is, on the scale the Media's echoes are
## worked on (hardness times solid fraction, DiveSimulation._reflection()),
## so its surface reflects as the contrast with its host rock says.
var stiffness: float
## What a full record of it adds to the survey's value, as ColumnFeature.worth.
var worth: float


func _init(p_label: StringName, p_kind: StringName, p_centre: Vector3, p_half_size: Vector3,
		p_stiffness: float, p_worth: float) -> void:
	label = p_label
	kind = p_kind
	centre = p_centre
	half_size = p_half_size
	stiffness = p_stiffness
	worth = p_worth


## True when this world place lies inside the body.
func holds(place: Vector3) -> bool:
	var off := (place - centre) / half_size
	return off.length_squared() <= 1.0


## Where the straight piece from `from` to `to` passes through the body's
## surface: [[metres from `from`, true entering or false leaving], ...],
## nearest first, only within the piece.
func crossings(from: Vector3, to: Vector3) -> Array:
	var found := []
	var length := from.distance_to(to)
	if length <= 0.0:
		return found
	# In the body's own frame, stretched so its surface is the unit sphere.
	var start := (from - centre) / half_size
	var along := (to - from) / half_size
	var a := along.length_squared()
	var b := 2.0 * start.dot(along)
	var c := start.length_squared() - 1.0
	var disc := b * b - 4.0 * a * c
	if disc <= 0.0:
		return found
	var root := sqrt(disc)
	var entering := (-b - root) / (2.0 * a)
	var leaving := (-b + root) / (2.0 * a)
	if entering >= 0.0 and entering <= 1.0:
		found.append([entering * length, true])
	if leaving >= 0.0 and leaving <= 1.0:
		found.append([leaving * length, false])
	return found


## How far a straight line entering the body at `place` along `direction` (a
## unit vector) runs inside it before it leaves, metres: the length of Column
## a straight cut through it holds.
func chord(place: Vector3, direction: Vector3) -> float:
	var reach := 2.0 * maxf(half_size.x, maxf(half_size.y, half_size.z))
	for crossing in crossings(place, place + direction * reach):
		if not crossing[1] and crossing[0] > 0.0:
			return crossing[0]
	return 0.0


# --- Kinds of target -----------------------------------------------------

## Stiffness of hematite breccia on the Media's scale: granite's (5.0 x 0.99)
## times the real ratio of their acoustic impedances, about 1.6 (hematite
## breccia some 4 g/cc at 6 km/s against granite's 2.65 g/cc at 5.5 km/s).
## Tuned for play (ADR 0001): only that it is stiffer than granite matters.
const _BRECCIA_STIFFNESS := 8.0
## Its half-extents: a flattened lens 18 m across and 10 m tall, longer than
## the Column is wide and about as tall as the vessel is long. Tuned for play
## (ADR 0001).
const _BRECCIA_HALF_SIZE := Vector3(9.0, 5.0, 9.0)
## What a full record of it is worth: several features' worth, as a find the
## dive was sent for. Tuned for play (ADR 0001).
const _BRECCIA_WORTH := 400.0


## The first slice's one kind of target: a lens of hematite breccia, granite
## shattered and cemented by iron oxide. Real basis: Olympic Dam was found in
## 1975 by boring into a gravity and magnetic high under cover; the survey
## sees a dense, magnetic body and cannot say what it is until a hole is
## bored through it and the rock is looked at (here, as the Column).
static func hematite_breccia(p_label: StringName, p_centre: Vector3) -> TargetBody:
	return TargetBody.new(p_label, &"hematite_breccia", p_centre, _BRECCIA_HALF_SIZE,
			_BRECCIA_STIFFNESS, _BRECCIA_WORTH)
