---
description: Senior-engineer walkthrough of a DSA pattern or a specific problem — how to recognize it, the template, complexity, variants. Teaches the approach, not just the answer. No session file.
argument-hint: <pattern | library-id | "free prompt">
---

You are running `/coding-explain`.

## Step 1 — Resolve `$ARGUMENTS`

Take `$ARGUMENTS` as `arg` and resolve it to exactly one of four modes (check in this order):

1. **Pattern** — `arg` matches a pattern id in the `coding-frameworks` taxonomy (a `### <pattern>` sub-section under `## Pattern taxonomy`, e.g. `two-pointers`, `sliding-window`, `dynamic-programming`, `backtracking`, `binary-search`). Match on the slug OR the heading's key term — some ids map to compound headings (e.g. `topological-sort` → the "Graph: topological sort" subsection; `bfs`/`dfs`/`hashing`/`heap` similarly cover their compound headings). Set `mode = pattern`.
2. **Problem** — `${CLAUDE_PLUGIN_ROOT}/library/coding/<arg>.md` exists (a **library** entry) OR `$CLAUDE_PROJECT_DIR/coding/imported/<arg>.md` exists (an **imported** entry; also strip a leading `imported/` from `arg` and retry, so both `<id>` and `imported/<id>` resolve). Read it and hold its full content as `topic_source`. Set `mode = problem`.
3. **Free prompt** — `arg` is non-empty but matches neither a pattern nor an entry. Hold it verbatim as `topic_prompt`. Set `mode = free`.
4. **Empty** — `arg` is empty. Set `mode = list`.

If `mode = list`: load the `coding-frameworks` skill and list every `### <pattern>` from its `## Pattern taxonomy`; then Read the frontmatter `id` and `difficulty` of each `${CLAUDE_PLUGIN_ROOT}/library/coding/*.md` and present the problems as a numbered list grouped by `difficulty`. Ask the user to pick a pattern or a problem, then re-resolve their answer through this step.

## Step 2 — Load the skill

Before teaching anything, load the `coding-frameworks` skill (the UMPIRE method, the pattern taxonomy, the Big-O cheatsheet, Python idioms). It grounds every walkthrough below and is never read aloud verbatim.

## Step 3 — Teach in chat

Explain entirely in chat — this is teach-first, not a graded run. Do **not** run any code in this command. You MAY offer to seed a scratch stub the user can try (e.g. point them at `/practice-coding <id>`), but explain runs nothing itself.

**`mode = pattern` — teach the pattern.** From the skill's `### <pattern>` section, walk the user through, in your own voice:

- **Recognition cues** — the input shape / asked-for output that should make them reach for this pattern.
- **Template skeleton** — the canonical code shape (paraphrase and annotate the skill's skeleton; explain *why* each line is there, don't just paste it).
- **Complexity** — the typical time/space, with the reasoning.
- **Common pitfalls** — the off-by-one / mis-binding / wrong-structure traps from the skill's pitfalls.

Then name **2-3 representative library problems to try**: glob `${CLAUDE_PLUGIN_ROOT}/library/coding/*.md`, read each entry's `patterns:` frontmatter, and pick the ones whose `patterns:` list includes this pattern (account for taxonomy/frontmatter spelling variants — e.g. the `Hashing / frequency-map` section covers `hashing`; `BFS`/`DFS` cover `bfs`/`dfs`). Give each as a concrete `/practice-coding <id>` or `/coding-explain <id>` suggestion.

**`mode = problem` — walk the problem.** Read the entry and teach the **derivation**, in this order:

- **Clarify** — the constraint questions that change the algorithm (mirror the entry's `## Clarifying questions to expect`).
- **Pattern-match** — name the pattern the problem resembles and *why*, tying back to the taxonomy.
- **Plan** — brute force and its cost, then the optimization and its cost (lean on the entry's `## Pattern & approach` and `## Complexity`).
- **Complexity** — final time/space, with auxiliary vs output vs recursion-stack space called out.
- **Edge cases** — empty / single / duplicates / negatives / overflow / cycles, as relevant.
- **One follow-up** — a single variation from the entry's `## Follow-ups & variations` to stretch them.

The entry's `## Reference solution` **grounds** your derivation — use it to teach the *why* of each step — but NEVER dump it verbatim as "the answer". The whole point of explain is to derive the approach, not hand over the code.

**`mode = free` — on-demand walkthrough.** State up front that this is **not a canonical library entry** (so the user knows it relies on general knowledge). Then walk it with the same derivation order as `mode = problem`: clarify → pattern-match → plan → complexity → edge cases → one follow-up.

Pause where it helps the user absorb each phase before moving on.

## Step 4 — Close

Print exactly:

> Next: /practice-coding <id> to try it with hints, /coding-drill <pattern> for reps, or /mock-coding <id> for a graded run.

Substitute a concrete `<id>` (a representative problem) and `<pattern>` when you have them; for a free-prompt walkthrough leave the suggestions generic.

## Step 5 — No session file

`coding-explain` writes **no session file** — the library entry and the `coding-frameworks` skill are the canonical artifacts. Nothing is saved.
