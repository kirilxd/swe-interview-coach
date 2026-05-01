---
description: Untimed guided coding practice: you write code in a seeded solution file in your own editor; a warm interviewer hints via a ladder, runs your code, and teaches inline. Summarized, not scored.
argument-hint: [library-id | "free prompt"]
---

You are running `/practice-coding`.

## Step 1 — Resolve the topic

Take `$ARGUMENTS` and resolve it to exactly one of `topic_source` / `topic_prompt`:

- If `${CLAUDE_PLUGIN_ROOT}/library/coding/<arg>.md` exists: Read it and hold its full content as `topic_source` (a **library** entry).
- Else if `$CLAUDE_PROJECT_DIR/coding/imported/<arg>.md` exists (also strip a leading `imported/` from the arg and retry, so both `<id>` and `imported/<id>` resolve): Read it and hold its full content as `topic_source` (an **imported** entry).
- Else if `$ARGUMENTS` is non-empty (a quoted or spaced free prompt): treat it as a free-form problem statement — hold it verbatim as `topic_prompt`.
- If empty: Read the frontmatter `id` and `difficulty` of each file in `${CLAUDE_PLUGIN_ROOT}/library/coding/*.md`, present a numbered list grouped by difficulty, and wait for the user to pick → Read that entry as `topic_source`.

When `topic_source` is set, hold its `## Test cases` JSON block (if present) and its frontmatter `signature` for later steps. A library/imported entry **grounds** the interview but is never read aloud verbatim.

## Step 2 — Compute the session folder + seed the scratch file

Compute the session folder up front: `$CLAUDE_PROJECT_DIR/coding/sessions/<YYYY-MM-DD-HHMM>-practice-coding/` where `<YYYY-MM-DD-HHMM>` comes from `date +%Y-%m-%d-%H%M`. Hold it as `session_folder`. Hold `solution_file = <session_folder>/solution.py`.

Write `solution.py` into the session folder, seeded as follows (Writing with the full absolute path creates intermediate dirs automatically — no mkdir needed):

- `topic_source` **with** a `## Starter stub` python block → write that block's body **verbatim**.
- `topic_source` **without** a starter stub → synthesize from the frontmatter `signature`:
  ```python
  from typing import List   # include only if a param/return type references List/Dict/Optional/etc.

  def <signature.name>(<param-name>: <param-type>, …) -> <signature.returns>:
      # your code here
      pass
  ```
- `topic_prompt` (free-form, no signature) → a generic stub:
  ```python
  def solve(*args):
      # your code here
      pass
  ```

Then tell the user the **absolute path** to `solution_file` and that they should open it in their own editor — they write the code there; you read it, hint, and run it.

## Step 3 — Detect the runtime

Run `command -v python3`:

- present → set `run_mode = run`.
- absent → set `run_mode = review-only`; warn the user plainly that you can't execute their code here so you'll reason it through by inspection, and CONTINUE. Never abort over a missing runtime.

## Step 4 — Run the practice interview

Read `${CLAUDE_PLUGIN_ROOT}/agents/coding-interviewer.md` and EMBODY it in this session (it is NOT spawned via the Task tool — it needs Bash + Read in this main context) with these Inputs:

- `mode = practice`
- `topic_source` / `topic_prompt` — whichever Step 1 resolved
- `solution_file` — the absolute path from Step 2
- `lang = python`
- `run_mode` from Step 3
- `RUN_SOLUTION = ${CLAUDE_PLUGIN_ROOT}/scripts/run-solution.sh`

Run `date +%s` once now and remember it as `start_ts` so the final summary can mention total practice time (practice has no clock callouts and the session file records no duration).

Conduct the interview following the persona's **practice** rules exactly:

- Warm, helpful tone; untimed; no clock talk; no curveballs.
- Hints flow through the entry's `## Hint ladder` (when `topic_source` has one), one rung at a time; teach inline.
- Read `solution_file` at natural moments to see what the candidate has written; never write to it — they own it.
- `run_mode=run`: run their code whenever useful via `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run-solution.sh" python <solution_file> <cases.json>` (write the entry's `## Test cases` JSON to a temp `cases.json` via `mktemp -d`), and walk through what failures reveal — this is teaching.
- `run_mode=review-only`: trace inputs by hand instead of running.

Continue across as many turns as the user wants. When the user signals done, emit the persona's yield line `[end of session — yielding to coach]` yourself and move to Step 5.

## Step 5 — Coverage summary (no scoring)

Load the `coding-frameworks` skill. From the conversation, determine — NO rubric, NO 1–5 scores:

- `umpire_phases_covered` — which of Understand, Match, Plan, Implement, Review, Evaluate got real attention vs were thin or skipped.
- `hints_given` — integer count of explicit asks plus unprompted rescues / ladder rungs walked.
- final harness pass/fail if you ran the code at all (the last `{passed, total}` you observed), else null.
- A one-paragraph `coverage_summary`: what got attention, what was thin, what to drill next.
- Suggested next drills as concrete commands (e.g. `/coding-drill <pattern>`, `/coding-explain <id>`, `/mock-coding <id>`).

## Step 6 — Write the session folder

Write `<session_folder>/transcript.md` with EXACTLY this structure (`solution.py` is already in the folder from Step 2):

~~~markdown
---
type: practice-coding
topic: <library-id, imported-id, or the free-prompt string>
lang: python
run_mode: <run | review-only>
date: <ISO-8601 datetime, from `date -Iseconds`>
solution_path: <absolute path to solution.py>
umpire_phases_covered: [<phases that got real attention>]
hints_given: <integer>
harness: <{passed: <int>, total: <int>} | null>
coverage_summary: "<the one-paragraph summary>"
---

## Transcript
<turn-by-turn, **Interviewer:** / **Candidate:** prefixes>

## Coverage Analysis
<per-UMPIRE-phase bullets: covered / thin / skipped, with one-line evidence>

## Suggested Next Drills
- <concrete command, e.g. /coding-drill sliding-window>
- …
~~~

## Step 7 — Print

- The coverage paragraph.
- The `hints_given` count.
- The harness pass/fail result if you ran the code (else note that nothing was executed).
- The single top suggested drill.
- The session folder path.
