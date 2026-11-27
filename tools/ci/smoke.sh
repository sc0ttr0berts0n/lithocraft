#!/usr/bin/env bash
# Scene smoke check: runs a scene headless for 120 frames and fails on any error it prints.
# Godot exits 0 after a script or parse error, so the output is read as well as the exit code.
# Usage: tools/ci/smoke.sh [res://scene.tscn]   (no scene: the main scene)
# Needs GODOT_BIN set as for ./test.sh. Exits 0 on a clean run, 1 otherwise.
set -u
cd "$(dirname "$0")/../.."
if [ -z "${GODOT_BIN:-}" ]; then
  echo "Set GODOT_BIN to the Godot 4 binary." >&2
  exit 1
fi
# One import pass so class_name scripts are registered, as test.sh does.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1
output=$("$GODOT_BIN" --headless --path . "$@" --quit-after 120 2>&1)
code=$?
printf '%s\n' "$output"
if [ "$code" -ne 0 ]; then
  echo "Smoke check failed: Godot exited $code." >&2
  exit 1
fi
# "SCRIPT ERROR:", "ERROR:" and "Parse Error:" all fail; a warning (leaked ObjectDB) does not.
if printf '%s\n' "$output" | grep -qE 'ERROR|Parse Error'; then
  echo "Smoke check failed: the scene printed an error." >&2
  exit 1
fi
echo "Smoke check passed: ${1:-the main scene}."
