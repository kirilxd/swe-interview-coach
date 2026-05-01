#!/usr/bin/env bash
# Gate: every bundled coding problem's reference solution must pass 100% of its
# own test cases through the real harness. Run from repo root.
set -u
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok   - $1";
          else FAIL=$((FAIL+1)); echo "FAIL - $1 (expected: $2, got: $3)"; fi; }
WORK="$(mktemp -d)"
shopt -s nullglob
ENTRIES=(library/coding/*.md)
check "library is non-empty" "yes" "$([ ${#ENTRIES[@]} -gt 0 ] && echo yes || echo no)"

for entry in "${ENTRIES[@]}"; do
  id="$(basename "$entry" .md)"
  python3 - "$entry" "$WORK/$id.py" "$WORK/$id.cases.json" <<'PY'
import sys, re
md, sol_out, cases_out = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(md).read()
def section(title):
    m = re.search(r"^##\s+" + re.escape(title) + r"\s*$(.*?)(?=^##\s|\Z)", text, re.S | re.M)
    return m.group(1) if m else ""
def block(section_text, lang):
    m = re.search(r"```" + lang + r"\s*\n(.*?)\n```", section_text, re.S)
    return m.group(1) if m else ""
open(sol_out, "w").write(block(section("Reference solution"), "python"))
open(cases_out, "w").write(block(section("Test cases"), "json"))
PY
  if [ ! -s "$WORK/$id.py" ] || [ ! -s "$WORK/$id.cases.json" ]; then
    check "$id: has Reference solution + Test cases blocks" "yes" "no"; continue
  fi
  OUT=$(bash scripts/run-solution.sh python "$WORK/$id.py" "$WORK/$id.cases.json")
  RATIO=$(echo "$OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('%d/%d'%(d['passed'],d['total']))")
  T=$(echo "$OUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['total'])")
  HE=$(echo "$OUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['harness_error'] or '')")
  check "$id: reference passes all cases${HE:+ (err=$HE)}" "$T/$T" "$RATIO"
done

rm -rf "$WORK"
echo "---"; echo "pass=$PASS fail=$FAIL"
[ $FAIL -eq 0 ]
