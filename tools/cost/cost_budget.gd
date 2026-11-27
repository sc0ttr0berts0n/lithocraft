## The cost budget (tools/cost/cost.sh): the tally of what each frame and each
## simulation query cost in one run, whether that is inside the budget, and
## the report of it.
##
## A frame's cost comes as its parts, {"<group> / <part>": milliseconds}: the
## group a Station by the name on its screen (or what CostProbe calls the rest:
## the simulation's step, the Habitat's), the part what of its screen took the
## time. Every budget is a count of baselines, the time one fixed piece of work
## took in the same run, so a slower machine, slower at both, gets the same
## verdict. Plain data in, plain text out: nothing here reads a clock.
class_name CostBudget
extends RefCounted

## The budget, in baselines. Generous on purpose: about twice what the mean
## and the worst frame cost when it was set and four times the dearest query,
## to catch a query or a screen grown several times dearer, not a small drift.
## No condition's mean frame may pass the first, no single frame the second,
## no single call of a query the simulation hands a screen the third. Ticket
## #96 tightens them once it has found where a quiet frame goes.
const MEAN_FRAME_BASELINES := 25.0
const WORST_FRAME_BASELINES := 75.0
const QUERY_BASELINES := 20.0

## How many queries the report lists, dearest first.
const QUERIES_LISTED := 12
## What joins a group to its part in a part's name.
const JOIN := " / "

## Milliseconds the fixed piece of work took in this run.
var baseline_ms := 1.0

## The conditions in the order they were first given, and each one's tally:
## {frames, total_ms, worst_ms, worst_parts, parts = {name: summed ms}}.
var _conditions: Array[String] = []
var _tallies := {}
## Each query's tally: {calls, total_ms, worst_ms, worst_in}.
var _queries := {}


## One frame played under a condition: what each part of it cost.
func add_frame(condition: String, parts: Dictionary) -> void:
	if not _tallies.has(condition):
		_conditions.append(condition)
		_tallies[condition] = {frames = 0, total_ms = 0.0, worst_ms = 0.0, worst_parts = {}, parts = {}}
	var tally: Dictionary = _tallies[condition]
	var total := 0.0
	for part: String in parts:
		total += parts[part]
		tally.parts[part] = tally.parts.get(part, 0.0) + parts[part]
	tally.frames += 1
	tally.total_ms += total
	if total > tally.worst_ms:
		tally.worst_ms = total
		tally.worst_parts = parts.duplicate()


## One call of a simulation query under a condition.
func add_query(condition: String, query: String, ms: float) -> void:
	if not _queries.has(query):
		_queries[query] = {calls = 0, total_ms = 0.0, worst_ms = -1.0, worst_in = ""}
	var tally: Dictionary = _queries[query]
	tally.calls += 1
	tally.total_ms += ms
	if ms > tally.worst_ms:
		tally.worst_ms = ms
		tally.worst_in = condition


## How many frames were tallied.
func frames() -> int:
	var count := 0
	for condition in _conditions:
		count += _tallies[condition].frames
	return count


## The mean frame over every condition, milliseconds.
func mean_frame_ms() -> float:
	var total := 0.0
	for condition in _conditions:
		total += _tallies[condition].total_ms
	return total / maxi(frames(), 1)


## The dearest single frame, milliseconds.
func worst_frame_ms() -> float:
	var worst := 0.0
	for condition in _conditions:
		worst = maxf(worst, _tallies[condition].worst_ms)
	return worst


## The group that took the most of the mean frame: a Station by the name on
## its screen, or "Simulation" or "Habitat". "" with no frame tallied.
func slowest_station() -> String:
	return _largest(_by_group(_mean_parts()))


## The query whose dearest call cost most. "" with none timed.
func slowest_query() -> String:
	var slowest := ""
	for query: String in _queries:
		if slowest.is_empty() or _queries[query].worst_ms > _queries[slowest].worst_ms:
			slowest = query
	return slowest


## What is over budget, one sentence each, naming the condition and the
## Station or query that took longest in it; empty when the run is inside the
## budget.
func over() -> PackedStringArray:
	var found := PackedStringArray()
	for condition in _conditions:
		var tally: Dictionary = _tallies[condition]
		var mean: float = tally.total_ms / tally.frames
		if mean > MEAN_FRAME_BASELINES * baseline_ms:
			var groups := _by_group(_scaled(tally.parts, 1.0 / tally.frames))
			var group := _largest(groups)
			found.append("the mean frame in \"%s\" took %s, %.1f baselines against a budget of %.1f: %s took longest, %s of it (%s)" % [
					condition, _ms(mean), mean / baseline_ms, MEAN_FRAME_BASELINES, group,
					_ms(groups[group]), _largest_part(_scaled(tally.parts, 1.0 / tally.frames), group)])
		if tally.worst_ms > WORST_FRAME_BASELINES * baseline_ms:
			var groups := _by_group(tally.worst_parts)
			var group := _largest(groups)
			found.append("the worst frame in \"%s\" took %s, %.1f baselines against a budget of %.1f: %s took longest, %s of it (%s)" % [
					condition, _ms(tally.worst_ms), tally.worst_ms / baseline_ms, WORST_FRAME_BASELINES,
					group, _ms(groups[group]), _largest_part(tally.worst_parts, group)])
	for query: String in _queries:
		var tally: Dictionary = _queries[query]
		if tally.worst_ms > QUERY_BASELINES * baseline_ms:
			found.append("the query %s() took %s in one call in \"%s\", %.1f baselines against a budget of %.1f" % [
					query, _ms(tally.worst_ms), tally.worst_in, tally.worst_ms / baseline_ms, QUERY_BASELINES])
	return found


## The whole report, a line each: the frame by condition, by Station and its
## parts, the dearest queries, the slowest Station and query, and the verdict
## (the last line: "COST OK" or "COST OVER BUDGET").
func report() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("baseline %s: a fixed piece of work timed in this run, which every budget is a count of" % _ms(baseline_ms))
	lines.append("frame: one simulation step and one update of every Station's screen, %d of them" % frames())
	lines.append("")
	lines.append("%-34s %10s %10s   %s" % ["BY CONDITION", "mean", "worst", "slowest in the mean frame; in the worst frame"])
	for condition in _conditions:
		var tally: Dictionary = _tallies[condition]
		var shares := _by_group(_scaled(tally.parts, 1.0 / tally.frames))
		var most := _largest(shares)
		var worst := _by_group(tally.worst_parts)
		var most_of_worst := _largest(worst)
		lines.append("%-34s %10s %10s   %s %s; %s %s (%s)" % [condition, _ms(tally.total_ms / tally.frames),
				_ms(tally.worst_ms), most, _ms(shares[most]), most_of_worst, _ms(worst[most_of_worst]),
				_largest_part(tally.worst_parts, most_of_worst)])
	lines.append("%-34s %10s %10s" % ["every condition", _ms(mean_frame_ms()), _ms(worst_frame_ms())])
	lines.append("%-34s %10s %10s" % ["  in baselines", "%.1f" % (mean_frame_ms() / baseline_ms),
			"%.1f" % (worst_frame_ms() / baseline_ms)])
	lines.append("%-34s %10s %10s" % ["  budget, each condition", "%.1f" % MEAN_FRAME_BASELINES,
			"%.1f" % WORST_FRAME_BASELINES])
	lines.append("")
	lines.append("%-34s %10s %10s   %s" % ["BY STATION AND PART", "mean", "share", "dearest condition (its mean)"])
	var mean_parts := _mean_parts()
	var groups := _by_group(mean_parts)
	for group in _dearest_first(groups):
		lines.append("%-34s %10s %9.0f%%   %s" % [group, _ms(groups[group]),
				100.0 * groups[group] / maxf(mean_frame_ms(), 1e-9), _dearest_condition(group + JOIN)])
		var parts := {}
		for part: String in mean_parts:
			if part.begins_with(group + JOIN):
				parts[part] = mean_parts[part]
		for part in _dearest_first(parts):
			lines.append("%-34s %10s %9.0f%%   %s" % ["  " + part.trim_prefix(group + JOIN), _ms(parts[part]),
					100.0 * parts[part] / maxf(mean_frame_ms(), 1e-9), _dearest_condition(part)])
	lines.append("")
	lines.append("%-34s %10s %10s   %s" % ["BY QUERY, one call", "mean", "worst", "worst in"])
	var worsts := {}
	for query: String in _queries:
		worsts[query] = _queries[query].worst_ms
	var listed := _dearest_first(worsts)
	for query in listed.slice(0, QUERIES_LISTED):
		var tally: Dictionary = _queries[query]
		lines.append("%-34s %10s %10s   %s" % [query + "()", _ms(tally.total_ms / tally.calls),
				_ms(tally.worst_ms), tally.worst_in])
	if listed.size() > QUERIES_LISTED:
		lines.append("  and %d cheaper queries; budget %.1f baselines a call" % [
				listed.size() - QUERIES_LISTED, QUERY_BASELINES])
	lines.append("")
	var slowest := slowest_station()
	if not slowest.is_empty():
		lines.append("slowest Station: %s, %s of the mean frame (%s)" % [slowest, _ms(groups[slowest]),
				_largest_part(mean_parts, slowest)])
	var query := slowest_query()
	if not query.is_empty():
		lines.append("slowest query: %s(), %s in one call in \"%s\"" % [query, _ms(_queries[query].worst_ms),
				_queries[query].worst_in])
	var found := over()
	for sentence in found:
		lines.append("OVER BUDGET: " + sentence)
	lines.append("COST OK" if found.is_empty() else "COST OVER BUDGET")
	return lines


## Every part's mean cost a frame over the whole run.
func _mean_parts() -> Dictionary:
	var parts := {}
	for condition in _conditions:
		for part: String in _tallies[condition].parts:
			parts[part] = parts.get(part, 0.0) + _tallies[condition].parts[part]
	return _scaled(parts, 1.0 / maxi(frames(), 1))


## The condition in which the parts whose names begin so cost most a frame,
## and that mean.
func _dearest_condition(prefix: String) -> String:
	var dearest := ""
	var most := -1.0
	for condition in _conditions:
		var tally: Dictionary = _tallies[condition]
		var mean := 0.0
		for part: String in tally.parts:
			if part.begins_with(prefix):
				mean += tally.parts[part] / tally.frames
		if mean > most:
			most = mean
			dearest = condition
	return "%s (%s)" % [dearest, _ms(most)]


static func _scaled(parts: Dictionary, by: float) -> Dictionary:
	var scaled := {}
	for part: String in parts:
		scaled[part] = parts[part] * by
	return scaled


## Parts summed into their groups.
static func _by_group(parts: Dictionary) -> Dictionary:
	var groups := {}
	for part: String in parts:
		var group := part.get_slice(JOIN, 0)
		groups[group] = groups.get(group, 0.0) + parts[part]
	return groups


static func _largest(costs: Dictionary) -> String:
	var largest := ""
	for key: String in costs:
		if largest.is_empty() or costs[key] > costs[largest]:
			largest = key
	return largest


## A group's dearest part, as "<part> <its cost>".
static func _largest_part(parts: Dictionary, group: String) -> String:
	var own := {}
	for part: String in parts:
		if part.begins_with(group + JOIN):
			own[part] = parts[part]
	var largest := _largest(own)
	return "" if largest.is_empty() else "%s %s" % [largest.trim_prefix(group + JOIN), _ms(own[largest])]


static func _dearest_first(costs: Dictionary) -> Array:
	var keys := costs.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return costs[a] > costs[b] or (costs[a] == costs[b] and a < b))
	return keys


static func _ms(ms: float) -> String:
	return "%.3f ms" % ms
