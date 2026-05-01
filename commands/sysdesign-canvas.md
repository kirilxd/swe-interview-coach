---
description: Manually start (or restart) the local Excalidraw canvas server and open it in your browser. Rarely needed — the coaching commands boot it automatically. Use this to reopen a closed tab or recover a stopped server.
argument-hint:
---

You are running `/sysdesign-canvas`. This is a maintenance command: it (re)starts the canvas server and opens the tab. It does NOT start any coaching.

## When to reach for this

The coaching commands (`/sysdesign-explain`, `/practice-sysdesign`, `/mock-sysdesign`) each boot the canvas on their own, so you rarely need this. Use it when:

- you closed the browser tab mid-session and want it back, or
- the server stopped (machine slept, process killed) and a coaching command reported it couldn't reach the canvas.

It only (re)starts the server and reopens the tab — it never resets your scene and never starts an interview.

## Step 1 — Boot

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ensure-canvas.sh"`. The script is idempotent: it starts the server only if it isn't already listening, reuses a running one otherwise, then opens http://localhost:9999 in the browser. The canvas content syncs through `~/.config/swe-interview-coach/canvas.json`.

(The `SWE_INTERVIEW_COACH_CONFIG_DIR`/`SWE_INTERVIEW_COACH_PORT` env vars are test knobs (also usable to relocate the port if 9999 is taken); this command's contract is the default config path `~/.config/swe-interview-coach/canvas.json` and port 9999.)

## Step 2 — Report by parsing the LAST line

Read the script's output and act on its LAST line:

- `READY` → tell the user the canvas is live at http://localhost:9999. The script already opened it; if no tab appeared, ask them to open that URL manually. They can now run `/sysdesign-explain`, `/practice-sysdesign`, or `/mock-sysdesign`.
- Starts with `ERROR:` → print the line verbatim and give the matching remedy:
  - `node not found` → install Node.js from https://nodejs.org/ and retry.
  - `lsof not found` → install `lsof` (required for port detection) and retry.
  - `didn't bind` → another process may be holding port 9999; retry, or set `SWE_INTERVIEW_COACH_PORT` to a free port and retry.
  - `canvas-server.js missing` → the plugin install looks incomplete; reinstall the plugin.
