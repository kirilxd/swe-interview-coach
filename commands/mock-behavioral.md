---
description: Run a mock behavioral interview tailored to a target company and JD. Spawns the behavioral-interviewer subagent with mapped stories as context; main session scores the transcript and writes a session file afterward.
argument-hint: <company> [job-title-or-jd]
---

You are running `/mock-behavioral`.

## Step 1 — Parse arguments

Parse `$ARGUMENTS` into `company` (required) and `job_title_or_jd` (optional). Strip surrounding quotes from `job_title_or_jd` if present.

If `job_title_or_jd` looks like a URL (starts with `http://` or `https://`) or a local path ending in `.pdf`/`.md`/`.txt`, treat it as a JD reference for `/story-map`.

If no company: ask the user.

## Step 2 — Verify story bank

If `$CLAUDE_PROJECT_DIR/behavioral/stories/` is empty: print

> No canonical stories. Run /story-add or /story-import first.

Then stop.

## Step 3 — Resolve mapping

Determine `job_title`:
- If `job_title_or_jd` is a plain string: slugify it using the same rules as `/story-import` (lowercase, strip leading articles "the"/"a"/"an", replace whitespace and punctuation with single hyphens, collapse consecutive hyphens, trim hyphens from edges).
- If it's a URL/path: defer to `/story-map` for resolution (offer to run `/story-map <company> <jd>` first; if user agrees, complete that flow before continuing here).
- If empty: try to find the most recently modified subdir under `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/`. If none exist, default to `_general`.

Check `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job_title>/` exists AND contains at least one `<id>.md` file (excluding `_questions.md`). If the directory is missing OR contains no mapped story files, treat as missing.

If missing: print

> No mappings for <company>/<job_title>. Run /story-map <company> <jd> first?

Ask the user. If they say yes, run the equivalent of `/story-map <company>` (or with the JD they provide). If they decline, abort with no file writes.

## Step 4 — Stale check

For each `<id>.md` in the mapped-stories dir:
- Try to read `$CLAUDE_PROJECT_DIR/behavioral/stories/<id>.md`. If the canonical file is missing (Read returns "file not found" or similar), classify the mapping as **orphaned**.
- Otherwise, compare the canonical's `last_modified` to the mapped file's `canonical_modified_at_mapping` frontmatter. If the canonical's date is newer, classify as **stale**.

If any mappings are stale or orphaned, prompt the user with a numbered choice (label each entry as "stale" or "orphaned"):
`Issues found: <list with labels>. Choose: (1) re-map all stale via /story-map (orphaned ones are skipped — their canonical no longer exists), (2) proceed anyway with current mapped versions, (3) cancel.`
Wait for the user's response (1-3) and act accordingly. Note: orphaned mappings cannot be re-mapped (canonical missing); option (1) only refreshes stale entries.

## Step 5 — Spawn behavioral-interviewer

Pass as context:
- `company`: <company>
- `job_title`: <job_title>
- `mapped_stories`: full content of every `<id>.md` under `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job_title>/` (exclude `_questions.md`).
- `values`: full content of `$CLAUDE_PROJECT_DIR/<company>/values.md`.
- `question_index`: full content of `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job_title>/_questions.md`.

Let the subagent run the mock until it emits the `[end of mock — yielding to main session for debrief]` marker.

## Step 6 — Score the transcript

Before scoring, ensure the `behavioral-frameworks` skill content is loaded (if it has not already been auto-loaded, invoke it explicitly — the rubric below relies on its anti-pattern definitions and time-budget conventions).

Score the transcript on a 1-5 scale per axis:
- `star_clarity` — was each Situation/Task/Action/Result clearly delineated?
- `metric_quality` — were Results quantified concretely?
- `conciseness` — did the candidate stay within reasonable time-budget per element (Situation ~30s, Task ~20s, Action ~60s, Result ~30s)?
- `values_alignment` — did the answers signal the company's values without being heavy-handed?

Compute `overall` as the mean (rounded to two decimal places).

## Step 7 — Write the session file

Compute filename: `$CLAUDE_PROJECT_DIR/<company>/behavioral/sessions/<YYYY-MM-DD-HHMM>-mock-behavioral.md` (today's date + current time, where HHMM is zero-padded 24-hour, e.g., `2026-05-10-1430-mock-behavioral.md`).

Use the `Write` tool with the full absolute path — it creates any missing intermediate directories automatically. No explicit `mkdir` is needed.

Write the file with this exact structure:

~~~markdown
---
type: mock-behavioral
company: <company>
job_title: <job_title>
date: <ISO-8601 datetime, e.g., 2026-05-10T14:30:00>
duration_minutes: <estimate>
stories_used: [<canonical-id/variant-id>, ...]
rubric_scores:
  star_clarity: <1-5>
  metric_quality: <1-5>
  conciseness: <1-5>
  values_alignment: <1-5>
overall: <mean>
---

## Transcript
<full transcript turn-by-turn, prefixed **Interviewer:** / **Candidate:**>

## Coach Notes
- Strengths: <2-4 bullets>
- Improvements: <2-4 bullets>
- Suggested drills: <specific `/story-rehearse <id> <variant>` or `/story-add` commands>
~~~

## Step 8 — Summary output

Print to the user:
- The four rubric scores plus the overall mean.
- The top 1-2 strengths and improvements (one line each).
- The top suggested drill (a specific command the user can run).
- Path to the saved session file.
