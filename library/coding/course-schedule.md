---
id: course-schedule
title: Course Schedule
difficulty: medium
patterns: [topological-sort, graph]
companies_known_to_ask: [amazon, google, meta, apple]
estimated_time: 25m
signature:
  name: canFinish
  params:
    - {name: numCourses, type: int}
    - {name: prerequisites, type: "List[List[int]]"}
  returns: bool
languages: [python]
cases_source: canonical
---

# Course Schedule

## Problem

There are `numCourses` courses labeled `0 .. numCourses-1`. Each pair `[a, b]` in `prerequisites` means you must take course `b` **before** course `a`. Return `true` if you can finish all courses (i.e. some valid ordering exists), `false` otherwise.

- Example: `numCourses = 2, prerequisites = [[1,0]]` → `true` (take 0, then 1).
- Example: `numCourses = 2, prerequisites = [[1,0],[0,1]]` → `false` (0 and 1 depend on each other — a cycle).
- Constraints: `1 ≤ numCourses ≤ 2000`; `0 ≤ len(prerequisites) ≤ 5000`; no duplicate edges.

## Clarifying questions to expect

- What does the edge direction mean — does `[a, b]` mean "a before b" or "b before a"? (Here: `b` is a prerequisite of `a`, so edge `b → a`.)
- Can there be duplicate prerequisite pairs or self-loops? (Assume no duplicates; a self-loop `[a,a]` would itself be a cycle.)
- Do I need to return the ordering, or just whether one exists? (Just the boolean here; the ordering variant is Course Schedule II.)

## Pattern & approach

The question "can all courses be finished?" is exactly **"is the prerequisite graph a DAG (acyclic)?"** Build a directed graph (`b → a` for each `[a, b]`). Two standard ways to detect a cycle:

- **Kahn's algorithm (BFS topological sort):** repeatedly remove nodes with in-degree 0. If you can remove all `numCourses` nodes, the graph is acyclic; if some remain, they're stuck in a cycle.
- **DFS with coloring:** white/gray/black states; encountering a gray (in-progress) node means a back edge → cycle.

Kahn's is shown below — it's iterative (no recursion-depth worries) and naturally yields a topological order if you need it.

## Complexity

- Time: **O(V + E)** — each course and prerequisite edge processed once.
- Space: **O(V + E)** — adjacency list plus the in-degree array and queue.

## Hint ladder

1. Reframe it: when is it *impossible* to finish? What structural property of the dependency graph blocks every ordering?
2. "Can finish all courses" ⇔ "the directed prerequisite graph has no cycle" (it's a DAG).
3. Build adjacency `b → a` and an in-degree count; this is topological sort.
4. Kahn's algorithm: queue all in-degree-0 nodes, pop and decrement neighbors, enqueue new zeros. If the number processed equals `numCourses`, no cycle → `true`.

## Starter stub

```python
from typing import List

def canFinish(numCourses: int, prerequisites: List[List[int]]) -> bool:
    # your code here
    pass
```

## Reference solution

```python
from typing import List
from collections import deque

def canFinish(numCourses: int, prerequisites: List[List[int]]) -> bool:
    adj = [[] for _ in range(numCourses)]
    indeg = [0] * numCourses
    for a, b in prerequisites:        # must take b before a  => edge b -> a
        adj[b].append(a)
        indeg[a] += 1

    queue = deque(c for c in range(numCourses) if indeg[c] == 0)
    taken = 0
    while queue:
        course = queue.popleft()
        taken += 1
        for nxt in adj[course]:
            indeg[nxt] -= 1
            if indeg[nxt] == 0:
                queue.append(nxt)

    return taken == numCourses
```

## Follow-ups & variations

- "Return a valid order of courses (Course Schedule II)." → emit nodes in the order Kahn's pops them; empty list if a cycle exists.
- "There may be duplicate prerequisite pairs." → dedupe edges, or accept that in-degrees double-count (use a set per node).
- "Minimum number of semesters to finish (Course Schedule III/IV variants)." → track depth/levels in the BFS.
- "Detect *which* courses are in a cycle." → the unprocessed nodes after Kahn's are exactly the cyclic ones.

## Test cases

```json
{"function": "canFinish", "unordered": false,
 "cases": [
   {"args": [2, [[1, 0]]], "expected": true},
   {"args": [2, [[1, 0], [0, 1]]], "expected": false},
   {"args": [1, []], "expected": true},
   {"args": [4, [[1, 0], [2, 0], [3, 1], [3, 2]]], "expected": true},
   {"args": [3, [[0, 1], [1, 2], [2, 0]]], "expected": false}
 ]}
```
