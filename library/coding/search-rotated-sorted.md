---
id: search-rotated-sorted
title: Search in Rotated Sorted Array
difficulty: medium
patterns: [binary-search]
companies_known_to_ask: [meta, amazon, microsoft]
estimated_time: 25m
signature:
  name: search
  params:
    - {name: nums, type: "List[int]"}
    - {name: target, type: int}
  returns: int
languages: [python]
cases_source: canonical
---

# Search in Rotated Sorted Array

## Problem

A sorted ascending array of distinct integers is rotated at an unknown pivot (e.g. `[0,1,2,4,5,6,7]` → `[4,5,6,7,0,1,2]`). Given `target`, return its index or `-1`. Must run in `O(log n)`.

- `[4,5,6,7,0,1,2], target=0` → `4`; `target=3` → `-1`.
- Constraints: `1 ≤ len ≤ 5000`, distinct values.

## Clarifying questions to expect

- Are values distinct? (Yes — duplicates change the worst case to O(n).)
- Is the rotation amount known? (No.)
- Must it be O(log n), or is O(n) acceptable? (O(log n) is the point.)

## Pattern & approach

**Binary search** with a twist. At any `mid`, at least one half (`lo..mid` or `mid..hi`) is sorted — compare `nums[lo]` to `nums[mid]` to find which. If the target lies within the sorted half's range, recurse there; otherwise recurse the other half. Each step still halves the search space, preserving O(log n).

## Complexity

- Time: **O(log n)**.
- Space: **O(1)** iterative.

## Hint ladder

1. Plain binary search breaks because the array isn't fully sorted — but how much of it *is* sorted at any midpoint?
2. One side of `mid` is always sorted. Detect which by comparing `nums[lo]` and `nums[mid]`.
3. If the target is within the sorted side's value range, search there; else search the other side.
4. Use half-open comparisons carefully (`nums[lo] <= target < nums[mid]`) to place the target correctly.

## Starter stub

```python
from typing import List

def search(nums: List[int], target: int) -> int:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def search(nums: List[int], target: int) -> int:
    lo, hi = 0, len(nums) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if nums[mid] == target:
            return mid
        if nums[lo] <= nums[mid]:            # left half sorted
            if nums[lo] <= target < nums[mid]:
                hi = mid - 1
            else:
                lo = mid + 1
        else:                                # right half sorted
            if nums[mid] < target <= nums[hi]:
                lo = mid + 1
            else:
                hi = mid - 1
    return -1
```

## Follow-ups & variations

- "What if duplicates are allowed?" → worst case O(n); skip equal `nums[lo]==nums[mid]==nums[hi]`.
- "Find the minimum (the rotation pivot)" (find-min-in-rotated).
- "Find how many times it was rotated" (= index of the minimum).

## Test cases

```json
{"function": "search", "unordered": false,
 "cases": [
   {"args": [[4, 5, 6, 7, 0, 1, 2], 0], "expected": 4},
   {"args": [[4, 5, 6, 7, 0, 1, 2], 3], "expected": -1},
   {"args": [[1], 0], "expected": -1},
   {"args": [[1], 1], "expected": 0},
   {"args": [[5, 1, 3], 5], "expected": 0}
 ]}
```
