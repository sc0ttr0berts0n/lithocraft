# Lithocraft

A hard-science-fiction Godot 4 game about operating the Lithocraft, a ring-shaped vessel that bores through rock. See `CLAUDE.md`, `GLOSSARY.md` and GitHub issue #1 for the design.

Built with Godot 4.7 (standard, not .NET).

## Layout

- `sim/`: the simulation. Plain GDScript classes (`RefCounted`) with no scene nodes, rendering or input. Commands in, `advance(dt)`, state out.
- `view/`: scenes that read the simulation and send it commands. `view/habitat.tscn` is the main scene: it owns the simulation and shows the Habitat in first person. `view/dive_view.tscn` is a developer overlay, off by default (F3).
- `test/`: GdUnit4 test suites. They test only through the simulation's interface.
- `addons/gdUnit4/`: vendored GdUnit4 v6.2.3.

## Run the game

Open the folder in the Godot 4.7 editor and press F5, or from a shell:

```sh
<godot-binary> --path .
```

You start at the surface in the Habitat, in first person. Click to look around with the mouse (Esc lets it go) and walk with WASD. Space calls the Arm, which carries you to the nearest Station; A / D move you to the next Station left or right, and Space lets go. Each Station's keys work only while you are at it. F1 shows every key; `docs/conventions.md` has the full key map.

A dive in brief: plot the Course at Navigation, set power at the Drive, split heat at Thermal, Shift at the Reactor as you cross each Boundary, and record the Column at the Bore Station. "Down" follows the vessel's real acceleration and everything you know comes from the Stations, the Bore and the sound of the vessel; F3 toggles a developer overlay. `.` speeds time up and any Station call drops it back. Surfacing sells the survey; Enter starts another dive.

## Run the tests

Set `GODOT_BIN` to the Godot binary (on Windows, the `_console.exe` build so output reaches the terminal), then run the suite headless. It exits non-zero on any failure.

Windows (cmd or PowerShell):

```bat
set GODOT_BIN=C:\path\to\Godot_v4.7.2-stable_win64_console.exe
test.cmd
```

macOS / Linux / Git Bash:

```sh
GODOT_BIN=/path/to/godot ./test.sh
```

Extra arguments are passed to the GdUnit4 runner. Reports are written to `reports/` (ignored by git).
