---
description: Graded ~40-min coding mock: you write code in a seeded solution file while a neutral interviewer probes your approach and throws one follow-up; afterward it runs your solution against the test cases and scores a 6-axis rubric.
argument-hint: [library-id | "free prompt in quotes"]
---

You are running `/mock-coding`.

## Step 1 — Resolve the topic

Take `$ARGUMENTS` and resolve it to exactly one of `topic_source` / `topic_prompt`:

- If `${CLAUDE_PLUGIN_ROOT}/library/coding/<arg>.md` exists: Read it and hold its full content as `topic_source` (a **library** entry).
- Else if `$CLAUDE_PROJECT_DIR/coding/imported/<arg>.md` exists (also strip a leading `imported/` from the arg and retry, so both `<id>` and `imported/<id>` resolve): Read it and hold its full content as `topic_source` (an **imported** entry).
- Else if `$ARGUMENTS` is non-empty (a quoted free prompt — strip the surrounding quotes): treat it as a free-form problem statement — hold it verbatim as `topic_prompt`.
- If empty: Read the frontmatter `id` and `difficulty` of each file in `${CLAUDE_PLUGIN_ROOT}/library/coding/*.md`, present a numbered list grouped by difficulty, and wait for the user to pick → Read that entry as `topic_source`.

When `topic_source` is set, hold its `## Test cases` JSON block (if present), its `## Follow-ups & variations`, and its frontmatter `patterns` and `signature` for later steps. A library/imported entry **grounds** the interviewer's probes but is never read aloud verbatim.

## Step 2 — Compute the session folder + seed the scratch file

Compute the session folder up front: `$CLAUDE_PROJECT_DIR/coding/sessions/<YYYY-MM-DD-HHMM>-mock-coding/` where `<YYYY-MM-DD-HHMM>` comes from `date +%Y-%m-%d-%H%M`. Hold it as `session_folder`. Hold `solution_file = <session_folder>/solution.py`.

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

Then tell the user the **absolute path** to `solution_file` and set expectations: this is a graded ~40-minute mock; write your code in that file; think aloud as you go; you may ask to run your own tests; expect one follow-up around the 25-minute mark; you'll be scored on a 6-axis rubric at the end.

## Step 3 — Detect the runtime

Run `command -v python3`:

- present → set `run_mode = run`.
- absent → set `run_mode = review-only`; warn the user plainly that you can't execute code here, so grading falls back to inspection — the `correctness` axis will be judged by reading the code and flagged `(not executed)`. CONTINUE; never abort.

## Step 4 — Run the mock interview

Run `date +%s` once now and remember it as `start_ts`.

Read `${CLAUDE_PLUGIN_ROOT}/agents/coding-interviewer.md` and EMBODY it in this session (it is NOT spawned via the Task tool — it needs Bash + Read in this main context) with these Inputs:

- `mode = mock`
- `topic_source` / `topic_prompt` — whichever Step 1 resolved
- `solution_file` — the absolute path from Step 2
- `lang = python`
- `run_mode` from Step 3
- `RUN_SOLUTION = ${CLAUDE_PLUGIN_ROOT}/scripts/run-solution.sh`

Conduct the interview following the persona's **mock** rules exactly:

- Neutral, probing tone; refuse hints ("what's your reasoning?"); never teach mid-mock.
- The two time callouts (~25 min "about 15 left", ~35 min "5-minute warning") and the ONE follow-up (~25 min, from the entry's `## Follow-ups & variations`) live in the persona — check `date +%s` against `start_ts` before each turn; the persona's Time tracking section is authoritative, don't restate the timing here.
- Read `solution_file` to ground probes; never write to it — the candidate owns it.
- Run code ONLY when the candidate asks to test, and report only the raw pass/fail tally (no diagnosis). Grade-running happens in Step 5, not here.

End at ~40 minutes — or earlier if the user signals done — then emit the persona's yield line `[end of session — yielding to coach]` yourself and proceed to Step 5.

## Step 5 — Coach post-process (rubric)

Load the `coding-frameworks` skill, then:

### a. Grade-run the final solution

- **Library/imported entry with a `## Test cases` block:** write that JSON block to a temp `cases.json` (in a `mktemp -d` dir) and run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run-solution.sh" python <solution_file> <cases.json>`. Capture `passed` / `total` from its JSON output, and any `harness_error`. Set `partial_coverage = false`.
- **Free-form `topic_prompt` / no `## Test cases`:** write a small ad-hoc driver (a few representative inputs + expected outputs you derive) to a temp file and run it via Bash; capture an approximate `passed` / `total`. Set `partial_coverage = true` (the cases are ad-hoc, not canonical).
- **`run_mode=review-only`:** skip execution entirely; judge correctness by reading the code. Leave `passed`/`total` null and note `(not executed)`.

### b. Score 6 axes, integer 1–5, each with a one-line justification

- `problem_solving` — clarified, matched a pattern, planned before coding.
- `correctness` — map the harness pass-rate: all pass → 5; most pass → 3–4; few/none → 1–2. In `review-only`, give an inspection estimate and note `(not executed)`.
- `complexity_analysis` — did they state time/space, brute-force vs optimized, and was it right?
- `code_quality` — readable names, clean structure, idiomatic Python, edge handling.
- `communication` — narrated approach and tradeoffs; thought aloud, didn't go silent.
- `testing_edge_cases` — surfaced and tested empties/singles/duplicates/negatives/etc.

Compute `overall` = arithmetic mean of the six, rounded to 2 decimals.

### c. Coach notes

- 2–4 **Strengths** — specific; quote their code or their words.
- 2–4 **Improvements** — specific, each paired with the concrete fix.
- **Suggested drills** — concrete commands, e.g. `/coding-drill <pattern>`, `/coding-explain <id>`, `/practice-coding <id>`.

### d. Update the weak-pattern tracker

Append the entry's frontmatter `patterns` to `$CLAUDE_PROJECT_DIR/coding/weak-patterns.md` (create the file if missing, with the header row `pattern | encounters | weak_signals | last_seen`). For EACH pattern in `patterns`:

- If a row for that pattern exists: increment `encounters`; set `last_seen` to today's date (`date +%Y-%m-%d`); increment `weak_signals` only when this session's `overall < 3.5`.
- If no row exists: add one with `encounters = 1`, `last_seen` = today, `weak_signals = 1` if `overall < 3.5` else `0`.

(For a `topic_prompt` with no `patterns` frontmatter, infer the dominant pattern name from the `coding-frameworks` taxonomy and use that; if none is clear, skip this step.)

## Step 6 — Write the session folder

Write `<session_folder>/transcript.md` with EXACTLY this structure (`solution.py` is already in the folder from Step 2):

~~~markdown
---
type: mock-coding
topic: <library-id, imported-id, or the free-prompt string>
lang: python
run_mode: <run | review-only>
date: <ISO-8601 datetime, from `date -Iseconds`>
duration_minutes: <integer, (now - start_ts)/60>
solution_path: <absolute path to solution.py>
harness: {passed: <int | null>, total: <int | null>, partial_coverage: <true | false>}
rubric_scores:
  problem_solving: <1-5>
  correctness: <1-5>
  complexity_analysis: <1-5>
  code_quality: <1-5>
  communication: <1-5>
  testing_edge_cases: <1-5>
overall: <mean to 2 decimals>
patterns_covered: [<patterns from the entry, or inferred>]
---

## Transcript
<turn-by-turn, **Interviewer:** / **Candidate:** prefixes>

## Coach Notes
- **Strengths:** …
- **Improvements:** …
- **Suggested drills:** …
~~~

## Step 7 — Print

- The 6 rubric scores and the `overall`.
- The harness result `passed/total` (or "(not executed)" in review-only).
- The top 1–2 strengths and the top 1–2 improvements.
- The single top suggested drill.
- The session folder path.
