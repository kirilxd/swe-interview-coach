---
id: lru-cache
title: LRU Cache
difficulty: medium
patterns: [hashmap, linked-list, design]
companies_known_to_ask: [amazon, google, microsoft, bloomberg]
estimated_time: 35m
signature:
  name: lru_ops
  params:
    - {name: capacity, type: int}
    - {name: calls, type: "List[List]"}
  returns: "List"
languages: [python]
cases_source: canonical
---

# LRU Cache

## Problem

Design a **Least Recently Used (LRU) cache** with a fixed `capacity` supporting:

- `get(key)` — return the value if present, else `-1`. A `get` counts as a use.
- `put(key, value)` — insert/update. If the cache is over capacity, evict the **least recently used** key first. A `put` counts as a use.

Both operations must run in **O(1)** average time.

Because this harness only passes JSON, the function is driven by **op-replay**: `calls` is a list of operations like `[["put",1,1],["get",1], …]`, and `lru_ops(capacity, calls)` returns one result per call — the value for a `get` (or `-1` on a miss), and `null` (Python `None`) for a `put`. The `LRUCache` class and the `lru_ops` driver are provided; **you fill in only `get` and `put`.**

- Example (capacity 2): `put(1,1), put(2,2), get(1)→1, put(3,3) [evicts 2], get(2)→-1, put(4,4) [evicts 1], get(1)→-1, get(3)→3, get(4)→4`
  → results `[null, null, 1, null, -1, null, -1, 3, 4]`.
- Constraints: `1 ≤ capacity ≤ 3000`; up to `~10^5` calls; keys/values are integers.

## Clarifying questions to expect

- Does a `get` count as "using" the key (refreshing its recency)? (Yes.)
- On a `put` to an existing key, does it update the value *and* refresh recency? (Yes — and it does not evict.)
- What does `get` return on a miss? (`-1`.)
- Is the required complexity O(1) for both ops? (Yes — that's the whole challenge; a list scan is too slow.)

## Pattern & approach

You need two structures working together: a **hash map** for O(1) key lookup, and an **ordering structure** that tracks recency and supports O(1) move-to-most-recent and pop-least-recent. The textbook combo is a hash map + **doubly linked list** (head = most recent, tail = least recent). Python shortcuts this with `collections.OrderedDict`, which is exactly a hash map over a doubly linked list:

- `get`: if missing → `-1`; else `move_to_end(key)` (mark most recent) and return the value.
- `put`: if key exists, update and `move_to_end`; insert; if `len > capacity`, `popitem(last=False)` evicts the oldest (front).

## Complexity

- Time: **O(1)** average per `get`/`put` — hash lookup plus constant linked-list splicing.
- Space: **O(capacity)** — at most `capacity` entries retained.

## Hint ladder

1. A plain dict gives O(1) lookup but no notion of "which key is oldest" — what extra structure tracks recency cheaply?
2. Pair the dict with a doubly linked list ordered by recency: most-recent at one end, least-recent at the other.
3. On every `get`/`put`, splice the touched node to the most-recent end; on overflow, drop the node at the least-recent end.
4. In Python, `OrderedDict` *is* that pairing: `move_to_end(key)` refreshes recency, `popitem(last=False)` evicts the oldest.

## Starter stub

```python
from typing import List
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.store = OrderedDict()

    def get(self, key: int) -> int:
        # your code here
        pass

    def put(self, key: int, value: int) -> None:
        # your code here
        pass

def lru_ops(capacity: int, calls: List[list]) -> list:
    cache = LRUCache(capacity)
    results = []
    for call in calls:
        op = call[0]
        if op == "get":
            results.append(cache.get(call[1]))
        elif op == "put":
            cache.put(call[1], call[2])
            results.append(None)
        else:
            results.append(None)
    return results
```

## Reference solution

```python
from typing import List
from collections import OrderedDict

class LRUCache:
    def __init__(self, capacity: int):
        self.capacity = capacity
        self.store = OrderedDict()

    def get(self, key: int) -> int:
        if key not in self.store:
            return -1
        self.store.move_to_end(key)          # mark as most recently used
        return self.store[key]

    def put(self, key: int, value: int) -> None:
        if key in self.store:
            self.store.move_to_end(key)
        self.store[key] = value
        if len(self.store) > self.capacity:
            self.store.popitem(last=False)   # evict least recently used (front)

def lru_ops(capacity: int, calls: List[list]) -> list:
    cache = LRUCache(capacity)
    results = []
    for call in calls:
        op = call[0]
        if op == "get":
            results.append(cache.get(call[1]))
        elif op == "put":
            cache.put(call[1], call[2])
            results.append(None)
        else:
            results.append(None)
    return results
```

## Follow-ups & variations

- "Implement it without `OrderedDict` (raw doubly linked list + dict)." → maintain `head`/`tail` sentinel nodes and splice manually; this is what interviewers usually want to see.
- "Make it thread-safe." → wrap operations in a lock; discuss contention and sharding.
- "LFU cache (least *frequently* used)." → add a frequency dimension: dict of frequency → ordered list of keys.
- "TTL / time-based expiry." → store timestamps and lazily evict expired entries on access.

## Test cases

```json
{"function": "lru_ops", "unordered": false,
 "cases": [
   {"args": [2, [["put", 1, 1], ["put", 2, 2], ["get", 1], ["put", 3, 3], ["get", 2], ["put", 4, 4], ["get", 1], ["get", 3], ["get", 4]]],
    "expected": [null, null, 1, null, -1, null, -1, 3, 4]},
   {"args": [1, [["put", 2, 1], ["get", 2], ["put", 3, 2], ["get", 2], ["get", 3]]],
    "expected": [null, 1, null, -1, 2]},
   {"args": [2, [["get", 0]]],
    "expected": [-1]},
   {"args": [2, [["put", 1, 10], ["put", 1, 20], ["get", 1]]],
    "expected": [null, null, 20]}
 ]}
```
