# Lithocraft

A hard-science-fiction Godot 4 game about operating the Lithocraft, a ring-shaped vessel that bores through rock. See `CLAUDE.md`, `GLOSSARY.md` and GitHub issue #1 for the design.

Built with Godot 4.7 (standard, not .NET).

## Layout

- `sim/`: the simulation. Plain GDScript classes (`RefCounted`) with no scene nodes, rendering or input. Commands in, `advance(dt)`, state out.
- `view/`: scenes that read the simulation and send it commands. `view/habitat.tscn` is the main scene: it owns the simulation and shows the Habitat in first person, with the `view/dive_view.tscn` power panel as an overlay.
- `test/`: GdUnit4 test suites. They test only through the simulation's interface.
- `addons/gdUnit4/`: vendored GdUnit4 v6.2.3.

## Run the game

Open the folder in the Godot 4.7 editor and press F5, or from a shell:

```sh
<godot-binary> --path .
```

Click to look around with the mouse (Esc lets it go) and walk with WASD. Up and Down arrows (or the slider) set Drive power; depth rises while power is above zero. The dive passes sand, then sandstone, then granite. Asking for more power than the Medium's grip allows shows a red SLIP readout and plays a grinding noise (placeholder) instead of going faster.

Pitch has a stand-in control until the Drive Station gets its own: 1 dives nose-down, 2 levels out, 3 climbs, Z and X step pitch by 15 degrees. "Down" follows the vessel's felt acceleration, so diving puts you on the Head end cap and level travel on the outer wall; the Stations swing on their gimbals to stay upright.

Until the Habitat's Bore and Bore Station show them, the overlay also has the Column at the right edge, sliding from Head (bottom) to Tail (top) at the vessel's speed and coloured by the Medium's composition, and the Bore Station's survey beside it: one bar per surveyed stretch, its height the stretch's quality.

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
