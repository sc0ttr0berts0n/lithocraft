#!/usr/bin/env bash
# Runs the GdUnit4 suite headless: every suite, or only the ones named.
#   ./test.sh                      every suite under test/
#   ./test.sh heat scan_test       only test/heat_test.gd and test/scan_test.gd
#   ./test.sh --verbose [suite...] GdUnit's full coloured output, as it comes
# Prints each failing test's report, then one plain summary line.
# The full output of the last quiet run is kept in reports/last_run.log.
# Exits with GdUnit's code: 0 pass, 100 test failure, 101 orphan nodes, 105 script error.
# Needs GODOT_BIN set to a Godot 4 binary (the console build on Windows).
set -u
cd "$(dirname "$0")"

usage() {
  sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
}

verbose=0
targets=()
for arg in "$@"; do
  case "$arg" in
    --verbose | -v) verbose=1 ;;
    --help | -h)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $arg" >&2
      usage >&2
      exit 1
      ;;
    *)
      # A suite by its name, with or without _test, .gd, test/ or res://.
      name="${arg#res://}"
      name="${name#test/}"
      name="${name%.gd}"
      if [ -f "test/$name.gd" ]; then
        targets+=(-a "res://test/$name.gd")
      elif [ -f "test/${name}_test.gd" ]; then
        targets+=(-a "res://test/${name}_test.gd")
      elif [ -d "test/$name" ]; then
        targets+=(-a "res://test/$name")
      else
        echo "No suite '$arg': looked for test/$name.gd and test/${name}_test.gd." >&2
        exit 1
      fi
      ;;
  esac
done
if [ ${#targets[@]} -eq 0 ]; then
  targets=(-a res://test)
fi

if [ -z "${GODOT_BIN:-}" ]; then
  echo "Set GODOT_BIN to the Godot 4 binary." >&2
  exit 1
fi
# One import pass so class_name scripts are registered before the runner starts.
"$GODOT_BIN" --headless --path . --import >/dev/null 2>&1

run() {
  bash ./addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode "${targets[@]}"
}

if [ "$verbose" -eq 1 ]; then
  run
  exit $?
fi

log=reports/last_run.log
mkdir -p reports
run >"$log" 2>&1
code=$?

# GdUnit colours every line; strip the colour codes and carriage returns, then
# keep only the reports of what failed and the totals.
esc=$(printf '\033')
sed -e "s/$esc\[[0-9;]*[A-Za-z]//g" -e 's/\r$//' "$log" | awk -v code="$code" -v log_path="$log" '
  function trimmed(text) {
    sub(/^[ \t]+/, "", text)
    return text
  }
  # The end of a report: the next test, the suite totals, the next suite.
  / > .* STARTED$/ || /^Statistics:/ || /^Run Test Suite:/ || /^Overall Summary:/ {
    reporting = 0
  }
  / > .* FAILED/ {
    line = trimmed($0)
    sub(/ FAILED.*$/, "", line)
    print "FAILED " line
    reporting = 1
    shown = 1
    next
  }
  # A report with no failed test above it: a suite hook, a warning, orphan nodes.
  /^[ \t]*Report:$/ {
    if (!reporting) {
      line = trimmed(previous)
      sub(/ (PASSED|SKIPPED|WARNING|FLAKY).*$/, "", line)
      print "REPORT " line
      reporting = 1
      shown = 1
    }
    next
  }
  reporting && !/^[ \t]*$/ {
    print "  " trimmed($0)
  }
  # Engine and script errors, with the line that says where; shown if no totals come.
  # (Not the two about the remote debugger, which GdUnit turns off on purpose.)
  /^(SCRIPT )?ERROR:/ && !/emote (port|Debugger)/ {
    errors = errors $0 "\n"
    where = 1
    previous = $0
    next
  }
  where {
    errors = errors $0 "\n"
    where = 0
  }
  /^Overall Summary:/ {
    totals = $0
    sub(/^Overall Summary:[ \t]*/, "", totals)
    sub(/[ \t]*\|[ \t]*$/, "", totals)
    gsub(/[ \t]*\|[ \t]*/, ", ", totals)
  }
  /^Executed test suites:/ {
    suites = $0
    sub(/^.*\(/, "", suites)
    sub(/\/.*$/, "", suites)
  }
  /^Total execution time:/ {
    took = $0
    sub(/^Total execution time:[ \t]*/, "", took)
  }
  { previous = $0 }
  END {
    state = (code == 0) ? "PASSED" : "FAILED"
    if (totals == "") {
      printf "%s", errors
      totals = "no totals from GdUnit"
    } else {
      totals = totals ", " suites " suites, " took
    }
    if (code != 0) {
      print "Full output: " log_path
    }
    print state ": " totals " (exit " code ")"
  }
'
exit "$code"
