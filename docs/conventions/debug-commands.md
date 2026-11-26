# Debug commands

**Debug commands.**
The developer's shortcuts for testing a dive by hand live on `DiveSimulation`, in their own section ("Debug commands", after the Station commands), each named `debug_*` and returning a `StringName`, `&""` when it acted or why it could not (the catalogue is the section's header comment; the debug menu shows it, `DebugPanel.REFUSALS`):
`debug_wear_hull(amount)`, `debug_hull_to_brink()`, `debug_wear_head(amount)`, `debug_lose_plasma()`, `debug_strand()`, `debug_refill_store()`, `debug_surface()`, `debug_skip(seconds)`, `debug_self_destruct()`, `debug_shift_due()`, `debug_next_boundary()`, `debug_next_scan_view()`.
They are not crew controls: no Station works them, they ignore attendance and self-destruct's lock on the Stations, and each reaches the state it names at once (not on the next step), going through the simulation's own paths (`_check_stranded()`, `_surface()`, `_rescue()`, `_start_self_destruct()`, `_step()`,
`_follow_the_head()`) so its events and consequences are the real ones: surface now while stranded is the rescue arriving, billed.
Every one starts with the one guard `if _debug_dive_over(): return &"dive_over"`.
A subsystem's state they set goes through its own `debug_*` method (`Heat.debug_set_wear()`, `Plasma.debug_set_wear()` / `debug_lose()` (through the plasma's own `_lose()`, which raises `&"plasma_lost"`) / `debug_mistune()`, `Stranding.debug_refill()`), never a crew command.
Their sizes are `_DEBUG_*` constants, debug settings, not tuned for play.
Each is tested in `debug_command_test.gd` to reach the state it names.
A new one: a `debug_*` method here with a test, then a key in the debug menu (see Key map).
`debug_next_scan_view()` is the one that sets nothing of the dive: it picks which candidate view Navigation's scan display draws (`scan_view()`), is held by the simulation so a screenshot can send it with `--do`, and has its own key (F4, anywhere) outside the menu, whose numpad is full.
Crew-facing code and tests of the game never call them.
