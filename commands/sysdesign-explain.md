---
description: Canonical senior-engineer walkthrough of a system design. Pulls the library entry and walks through it step-by-step — requirements, estimation, architecture, API, storage, deep dives, curveballs — rendering the architecture progressively on the local Excalidraw canvas (browser tab); falls back to structured markdown when the canvas can't start. Does not save a session file.
argument-hint: <library-id-or-prose>
---

You are running `/sysdesign-explain`.

## Step 0 — Boot the canvas

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/ensure-canvas.sh"` and parse its LAST line:

- `READY` → set `canvas_mode = true`. The script has already opened http://localhost:9999 in the user's browser.
- Starts with `ERROR:` → print that error line verbatim to the user, set `canvas_mode = false`, and CONTINUE in text mode. Never abort coaching over canvas trouble.

(The `SWE_INTERVIEW_COACH_CONFIG_DIR`/`_PORT` env vars are test-only knobs; this command's contract is the default path `~/.config/swe-interview-coach/canvas.json` and port 9999.)

## Step 1 — Resolve the design

Take `$ARGUMENTS` as `design`.

- If empty: glob `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/*.md`, strip the path and `.md` extension to get the available ids, list them, and ask the user to pick one.
- If `${CLAUDE_PLUGIN_ROOT}/library/sysdesign/<design>.md` exists: Read it; hold its frontmatter and sections — they drive the whole walkthrough.
- If it does not exist: present a numbered choice and wait for the answer:

> Design "<design>" not in library. (1) on-demand walkthrough (not canonical — relies on general knowledge; I'll say so) (2) cancel.

## Step 2 — Set expectations

- Canvas mode: tell the user you'll explain in chat AND build the diagram live in their open tab at http://localhost:9999. If the tab looks blank, the Excalidraw library may still be loading from the CDN (first load needs internet) — coaching continues either way.
- Text mode: tell the user they get a structured markdown walkthrough instead.

## Step 3 — Walkthrough (canvas mode)

Follow the library entry's section order: Requirements → Capacity estimation → High-level architecture → API design → Storage choices → Key components & deep dives → Common tradeoffs → Curveballs interviewers throw. (On-demand: follow the same eight sections from general knowledge, and restate up front that this is not a canonical entry.)

For each section:

a. Explain in chat — paraphrase the entry in your own voice; never dump it verbatim.
b. Read the scene file first and fold in any edits the user made in their tab (they sync silently within ~300 ms), then Write the merged cumulative scene — never Write from memory alone. Update the canvas by Writing the FULL cumulative scene to `~/.config/swe-interview-coach/canvas.json` as `{"elements":[…],"appState":{"viewBackgroundColor":"#ffffff"}}`. The browser tab applies it within ~500 ms.

Canvas staging per section:

- High-level architecture → the first batch of boxes (each a rectangle + a bound text label — see the Element JSON reference) and arrows for the core data flow. Lay boxes out left→right in data-flow order with ~220 px horizontal spacing; place deep-dive sub-groups below their parent component.
- API design → one text element listing the endpoints, placed next to the entry-point box.
- Storage choices → update the storage boxes' labels with suffixes like `(KV)`, `(SQL)`, `(cache)` (edit the bound label's `text`).
- Key components & deep dives → small sub-groups of shapes near the relevant component (e.g. a hash-ring sketch beside the partitioner).
- Curveballs → short text annotations near the affected components (e.g. `← celebrity user: split the fan-out`).

Sections without a staging entry (Requirements, Capacity estimation, Common tradeoffs): chat only — skip the canvas Write.

Conventions:

- Stable human-readable element ids (`api-gateway`, `users-db`, `gw-to-db`) — keep ids identical across writes.
- Aim for ≤30 elements; when the scene outgrows that, consolidate rather than drop.
- Element JSON shapes (rectangle / text / arrow, including the reciprocal-binding rule for bound arrows) are documented in `${CLAUDE_PLUGIN_ROOT}/agents/sysdesign-interviewer.md` — Read its "Element JSON reference" section once before your first Write.

Pause briefly between sections so the chat explanation and the canvas update can be absorbed together.

## Step 4 — Walkthrough (text mode)

Produce a structured markdown walkthrough matching the entry's H2s, in the same order as Step 3. Same paraphrase rule — no verbatim dumps. Use ASCII boxes-and-arrows where they help:

```
[Client] → [Gateway] → [App] → [KV]
```

Include the entry's mermaid block verbatim for users with a markdown renderer (library entries only).

## Step 5 — Close

Print:

> Done. Next: /practice-sysdesign <id> to drill it with hints, or /mock-sysdesign <id> for a graded mock.

Omit `<id>` if this was an on-demand walkthrough.

## Step 6 — No session file

The library entry is the canonical artifact; explain saves nothing.

Exception — only if the user explicitly asks to keep the canvas: Read the scene file at `~/.config/swe-interview-coach/canvas.json` and Write the user's chosen path with the Excalidraw v2 envelope `{"type":"excalidraw","version":2,"source":"swe-interview-coach","elements":[…],"appState":{}}` — that file opens on excalidraw.com via drag-drop.
