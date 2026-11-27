#!/usr/bin/env bash
# The cost budget: plays the Shift drill headless with every Station's screen
# live, through the conditions that have been slow, and times a simulation
# step, a frame of every screen's update and every simulation query.
#
#   GODOT_BIN=<Godot 4.7 console binary> tools/cost/cost.sh [--seconds <n>]
#
#   --seconds <n>   dive time each condition is played for (default 4)
#
# Prints the cost by condition, by Station and its parts, and by query, names
# the slowest Station and the slowest query, and ends with "COST OK" (exit 0)
# or "COST OVER BUDGET" (exit 1). Also exits 1, saying why, if the measurement
# could not be made. The budget is a ratio to a baseline timed in the same
# run (tools/cost/cost_budget.gd), so the same command serves a developer's PC
# and a CI runner. The run is given up after COST_TIMEOUT seconds (default 180).
# What it measures: docs/conventions/cost-budget.md.

set -u

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }
fail() { echo "cost.sh: $*" >&2; exit 1; }
# A path as the Godot binary reads it (a Windows binary under Git Bash).
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ -n "${GODOT_BIN:-}" ] || fail "set GODOT_BIN to the Godot 4 binary (the console build on Windows)"
root="$(cd "$(dirname "$0")/../.." && pwd)"
log="$(mktemp)"
trap 'rm -f "$log"' EXIT

# One import pass, so class_name scripts are registered (as test.sh does).
"$GODOT_BIN" --headless --path "$(native "$root")" --import >/dev/null 2>&1

timeout "${COST_TIMEOUT:-180}" "$GODOT_BIN" --headless --path "$(native "$root")" \
    -s tools/cost/cost.gd -- "$@" 2>&1 | tee "$log" | grep -v '^Godot Engine'
status="${PIPESTATUS[0]}"

[ "$status" -ne 124 ] || fail "gave up after ${COST_TIMEOUT:-180} s"
if grep -q 'SCRIPT ERROR' "$log"; then fail "a script error: no measurement"; fi
if [ "$status" -eq 0 ] && ! grep -q '^COST OK' "$log"; then fail "no verdict: no measurement"; fi
exit "$status"
