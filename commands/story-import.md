---
description: Migrate a legacy STAR-stories markdown file into one or more canonical story files in behavioral/stories/. Use once per legacy file; not part of the regular prep loop.
argument-hint: <path-to-legacy-md-file>
---

You are running `/story-import`. This is a one-shot migration tool that converts a legacy STAR-stories markdown file into the canonical schema.

The user's working directory is `$CLAUDE_PROJECT_DIR`. Paths in the command instructions below are relative to it unless prefixed with `~/` or `/`.

## Step 1 — Resolve source file

If the user supplied an argument (`$ARGUMENTS`), treat it as the source path. Resolve `~/` if present.

If no argument, ask the user for the source file path. Suggest scanning `$CLAUDE_PROJECT_DIR` for `*-star-stories.md` and listing matches; let user pick.

If the resolved path doesn't exist or isn't readable: report the error and stop.

## Step 2 — Read the source

Use the `Read` tool on the resolved path. Limit to the file's full length (no offset).

## Step 3 — Parse the source

Identify these sections:

- **Title:** the H1 heading. Use this as the canonical title; slugify to kebab-case for the canonical `id` (e.g., "Acme UI Components Library — Netflix JSF" → strip company-specific suffixes if obvious, then slugify → `acme-ui-library`).
- **Core Facts:** any `## Core Facts` section (or close variant like "Core Facts (memorize these...)").
- **Key Metrics:** any `## Key Metrics` section. Extract bullet items into a flat list for frontmatter `metrics:`. If this section is absent, emit `metrics: []` and continue; do NOT fall back to Step 6.
- **Approaches:** every `## APPROACH X: <Theme>` heading. Slugify `<Theme>` to derive an approach-slug (e.g., "The Platform Builder" → `platform-builder`).
  - **Slugification rules** (apply to both approach-slug and theme-slug for determinism on re-runs):
    1. Lowercase.
    2. Strip leading articles: "the", "a", "an".
    3. Replace whitespace and punctuation (em-dashes, slashes, commas, etc.) with single hyphens.
    4. Collapse consecutive hyphens.
    5. Trim hyphens from edges.
- **Variants:** every `### Q: <question>` heading under an approach. For each:
  - Slugify the question's main theme (the noun-phrase, not the full question) to derive a theme-slug (apply the slugification rules above).
  - Variant id = `<approach-slug>-<theme-slug>` (e.g., `platform-driving-adoption`).
  - Capture the bold-key blocks: `**Situation:**`, `**Task:**`, `**Action:**`, `**Result:**`. Preserve their multi-paragraph content verbatim. If any of the four STAR blocks is absent for a variant, write the field with the value `(not captured — fill in manually)` and include the variant id + missing field in the Step 7 summary's "themes to refine" or a new "gaps to fill" section.

(treat absence of `## APPROACH` headings or `### Q:` headings as the fallback condition described in Step 6; missing `Key Metrics` is NOT a fallback trigger — emit `metrics: []` instead).

Auto-tag themes for frontmatter `themes:` from the union of approach descriptors and variant content (e.g., `[platform, leadership, adoption, dependency-management, feedback-loops]`).

## Step 4 — Detect collisions

Compute target path: `$CLAUDE_PROJECT_DIR/behavioral/stories/<id>.md`.

Check if the file already exists. If yes:
- Read the existing file's frontmatter `id` and compare.
- If match: Prompt the user with a numbered choice:
  `A file already exists at behavioral/stories/<id>.md with matching id. Choose: (1) overwrite it, (2) write as <id>-v2, (3) write as <id>-<YYYY-MM-DD>, (4) cancel.`
  Wait for the user's response (1-4) and act accordingly.
- If id differs but file still exists: very unusual; report and stop.

If multiple canonical stories would be produced (rare for a single source — usually one source = one experience), repeat the collision check per output.

## Step 5 — Write canonical file(s)

Use the `Write` tool with the full absolute target path — it creates any missing intermediate directories automatically. No explicit `mkdir` is needed.

Write each canonical file using this exact structure (use the actual parsed values; the example below shows the shape):

~~~markdown
---
id: acme-ui-library
title: Acme UI Components Library
company_context: Acme (B2B SaaS, booking/ticketing)
role: Frontend Lead
timeline: 2021-12 to 2024-04
themes: [platform, leadership, dependency-management, adoption, feedback-loops]
metrics:
  - QA bounceback rate dropped (Jira state transitions)
  - Sprint velocity improved on UI-heavy features
  - SonarQube duplication metrics dropped
  - DX survey tooling satisfaction improved
last_modified: 2026-05-10
---

## Core Facts
(verbatim from source's Core Facts section)

## Variants

### Variant: platform-driving-adoption
**Approach group:** platform-builder
**Theme:** Driving adoption of a tech change across many teams
**Best for questions like:** "Tell me about a time you drove adoption of a technology change..."

**Situation:** ...
**Task:** ...
**Action:** ...
**Result:** ...

(repeat per variant)
~~~

Set `last_modified` to today's date (YYYY-MM-DD).

For `company_context`, `role`, `timeline`: extract from Core Facts looking for labeled bullet patterns ("Company:", "Role:", "Timeline:", "Period:") or date-range patterns (YYYY-MM to YYYY-MM, YYYY-MM – YYYY-MM, or similar). If a value cannot be confidently extracted from a labeled bullet or recognizable pattern, set the field to `null` and note it in the Step 7 summary so the user knows to fill it in manually.

## Step 6 — Fallback for unparseable sources

If the source file has no `## APPROACH` headings or no `### Q:` headings under approaches, fall back:

- Treat the entire file as one experience.
- Prompt the user: "I see no APPROACH/Q structure. Should I treat this as a single experience with one variant, or can you point me to the variant boundaries by paragraph (e.g., paragraphs 3-7 = variant 1)?"
- Use the user's answer to construct variants. If unclear, write a single variant per Q-style section detected (### or ## under the title), or as a last resort one variant with theme = "general".

## Step 7 — Summary output

After writing, report to the user:
- Files created (full paths).
- Number of variants in each.
- Any auto-tagged themes the user might want to refine.
- Any STAR fields written as `(not captured — fill in manually)`: list by variant id and field name. Skip this bullet if no gaps were found.
- Suggested next step: `/story-map <company>` to map this story for a target company.

## Step 8 — Legacy file

Do NOT modify or move the source file. The legacy file is retained at its original location for reference.
