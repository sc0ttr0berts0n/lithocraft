## A Medium the Lithocraft can travel through, described by its properties.
## Plain data: a new Medium is a new set of values, not new code.
class_name Medium
extends RefCounted

## How hard the Medium is to cut. Higher is harder. Relative, tuned for play.
var hardness: float


func _init(p_hardness: float) -> void:
	hardness = p_hardness


static func sand() -> Medium:
	return Medium.new(1.0)
