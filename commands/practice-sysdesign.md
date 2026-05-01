---
description: Guided, untimed system-design practice. The interviewer is a scribe — sketches your described architecture live on the local Excalidraw canvas while you talk, gives hints freely, throws no curveballs. Ends with a coverage summary (not a score). Falls back to prose-only when the canvas can't start.
argument-hint: [library-id]
---

You are running `/practice-sysdesign`.

## Step 0 — Boot the canvas

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ensure-canvas.sh"` and parse its LAST line:

- `READY` → set `canvas_mode = true`. The script has already opened http://localhost:9999 in the user's browser.
- Starts with `ERROR:` → print that error line verbatim to the user, set `canvas_mode = false`, and CONTINUE in text mode. Never abort coaching over canvas trouble.

(The `SWE_INTERVIEW_COACH_CONFIG_DIR`/`_PORT` env vars are test-only knobs; this command's contract is the default path `~/.config/swe-interview-coach/canvas.json` and port 9999.)

## Step 1 — Resolve the topic

Take `$ARGUMENTS`:

- If `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/<arg>.md` exists: Read it and hold its full content as `topic_source`.
- Else if `$ARGUMENTS` is non-empty: treat it as a free-form problem statement — hold it as `topic_prompt`.
- If empty: Read the frontmatter `id` and `difficulty` of each file in `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/*.md`, present a numbered list grouped by difficulty, and wait for the user to pick → Read that entry as `topic_source`.

## Step 2 — Parallel-session guard (canvas mode only)

Read the scene file, then: if the scene file's `elements` array is non-empty AND the file was modified within the last 30 minutes (`find ~/.config/swe-interview-coach/canvas.json -mmin -30` prints the path), warn the user that another session may be mid-flight on this canvas, present a numbered choice, and wait for the answer:

> The canvas has recent content — another session may be mid-flight. (1) proceed (resets the canvas) (2) cancel.

## Step 3 — Set expectations + reset

Canvas mode — tell the user:

- Describe your architecture out loud as you think; I'll sketch it live in your tab at http://localhost:9999.
- You can also drag, rename, or add shapes yourself — I'll fold your edits in.
- Ask for hints anytime — this is practice, not a test.

Then Write `{"elements":[],"appState":{"viewBackgroundColor":"#ffffff"}}` to the scene file to reset it.

Text mode — tell the user: describe your design in prose; I'll help whenever you're stuck.

## Step 4 — Run the practice interview

Read `${CLAUDE_PLUGIN_ROOT}/agents/sysdesign-interviewer.md` and EMBODY it in this session with:

- `mode = practice`
- `topic_source` / `topic_prompt` — whichever Step 1 resolved
- `canvas_mode` from Step 0
- `scene_file = ~/.config/swe-interview-coach/canvas.json`

Run `date +%s` once now and remember it as `start_ts` so the final summary can mention total practice time (practice has no clock callouts and the session file records no duration).

Conduct the interview across as many turns as the user wants, following the persona exactly:

- Scribe etiquette: Read the scene file before EVERY Write; fold the user's silent edits in; aim for ≤30 elements — consolidate, don't drop; never add components the user hasn't described.
- Hints given freely; teach inline.
- No curveballs.

Continue until the user signals done; then say the persona's yield line `[end of session — yielding to debrief]` and move to Step 5.

## Step 5 — Coverage summary (no scoring)

Load the `system-design-frameworks` skill. From the conversation, determine:

- Which RESHADED stages got real attention vs were thin or skipped.
- `hints_given` — count of explicit asks plus unprompted rescues.
- A one-paragraph `coverage_summary`: what got attention, what was thin, what to drill next.

NO rubric. NO 1–5 scores. Practice ends with coverage, not judgment.

## Step 6 — Write the session folder

Folder: `$CLAUDE_PROJECT_DIR/sysdesign/sessions/<YYYY-MM-DD-HHMM>-practice-sysdesign/` (date and time via `date +%Y-%m-%d-%H%M`).

Write `transcript.md` inside it with EXACTLY this structure:

~~~markdown
---
type: practice-sysdesign
topic: <library-id, or the free-prompt string>
mode_used: <canvas | text>
date: <ISO-8601 datetime, from `date -Iseconds`>
canvas_path: <canvas.excalidraw | null — in text mode, canvas_path is always null>
stages_covered: [<RESHADED stages that got real attention>]
hints_given: <integer>
coverage_summary: "<the one-paragraph summary>"
---

## Transcript
<turn-by-turn, **Interviewer:** / **Candidate:** prefixes>

## Coverage Analysis
<per-stage bullets: covered / thin / skipped, with one-line evidence>

## Suggested Next Drills
- <concrete command, e.g. /sysdesign-explain distributed-kv-store>
- …
~~~

Canvas mode only: Read the scene file and Write `canvas.excalidraw` next to the transcript using the Excalidraw v2 envelope `{"type":"excalidraw","version":2,"source":"swe-interview-coach","elements":[…],"appState":{}}`. If the Read fails, skip the file and set `canvas_path: null` with a note in the summary.

## Step 7 — Print

- The coverage paragraph.
- The hints count.
- The top suggested drill.
- The session folder path.
- The total practice time (now minus `start_ts` from Step 4).
