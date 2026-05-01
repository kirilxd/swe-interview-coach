# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`swe-interview-coach` is a **Claude Code plugin** (distributed via the `kirilxd-plugins` marketplace) that turns Claude Code into an interview-prep coach. There is **no application runtime and no build step** — the plugin is markdown (commands, agents, skills, a reference library) plus two small scripts that power a local diagramming canvas. "The code" is mostly prompt-as-program: command files are procedural instructions the main Claude session executes.

Three interview domains are implemented and structured identically:
- **Behavioral** (v0.1.0): STAR story bank → company mapping → mock → drill → debrief.
- **System design** (v0.2.0): canonical walkthrough → practice → graded mock → debrief, on a shared local Excalidraw canvas.
- **Coding** (v0.3.0): DSA pattern walkthrough → practice → graded mock → drill → debrief, with a local Python-stdlib test harness that runs the candidate's code; `/coding-import` pulls public LeetCode problems into the library.

`take-home/` is still planned; the data layout already reserves room for it so adding a domain needs no migration.

## Commands

There is no compiler, linter, or package manager — nothing to `npm install`. The only executable code is the canvas scripts.

```bash
# Develop the plugin locally (loads this dir as a plugin)
claude --plugin-dir ~/Documents/swe-interview-coach
# After editing ANY command/agent/skill .md, reload inside the session:
/reload-plugins

# Run the canvas server test suite (uses an isolated port + temp config dir)
bash tests/canvas-server.test.sh        # prints "pass=N fail=M"; exits non-zero on any failure

# Syntax-check the scripts before committing
node --check scripts/canvas-server.js
bash -n scripts/ensure-canvas.sh tests/canvas-server.test.sh

# Manually boot the canvas (rarely needed; commands do this themselves)
bash scripts/ensure-canvas.sh            # opens browser; last line is READY or ERROR: <details>
bash scripts/ensure-canvas.sh --no-browser
```

`tests/canvas-server.test.sh` is the whole test suite (8 checks against `canvas-server.js`). To run a single check, comment out the others — they share one server process started at line 15. The test isolates state via `SWE_INTERVIEW_COACH_PORT` and `SWE_INTERVIEW_COACH_CONFIG_DIR`, so it never touches real canvas state.

## Two path roots — never confuse them

Every command body distinguishes two locations, and mixing them up is the most common way to break things:

- **`${CLAUDE_PLUGIN_ROOT}`** — the installed plugin dir. Read-only bundled assets live here: `library/`, `scripts/`, `agents/`, `skills/`. Commands read from it; nothing user-specific is ever written here.
- **`$CLAUDE_PROJECT_DIR`** — the user's working directory (typically `~/Documents/interview/`). **All user state is written here** as plain markdown: STAR stories, mapped variants, per-company values/JDs, and timestamped session folders. No database, no JSON config, no hidden home dir.

The one exception to "state lives in the project dir": the live canvas scene at `~/.config/swe-interview-coach/canvas.json` (transient working state; final diagrams are exported into the project dir's session folders).

## How a command runs (the orchestration model)

Files in `commands/*.md` are **not passive prompts** — they are numbered `## Step N` procedures the main session executes top to bottom. A typical command: resolves `$ARGUMENTS` → reads bundled assets from `${CLAUDE_PLUGIN_ROOT}` → runs the interview (via one of the two agent patterns below) → post-processes (scores, writes a session file to `$CLAUDE_PROJECT_DIR`). Read `commands/mock-sysdesign.md` for the most complete example (8 steps: boot canvas → resolve topic → guard → reset → interview → rubric → annotate → write).

Command frontmatter is just `description` + `argument-hint`.

### Two agent invocation patterns (this trips people up)

`agents/*.md` files are used in **two structurally different ways** — check the file's header before assuming:

1. **Spawned subagents** — `behavioral-interviewer`, `behavioral-story-extractor`. They have full frontmatter (`name`, `description`, `tools: Read`, `model: sonnet`) and are launched with the Task tool. They are **Read-only by design**: they conduct the interview and *return a draft/transcript as text*; the main session does every file write. This keeps writes in one place and isolates the persona's context.

2. **Embodied personas** — `agents/sysdesign-interviewer.md`. It has **no frontmatter** and states "Not a spawnable subagent." The command `Read`s the file and the **main session role-plays it inline**. This is necessary because the sysdesign interviewer needs Bash (`date +%s` for live timing) and canvas read/write in the main context — capabilities a Read-only subagent lacks.

### The yield-marker handoff

In-character interview portions end with an **exact marker line** that signals the command's post-processing to take over:
- `[end of session — yielding to debrief]` (sysdesign-interviewer)
- `[end of mock — yielding to main session for debrief]` (behavioral-interviewer)
- `[end of session — yielding to coach]` (coding-interviewer)

These strings are a contract between the agent file and the command that reads it. If you change a marker, change it in **both** places.

### Skills are reference knowledge, loaded on demand

`skills/*/SKILL.md` hold the domain frameworks (`behavioral-frameworks`: STAR/SBI/CARL, anti-patterns, follow-ups; `system-design-frameworks`: RESHADED, 4S, capacity-estimation cheatsheet, building blocks, tradeoffs). Commands explicitly load the relevant skill at teaching/scoring time (e.g. mock scoring loads `system-design-frameworks` to ground the 6-axis rubric).

## The sysdesign canvas

A bidirectional Excalidraw sync, deliberately built with **zero dependencies — no MCP, no npm install, Node stdlib only**:

- `scripts/canvas-server.js` — tiny HTTP server on `localhost:9999`. Serves `viewer/canvas.html` and GET/POST `/api/canvas.json` (atomic tmp-then-rename write, 2 MB cap, validates the scene is `{elements:[…], appState:{}}`).
- `scripts/ensure-canvas.sh` — idempotent boot. **Output contract: the LAST line is `READY` or `ERROR: <details>`** — commands parse only that line. Requires `node` + `lsof`. Critically, it locates `canvas-server.js` **relative to itself**, *not* via `${CLAUDE_PLUGIN_ROOT}`, because that variable is substituted into command *text* but is **not exported into spawned-process environments**.
- `viewer/canvas.html` — loads Excalidraw from a pinned esm.sh CDN once, then browser-caches it (only the first load needs internet).
- Sync path: the agent's `Write` to the scene file appears in the browser within ~500 ms; the user's browser edits POST back within ~300 ms. **In scribe mode, always `Read` the scene file immediately before every `Write`** and fold in the user's edits — never write from memory, or you'll clobber their changes.

**Roles shift per mode:** explain → agent draws; practice → agent scribes while the user may also edit; mock → user draws and the agent only observes during the interview, then annotates the saved diagram afterward.

**Graceful degradation is mandatory:** if the canvas can't start, commands print the `ERROR:` line and continue in **text mode** — never abort coaching over canvas trouble.

Test-only env knobs (do not bake into the default contract): `SWE_INTERVIEW_COACH_PORT`, `SWE_INTERVIEW_COACH_CONFIG_DIR`. The real contract is always port 9999 + `~/.config/swe-interview-coach/canvas.json`.

Excalidraw element notes (see the "Element JSON reference" in `agents/sysdesign-interviewer.md`): a labeled box is a **rectangle + a bound text element** that reference each other (rectangle `boundElements` ↔ text `containerId` — both directions required). Bound arrows also need the reciprocal `boundElements` entry on each endpoint, or drag-following breaks. Use stable human-readable ids (`api-gateway`, `users-db`) so the browser diffs cleanly and elements don't flicker across writes.

## The coding harness

The coding domain runs the candidate's code locally with **zero dependencies — no MCP, no npm install, no server; Python stdlib only**:

- `scripts/run-solution.sh <lang> <solution-file> <cases-file>` — the dispatcher. **No server**: it's a one-shot run that dispatches to a per-language adapter and prints the adapter's JSON result (`{passed,total,cases,harness_error}`) to stdout, exit 0 iff all cases pass. Critically, it locates its adapter (`harness/<lang>_runner.py`) **relative to itself**, *not* via `${CLAUDE_PLUGIN_ROOT}` — same gotcha `ensure-canvas.sh` notes: that variable is substituted into command *text* but is **not exported into spawned-process environments**. v0.3.0 ships `python` only; an unknown language emits a `harness_error` and exits non-zero.
- `scripts/harness/python_runner.py` — the Python adapter. Loads the candidate's `solution.py` as a module, calls the case file's named `function` per case under a per-case SIGALRM wall-clock timeout (portable, no GNU `timeout` needed). **Candidate-stdout isolation:** the candidate's own `print`/stderr (debug output) is redirected to a sink and the JSON result is written to the *real* saved stdout, so debug prints can never corrupt the single-line JSON result the command parses.
- **Markdown extraction contract:** each `library/coding/<id>.md` carries a `## Reference solution` section with a ```python fenced block and a `## Test cases` section with a ```json fenced block. `tests/library-coding.test.sh` depends on exactly these headings + fence languages: it extracts both, runs the reference solution through `run-solution.sh`, and gates that every bundled problem passes 100% of its own cases. Changing a heading or fence language breaks that gate — keep them in sync across the library and the test.
- **Graceful degradation:** if `python3` isn't on PATH (or the adapter errors), the command degrades to a read-only review of the candidate's code rather than aborting — same principle as the canvas's text-mode fallback.

Test-only env knob: `SWE_CODING_TIMEOUT_S` overrides the per-case timeout (default 5s).

## The reference library

`library/sysdesign/*.md` are canonical reference designs (8 problems). Frontmatter: `id`, `title`, `difficulty`, `themes`, `companies_known_to_ask`, `estimated_time`. Standard topic-resolution pattern across sysdesign commands: match `$ARGUMENTS` against `library/sysdesign/<arg>.md`; else treat it as a free-form prompt; else list entries grouped by `difficulty` and let the user pick. A library entry loaded as `topic_source` **grounds the interviewer's probes but is never read aloud** to the candidate.

`library/coding/*.md` are canonical reference problems (14 problems). Frontmatter: `id`, `title`, `difficulty`, `patterns`, `companies_known_to_ask`, `estimated_time`, plus a `signature` (function name + params) and `languages`. The coding commands resolve a topic the same way as sysdesign, and additionally check `$CLAUDE_PROJECT_DIR/coding/imported/<arg>.md` so `/coding-import`'ed problems resolve too. Each entry also carries the harness contract above — the `## Reference solution` and `## Test cases` fenced blocks — which the interviewer's probes draw on but never reads aloud.

## Session output convention

Commands write results to `$CLAUDE_PROJECT_DIR` under per-domain, often per-company trees (e.g. `<company>/sysdesign/sessions/`, `behavioral/stories/`). Graded sessions go in a folder named `<YYYY-MM-DD-HHMM>-<command>/` containing `transcript.md` (with a YAML-frontmatter rubric block) plus any canvas exports (`canvas.excalidraw`, `canvas-annotated.excalidraw` in the v2 `{"type":"excalidraw","version":2,...}` envelope). Everything is hand-editable markdown — a user can `vim` any artifact and the plugin still works.

## Notes

- `docs/` (specs + plans under `docs/superpowers/`) is **gitignored** — local-only design history, not shipped.
- When editing a command and its agent/skill together, remember the runtime contracts that span files: the two path roots, the yield markers, and the `ensure-canvas.sh` last-line output. A change on one side usually needs the matching change on the other.
