#!/usr/bin/env bash
# Scripted tests for scripts/run-solution.sh + the Python adapter. Run from repo root.
# Uses a temp workspace and a short per-case timeout so the suite is fast.
set -u
export SWE_CODING_TIMEOUT_S=2
WORK="$(mktemp -d)"
RUN="bash scripts/run-solution.sh"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok   - $1";
          else FAIL=$((FAIL+1)); echo "FAIL - $1 (expected: $2, got: $3)"; fi; }
# JSON helpers (python3 is a harness prerequisite anyway).
field() { python3 -c "import sys,json; print(json.load(sys.stdin)$1)"; }
truthy() { python3 -c "import sys,json; print('yes' if json.load(sys.stdin)$1 else 'no')"; }

cat > "$WORK/good.py" <<'EOF'
def twoSum(nums, target):
    seen = {}
    for i, n in enumerate(nums):
        if target - n in seen:
            return [seen[target - n], i]
        seen[n] = i
    return []
EOF
cat > "$WORK/bad.py" <<'EOF'
def twoSum(nums, target):
    return [0, 0]
EOF
cat > "$WORK/loop.py" <<'EOF'
def twoSum(nums, target):
    while True:
        pass
EOF
printf 'def twoSum(nums, target)\n    return []\n' > "$WORK/syntax.py"
cat > "$WORK/nofn.py" <<'EOF'
def somethingElse(a, b):
    return []
EOF
cat > "$WORK/prints.py" <<'EOF'
import sys
def twoSum(nums, target):
    print("debug:", nums, target)
    print("to stderr", file=sys.stderr)
    seen = {}
    for i, n in enumerate(nums):
        if target - n in seen:
            return [seen[target - n], i]
        seen[n] = i
    return []
EOF
cat > "$WORK/cases.json" <<'EOF'
{"function":"twoSum","unordered":false,
 "cases":[{"args":[[2,7,11,15],9],"expected":[0,1]},
          {"args":[[3,2,4],6],"expected":[1,2]}]}
EOF
cat > "$WORK/uno.py" <<'EOF'
def topK(nums, k):
    return [3, 1, 2]
EOF
cat > "$WORK/uno.cases.json" <<'EOF'
{"function":"topK","unordered":true,
 "cases":[{"args":[[1,1,1,2,2,3],3],"expected":[1,2,3]}]}
EOF
cat > "$WORK/sysexit.py" <<'EOF'
import sys
def twoSum(nums, target):
    sys.exit(3)
EOF
cat > "$WORK/importhang.py" <<'EOF'
while True:
    pass
def twoSum(nums, target):
    return [0, 1]
EOF
printf '{"function":"twoSum","unordered":false,"cases":{"oops":"not a list"}}' > "$WORK/badcases.json"

# 1. Correct solution: all pass, exit 0, no harness_error
OUT=$($RUN python "$WORK/good.py" "$WORK/cases.json"); RC=$?
check "good: passed==total" "2" "$(echo "$OUT" | field "['passed']")"
check "good: exit 0" "0" "$RC"
check "good: harness_error null" "None" "$(echo "$OUT" | field "['harness_error']")"

# 2. Buggy solution: partial pass, non-zero exit, no harness_error
OUT=$($RUN python "$WORK/bad.py" "$WORK/cases.json"); RC=$?
check "bad: passed==0" "0" "$(echo "$OUT" | field "['passed']")"
check "bad: exit 1" "1" "$RC"
check "bad: harness_error null" "None" "$(echo "$OUT" | field "['harness_error']")"

# 3. Infinite loop: case 0 times out (proves SIGALRM timeout — no GNU timeout needed)
OUT=$($RUN python "$WORK/loop.py" "$WORK/cases.json"); RC=$?
check "loop: case0 timed_out" "True" "$(echo "$OUT" | field "['cases'][0]['timed_out']")"
check "loop: exit 1" "1" "$RC"

# 4. Syntax error: harness_error set, exit 1
OUT=$($RUN python "$WORK/syntax.py" "$WORK/cases.json"); RC=$?
check "syntax: harness_error set" "yes" "$(echo "$OUT" | truthy "['harness_error']")"
check "syntax: exit 1" "1" "$RC"

# 5. Missing function: harness_error set
OUT=$($RUN python "$WORK/nofn.py" "$WORK/cases.json"); RC=$?
check "missing fn: harness_error set" "yes" "$(echo "$OUT" | truthy "['harness_error']")"

# 6. Unordered comparison passes despite different order
OUT=$($RUN python "$WORK/uno.py" "$WORK/uno.cases.json"); RC=$?
check "unordered: passed==1" "1" "$(echo "$OUT" | field "['passed']")"
check "unordered: exit 0" "0" "$RC"

# 7. Unsupported language: harness_error set, exit 3
OUT=$($RUN ruby "$WORK/good.py" "$WORK/cases.json"); RC=$?
check "unsupported lang: harness_error set" "yes" "$(echo "$OUT" | truthy "['harness_error']")"
check "unsupported lang: exit 3" "3" "$RC"

# 8. Candidate stdout/stderr does not corrupt the JSON result
OUT=$($RUN python "$WORK/prints.py" "$WORK/cases.json"); RC=$?
check "prints: passed==total (stdout isolated)" "2" "$(echo "$OUT" | field "['passed']")"
check "prints: exit 0" "0" "$RC"

# 9. Malformed cases (not a JSON array): structured harness_error, no traceback
OUT=$($RUN python "$WORK/good.py" "$WORK/badcases.json"); RC=$?
check "malformed cases: harness_error set" "yes" "$(echo "$OUT" | truthy "['harness_error']")"

# 10. Candidate sys.exit() is captured as a case error, not a false success
OUT=$($RUN python "$WORK/sysexit.py" "$WORK/cases.json"); RC=$?
check "sys.exit: passed==0 (no false success)" "0" "$(echo "$OUT" | field "['passed']")"
check "sys.exit: exit non-zero" "1" "$RC"
check "sys.exit: still valid JSON (harness_error null)" "None" "$(echo "$OUT" | field "['harness_error']")"

# 11. Infinite loop at IMPORT time is bounded by the timer, not a hang
OUT=$($RUN python "$WORK/importhang.py" "$WORK/cases.json"); RC=$?
check "import hang: harness_error set" "yes" "$(echo "$OUT" | truthy "['harness_error']")"
check "import hang: exit non-zero" "1" "$RC"

rm -rf "$WORK"
echo "---"; echo "pass=$PASS fail=$FAIL"
[ $FAIL -eq 0 ]
