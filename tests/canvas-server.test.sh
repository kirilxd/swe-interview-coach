#!/usr/bin/env bash
# Scripted tests for scripts/canvas-server.js. Run from repo root.
# Uses an isolated config dir and port so it never touches real state.
set -u
PORT=19998
export SWE_INTERVIEW_COACH_PORT=$PORT
export SWE_INTERVIEW_COACH_CONFIG_DIR="$(mktemp -d)"
BASE="http://127.0.0.1:$PORT"
PASS=0; FAIL=0
check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); echo "ok   - $1";
  else FAIL=$((FAIL+1)); echo "FAIL - $1 (expected: $2, got: $3)"; fi
}

node scripts/canvas-server.js & SERVER_PID=$!
for i in $(seq 1 20); do curl -sf "$BASE/" >/dev/null 2>&1 && break; sleep 0.1; done

# 1. GET / serves the viewer byte-identically
curl -s -o /tmp/cs-test-viewer.html "$BASE/"
check "GET / matches viewer/canvas.html" \
  "$(shasum < viewer/canvas.html)" "$(shasum < /tmp/cs-test-viewer.html)"

# 2. GET scene returns empty default
check "GET empty scene" '{"elements":[],"appState":{}}' \
  "$(curl -s "$BASE/api/canvas.json")"

# 3. POST round-trip
SCENE='{"elements":[{"id":"t1","type":"rectangle","x":1,"y":2,"width":10,"height":10}],"appState":{}}'
POST_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$SCENE" "$BASE/api/canvas.json")
check "POST returns 200" "200" "$POST_CODE"
check "GET reflects POST" "$SCENE" "$(curl -s "$BASE/api/canvas.json")"

# 4. Scene file written atomically to the config dir (no .tmp leftovers)
check "scene file exists" "yes" "$([ -s "$SWE_INTERVIEW_COACH_CONFIG_DIR/canvas.json" ] && echo yes || echo no)"
check "no tmp leftovers" "0" "$(ls "$SWE_INTERVIEW_COACH_CONFIG_DIR" | grep -c '\.tmp\.' || true)"

# 5. Invalid JSON rejected with 400
BAD_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -d 'not json' "$BASE/api/canvas.json")
check "invalid JSON -> 400" "400" "$BAD_CODE"

# 6. >2MB body rejected (server cap)
python3 -c "import json,sys; sys.stdout.write(json.dumps({'elements':[{'pad':'x'*100} for _ in range(25000)],'appState':{}}))" > /tmp/cs-test-huge.json
HUGE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" --data-binary @/tmp/cs-test-huge.json "$BASE/api/canvas.json" || echo 400)
check ">2MB rejected (not 200)" "no" "$([ "$HUGE_CODE" = "200" ] && echo yes || echo no)"

# 7. 404 for unknown route
check "404 unknown route" "404" "$(curl -s -o /dev/null -w "%{http_code}" "$BASE/nope")"

# 8. Clean shutdown
kill $SERVER_PID
wait $SERVER_PID 2>/dev/null
check "server stopped" "no" "$(kill -0 $SERVER_PID 2>/dev/null && echo yes || echo no)"

rm -rf "$SWE_INTERVIEW_COACH_CONFIG_DIR" /tmp/cs-test-viewer.html /tmp/cs-test-huge.json
echo "---"; echo "pass=$PASS fail=$FAIL"
[ $FAIL -eq 0 ]
