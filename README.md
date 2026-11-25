# Lithocraft

A hard-science-fiction Godot 4 game about operating the Lithocraft, a ring-shaped vessel that bores through rock. See `CLAUDE.md`, `GLOSSARY.md` and GitHub issue #1 for the design.

Built with Godot 4.7 (standard, not .NET).

## Layout

- `sim/`: the simulation. Plain GDScript classes (`RefCounted`) with no scene nodes, rendering or input. Commands in, `advance(dt)`, state out.
- `view/`: scenes that read the simulation and send it commands. `view/dive_view.tscn` is the main scene.
- `test/`: GdUnit4 test suites. They test only through the simulation's interface.
- `addons/gdUnit4/`: vendored GdUnit4 v6.2.3.

## Run the game

Open the folder in the Godot 4.7 editor and press F5, or from a shell:

```sh
<godot-binary> --path .
```

Up and Down arrows (or the slider) set Drive power; depth rises while power is above zero. The dive passes sand, then sandstone, then granite. Asking for more power than the Medium's grip allows shows a red SLIP readout and plays a grinding noise (placeholder) instead of going faster.

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
