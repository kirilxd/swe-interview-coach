---
description: Capture a debrief from a real interview. Main session interviews you about what was asked, what stories you told, what surprised you, and your gut sense. Writes a session file and updates the question index for that company/JD.
argument-hint: <company> [job-title]
---

You are running `/debrief`. The user just had a real behavioral interview at `<company>` and wants to capture what happened.

## Step 1 — Parse arguments

Extract `company` (required) and `job_title` (optional) from `$ARGUMENTS`.

If no company: ask the user.

If `job_title` is provided as a plain string: slugify using the same rules as `/story-import` (lowercase, strip leading articles "the"/"a"/"an", replace whitespace and punctuation with single hyphens, collapse consecutive hyphens, trim hyphens from edges).

If no `job_title`: ask the user. If they don't have a specific title, default to `_general`.

## Step 2 — Conduct the debrief interview

You are NOT in mock-interviewer mode. You are a debriefer. Be empathetic and brisk. Ask one focused question at a time. Cover all four areas:

1. **Verbatim questions:** "Walk me through every question they asked, as close to verbatim as you remember."
   - Capture each as a list item.
   - If the user cannot recall exact wording, accept paraphrases and append `(approx.)` after the question text. Capture the topic/intent even if the precise phrasing is lost.
2. **Stories told:** "For each question, which canonical/mapped story did you tell? How did it land?"
   - Capture: story-id/variant-id; landing notes (e.g., "got follow-up", "they pushed back", "no follow-up").
3. **Surprises:** "Any questions you didn't have a story for? Anything that felt out-of-distribution?"
   - Capture as a list of new gaps. Slugify each gap to a short identifier (e.g., "disagreed-with-manager", "calculated-risk-failed") for the frontmatter list.
4. **Self-assessment:** "What worked, what didn't — gut sense, pass / fail / unknown?"
   - Only accepted values for `outcome_gut` in the frontmatter: `pass`, `fail`, `unknown`.
   - If the user gives an ambiguous answer (e.g., "leaning pass but not sure", "probably failed"), map it to the closest enum value and confirm: "I'll log that as `unknown` — sound right, or would you say `pass`?"
   - Persist only the canonical enum value to the frontmatter; the prose summary in the body can carry the user's nuanced phrasing.

## Step 3 — Write the session file

Compute filename: `$CLAUDE_PROJECT_DIR/<company>/behavioral/sessions/<YYYY-MM-DD-HHMM>-debrief.md` (today's date and current time, 24-hour HHMM).

Use the `Write` tool with the full absolute path — it creates any missing intermediate directories automatically. No explicit `mkdir` is needed.

Write the file with this exact structure:

~~~markdown
---
type: debrief
company: <company>
job_title: <job_title>
date: <ISO-8601 datetime, e.g., 2026-05-10T14:30:00>
outcome_gut: <pass|fail|unknown>
questions_logged: <N>
new_gaps_identified: [<gap-slug>, ...]
stories_used: [<canonical-id/variant-id>, ...]
---

## Verbatim Questions
1. ...
2. ...

## Stories I Told
- <canonical-id>/<variant-id> — <landing notes>
- ...

## Surprises
- ...

## Self-Assessment
- ...
~~~

## Step 4 — Update the question index (if mapping exists)

Path: `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job_title>/_questions.md`.

**If the file exists:**
- Read it.
- For each verbatim question from the debrief, check if it (or a near-match — same intent, different wording) is already in either the **Classic Behavioral Questions** or **Company-Specific Questions** tables.
- For each new question: append it to the appropriate table (Classic if generic, Company-Specific if value-keyed). If a canonical story already covers the question, fill in the Story / Variant columns; if not, leave those columns as `—` and add the question's slug to **Coverage Gaps**.
- Regenerate the **Coverage Gaps** section: include any old gaps still uncovered plus new ones from this debrief, deduplicated.
- Before editing, verify the file contains all three expected sections: `## Classic Behavioral Questions`, `## Company-Specific Questions`, `## Coverage Gaps`. If any section is missing (e.g., the user manually edited the file or a future `/story-map` produced a different structure), warn the user, skip the edit for that section, and append a note to the Step 5 suggestions list pointing to the malformed file. Do NOT attempt to append in an unpredictable location.
- Use the `Edit` tool (not `Write`) to update the file in place — preserve existing rows and frontmatter; do not rewrite the whole file.

**If the file does NOT exist** (no prior `/story-map` for this company/job-title):
- Skip the index update.
- Add to the Step 5 suggestion list: "Run `/story-map <company>` for next time so I can update the question index automatically."

## Step 5 — Print summary and suggestions

Print to the user:
- The session file path.
- Number of verbatim questions logged: N.
- Number of new gaps identified: M.
- Specific suggested next steps:
  - For each new gap: `Run /story-add to fill the '<gap-slug>' gap.`
  - If the interviewer's framing surfaced value priorities not reflected in the cached values: `Run /story-map <company> --refresh — values cache may be stale.`
  - If no mapping existed: `Run /story-map <company>` for next time.
