---
id: kth-largest
title: Kth Largest Element in an Array
difficulty: medium
patterns: [heap, quickselect]
companies_known_to_ask: [amazon, facebook, microsoft, apple]
estimated_time: 25m
signature:
  name: findKthLargest
  params:
    - {name: nums, type: "List[int]"}
    - {name: k, type: int}
  returns: int
languages: [python]
cases_source: canonical
---

# Kth Largest Element in an Array

## Problem

Given an integer array `nums` and an integer `k`, return the **kth largest** element. This is the kth largest in **sorted order**, not the kth distinct value — duplicates count.

- Example: `nums = [3,2,1,5,6,4], k = 2` → `5` (sorted descending: `6, 5, …` → 2nd is 5).
- Example: `nums = [3,2,3,1,2,4,5,5,6], k = 4` → `4` (sorted descending: `6,5,5,4,…` → 4th is 4).
- Constraints: `1 ≤ k ≤ len(nums) ≤ 10^5`; `-10^4 ≤ nums[i] ≤ 10^4`.

## Clarifying questions to expect

- kth largest by sort position, or kth *distinct* value? (By position — duplicates count.)
- Can the array be modified in place? (Quickselect partitions in place; ask if the input must be preserved.)
- Is `k` 1-indexed? (Yes — `k = 1` is the maximum.)
- Do you want better than O(n log n)? (Heap → O(n log k); Quickselect → O(n) average.)

## Pattern & approach

Three tiers of answer:

- **Sort:** sort descending, index `k-1`. O(n log n) — fine but not what they're fishing for.
- **Heap:** keep a size-`k` **min-heap** of the largest elements seen; its root is the kth largest. O(n log k), O(k) space.
- **Quickselect:** the optimal expected-O(n) approach. Partition around a (randomized) pivot like quicksort, but recurse into only the side that contains the target rank. The kth largest sits at index `len-k` in ascending order.

The heap version is shown — clean, no in-place mutation, and the standard "good" interview answer; quickselect is the stretch.

## Complexity

- Time: **O(n log k)** for the heap (Quickselect is O(n) average, O(n²) worst).
- Space: **O(k)** — the heap holds at most k elements.

## Hint ladder

1. Sorting works but is O(n log k) wasteful when k is small — can you avoid fully ordering everything?
2. You only ever need to remember the k biggest values seen so far.
3. A size-`k` **min-heap**: push each number; if the heap exceeds k, pop the smallest. The root is then the kth largest.
4. For O(n) average, use Quickselect: partition around a random pivot and recurse only into the partition holding rank `len-k`.

## Starter stub

```python
from typing import List

def findKthLargest(nums: List[int], k: int) -> int:
    # your code here
    pass
```

## Reference solution

```python
from typing import List
import heapq

def findKthLargest(nums: List[int], k: int) -> int:
    heap = []                      # size-k min-heap of the largest seen so far
    for n in nums:
        heapq.heappush(heap, n)
        if len(heap) > k:
            heapq.heappop(heap)    # evict the smallest; root stays = kth largest
    return heap[0]
```

## Follow-ups & variations

- "Guarantee O(n) worst case." → median-of-medians pivot selection (deterministic Quickselect).
- "Kth *smallest* instead." → min-heap of size k inverted, or partition to index `k-1`.
- "Streaming kth largest (design a class)." → maintain a size-k min-heap across `add()` calls (Kth Largest in a Stream).
- "Kth largest distinct value." → dedupe first (e.g. into a set) before selecting.

## Test cases

```json
{"function": "findKthLargest", "unordered": false,
 "cases": [
   {"args": [[3, 2, 1, 5, 6, 4], 2], "expected": 5},
   {"args": [[3, 2, 3, 1, 2, 4, 5, 5, 6], 4], "expected": 4},
   {"args": [[1], 1], "expected": 1},
   {"args": [[2, 1], 2], "expected": 1},
   {"args": [[7, 7, 7, 7], 3], "expected": 7}
 ]}
```
