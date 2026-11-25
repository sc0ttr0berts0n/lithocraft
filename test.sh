#!/usr/bin/env bash
# Runs the whole GdUnit4 suite headless. Exits non-zero on any failure.
# Needs GODOT_BIN set to a Godot 4 binary (the console build on Windows).
set -u
cd "$(dirname "$0")"
if [ -z "${GODOT_BIN:-}" ]; then
  echo "Set GODOT_BIN to the Godot 4 binary." >&2
  exit 1
fi
# One import pass so class_name scripts are registered before the runner starts.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1
bash ./addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode -a res://test "$@"
