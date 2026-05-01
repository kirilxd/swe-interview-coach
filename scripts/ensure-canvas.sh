#!/usr/bin/env bash
# Ensure the sysdesign canvas is running and (optionally) open in the browser.
# Idempotent. Output contract (last line): READY | ERROR: <details>
set +e

CONFIG_DIR="${SWE_INTERVIEW_COACH_CONFIG_DIR:-$HOME/.config/swe-interview-coach}"
CANVAS_JSON="$CONFIG_DIR/canvas.json"
# Locate canvas-server.js relative to THIS script — do not rely on CLAUDE_PLUGIN_ROOT
# being exported into the shell env (Claude Code substitutes it into command text,
# not into spawned-process environments).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_JS="$SCRIPT_DIR/canvas-server.js"
PORT="${SWE_INTERVIEW_COACH_PORT:-9999}"
URL="http://localhost:${PORT}"
LOG="/tmp/swe-interview-coach-canvas.log"

mkdir -p "$CONFIG_DIR"
[ -s "$CANVAS_JSON" ] || printf '{"elements":[],"appState":{}}' > "$CANVAS_JSON"

command -v node >/dev/null 2>&1 || { echo "ERROR: node not found on PATH. Install Node.js from https://nodejs.org/ and retry."; exit 1; }
command -v lsof >/dev/null 2>&1 || { echo "ERROR: lsof not found on PATH (required for port detection). Install lsof and retry."; exit 1; }
[ -f "$SERVER_JS" ] || { echo "ERROR: canvas-server.js missing at $SERVER_JS (plugin install incomplete?)"; exit 1; }

is_listening() { command -v lsof >/dev/null 2>&1 && lsof -i ":$PORT" -sTCP:LISTEN >/dev/null 2>&1; }

if ! is_listening; then
  echo "--- boot $(date) pid $$ ---" >> "$LOG"
  nohup node "$SERVER_JS" >> "$LOG" 2>&1 &
  disown 2>/dev/null || true
  sleep 1
  is_listening || sleep 1
  is_listening || { echo "ERROR: canvas server didn't bind to :$PORT (in use by another process, or crashed — see $LOG; override port with SWE_INTERVIEW_COACH_PORT)"; exit 1; }
fi

if [ "${1:-}" != "--no-browser" ]; then
  if command -v open >/dev/null 2>&1; then (open "$URL" >/dev/null 2>&1 &)
  elif command -v xdg-open >/dev/null 2>&1; then (xdg-open "$URL" >/dev/null 2>&1 &)
  fi
fi

echo "READY"
