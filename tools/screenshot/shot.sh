#!/usr/bin/env bash
# One screenshot of the game: a Scenario run to a dive time, as a PNG.
#
#   GODOT_BIN=<Godot 4.7 console binary> tools/screenshot/shot.sh \
#       --look <what> --time <seconds> [options]
#   GODOT_BIN=... tools/screenshot/shot.sh --sheet <list file> [--out, --size,
#       --tile, --columns]
#
#   --look <what>        a Station by the name on its screen (Reactor, Drive,
#                        Navigation, Thermal, "Bore Station"), seen seated at
#                        it by the Arm; bore, into the Bore from the outer
#                        wall; column, the Column as the crew see it turning
#                        round from the Bore Station; crew, the crew's own
#                        view where the dive starts them
#   --time <seconds>     the dive time to run to
#   --scenario <title>   the Scenario or drill, by its title (default
#                        "First dive"; first-dive is the same name)
#   --do "<seconds> <command> [arguments]"
#                        send a DiveSimulation command at that dive time;
#                        repeat for more: sent in time order, then as given
#   --out <file.png>     where the PNG goes (default tools/screenshot/out/
#                        <scenario>-<look>-<time>.png, which Godot and git
#                        both ignore)
#   --overlay            keep the screen-space layer the crew sees (the centre
#                        notice); the debug overlay stays hidden either way
#   --checklist          open the Checklist panel (Tab) over the look, with
#                        surface control's messages at its foot, without
#                        reading the orders
#   --size <W>x<H>       the window's and the PNG's size (default 1152x648)
#   --tilt <degrees>     tilt the look up from what it names (down if negative)
#   --turn <degrees>     turn the look to the right (left if negative); with
#                        --tilt, for a look along the Habitat's height
#   --sheet <list file>  take every shot of a list in one run and tile them
#                        into one PNG, each under a label with its name. The
#                        list is plain text, a shot to a line, "<name>: <the
#                        arguments above, without --out, --size or --sheet>";
#                        blank lines and lines starting with # are skipped.
#                        --out defaults to tools/screenshot/out/<list>-sheet.png
#                        and --size is the size every shot is taken at
#   --tile <width>       with --sheet: a tile's width on the sheet in pixels
#                        (default 768; a shot is scaled down to it, never up)
#   --columns <count>    with --sheet: tiles side by side (default 2)
#
# Prints the PNG's path and exits 0; on any failure prints why, leaves no PNG
# at that path and exits 1; a sheet with a shot that fails is no sheet, and the reason names the
# shot. The window opens centred on the developer's second
# monitor (SHOT_MONITOR="<x>,<y>,<width>,<height>" names another); the run is
# given up after SHOT_TIMEOUT seconds (default 300).
# How it works and what it cannot show: docs/conventions/running-and-testing.md.

set -u

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }
fail() { echo "shot.sh: $*" >&2; exit 1; }
slug() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9.' '-' | sed 's/^-//; s/-$//'; }
# A path as the Godot binary reads it (a Windows binary under Git Bash).
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }

root="$(cd "$(dirname "$0")/../.." && pwd)"
scenario="First dive"
look=""
time=""
out=""
sheet=""
size="1152x648"
pass=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --out|--size|--scenario|--look|--time|--do|--tilt|--turn|--sheet|--tile|--columns)
      [ $# -ge 2 ] || fail "$1 needs a value (see --help)"
      case "$1" in
        --out) out="$2" ;;
        --size) size="$2" ;;
        --scenario) scenario="$2"; pass+=("$1" "$2") ;;
        --look) look="$2"; pass+=("$1" "$2") ;;
        --time) time="$2"; pass+=("$1" "$2") ;;
        --sheet) sheet="$2" ;;
        --do|--tilt|--turn|--tile|--columns) pass+=("$1" "$2") ;;
      esac
      shift 2 ;;
    *) pass+=("$1"); shift ;;
  esac
done

[ -n "${GODOT_BIN:-}" ] || fail "set GODOT_BIN to the Godot 4 binary (the console build on Windows)"
[[ "$size" =~ ^([0-9]+)x([0-9]+)$ ]] || fail "--size needs <W>x<H>, got '$size'"
width="${BASH_REMATCH[1]}"
height="${BASH_REMATCH[2]}"
IFS=, read -r monitor_x monitor_y monitor_w monitor_h <<<"${SHOT_MONITOR:-3840,275,2560,1440}"
position="$((monitor_x + (monitor_w - width) / 2)),$((monitor_y + (monitor_h - height) / 2))"

if [ -n "$sheet" ]; then
  [ -f "$sheet" ] || fail "no list of shots at $sheet"
  [ -n "$out" ] || out="$root/tools/screenshot/out/$(slug "$(basename "${sheet%.*}")")-sheet.png"
  pass+=(--sheet "$(native "$(cd "$(dirname "$sheet")" && pwd)/$(basename "$sheet")")")
fi
if [ -z "$out" ]; then
  out="$root/tools/screenshot/out/$(slug "$scenario")-$(slug "$look")-$(slug "$time").png"
fi
case "$out" in /*|[A-Za-z]:*) ;; *) out="$PWD/$out" ;; esac
mkdir -p "$(dirname "$out")" || fail "cannot make the folder for $out"
# The old PNG goes first, so a failed run never leaves one that looks new.
rm -f "$out" || fail "cannot replace $out"
part="${out%.png}.$$.part.png"
log="$(mktemp)"
trap 'rm -f "$part" "$log"' EXIT

# One import pass, so class_name scripts are registered (as test.sh does);
# one at a time in a checkout, since two would write the same cache.
mkdir -p "$root/.godot"
lock="$root/.godot/shot-import.lock"
waited=0
until mkdir "$lock" 2>/dev/null; do
  [ "$waited" -lt 120 ] || { rmdir "$lock" 2>/dev/null; waited=0; }
  sleep 1
  waited=$((waited + 1))
done
"$GODOT_BIN" --headless --path "$(native "$root")" --import >/dev/null 2>&1
rmdir "$lock" 2>/dev/null

# Windowed (headless draws nothing), silent, and at a fixed frame time so the
# same arguments give the same picture.
timeout "${SHOT_TIMEOUT:-300}" "$GODOT_BIN" --path "$(native "$root")" \
    --audio-driver Dummy --fixed-fps 60 --resolution "$size" --position "$position" \
    -s tools/screenshot/shot.gd -- "${pass[@]}" --out "$(native "$part")" >"$log" 2>&1
status=$?

if [ "$status" -ne 0 ] || ! grep -q '^SHOT OK' "$log" || grep -q 'SCRIPT ERROR' "$log" || [ ! -s "$part" ]; then
  grep -v '^Godot Engine\|^$' "$log" >&2
  [ "$status" -ne 124 ] || echo "shot.sh: gave up after ${SHOT_TIMEOUT:-300} s" >&2
  fail "no screenshot (see --help)"
fi
mv -f "$part" "$out" || fail "cannot write $out"
grep '^SHOT OK' "$log" >&2
native "$out"
echo
