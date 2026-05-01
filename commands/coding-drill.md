---
description: Rapid-fire reps — pattern recognition, complexity-of-this-snippet, template recall — flashcard cadence; prioritizes your weak patterns.
argument-hint: [pattern]
---

You are running `/coding-drill`. This is a fast flashcard-style drill — short prompts, instant reveals, no full implementations. Keep the cadence tight; you are a brisk drill partner, not a teacher.

## Step 1 — Resolve which patterns to drill

Take `$ARGUMENTS` (a single pattern name, optional).

- **Explicit pattern arg** (e.g. `sliding-window`, `two-pointers`, `dynamic-programming`): drill that one pattern for the whole session. Match it case-insensitively against the `## Pattern taxonomy` headings in the skill (Step 2); if it doesn't match a known pattern, tell the user the closest matches and ask them to pick.
- **Empty arg, tracker exists:** Read `$CLAUDE_PROJECT_DIR/coding/weak-patterns.md` (header `pattern | encounters | weak_signals | last_seen`). Pick the 2–3 patterns with the highest `weak_signals` (break ties by oldest `last_seen`) and weight the reps toward them; sprinkle in one or two others for variety.
- **Empty arg, no tracker yet:** assemble a **mixed set** spanning the taxonomy (e.g. one each from two-pointers, sliding-window, BFS/DFS, hashing, dynamic-programming, binary-search). Create the tracker in Step 4 as you score.

Tell the user in one line what you're drilling and why (e.g. "Drilling your two weakest patterns: `dynamic-programming` and `binary-search`, plus a couple of mixed reps.").

## Step 2 — Load the `coding-frameworks` skill

Read `${CLAUDE_PLUGIN_ROOT}/skills/coding-frameworks/SKILL.md`. Its `## Pattern taxonomy` (recognition cues, template skeletons, complexity, pitfalls) and `## Big-O cheatsheet` are the source of truth for every rep's answer — never improvise complexities or skeletons from memory.

## Step 3 — Run the reps (~8–10, or until the user says stop)

Pose ONE rep at a time, wait for the user's answer, then reveal. Each rep is exactly ONE of these three kinds (vary the kind across the session; weight toward the resolved patterns):

- **Pattern recognition** — give a one- or two-line problem prompt and ask: "Which pattern, and your one-sentence approach?" (e.g. "Longest contiguous subarray with at most K distinct chars — pattern + one-sentence approach?")
- **Complexity** — show a short ```python snippet (≤ ~8 lines) and ask: "Time and space?" Pull the snippet from the taxonomy templates or a close variant; ground the answer in the Big-O cheatsheet.
- **Template recall** — ask: "Sketch the `<pattern>` skeleton" (e.g. "Sketch the BFS-shortest-path skeleton — queue, visited, when you mark seen"). The user types a rough skeleton; you check it against the taxonomy template.

After each answer, REVEAL: the correct answer in 1–3 lines, then a one-line verdict — **correct** / **partially correct** / **incorrect** — and the single most important fix if not fully correct. Keep it tight. Do NOT ask the user to write a full solution; do NOT trace executions line by line — this is flashcards, not `/practice-coding`.

Track the running tally (correct vs total) and note which sub-skill each miss was (e.g. "missed the `{0:1}` prefix-sum seed", "called BFS O(V) instead of O(V+E)") so you can name the weakest sub-skills at the close.

Stop at ~8–10 reps, or immediately whenever the user says stop / done / that's enough.

## Step 4 — Close + update the tracker

Print a close:

- The tally (e.g. "**7/10**").
- The 1–2 weakest sub-skills, named concretely (the recurring miss type, not just the pattern).
- A suggested next command per weak pattern: `/coding-explain <pattern>` to re-teach, or `/practice-coding <id>` to drill it in code (suggest a library id whose `patterns` include that pattern — e.g. `sliding-window` → `longest-substring-no-repeat`, `dynamic-programming` → `coin-change`, `two-pointers` → `trapping-rain-water`).

Then update `$CLAUDE_PROJECT_DIR/coding/weak-patterns.md` (create it if missing, with the header row `pattern | encounters | weak_signals | last_seen`). For EACH pattern you drilled this session:

- Compute that pattern's per-pattern hit rate from this session's reps (correct reps of that pattern ÷ reps of that pattern). Treat a hit rate below ~0.5 as a weak showing.
- If a row for the pattern exists: increment `encounters`; set `last_seen` to today (`date +%Y-%m-%d`); increment `weak_signals` only on a weak showing.
- If no row exists: add one with `encounters = 1`, `last_seen` = today, `weak_signals = 1` on a weak showing else `0`.

## Step 5 — Write the drill session file

Compute the date string via `date +%Y-%m-%d-%H%M` (24-hour HHMM). Let `<pattern>` be the resolved pattern arg, or `mixed` when the session spanned several patterns.

Write `$CLAUDE_PROJECT_DIR/coding/drills/<YYYY-MM-DD-HHMM>-drill-<pattern>.md` with the `Write` tool using the full absolute path (it creates missing parent dirs — no `mkdir`). Use EXACTLY this structure:

~~~markdown
---
type: coding-drill
patterns: [<patterns drilled this session>]
date: <ISO-8601 datetime, from `date -Iseconds`>
score: {correct: <int>, total: <int>}
missed: [<short slugs of the sub-skills missed, e.g. prefix-sum-seed, bfs-complexity>]
---

## Reps

1. **[recognition]** <prompt> → answered `<user's answer>` — **correct** (expected: <pattern, one-line approach>)
2. **[complexity]** <snippet summary> → answered `<user's answer>` — **incorrect** (expected: O(n) time, O(1) space)
3. **[template]** Sketch the `<pattern>` skeleton → **partially correct** (missing: <the one fix>)
…

## Weakest sub-skills
- <named miss type>
- <named miss type>

## Suggested next
- `/coding-explain <pattern>` — <why>
- `/practice-coding <id>` — <why>
~~~

Then print the session file path.
