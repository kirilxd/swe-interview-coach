---
description: Map your canonical story bank to a specific company (and optionally a JD). Caches company values, optionally fetches a JD, and writes tailored mapped stories under <company>/behavioral/mapped-stories/<job-title>/.
argument-hint: <company> [jd-url-or-path] [--refresh]
---

You are running `/story-map`. The user wants to tailor canonical stories for a target company and optionally a specific JD.

## Step 1 — Parse arguments

Parse `$ARGUMENTS` into:
- `company` (required): first positional arg.
- `jd_arg` (optional): second positional arg if not `--refresh`.
- `refresh_flag` (optional): true if `--refresh` appears anywhere.

Strip surrounding quotes from `jd_arg` if present.

If no company: ask the user.

## Step 2 — Verify story bank

Scan `$CLAUDE_PROJECT_DIR/behavioral/stories/` for `*.md` files. If none exist, print:

> No canonical stories. Run /story-add or /story-import first.

Then stop.

## Step 3 — Resolve JD

If `jd_arg` starts with `http://` or `https://`: use `WebFetch` to retrieve. Strip nav/footer noise, keep the role description and requirements. If `WebFetch` fails or returns empty content: warn the user ("Could not retrieve the JD — proceeding without it"), skip the JD write step, and treat `jd_arg` as empty (outputs go to `_general/`).

If `jd_arg` is a local file path: use `Read`. Accept `.pdf` (Read handles PDF natively) or `.md`/`.txt`.

If `jd_arg` is empty: skip JD; outputs go to `_general/`.

After resolving, infer the `job_title` from the JD content (look for the role title near the top). Slugify to kebab-case using the same slugification rules as `/story-import`: lowercase, strip leading articles ("the", "a", "an"), replace whitespace and punctuation with single hyphens, collapse consecutive hyphens, trim hyphens from edges. Example: "Senior Frontend Engineer" → `senior-fe-engineer` (the user may shorten the slug; offer the suggestion if the auto-derived slug is long). If no clear title, ask the user or default to `_general`.

If JD was resolved: write the JD content to `$CLAUDE_PROJECT_DIR/<company>/jds/<job-title>.md` using the `Write` tool with the full absolute path (intermediate directories are created automatically). Use this frontmatter:

~~~yaml
---
company: <company>
job_title: <job-title>
source_url: <url or null>
fetched_at: <today YYYY-MM-DD>
---
~~~

## Step 4 — Resolve company values

Compute path: `$CLAUDE_PROJECT_DIR/<company>/values.md`.

If file exists AND `refresh_flag` is false:
- Read its frontmatter `fetched_at`. If `(today - fetched_at) < 90 days`: use the cache, skip to Step 5.
- If older than 90 days: treat as stale, fall through to fetch.

Fetch flow:
1. Use `WebSearch` with query: `<company> company culture values principles for engineering interviews`. Pull the top 2-3 results.
2. For each result URL, use `WebFetch` to extract values content.
3. Synthesize a values document: list each value with a 1-2 sentence definition; note common behavioral question patterns the company asks.
4. Use the `Write` tool with the full absolute path `$CLAUDE_PROJECT_DIR/<company>/values.md` to create the file (intermediate directories are created automatically). Frontmatter must include `company`, `fetched_at` (today YYYY-MM-DD), and `sources` (list of URLs that were fetched).

If `WebSearch` returns nothing useful or `WebFetch` fails: ask the user to paste the values manually; save those.

## Step 5 — Read all canonical stories

Use `Read` (or `Bash` ls + glob loop) on `$CLAUDE_PROJECT_DIR/behavioral/stories/*.md`. Hold all canonicals in memory: id, title, themes, metrics, variants (with their themes and questions).

## Step 6 — Detect stale prior mappings

Target dir: `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job-title>/`.

If it exists, read each existing `<id>.md`:
- Compare its `canonical_modified_at_mapping` to the canonical's `last_modified`.
- If canonical is newer: this mapping is stale.

If any are stale: list them and prompt the user with a numbered choice:
`Stale mappings found: <list of <id>.md files>. Choose: (1) re-map all stale, (2) skip stale and map only new stories, (3) cancel.`
Wait for the user's response (1-3) and act accordingly.

## Step 7 — Generate tailored mapped stories

For each canonical story:

1. Pick the variants that best match the company's values + (if JD present) JD requirements. A canonical may map to multiple Q&As in the mapped output (one canonical → tailored variants for several questions).
2. Generate a tailored `Q: <question>` block per (story, question) pair. Pick from:
   - **Classic behavioral questions** (always include 4-6): "Tell me about driving change", "Describe a conflict and how you resolved it", "Time you made a hard decision with incomplete info", "Time you failed", "Time you disagreed with your manager", "How do you handle competing priorities".
   - **Company-specific questions** (derived from values): for each value in `<company>/values.md`, generate one or two questions an interviewer would actually ask to probe it.
3. For each tailored Q&A: pick the best canonical variant; copy its STAR sections; adjust framing to highlight values/JD alignment without rewriting the substance.

Write one file per canonical story to `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job-title>/<id>.md` using the `Write` tool with full absolute path (intermediate directories are created automatically):

~~~markdown
---
canonical: <story-id>
company: <company>
job_title: <job-title or _general>
jd_source: jds/<job-title>.md   # or null
mapped_at: <today YYYY-MM-DD>
canonical_modified_at_mapping: <canonical's last_modified>
values_aligned: [<the values this story most strongly signals>]
---

## Tailored Variants

### Q: <question>
**Maps to canonical variant:** <variant-id>
**Why this story:** <one-line rationale>
**Tailored Situation:** ...
**Tailored Task:** ...
**Tailored Action:** ...
**Tailored Result:** ...

(repeat per question this canonical answers)
~~~

## Step 8 — Build the question index

Write `$CLAUDE_PROJECT_DIR/<company>/behavioral/mapped-stories/<job-title>/_questions.md` using the `Write` tool:

~~~markdown
---
company: <company>
job_title: <job-title or _general>
mapped_at: <today YYYY-MM-DD>
---

## Classic Behavioral Questions
| Question | Story | Variant |
|---|---|---|
(rows: classic question → which canonical story → which variant)

## Company-Specific Questions
| Value | Question | Story | Variant |
|---|---|---|---|
(rows: value → question → story → variant)

## Coverage Gaps
- No story for: "<question>" → consider /story-add
- ...
~~~

The Coverage Gaps list comes from any classic or company-specific question that has no matching canonical (compare question themes to canonical `themes` and variant `Best for questions like` lines).

## Step 9 — Summary output

Print to the user:
- Number of canonical stories mapped: N.
- Number of mapped files written: M.
- Number of classic questions covered: X / Y.
- Number of company-specific questions covered: P / Q.
- Coverage gaps (the bullet list).
- Suggested next steps:
  - Fill gaps: `/story-add` (add a new canonical) or `/story-add ~/path/to/CV.pdf`.
  - Run a mock: `/mock-behavioral <company> <job-title-or-blank>`.
