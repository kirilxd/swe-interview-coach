#!/usr/bin/env bash
# Dispatch a candidate solution to the right per-language adapter and run it
# against a cases file. Locates its adapter relative to THIS script (NOT via
# ${CLAUDE_PLUGIN_ROOT}, which is substituted into command text but is not
# exported into spawned-process environments — same gotcha ensure-canvas.sh notes).
# Usage: run-solution.sh <lang> <solution-file> <cases-file>
# Prints the adapter's JSON result to stdout; exit 0 iff all cases pass.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LANG_ID="${1:-}"; SOLUTION="${2:-}"; CASES="${3:-}"

emit_err() { printf '{"passed":0,"total":0,"cases":[],"harness_error":"%s"}\n' "$1"; }

{ [ -n "$LANG_ID" ] && [ -n "$SOLUTION" ] && [ -n "$CASES" ]; } || {
  emit_err "usage: run-solution.sh <lang> <solution-file> <cases-file>"; exit 2; }
[ -f "$SOLUTION" ] || { emit_err "solution file not found: $SOLUTION"; exit 2; }
[ -f "$CASES" ]    || { emit_err "cases file not found: $CASES"; exit 2; }

case "$LANG_ID" in
  python|python3|py)
    command -v python3 >/dev/null 2>&1 || { emit_err "python3 not found on PATH"; exit 3; }
    exec python3 "$HERE/harness/python_runner.py" "$SOLUTION" "$CASES"
    ;;
  *)
    emit_err "unsupported language: $LANG_ID (v0.3.0 ships python only)"; exit 3
    ;;
esac
