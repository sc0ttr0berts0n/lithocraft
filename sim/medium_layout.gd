## Which Medium lies at each point underground. Queried, never rendered.
class_name MediumLayout
extends RefCounted

var _medium: Medium


func _init(medium: Medium) -> void:
	_medium = medium


## A layout of one Medium at every depth.
static func uniform(medium: Medium) -> MediumLayout:
	return MediumLayout.new(medium)


## The Medium at the given depth in metres below the surface.
func medium_at(_depth: float) -> Medium:
	return _medium
