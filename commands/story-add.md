---
description: Add a new canonical STAR story to the behavioral story bank. Two modes — cold (you describe an experience from scratch) and CV-grounded (you point at a PDF resume; Claude reads it, suggests candidates, probes the one you pick).
argument-hint: [optional path to PDF resume]
---

You are running `/story-add`. The user wants to add a new canonical story to `$CLAUDE_PROJECT_DIR/behavioral/stories/`.

## Step 1 — Resolve mode

If `$ARGUMENTS` is empty: cold mode.
If `$ARGUMENTS` ends in `.pdf` (case-insensitive): CV-grounded mode; resolve the path (handle `~/` and surrounding quotes if any).
If `$ARGUMENTS` ends in `.docx`: print exactly this message and stop:

> DOCX isn't supported. Convert to PDF and retry — PDF is the more universal résumé format anyway.

If `$ARGUMENTS` is some other format: ask the user to provide a PDF or run cold mode.

## Step 2 — Cold mode

Spawn the `behavioral-story-extractor` subagent with this context:

> Mode: cold. The user wants to add one new STAR story. Begin the extraction interview.

After the subagent returns its draft, jump to Step 4.

## Step 3 — CV-grounded mode

Read the PDF using the `Read` tool. If the read returns very short or empty content (suggesting a scanned-without-OCR PDF or corrupt file), report that and ask the user for an alternative source (paste the text, point at a different file, or fall back to cold mode).

Spawn the `behavioral-story-extractor` subagent with this context:

> Mode: cv-grounded. Here is the user's resume content:
>
> <resume-content>
>
> Begin the extraction interview by listing 3-5 candidate experiences and asking the user to pick one.

After the subagent returns its draft, jump to Step 4.

## Step 4 — Confirm and write

Show the draft to the user verbatim. Ask: "Look right? Anything to revise before I save?"

If user requests revisions, apply them to the draft. Repeat until user confirms.

On confirmation:
1. Compute target path: `$CLAUDE_PROJECT_DIR/behavioral/stories/<id>.md`.
2. If a file already exists at that path, prompt the user with a numbered choice:
   `A file already exists at behavioral/stories/<id>.md. Choose: (1) overwrite, (2) write as <id>-v2, (3) write as <id>-<YYYY-MM-DD>, (4) cancel.`
   Wait for the user's response (1-4) and act accordingly.
3. Use the `Write` tool with the full absolute target path — it creates any missing intermediate directories automatically. No explicit `mkdir` is needed.

## Step 5 — Suggest next step

After write succeeds, print:

> Saved to behavioral/stories/<id>.md. Next: run `/story-map <company>` to tailor this story for a target company.
