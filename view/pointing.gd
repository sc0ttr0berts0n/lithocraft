## What lies under the centre dot: which Station screen the crew member is
## looking at, and which reading on it. The dot is what the explainer, and
## later clicking, point with.
##
## Plain data in the Habitat frame, no scene: each screen is a Face (its
## plane and the readings on it, laid out by GimballedStation.face()), and
## the look is a ray from the eyes. The Column fills the Bore, so a screen
## across the ring is hidden behind it; nothing else in the Habitat stands
## between the crew and a screen (the room is a ring, so a straight line
## between two points in it can only leave it through the Bore).
class_name Pointing
extends RefCounted


## A Station screen as the pointer sees it.
class Face:
	## From face coordinates to the Habitat frame: x to the right and y up as
	## the crew see the screen, z out of it toward them, origin at its middle.
	var transform := Transform3D.IDENTITY
	## The screen itself, in face coordinates (metres).
	var bounds := Rect2()
	## Each reading's place on the face, in face coordinates (metres). A
	## reading may lie past the screen's edge (text set above a display), and
	## a later one may lie over an earlier (an instrument on a display): the
	## later is the one pointed at.
	var readings: Array[Rect2] = []


## What lies along the look from eyes in direction (Habitat frame) among
## faces, with the Column filling the Bore out to bore_radius: {} for no
## screen, else {face = its index in faces, reading = the index of the
## reading on it (the last of those under the look), or -1 for the screen
## between readings}. Only a screen's front is pointed at, and the nearest
## screen along the look wins.
static func under(eyes: Vector3, direction: Vector3, faces: Array[Face], bore_radius: float) -> Dictionary:
	var best := {}
	var nearest := INF
	for i in faces.size():
		var face := faces[i]
		var normal := face.transform.basis.z.normalized()
		var facing := direction.dot(normal)
		if facing >= 0.0:
			continue
		var along := (face.transform.origin - eyes).dot(normal) / facing
		if along <= 0.0 or along >= nearest:
			continue
		var local := face.transform.affine_inverse() * (eyes + direction * along)
		var at := Vector2(local.x, local.y)
		var reading := -1
		for r in range(face.readings.size() - 1, -1, -1):
			if face.readings[r].has_point(at):
				reading = r
				break
		if reading < 0 and not face.bounds.has_point(at):
			continue
		nearest = along
		best = {face = i, reading = reading}
	if not best.is_empty() and _into_bore(eyes, direction, bore_radius) < nearest:
		return {}
	return best


## How far along the look it first enters the Bore (the Habitat's z axis),
## or INF if it never does.
static func _into_bore(eyes: Vector3, direction: Vector3, radius: float) -> float:
	var o := Vector2(eyes.x, eyes.y)
	var d := Vector2(direction.x, direction.y)
	var a := d.length_squared()
	# A Bore of no width hides nothing, even from a look through its axis.
	if a <= 0.0 or radius <= 0.0:
		return INF
	var b := o.dot(d)
	var c := o.length_squared() - radius * radius
	var disc := b * b - a * c
	# Eyes inside the Bore are nowhere the crew can be: read as clear.
	if disc < 0.0 or c < 0.0:
		return INF
	var t := (-b - sqrt(disc)) / a
	return t if t > 0.0 else INF
