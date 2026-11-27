# The cost budget

Tests assert relationships, so a query that is correct but slow passes them all; the cost budget is what catches it.
`tools/cost/cost.sh` (from Git Bash at the repo root, `GODOT_BIN` set as for the tests) prints `COST OK` and exits 0, or `COST OVER BUDGET` and exits 1; it takes about half a minute and is no part of `./test.sh`.

- It plays the Shift drill headless in a real Habitat, in the game's own 1/60 s steps, through five conditions of 4 s of dive time each (`--seconds` changes that): under way with a Boundary ahead, a slow turn, steering effort at zero, low power, and a full point cloud with pulses still coming.
  A new way to be slow gets a line in `tools/cost/cost.gd::CONDITIONS`.
- A frame is one Habitat step (the simulation's step, then every Station's status lines), one `_process` of every node that has one, and every redraw those ask for.
  `CostProbe` (`tools/cost/cost_probe.gd`) calls each itself and times it, and charges each cost to a Station by the name on its screen and to the part of the screen it was (the nearest named class: `Reactor / PlasmaDisplay`); a display that hangs off the Habitat itself names its Station in `CostProbe.SHOWN_AT`.
- Every simulation query that takes no argument is also timed alone, one call every few frames, on a twin simulation no screen reads, so a query that keeps its answer is timed working it out.
- Every budget is a count of baselines, the time a fixed piece of GDScript work takes in the same run, so a slower machine gets the same verdict: `CostBudget.MEAN_FRAME_BASELINES` for any condition's mean frame, `WORST_FRAME_BASELINES` for any one frame, `QUERY_BASELINES` for any one call of a query.
  They are generous, about twice the frame's cost when they were set and four times the dearest query's; lower them when the game gets cheaper, never raise them to pass.
- A query a screen polls must stay inside the budget in every condition, however slowly the vessel moves or turns and however full the cloud is: run the command after adding one, or after changing what one costs or how often a screen asks.
- The report lists the cost by condition, by Station and part, and by query, and names the slowest Station and the slowest query; over budget, each sentence names the condition and what took longest in it.
- Headless nothing reaches a GPU: it measures the scripts' and the engine's work on the CPU (text shaping included), not drawing.
  A worst frame is one frame, so another program busy at that moment can push it over: run it again before believing a lone worst-frame failure.
- `tools/cost/` is GDScript, none of it loaded by the game; `CostBudget` and `CostProbe` are tested in `test/cost_budget_test.gd`, with costs made up in baselines; no test times anything.
