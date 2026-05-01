---
id: valid-parentheses
title: Valid Parentheses
difficulty: easy
patterns: [stack]
companies_known_to_ask: [amazon, google, microsoft]
estimated_time: 15m
signature:
  name: isValid
  params:
    - {name: s, type: str}
  returns: bool
languages: [python]
cases_source: canonical
---

# Valid Parentheses

## Problem

Given a string `s` of just `()[]{}`, decide whether the brackets are balanced and correctly nested: every opener has a matching closer of the same type, and they close in the right order.

- `"()[]{}"` → `True`; `"(]"` → `False`; `"([)]"` → `False`; `""` → `True`.
- Constraints: `0 ≤ len(s) ≤ 10^4`, only bracket characters.

## Clarifying questions to expect

- Can the string be empty? (Yes — empty is valid.)
- Only the six bracket characters, or other characters too? (Only brackets here.)
- Do types have to match (a `(` can't be closed by `]`)? (Yes.)

## Pattern & approach

The **stack** pattern. Nesting is last-opened-first-closed — exactly a stack. Push every opener; on a closer, the top of the stack must be the matching opener or it's invalid. A leftover stack at the end means unclosed openers.

## Complexity

- Time: **O(n)** — each character pushed/popped at most once.
- Space: **O(n)** — worst case all openers.

## Hint ladder

1. What data structure models "the most recently opened bracket must close first"?
2. The stack pattern.
3. Push openers; on a closer, check the top is its match and pop.
4. Two failure modes: a closer with the wrong/empty top, and a non-empty stack at the end.

## Starter stub

```python
def isValid(s: str) -> bool:
    # your code here
    pass
```

## Reference solution

```python
def isValid(s: str) -> bool:
    pairs = {')': '(', ']': '[', '}': '{'}
    stack = []
    for ch in s:
        if ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                return False
        else:
            stack.append(ch)
    return not stack
```

## Follow-ups & variations

- "Return the index of the first unmatched bracket."
- "Allow a wildcard `*` that can be `(`, `)`, or empty" (valid-parenthesis-string — greedy low/high range).
- "Longest valid parentheses substring" (DP or stack of indices).

## Test cases

```json
{"function": "isValid", "unordered": false,
 "cases": [
   {"args": ["()"], "expected": true},
   {"args": ["()[]{}"], "expected": true},
   {"args": ["(]"], "expected": false},
   {"args": ["([)]"], "expected": false},
   {"args": [""], "expected": true},
   {"args": ["("], "expected": false}
 ]}
```
