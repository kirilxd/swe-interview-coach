---
id: two-sum
title: Two Sum
difficulty: easy
patterns: [hashing, array]
companies_known_to_ask: [amazon, google, meta]
estimated_time: 15m
signature:
  name: twoSum
  params:
    - {name: nums, type: "List[int]"}
    - {name: target, type: int}
  returns: "List[int]"
languages: [python]
cases_source: canonical
---

# Two Sum

## Problem

Given an array of integers `nums` and an integer `target`, return the indices of the two numbers that add up to `target`. Each input has exactly one solution, and you may not use the same element twice. Return the indices in any consistent order (these cases expect ascending).

- Example: `nums = [2,7,11,15], target = 9` → `[0,1]` (because `2 + 7 == 9`).
- Constraints: `2 ≤ len(nums) ≤ 10^4`, values and target fit in 32-bit ints, exactly one valid pair.

## Clarifying questions to expect

- Is there always exactly one solution? (Yes — so no "no answer" case.)
- Can the same index be reused? (No.)
- Are values sorted? (No — if they were, two-pointers gives O(1) space.)
- Can values be negative or duplicated? (Yes to both.)

## Pattern & approach

This is the **hashing / complement-lookup** pattern. The brute force checks every pair — O(n²). The insight: for each value `n`, the partner you need is `target - n`; a hash map of value→index turns "have I already seen the partner?" into an O(1) lookup. One pass, checking before inserting, guarantees you never pair an element with itself.

## Complexity

- Time: **O(n)** — one pass, O(1) hash operations.
- Space: **O(n)** — up to n entries in the map.

## Hint ladder

1. What would make the complement lookup O(1) instead of O(n)?
2. This is the hashing/frequency-map pattern — trade space for time.
3. One pass: store `value → index`; before inserting `n`, check whether `target - n` is already in the map.
4. On a hit, return `[stored_index, current_index]`; otherwise insert and continue.

## Starter stub

```python
from typing import List

def twoSum(nums: List[int], target: int) -> List[int]:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def twoSum(nums: List[int], target: int) -> List[int]:
    seen = {}
    for i, n in enumerate(nums):
        if target - n in seen:
            return [seen[target - n], i]
        seen[n] = i
    return []
```

## Follow-ups & variations

- "What if the array is sorted?" → two-pointers from both ends, O(1) extra space.
- "What if there can be multiple valid pairs?" → collect all, watch for duplicates.
- "Return the values instead of indices" / "three-sum" (sort + two-pointers, O(n²)).

## Test cases

```json
{"function": "twoSum", "unordered": false,
 "cases": [
   {"args": [[2, 7, 11, 15], 9], "expected": [0, 1]},
   {"args": [[3, 2, 4], 6], "expected": [1, 2]},
   {"args": [[3, 3], 6], "expected": [0, 1]}
 ]}
```
