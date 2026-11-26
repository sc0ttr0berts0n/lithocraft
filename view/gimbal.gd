## Turns a basis so its up axis moves toward a target "up" by the shortest
## rotation, keeping its heading as far as it can. Used by the crew member
## and the Station gimbals alike.
class_name Gimbal
extends RefCounted


## weight 0 leaves the basis alone, 1 aligns it fully.
static func toward_up(basis: Basis, up: Vector3, weight: float) -> Basis:
	var current := basis.y.normalized()
	if current.dot(up) > 0.999999:
		return basis.orthonormalized()
	if current.dot(up) < -0.999999:
		# Exactly upside down: any axis will do, so tip over sideways.
		up = (up + basis.x * 0.01).normalized()
	var turn := Quaternion(current, up)
	var partial := Quaternion.IDENTITY.slerp(turn, weight)
	return (Basis(partial) * basis).orthonormalized()
