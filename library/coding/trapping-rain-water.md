---
id: trapping-rain-water
title: Trapping Rain Water
difficulty: hard
patterns: [two-pointers, monotonic-stack]
companies_known_to_ask: [amazon, google, goldman-sachs, apple]
estimated_time: 35m
signature:
  name: trap
  params:
    - {name: height, type: "List[int]"}
  returns: int
languages: [python]
cases_source: canonical
---

# Trapping Rain Water

## Problem

Given `n` non-negative integers `height` representing an elevation map where the width of each bar is 1, compute how much water it can trap after raining.

- Example: `height = [0,1,0,2,1,0,1,3,2,1,2,1]` → `6`.
- Example: `height = [4,2,0,3,2,5]` → `9`.
- Example: `height = []` → `0`.
- Constraints: `0 ≤ n ≤ 2·10^4`; `0 ≤ height[i] ≤ 10^5`.

## Clarifying questions to expect

- Each bar has width 1, right? (Yes.)
- Can heights be 0, and can the array be empty? (Yes to both — handle the empty case.)
- Do I return the total trapped units, or a per-column breakdown? (Total.)
- Is O(1) extra space expected? (The two-pointer solution achieves it.)

## Pattern & approach

The water sitting above column `i` is `min(maxLeft[i], maxRight[i]) - height[i]` — bounded by the **shorter** of the tallest walls to its left and right. Three approaches:

- **Precompute prefix/suffix maxima:** two passes to fill `leftMax` and `rightMax`, then sum. O(n) time, O(n) space.
- **Two pointers (optimal):** walk `l` and `r` inward, tracking running `leftMax`/`rightMax`. Whichever side has the smaller running max is the binding constraint, so you can safely settle that side's water and advance that pointer. O(n) time, **O(1) space**.
- **Monotonic stack:** maintain a decreasing stack of indices; when a taller bar arrives, pop and fill the bounded basins layer by layer.

The two-pointer version below is the canonical optimal answer.

## Complexity

- Time: **O(n)** — each pointer crosses the array once.
- Space: **O(1)** — only a handful of scalar variables.

## Hint ladder

1. How much water rests on top of a single column? What two values cap it?
2. Water over column `i` = `min(tallest wall to the left, tallest wall to the right) − height[i]` (clamped at 0).
3. Precomputing left-max and right-max arrays gives an O(n)/O(n) solution — correct, but can you drop the arrays?
4. Two pointers from both ends: advance the side with the smaller running max; that side's water is fully determined by its own running max, so settle and move inward.

## Starter stub

```python
from typing import List

def trap(height: List[int]) -> int:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def trap(height: List[int]) -> int:
    if not height:
        return 0
    l, r = 0, len(height) - 1
    left_max, right_max = height[l], height[r]
    total = 0
    while l < r:
        if left_max <= right_max:
            l += 1
            left_max = max(left_max, height[l])
            total += left_max - height[l]   # left_max is the binding wall here
        else:
            r -= 1
            right_max = max(right_max, height[r])
            total += right_max - height[r]
    return total
```

## Follow-ups & variations

- "Solve it with O(n) space using prefix/suffix max arrays." → the precompute approach; good as a warm-up before the two-pointer trick.
- "Explain the monotonic-stack solution." → pop bars to fill horizontal layers when a taller bar appears.
- "Trapping Rain Water II (a 2-D grid)." → BFS/min-heap from the border inward, raising the water level.
- "Return which columns hold the most water." → track per-column contributions during the scan.

## Test cases

```json
{"function": "trap", "unordered": false,
 "cases": [
   {"args": [[0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1]], "expected": 6},
   {"args": [[4, 2, 0, 3, 2, 5]], "expected": 9},
   {"args": [[]], "expected": 0},
   {"args": [[3, 0, 2, 0, 4]], "expected": 7},
   {"args": [[1, 1, 1]], "expected": 0}
 ]}
```
