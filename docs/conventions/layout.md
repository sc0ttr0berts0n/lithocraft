# Layout

- `sim/`: the simulation.
  Every class is `RefCounted` with a `class_name`; nothing here touches the scene tree, `Input` or rendering.
  `DiveSimulation` is the one seam; `Medium`, `MediumLayout`, `SurveyStretch`, `ColumnFeature` and `ScanPoint` are data it reads or hands out.
  `Heat`, `Plasma` and `Stranding` are subsystems it owns (see Subsystems).
  `Scenario` is the data of a Scenario and `Checklist` the dive's progress through it (see Scenarios).
- `view/`: scenes and view logic.
  `view/start_menu.tscn` (`StartMenu`) is the main scene; it starts `view/habitat.tscn` with the chosen Scenario.
  `Arm` (`view/arm.gd`), `HullGroans` (`view/hull_groans.gd`), `KeyMap` (`view/key_map.gd`), `PowerLine` (`view/power_line.gd`), `ChecklistPanel` (`view/checklist_panel.gd`; `ChecklistPanel.text_of()` is the Tab panel's text, tested directly), `KeyPrompt` (`view/key_prompt.gd`;
  `KeyPrompt.rect()` builds a screen-space prompt for the F1 controls and the debug menu) `OutcomeScreen` (`view/outcome_screen.gd`), `FlightTape` (`view/flight_tape.gd`, a tape or pitch ladder of the Drive's flight display) and `Pointing` (`view/pointing.gd`, what lies under the centre dot) are view logic as plain `RefCounted`s, tested directly (plain transforms; a seeded RNG;
  plain data).
  A view node can be tested outside the tree when its logic needs no `Input` or physics (`crew_look_test.gd` drives `CrewMember.look()` / `hold()`); a node it makes in `_init` must be its child from then, or the test leaks orphans.
- `assets/`: vendored assets, each folder with a note of its source and licence.
  `assets/prompts/keyboard/` holds the key prompt images (Xelu's CC0 pack, the light keyboard set).
- `test/`: GdUnit4 suites, `*_test.gd`, `extends GdUnitTestSuite`, `func test_...`.
  Shared helpers in `test/support/dive_test_kit.gd`.
- Commit the `*.gd.uid` files Godot generates beside each script.
- Files are LF.
  On Windows, write files from Python with `newline=''`, or they come back CRLF.
