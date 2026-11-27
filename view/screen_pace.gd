## How often a Station screen's instrument brings itself up to the simulation:
## every frame while the crew is at its Station (watched), and once every
## UNWATCHED_S while they are not (the first frame at or past it), so a
## screen seen from across the Habitat is never more than that and a frame
## behind, and costs a fraction of a watched one. Plain view logic, fed the
## frame's time; tested in screen_pace_test.gd.
class_name ScreenPace
extends RefCounted

## The most a reading on a screen the crew is not at may lag the simulation,
## in seconds of the frame's own time.
const UNWATCHED_S := 0.1

## Slack for frame times that sum to UNWATCHED_S only nearly (six of 1/60 s).
const _SLACK_S := 0.0005

## Seconds of frame time since the instrument last brought itself up.
var _since := INF


## Whether this frame, `delta` seconds after the last, is one to bring the
## instrument up to the simulation in. The first frame always is, and the next
## after hurry().
func due(delta: float, watched: bool) -> bool:
	_since += delta
	if watched or _since >= UNWATCHED_S - _SLACK_S:
		_since = 0.0
		return true
	return false


## due(), watched while the crew is at `station` (the simulation's name for
## it); always watched with no Station named (a panel of the debug overlay) or
## no simulation yet.
func due_at(delta: float, sim: DiveSimulation, station: StringName) -> bool:
	return due(delta, station.is_empty() or sim == null or sim.attended(station))


## Makes the next frame due, watched or not: for a change the simulation does
## not make, such as the instrument's size.
func hurry() -> void:
	_since = INF
