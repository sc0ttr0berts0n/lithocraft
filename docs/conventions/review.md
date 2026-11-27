# Review standards

What the reviewer of a ticket carries: the judgement calls no test can make.
The reviewer reads the ticket, the spec it names, the diff and this file.
Rules a test, the lint or `tools/docs/check_docs.py` enforces are not here; a red suite or a failed check is a finding with no rule needed.
Read the topic files in the index `docs/conventions.md` only for the areas the diff touches.

Each rule says what the reviewer does, then what counts as a finding.
A finding names the rule, the file and line, and what would clear it.
The review is clean when no finding stands.

## A rule's test must die when the rule is inverted

- Do: list each relationship the diff adds or changes ("the Band narrows with wear", "faster in sand than granite").
  For each, name the test that fails if the relationship is reversed or removed.
  When reading the test does not settle it, invert the rule in the code, run that one suite, and put the code back.
- Finding: a relationship with no such test, or a test that still passes with the rule inverted.
- Why: ticket #60's "the Band narrows with wear" passed with the rule broken until it was inverted by hand.

## A query a screen polls states its cost

- Do: find every simulation query the diff adds, or newly calls, from a view's per-frame or per-step code.
  Read its doc comment for a bound on the work per call, then read the body against that bound.
- Finding: no stated bound; a body that does more than the bound says; or a bound that grows with something the crew controls (pulses sent, dive time, distance bored, the time rate).
- Not a finding: a bound that grows with something fixed for the dive, such as the number of Stations or of Boundaries in the layout.

## A choice that contradicts the spec is a finding, even when recorded

- Do: read every entry the diff adds to the design record, and every choice the ticket's report names, against the ticket and the spec.
- Finding: a choice that goes against what the spec says, however well reasoned and wherever it is written down.
  The record makes a choice visible; only the developer can change the spec.
  Say which sentence of the spec it contradicts, so the developer can rule on it.
- Not a finding: a choice the spec leaves open, recorded with its reason as an agent's choice.
- Why: ticket #61 asked the layout whether an Inferred Boundary was near a real one, against the spec's rule that the scan can mislead, and recorded it as a decision.

## A criterion that cannot be tested is reported, not ticked

- Do: for each acceptance criterion ticked in the ticket, find what shows it: a test, a regenerated screenshot, or a line of the diff.
- Finding: a ticked criterion shown by nothing, or shown only by the implementer's word (how a thing feels, sounds or reads to the crew).
  Such a criterion is unticked and listed in the report as needing the developer's eyes or a play test.
- Finding: a criterion ticked because a weaker thing than it asks for was tested.

## A ticket's report is not evidence

- Do: treat every claim in the implementer's report as a pointer to where to look, never as the thing seen.
  Check each against the diff; for anything the crew see, regenerate the screenshot with `tools/screenshot/shot.sh` and look at it.
  Run the suite yourself once, at the end, rather than trusting a pasted count.
- Finding: a claim the diff or the screenshot does not bear out, including one that is true of an earlier commit of the branch but not of its head.
- Finding: a change in the diff the report does not mention and the ticket did not ask for.

## A screen the diff touches is regenerated and read

- Do: for every Station screen or view the diff touches (its script in `view/`, or a simulation query it shows), regenerate its recipe's sheet, `tools/screenshot/shot.sh --sheet tools/screenshot/recipes/<screen>.txt` (`running-and-testing.md`, "Ad-hoc checks"), and read it once, at the default size.
  A change to what every screen shares (`StationScreen`, `StationTheme`, the key list) is read on `stations.txt`.
  Check each tile against its name and the comment over it in the recipe, and against the ticket.
- Finding: a tile that does not show the state its name says, or shows something the ticket or the spec rules out (text cut off or overlapping, a colour outside the colour language).
- Finding: a diff that adds a state to a screen, or a new screen, with no tile for it in a recipe; or one that makes a recipe's tile stale and leaves it.
- Finding: a sheet's PNG committed, or anywhere Godot imports it.
- Why: nine of round 3's tickets had "checked in screenshots" criteria; the pictures lived in a temporary folder the reviewer could not see, and are gone (ticket #88).
