---
description: Capture a debrief after a real system-design interview — the problem, your approach by stage, tradeoffs probed, curveballs, where you got stuck, and your gut outcome. Writes a structured session file under the company directory. Text-only.
argument-hint: <company> [library-id or topic-prose]
---

You are running `/debrief-sysdesign`. The user just had a real system-design interview and wants to capture what happened. This is text-only: NO canvas, NO mock-interviewer persona. You are an empathetic, brisk debriefer.

## Step 1 — Parse + slugify args

Take `$ARGUMENTS`. The first whitespace-delimited token is `company` (required). The remainder (if any) is `topic` — either a library id or free prose describing the problem.

If `company` is missing, ask the user for it before continuing.

Slugify BOTH `company` and `topic` with these rules (deterministic on re-runs):

1. Lowercase.
2. Strip a leading article: `the`, `a`, `an`.
3. Replace any run of whitespace/punctuation (em-dashes, slashes, commas, `!`, etc.) with a single hyphen.
4. Collapse consecutive hyphens.
5. Trim hyphens from the edges.

(e.g. "The Stripe!" → `stripe`.) If no `topic` was supplied, use the literal string `unspecified`.

## Step 2 — Conduct the debrief, ONE question at a time

Ask ONE question, wait for the answer, then ask the next — do NOT dump all six at once. Cover these six areas in order:

1. **Problem** — "What were you asked to design?" Capture verbatim if they recall the exact prompt; if they only remember the gist, accept a paraphrase and tag it `(approx.)`.
2. **Approach by stage** — "Walk me through which RESHADED stages you hit, and in what order." The stages are Requirements, Estimation, Storage, High-level design, API design, Detailed design, Evaluation & edge cases, Done. Note which stages they skipped.
3. **Tradeoffs probed** — "What tradeoffs did the interviewer push on?" (e.g. consistency vs availability, SQL vs NoSQL, fan-out on read vs write, sync vs async.)
4. **Curveballs** — "What scaling/failure/extension twists got thrown at you, and roughly when?"
5. **Stuck points** — "Where did you struggle or blank?" Capture each as a short slug (e.g. `quorum-math`, `hot-key-mitigation`, `cap-tradeoff`).
6. **Gut outcome** — "Pass, fail, or unknown?" Only `pass`, `fail`, `unknown` are valid values for the frontmatter `outcome_gut` field. If the user gives a fuzzy answer ("I think it went OK", "probably failed"), map it to the closest enum and CONFIRM before writing: "I'll log that as `unknown` — sound right, or would you say `pass`?" Persist only the canonical enum value; the prose body can keep their nuanced phrasing.

## Step 3 — Write the session file

Path: `$CLAUDE_PROJECT_DIR/<company>/sysdesign/sessions/<YYYY-MM-DD-HHMM>-debrief-sysdesign.md` — date and time from `date +%Y-%m-%d-%H%M` (24-hour HHMM). Use the `Write` tool with the full absolute path; it creates any missing parent directories automatically (no `mkdir` needed).

Write the file with EXACTLY this structure (substitute real parsed values):

~~~markdown
---
type: debrief-sysdesign
company: <slug>
topic: <slug | "unspecified">
date: <ISO-8601 datetime, from `date -Iseconds`>
outcome_gut: <pass | fail | unknown>
stages_attempted: [<RESHADED stages they hit, drawn from: Requirements, Estimation, Storage, High-level design, API design, Detailed design, Evaluation & edge cases, Done>]
stages_skipped: [<RESHADED stages they skipped, drawn from: Requirements, Estimation, Storage, High-level design, API design, Detailed design, Evaluation & edge cases, Done>]
stuck_points: [<short slugs>]
curveballs: [<short descriptions>]
---

## Problem
<verbatim or paraphrased, (approx.) tagged if not verbatim>

## Approach
<stage-by-stage narrative>

## Tradeoffs Probed
- …

## Curveballs
- …

## Stuck Points
- …
~~~

## Step 4 — Suggest drills

For each stuck point, map it to ONE concrete next command:

- Prefer `/practice-sysdesign <library-id>` when a library entry covers that theme. You may glob `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/*.md` and Read each entry's frontmatter `themes` list to match a stuck-point slug against a theme (e.g. `quorum-math` → the entry whose `themes` include `quorum`; `hot-key-mitigation` → an entry with `hot-keys`).
- Otherwise fall back to `/sysdesign-explain <id>` for the closest building block.

Then print:

- The session file path.
- The suggested drills, one per stuck point.
