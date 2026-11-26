## A moving scale on the Drive's primary flight display (FlightDisplay): the
## speed tape, the depth tape, the heading tape and the attitude indicator's
## pitch ladder are each one. The reading stays at the tape's middle and the
## scale slides past it, as on an airliner's tapes; a bug (the Course) sits at
## its own value on the scale, pinned to the tape's end when it is off it.
##
## Plain data, no drawing: places along the tape in pixels from its middle,
## positive the way the values grow (FlightDisplay turns that into the
## screen's x or y), so the display's scale logic is tested directly.
class_name FlightTape
extends RefCounted

## Units of the value across the whole tape's length.
var span: float
## The tape's length in pixels.
var length: float
## 360 for a compass heading, whose scale wraps round; 0 for one that does not.
var wrap: float


func _init(p_span: float, p_length: float, p_wrap: float = 0.0) -> void:
	span = p_span
	length = p_length
	wrap = p_wrap


## Pixels per unit of the value.
func scale() -> float:
	return length / span


## How far value lies from reading, in units: on a wrapping scale the short
## way round, so a Course of 350 is 20 to the left of a heading of 10.
func difference(value: float, reading: float) -> float:
	var d := value - reading
	if wrap > 0.0:
		d = fposmod(d + wrap / 2.0, wrap) - wrap / 2.0
	return d


## Where value lies along the tape with reading at its middle, pixels from
## the middle, positive the way the values grow. May lie off the tape.
func place(value: float, reading: float) -> float:
	return difference(value, reading) * scale()


## Whether value shows on the tape with reading at its middle.
func on_scale(value: float, reading: float) -> bool:
	return absf(place(value, reading)) <= length / 2.0


## Where a bug for value sits: at its place, or pinned to the tape's nearer
## end when its place is off the tape, so the bug always shows which way.
func pinned(value: float, reading: float) -> float:
	return clampf(place(value, reading), -length / 2.0, length / 2.0)


## The values of the ticks every step that show on the tape with reading at
## its middle, lowest first; a wrapping scale's are given in [0, wrap).
## Values outside [lowest, highest] are left off (a speed below 0, a pitch
## past straight down).
func ticks(reading: float, step: float, lowest: float = -INF, highest: float = INF) -> Array[float]:
	var half := span / 2.0
	var values: Array[float] = []
	var first := ceilf((reading - half) / step)
	var last := floorf((reading + half) / step)
	for i in range(int(first), int(last) + 1):
		var value := i * step
		if value < lowest or value > highest:
			continue
		values.append(fposmod(value, wrap) if wrap > 0.0 else value)
	return values
