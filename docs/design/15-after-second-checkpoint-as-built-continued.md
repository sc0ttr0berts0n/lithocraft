# After the second checkpoint: as built, continued

Agent's choices within round 3's design (spec #71), one bullet per ticket.
Continues `14-after-second-checkpoint-as-built.md`, which is full.

- **How the Reactor cancels the Wobble (ticket #60, agent's choices within the design).**
  The Wobble's frequency rises with the Medium's hardness, as before; its amplitude rises with the Medium's strength (stronger rock pushes back on the Head harder), so sand, sandstone and granite each differ in both.
  Only that ordering is meant true; the numbers are tuned (ADR 0001).
  The phase lock is played up from a real one: the Counter-wave's phase holds to the Wobble's on average and swings about it at the difference of the two frequencies, wider the further off, a full half turn each way past the lock's range.
  That gives the two looks the design asks for from one sum of two waves: a wrong amplitude alone leaves a steady Residual, a wrong frequency alone leaves beats that slow and shrink as it nears.
  Real basis: two waves of unlike frequency beat at the difference of their frequencies, and a phase-locked loop near the edge of its range slips and recovers.
  Wear is charged on the Residual's distance outside the Band, averaged along the beat, at a fixed rate; nothing is charged at the swap, so a Shift is only ever as good as the Counter-wave swapped in.
  The grinding is live too: the heat and the shudder that a poor Shift used to give in one lump now last exactly as long as the Residual is outside the Band.
  The plasma's steadiness falls only for the Residual outside the Band and for the Head's own wear, so a hot hull shows as a cause (HOT) only while the Band it narrowed is costing something.
  A disruption needs time: a Residual far outside the Band must stay there about four seconds on a badly worn Head before the plasma is lost.
  Without that, a Head worn past half could never cross a Boundary by hand, since no crew swaps in the very instant of the crossing; with it, a prompt swap saves a worn Head and the slow autopilot does not, which is what Stranded in the granite teaches.
  The Reactor's autopilot makes no Shift at all: it tunes ACTIVE toward the Wobble at a slow fixed rate and leaves STANDBY alone, so the First dive's four Boundaries cost it about a tenth of the Head and the crew's prepared swaps cost nothing.
  The Checklist's phase after a Boundary begins once the Residual is inside the Band in the new Medium, however it got there, since the autopilot no longer raises a Shift to begin it.
  A Reactor nobody tends is no longer merely weak: left alone past a Boundary it loses the plasma within minutes, so a dive with nobody at the Reactor engages its autopilot.
  (Before, an untuned plasma only supplied less power for ever, which also kept a full-power hull cool by accident.)
  The Reactor's Caution lamps (HEAD WORN, HOT, OUT OF BAND) sit in its header strip with every other Station's, lit by the causes the simulation names; they are judged with the Residual at its fullest, so a lamp does not blink with the beats.
  The Reactor's screen stays plain until its own ticket (#63): two lanes of three lines over the Band, in the colour language (Wobble white, Counter-wave cyan, Residual white inside the Band and amber outside it, the Band a green strip).
  Stand-in keys at the Reactor: C selects the channel, N / M tune frequency, J / K tune amplitude, R swaps.
  The Reactor's call for a Residual outside the Band is `out_of_band`, and the debug menu's "a Shift due now" became "detune ACTIVE now".
