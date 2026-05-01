#!/usr/bin/env bash
# Structural contracts across the coding domain's markdown. Run from repo root.
set -u
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok   - $1";
          else FAIL=$((FAIL+1)); echo "FAIL - $1 (expected: $2, got: $3)"; fi; }

for c in coding-explain practice-coding mock-coding coding-drill debrief-coding coding-import; do
  f="commands/$c.md"
  check "$c: exists" "yes" "$([ -f "$f" ] && echo yes || echo no)"
  check "$c: >=2 frontmatter fences" "yes" "$([ "$(grep -c '^---$' "$f" 2>/dev/null || echo 0)" -ge 2 ] && echo yes || echo no)"
  check "$c: has description" "yes" "$(grep -q '^description:' "$f" 2>/dev/null && echo yes || echo no)"
  check "$c: has argument-hint" "yes" "$(grep -q '^argument-hint:' "$f" 2>/dev/null && echo yes || echo no)"
done

P="agents/coding-interviewer.md"
check "persona: no YAML frontmatter" "0" "$(grep -c '^---$' "$P")"
check "persona: exact yield marker" "1" "$(grep -Fc '[end of session — yielding to coach]' "$P")"
for c in practice-coding mock-coding; do
  check "$c: references persona" "yes" "$(grep -q 'coding-interviewer.md' "commands/$c.md" && echo yes || echo no)"
done
check "mock: references run-solution.sh" "yes" "$(grep -q 'run-solution.sh' commands/mock-coding.md && echo yes || echo no)"
check "mock: routes review-only" "yes" "$(grep -q 'review-only' commands/mock-coding.md && echo yes || echo no)"
check "skill: name present" "yes" "$(grep -q '^name: coding-frameworks' skills/coding-frameworks/SKILL.md && echo yes || echo no)"

for entry in library/coding/*.md; do
  id="$(basename "$entry" .md)"
  check "$id: 9 section headers in order" "yes" "$(python3 - "$entry" <<'PY'
import sys, re
req = ["Problem","Clarifying questions to expect","Pattern & approach","Complexity",
       "Hint ladder","Starter stub","Reference solution","Follow-ups & variations","Test cases"]
heads = re.findall(r'^##\s+(.*?)\s*$', open(sys.argv[1]).read(), re.M)
print("yes" if heads == req else "no")
PY
)"
done
echo "---"; echo "pass=$PASS fail=$FAIL"
[ $FAIL -eq 0 ]
