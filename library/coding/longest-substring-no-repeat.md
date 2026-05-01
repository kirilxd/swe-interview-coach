---
id: longest-substring-no-repeat
title: Longest Substring Without Repeating Characters
difficulty: medium
patterns: [sliding-window, hashing]
companies_known_to_ask: [amazon, bloomberg, adobe]
estimated_time: 25m
signature:
  name: lengthOfLongestSubstring
  params:
    - {name: s, type: str}
  returns: int
languages: [python]
cases_source: canonical
---

# Longest Substring Without Repeating Characters

## Problem

Given a string `s`, return the length of the longest substring that contains no repeated character.

- `"abcabcbb"` → `3` (`"abc"`); `"bbbbb"` → `1`; `"pwwkew"` → `3` (`"wke"`).
- Constraints: `0 ≤ len(s) ≤ 5·10^4`, any unicode characters.

## Clarifying questions to expect

- Substring (contiguous) or subsequence? (Substring.)
- Case-sensitive? (Yes.)
- Return the length or the substring itself? (Length here.)

## Pattern & approach

The **sliding window** pattern. Maintain a window `[start, i]` that holds only distinct characters. As `i` advances, if the character was seen *inside the current window*, jump `start` to just past its previous position. Track the best window width. A hash map of char→last-index lets `start` jump in O(1) instead of shrinking one step at a time.

## Complexity

- Time: **O(n)** — each index advances `i` once and `start` monotonically.
- Space: **O(min(n, alphabet))** for the last-seen map.

## Hint ladder

1. Think of a window over the string that always holds distinct characters.
2. Sliding window with a map of each character's last index.
3. When you hit a repeat that's inside the window, move `start` to `last[ch] + 1`.
4. Guard the "inside the window" check (`last[ch] >= start`) so stale positions outside the window don't shrink it.

## Starter stub

```python
def lengthOfLongestSubstring(s: str) -> int:
    # your code here
    pass
```

## Reference solution

```python
def lengthOfLongestSubstring(s: str) -> int:
    last = {}
    start = 0
    best = 0
    for i, ch in enumerate(s):
        if ch in last and last[ch] >= start:
            start = last[ch] + 1
        last[ch] = i
        best = max(best, i - start + 1)
    return best
```

## Follow-ups & variations

- "Longest substring with at most K distinct characters" (window + count of distinct).
- "Return the substring, not just the length."
- "Smallest window containing all characters of T" (minimum-window-substring — need/have counts).

## Test cases

```json
{"function": "lengthOfLongestSubstring", "unordered": false,
 "cases": [
   {"args": ["abcabcbb"], "expected": 3},
   {"args": ["bbbbb"], "expected": 1},
   {"args": ["pwwkew"], "expected": 3},
   {"args": [""], "expected": 0},
   {"args": ["au"], "expected": 2},
   {"args": ["dvdf"], "expected": 3}
 ]}
```
