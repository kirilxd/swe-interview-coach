---
description: Drill a single story variant for delivery quality. Two modes — canonical (drill the underlying story) and mapped (drill the company-tailored variant). Critiques filler, ramble, metrics, pronoun discipline, time-to-deliver. Saves a session file but does NOT modify canonical files.
argument-hint: <story-id> [variant] [--company <name>] [--job-title <title>]
---

You are running `/story-rehearse`.

## Step 1 — Parse arguments

Extract from `$ARGUMENTS`:
- `story_id` (required, first positional).
- `variant` (optional, second positional).
- `company` (optional, value of `--company`).
- `job_title` (optional, value of `--job-title`).

Mode: `mapped` if `--company` is set, else `canonical`.

If `story_id` is missing: list available IDs by globbing `$CLAUDE_PROJECT_DIR/behavioral/stories/*.md` and ask the user to pick.

## Step 2 — Resolve story file

- **Canonical mode:** `$CLAUDE_PROJECT_DIR/behavioral/stories/<story_id>.md`.
- **Mapped mode:** `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job_title-or-_general>/<story_id>.md`. If `--job-title` is omitted in mapped mode, default to `_general`.

If the file doesn't exist:
- **Canonical:** list available IDs from `behavioral/stories/*.md` and ask the user to pick.
- **Mapped:** if the mapping directory doesn't exist (or contains no `<id>.md` files), prompt the user with a numbered choice:
  `No mapping for <company>/<job_title>. Choose: (1) run /story-map <company> first, (2) cancel.`
  Wait for the user's response (1-2). If (1), complete the equivalent of `/story-map <company>` before continuing here. If (2), abort with no file writes.
  If only this story's mapped file is missing (other mappings exist), list available mapped story IDs and ask.

Read the resolved file.

## Step 3 — Resolve variant

If `variant` is empty or not present in the file:
- **Canonical:** parse the file's `### Variant: <id>` headers; show the list to the user as a numbered choice and ask them to pick.
- **Mapped:** parse the `### Q:` blocks (each has a `**Maps to canonical variant:** <id>` line); show the question text + canonical-variant id pairs as a numbered choice and ask the user to pick.
- **If no `### Variant:` headers are found in canonical mode:** report to the user that the story has no variants yet, suggest editing the file directly or running `/story-add` to add them with the extractor's help, then abort.
- **If no `### Q:` blocks are found in mapped mode:** similar — suggest running `/story-map <company>` to (re)generate mapped variants, then abort.

Wait for the user's pick before proceeding.

## Step 4 — Run the drill loop

Pose the question for the chosen variant:
- **Canonical:** use the variant's `**Best for questions like:**` example.
- **Mapped:** use the `### Q:` heading text.

Wait for the user's typed answer. If the answer is empty or only whitespace, ask the user to try again — do not proceed to critique. Repeat until the user provides substantive content (a paragraph or more).

Before critiquing, ensure the `behavioral-frameworks` skill content is loaded (if it has not already been auto-loaded, invoke it explicitly — the critique below relies on its anti-pattern definitions and time-budget conventions).

Critique the answer using the `behavioral-frameworks` skill content. Score 1-5 overall. For each axis, give a specific note:
- **Filler:** count occurrences of "um", "uh", "kind of", "like", "sort of". State the count.
- **Pronouns:** flag every "we" where "I" would be clearer; reference paragraph number where the issue appears.
- **Metrics:** flag missing or vague Result metric; suggest specifically what to add.
- **Ramble:** estimate words/seconds per element; flag elements that exceed the budget (Situation ~30s, Task ~20s, Action ~60s, Result ~30s).
- **Suggested cuts:** list specific phrases or sentences to remove.

**Time-to-deliver estimate:** Sum the per-element time estimates you used for the Ramble check (Situation + Task + Action + Result words/seconds). Record the total as `time_to_deliver_seconds` in the session file. If the answer was a typed paragraph, estimate at ~150 words per minute (~2.5 words per second).

After delivering the critique, ask the user with a numbered choice:
`Choose: (1) re-run the same variant, (2) switch to a different variant, (3) wrap and save.`

## Step 5 — Loop or wrap

- If the user picks (1): pose the same question again; collect the new answer; re-critique.
- If the user picks (2): go back to Step 3 (variant selection).
- If the user picks (3): proceed to Step 6.

## Step 6 — Write the session file

Compute the target path:
- **Canonical mode:** `$CLAUDE_PROJECT_DIR/behavioral/rehearsals/<YYYY-MM-DD-HHMM>-<story_id>-<variant>.md`.
- **Mapped mode:** `$CLAUDE_PROJECT_DIR/<company>/behavioral/sessions/<YYYY-MM-DD-HHMM>-rehearse-<story_id>-<variant>.md`.

Use the `Write` tool with the full absolute path — it creates any missing intermediate directories automatically. No explicit `mkdir` is needed.

Write the file with this exact structure:

~~~markdown
---
type: rehearse
mode: <canonical|mapped>
story_id: <story-id>
variant: <variant>
company: <company or null>
job_title: <job-title or null>
date: <ISO-8601 datetime>
question_used: <question text>
time_to_deliver_seconds: <estimate — sum of per-element Ramble times; see Step 4>
critique_axes: [filler, ramble, metrics, pronouns]
---

## What I Said
<user's typed answer; if multiple attempts, use the final one>

## Critique
- Filler: <count>
- Pronouns: <notes>
- Metrics: <notes>
- Ramble: <notes>
- Suggested cuts: <bullets>

## Score
<1-5>
~~~

## Step 7 — Do NOT modify canonical files

The rehearsal session file is the only artifact this command writes. Do NOT touch any file under `$CLAUDE_PROJECT_DIR/behavioral/stories/`. No frontmatter updates, no `last_rehearsed`, no `rehearsal_count`.
