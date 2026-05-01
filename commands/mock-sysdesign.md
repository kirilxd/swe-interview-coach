---
description: Graded 45-minute system-design mock interview. You draw your architecture on the local Excalidraw canvas while a realistic interviewer probes what you draw, calls time, and throws one curveball; afterward it scores a 6-axis rubric, writes coach notes, and annotates your diagram with critique. Falls back to prose when the canvas can't start.
argument-hint: [library-id or "free prompt in quotes"]
---

You are running `/mock-sysdesign`.

## Step 0 — Boot the canvas

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ensure-canvas.sh"` and parse its LAST line:

- `READY` → set `canvas_mode = true`. The script has already opened http://localhost:9999 in the user's browser.
- Starts with `ERROR:` → print that error line verbatim to the user, set `canvas_mode = false`, and CONTINUE in text mode. Never abort coaching over canvas trouble.

(The `SWE_INTERVIEW_COACH_CONFIG_DIR`/`_PORT` env vars are test-only knobs; this command's contract is the default path `~/.config/swe-interview-coach/canvas.json` and port 9999.)

## Step 1 — Resolve the topic

Take `$ARGUMENTS`:

- If `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/<arg>.md` exists: Read it and hold its full content as `topic_source`.
- Else if `$ARGUMENTS` is non-empty (a quoted or spaced free prompt): treat it as a free-form problem statement — hold it as `topic_prompt`.
- If empty: Read the frontmatter `id` and `difficulty` of each file in `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/*.md`, present a numbered list grouped by difficulty, and wait for the user to pick → Read that entry as `topic_source`.

## Step 2 — Parallel-session guard (canvas mode only)

Read the scene file, then: if the scene file's `elements` array is non-empty AND the file was modified within the last 30 minutes (`find ~/.config/swe-interview-coach/canvas.json -mmin -30` prints the path), warn the user that another session may be mid-flight on this canvas, present a numbered choice, and wait for the answer:

> The canvas has recent content — another session may be mid-flight. (1) proceed (resets the canvas) (2) cancel.

## Step 3 — Set expectations + reset

Canvas mode — tell the user:

- This is a timed 45-minute mock interview, scored at the end.
- YOU draw your architecture in your open tab at http://localhost:9999, exactly as you'd whiteboard it.
- The interviewer watches what you draw and probes it, but will NOT draw on your canvas during the interview.
- It will call time as the clock runs and throw ONE curveball around the 30-minute mark.

Then Write `{"elements":[],"appState":{"viewBackgroundColor":"#ffffff"}}` to the scene file to reset it.

Text mode — tell the user: describe your architecture in prose; you'll get the same probing, just no canvas.

## Step 4 — Run the mock interview

Read `${CLAUDE_PLUGIN_ROOT}/agents/sysdesign-interviewer.md` and EMBODY it in this session with:

- `mode = mock`
- `topic_source` / `topic_prompt` — whichever Step 1 resolved
- `canvas_mode` from Step 0
- `scene_file = ~/.config/swe-interview-coach/canvas.json`

Run `date +%s` once now and remember it as `start_ts`.

Conduct the interview following the persona's mock rules exactly:

- Neutral, probing tone; refuse hints ("what do you think?"); never teach mid-mock.
- Observe-only canvas etiquette: Read `scene_file` at probing moments to see what the candidate drew, and never Write to `scene_file` during the interview — the interviewer won't draw on your canvas; annotations happen post-session, in Step 6.
- Deliver the two time callouts and the one curveball at the persona's specified elapsed marks (check `date +%s` before each turn against `start_ts`) — don't restate the timing here; the persona's Time tracking section is authoritative.

End at 45 minutes — or earlier if the user signals done — then say the persona's yield line `[end of session — yielding to debrief]` and proceed to Step 5.

## Step 5 — Coach post-process (rubric)

Load the `system-design-frameworks` skill. Capture the final architecture: canvas mode → Read `scene_file` (it holds everything the candidate drew); text mode → use their prose.

Score each axis on an integer 1–5 scale with a one-line justification:

- `requirements_clarity` — did they pin functional + non-functional requirements before designing?
- `estimation_quality` — were back-of-envelope numbers present, concrete, and reasonable?
- `architecture_soundness` — does the high-level design actually solve the problem at the stated scale?
- `tradeoff_articulation` — did they name and justify tradeoffs (not just assert)?
- `depth_under_pressure` — when probed/curveballed, did they go deeper or fold?
- `verbal_communication` — was the explanation structured and clear?

Compute `overall` = arithmetic mean of the six, rounded to 2 decimals.

Then write coach notes:

- 2–4 **Strengths** — specific; quote what they said or drew.
- 2–4 **Improvements** — specific, each paired with the fix.
- **Suggested drills** — concrete commands, e.g. `/practice-sysdesign <related-id>`, `/sysdesign-explain <building-block>`.

## Step 6 — Annotate the canvas (canvas mode only)

Compute the session folder path now (see Step 7). Then, in order:

1. **Preserve the un-annotated diagram.** Read `scene_file` and Write `<session-folder>/canvas.excalidraw` with the v2 envelope `{"type":"excalidraw","version":2,"source":"swe-interview-coach","elements":[…],"appState":{}}`. The interview has ended, so the board should be quiescent; the clean `canvas.excalidraw` saved here is the candidate's true final state. (If a late edit lands during annotation, only the live annotated view could miss it — the clean copy already captured their work.)
2. **Annotate the LIVE canvas** so the user watches the critique appear: build a new scene = the candidate's existing elements PLUS short red text-element callouts placed near the relevant components (`← SPOF`, `← no cache here`, `← unbounded queue`, `← add replication`). Write the merged scene to the live `scene_file` as `{"elements":[…],"appState":{"viewBackgroundColor":"#ffffff"}}`. Use the persona's "Element JSON reference" for the text-element shape; give annotations stable ids like `note-spof`; set `strokeColor: "#e03131"` (red) so they read as distinct from the candidate's work.
3. **Preserve the annotated diagram.** Read the live `scene_file` again and Write `<session-folder>/canvas-annotated.excalidraw` with the same v2 envelope.

If ANY of these canvas ops fail, warn the user, skip the rest of the annotation, and continue to Step 7 — never fail the whole command over annotation. Record `annotated_canvas_path: null` if step 2 or 3 did not complete. Set `canvas_path` from the clean copy regardless of annotation success; only `annotated_canvas_path` depends on the annotation steps.

## Step 7 — Write the session folder

Folder: `$CLAUDE_PROJECT_DIR/sysdesign/sessions/<YYYY-MM-DD-HHMM>-mock-sysdesign/` (date and time via `date +%Y-%m-%d-%H%M`).

Write `transcript.md` inside it with EXACTLY this structure:

~~~markdown
---
type: mock-sysdesign
topic: <library-id, or the free-prompt string>
mode_used: <canvas | text>
date: <ISO-8601 datetime, from `date -Iseconds`>
duration_minutes: <integer, (now - start_ts)/60>
canvas_path: <canvas.excalidraw | null — null in text mode>
annotated_canvas_path: <canvas-annotated.excalidraw | null — null in text mode or if annotation failed>
rubric_scores:
  requirements_clarity: <1-5>
  estimation_quality: <1-5>
  architecture_soundness: <1-5>
  tradeoff_articulation: <1-5>
  depth_under_pressure: <1-5>
  verbal_communication: <1-5>
overall: <mean to 2 decimals>
stages_covered: [<RESHADED stages that got real attention>]
stages_skipped: [<RESHADED stages not reached>]
---

## Transcript
<turn-by-turn, **Interviewer:** / **Candidate:** prefixes>

## Coach Notes
- **Strengths:** …
- **Improvements:** …
- **Suggested drills:** …
~~~

## Step 8 — Print

- The 6 rubric scores and the `overall`.
- The top 1–2 strengths and the top 1–2 improvements.
- The single top suggested drill.
- The session folder path.
