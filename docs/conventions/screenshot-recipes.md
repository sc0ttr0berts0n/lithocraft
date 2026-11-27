# Screenshot recipes

- The evidence for a screen is its recipe, a list for the screenshot tool's sheet mode (`running-and-testing.md`, "Ad-hoc checks") kept in `tools/screenshot/recipes/`, one per Station screen and per view a ticket checked by eye:
  `reactor.txt`, `thermal.txt`, `drive.txt`, `navigation.txt`, `stations.txt` (every Station from the Arm's hold), `habitat.txt` (the room, the ring at each end and mid-slide, and hull sparks), `column.txt` (features in the Column) and `checklist.txt` (the Checklist panel).
- `--checklist` opens the Checklist panel over any look, surface control's messages at its foot, without reading the orders; the panel is the only overlay the crew uses, so it is the one a shot shows.
- From the repo root, `tools/screenshot/shot.sh --sheet tools/screenshot/recipes/reactor.txt` makes its sheet, `tools/screenshot/out/reactor-sheet.png`.
  Each takes under a minute; the folder is ignored by git and by Godot, and no sheet is ever committed.
- A ticket that changes a screen or a view adds the states it makes to that recipe, or corrects the tiles it changes, and a new screen gets a new recipe.
  The reviewer regenerates the sheet and reads it (`review.md`).
- A tile's name says the state it shows, and a comment line over it says what to look for and how the state is reached.
- Stage a state with crew and Scenario start commands, and check it headless before the sheet is read (`ShotPlan.stage()` on a Habitat, then the simulation's queries): an image read costs far more than a query.
  A `debug_*` command only where the state is otherwise far away, named in the recipe's header.
- A state on the First dive's layout is reached at once with `start_below`: a feature of interest is at the seated crew's eye height with the Head 4.7 m past it.
- `shot_recipes_test.gd` fails a recipe that no longer makes a sheet (a renamed command, Station or Scenario); what a tile shows is the reader's to check.
