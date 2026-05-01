---
description: Import a LeetCode problem into your local library via WebFetch — no MCP, no login. Becomes a normal markdown problem you can practice or mock.
argument-hint: <leetcode-url | slug | daily>
---

You are running `/coding-import`. You import a single LeetCode problem into the user's local library as a normal markdown entry, using only the `WebFetch` tool — no MCP server, no login, no auth, no submission, and no redistribution beyond the user's own machine. This is a read-only fetch of a public problem page for personal interview prep.

## Step 1 — Parse `$ARGUMENTS`

Resolve `$ARGUMENTS` into a `slug` and a fetch target:

- A full URL like `https://leetcode.com/problems/<slug>/` → extract `<slug>` (the path segment after `problems/`); fetch target is that URL.
- A bare slug like `two-sum` (kebab-case, no slashes) → `slug = <arg>`; fetch target is `https://leetcode.com/problems/<slug>/`.
- The literal `daily` → fetch target is the daily endpoint (Step 2); `slug` is not yet known and is filled in from the fetched title.

If `$ARGUMENTS` is empty, ask the user for a URL, slug, or `daily`, then stop until they answer.

## Step 2 — Fetch with WebFetch

Fetch the problem with the `WebFetch` tool (the same tool the behavioral commands use) — no auth header, no cookies, no login.

1. **Primary (URL/slug):** `WebFetch` the `https://leetcode.com/problems/<slug>/` page. Prompt it to extract: title, difficulty (Easy/Medium/Hard), the full problem statement, every worked example (input → output, plus any explanation), the constraints, and the function name + parameters if a code signature is shown.
2. **Fallback (extraction poor — LeetCode is JS-heavy, so the page often renders thin):** if the primary fetch returns little or no statement/examples, `WebFetch` the unofficial REST endpoint instead, which returns JSON:
   - URL/slug: `https://alfa-leetcode-api.onrender.com/select?titleSlug=<slug>`
   - `daily`: `https://alfa-leetcode-api.onrender.com/daily` — then set `slug` from the returned `titleSlug`.
   Extract the same fields from the JSON (`question`/`content` HTML → statement + examples + constraints; `difficulty`; `title`).
3. **Both fail / empty:** do NOT invent a problem — ask the user to paste the problem text (statement + examples + constraints) and build from that; if they decline, stop.

Hold the extracted `title`, `difficulty`, `statement`, `examples` (each with args + expected, and explanation if any), `constraints`, and a best-effort `signature` (name + params + return type) if one was shown.

## Step 3 — Convert to the library schema and write

Convert what you extracted into the standard coding-library entry — the SAME schema as `${CLAUDE_PLUGIN_ROOT}/library/coding/two-sum.md` (read it if you need the exact shape). Do NOT write into `${CLAUDE_PLUGIN_ROOT}` (read-only bundled assets). Write to `$CLAUDE_PROJECT_DIR/coding/imported/<slug>.md` with the `Write` tool using the full absolute path (intermediate dirs are created automatically).

Frontmatter (fill from the extraction; leave a field's value best-effort/empty list if unknown):

```yaml
---
id: <slug>
title: <title>
difficulty: <easy|medium|hard>
patterns: []
companies_known_to_ask: []
estimated_time: <e.g. 20m>
signature:
  name: <fn name, best-effort from the page or a sensible camelCase guess>
  params:
    - {name: <p>, type: "<type>"}
  returns: "<type>"
languages: [python]
cases_source: examples
---
```

`cases_source: examples` is mandatory here — it records that the test cases came only from the worked examples, not a vetted canonical set.

Then the 9 H2 sections, IN THIS ORDER:

1. `## Problem` — the statement in your own clean markdown, with the worked example(s) and constraints as bullets.
2. `## Clarifying questions to expect` — 3-5 questions a candidate should ask (derive from the constraints/ambiguities).
3. `## Pattern & approach` — best-effort: name the likely pattern(s) and the core idea.
4. `## Complexity` — best-effort target time/space.
5. `## Hint ladder` — 3-4 escalating hints.
6. `## Starter stub` — a ```python block built from the extracted `signature` (best-effort): the imports it needs, the `def` with typed params, a `# your code here` line, and `pass`.
7. `## Reference solution` — EITHER omit this section entirely, OR include a generated sketch in a ```python block with the line **"(generated, not verified)"** immediately above it. Do NOT present it as a verified/canonical solution — example-only test cases cannot gate correctness, so never claim it passes.
8. `## Follow-ups & variations` — 2-3 plausible follow-ups.
9. `## Test cases` — a ```json block derived ONLY from the worked examples, one case per example:
   ```json
   {"function": "<signature.name>", "unordered": false,
    "cases": [
      {"args": [<example input args, in signature order>], "expected": <example output>}
    ]}
   ```
   Set `"unordered": true` only if the problem explicitly says the answer order doesn't matter.

## Step 4 — Tell the user

Report:
- The file written (full absolute path) and that it's immediately runnable:
  - `/practice-coding imported/<slug>`
  - `/mock-coding imported/<slug>`
- A clear WARNING: the test cases were derived from the problem's worked examples only, so they are **partial coverage** — a green run means "passed the provided examples", NOT "provably correct". The user can add edge cases by hand-editing the `## Test cases` JSON block; any `## Reference solution` present is a generated sketch, not verified.

## Step 5 — Posture

This command only does a read-only `WebFetch` of public problem pages for the user's personal interview prep: no MCP, no login, no auth, no submission to LeetCode, and no redistribution of problem content beyond the user's own machine. If the user asks for bulk scraping or anything that looks like republishing, decline and keep it to single-problem personal import.
