---
id: merge-intervals
title: Merge Intervals
difficulty: medium
patterns: [intervals, sorting]
companies_known_to_ask: [google, meta, bloomberg]
estimated_time: 20m
signature:
  name: merge
  params:
    - {name: intervals, type: "List[List[int]]"}
  returns: "List[List[int]]"
languages: [python]
cases_source: canonical
---

# Merge Intervals

## Problem

Given a list of intervals `[start, end]`, merge all overlapping intervals and return the non-overlapping set covering the same ranges.

- `[[1,3],[2,6],[8,10],[15,18]]` → `[[1,6],[8,10],[15,18]]`.
- Constraints: `1 ≤ len ≤ 10^4`, `start ≤ end`. Touching intervals (`[1,4],[4,5]`) count as overlapping → merge.

## Clarifying questions to expect

- Is the input sorted? (No — sort first.)
- Do touching endpoints merge (`[1,4]` and `[4,5]`)? (Yes here.)
- Can I mutate the input / the interval lists? (Assume yes.)

## Pattern & approach

The **interval sweep** pattern. Sort by start; then walk once, extending the last kept interval whenever the next one starts at or before the last's end, otherwise starting a fresh interval. Sorting is what makes a single linear sweep sufficient.

## Complexity

- Time: **O(n log n)** — dominated by the sort.
- Space: **O(n)** for the output (O(1) auxiliary beyond it, or O(n) if the sort isn't in place).

## Hint ladder

1. If the intervals were sorted by start, how far ahead would you ever have to look?
2. Sort by start, then sweep once.
3. Keep an output list; for each interval, if it starts `≤` the last output's end, extend that end, else append.
4. Extend with `max(last_end, cur_end)` — the next interval can be fully contained.

## Starter stub

```python
from typing import List

def merge(intervals: List[List[int]]) -> List[List[int]]:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def merge(intervals: List[List[int]]) -> List[List[int]]:
    intervals.sort(key=lambda x: x[0])
    out = []
    for s, e in intervals:
        if out and s <= out[-1][1]:
            out[-1][1] = max(out[-1][1], e)
        else:
            out.append([s, e])
    return out
```

## Follow-ups & variations

- "Insert one interval into an already-sorted list" (insert-interval, O(n) no sort).
- "Return the total length covered" / "count overlaps at the busiest point" (sweep-line with +1/-1 events).
- "Meeting rooms II — minimum rooms needed" (min-heap of end times).

## Test cases

```json
{"function": "merge", "unordered": false,
 "cases": [
   {"args": [[[1, 3], [2, 6], [8, 10], [15, 18]]], "expected": [[1, 6], [8, 10], [15, 18]]},
   {"args": [[[1, 4], [4, 5]]], "expected": [[1, 5]]},
   {"args": [[[1, 4]]], "expected": [[1, 4]]},
   {"args": [[[1, 4], [2, 3]]], "expected": [[1, 4]]}
 ]}
```
