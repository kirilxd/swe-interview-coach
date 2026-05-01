---
id: top-k-frequent
title: Top K Frequent Elements
difficulty: medium
patterns: [heap, hashing]
companies_known_to_ask: [amazon, facebook, google, yelp]
estimated_time: 20m
signature:
  name: topKFrequent
  params:
    - {name: nums, type: "List[int]"}
    - {name: k, type: int}
  returns: "List[int]"
languages: [python]
cases_source: canonical
---

# Top K Frequent Elements

## Problem

Given an integer array `nums` and an integer `k`, return the `k` most frequent elements. The answer may be returned in **any order** (these cases compare unordered). It is guaranteed the answer is unique.

- Example: `nums = [1,1,1,2,2,3], k = 2` → `[1,2]` (1 appears 3×, 2 appears 2×).
- Example: `nums = [1], k = 1` → `[1]`.
- Constraints: `1 ≤ len(nums) ≤ 10^5`; `k` is between 1 and the number of distinct elements; the top-k frequencies are unambiguous.

## Clarifying questions to expect

- Does the output order matter? (No — any order; the answer set is unique.)
- Is `k` always ≤ number of distinct values? (Yes, guaranteed.)
- Are ties possible at the cutoff? (The problem guarantees the answer is unique, so no boundary ambiguity.)
- Better than O(n log n)? (Yes — bucket sort gives O(n); heap gives O(n log k).)

## Pattern & approach

Two layers: a **frequency hash map** (count each value), then **select the k largest counts**. Options for the selection step:

- **Heap:** push `(count, value)` into a size-`k` min-heap; pop the smallest whenever it exceeds `k`. O(n log k).
- **Bucket sort:** index an array by frequency (`buckets[f]` holds all values with count `f`, `0 ≤ f ≤ n`), then walk from the highest bucket down collecting `k` values. O(n) — frequencies are bounded by `n`.

The heap version is shown below: simple, idiomatic with `heapq.nlargest`, and plenty fast for interview constraints.

## Complexity

- Time: **O(n log k)** — counting is O(n); `nlargest(k, …)` over `d` distinct items is O(d log k). (Bucket sort drops this to O(n).)
- Space: **O(n)** — the frequency map (up to n distinct keys).

## Hint ladder

1. You need frequencies first — what structure gives you each element's count in one pass?
2. After counting, the task is "k largest by count" — a classic selection problem (heap or bucket sort).
3. A size-`k` min-heap keyed on count keeps only the current top-k as you stream the distinct elements.
4. Or, since counts are bounded by `n`, bucket values by frequency and read buckets high-to-low until you've collected `k` — O(n), no heap needed.

## Starter stub

```python
from typing import List

def topKFrequent(nums: List[int], k: int) -> List[int]:
    # your code here
    pass
```

## Reference solution

```python
from typing import List
from collections import Counter
import heapq

def topKFrequent(nums: List[int], k: int) -> List[int]:
    counts = Counter(nums)
    # nlargest returns the k (value) keys with the highest counts
    return heapq.nlargest(k, counts.keys(), key=counts.get)
```

## Follow-ups & variations

- "Achieve O(n) time." → bucket sort by frequency (`buckets[f]`), scan from highest frequency.
- "Top k frequent *words*, ties broken alphabetically." → heap with a composite key `(-count, word)`.
- "Streaming data, can't store everything." → approximate counters (Count-Min Sketch) + a heap of heavy hitters.
- "k can equal the number of distinct elements." → just return all distinct values.

## Test cases

```json
{"function": "topKFrequent", "unordered": true,
 "cases": [
   {"args": [[1, 1, 1, 2, 2, 3], 2], "expected": [1, 2]},
   {"args": [[1], 1], "expected": [1]},
   {"args": [[4, 4, 4, 5, 5, 6, 7, 7, 7, 7], 2], "expected": [7, 4]},
   {"args": [[-1, -1, -2, -2, -2, 3], 1], "expected": [-2]}
 ]}
```
