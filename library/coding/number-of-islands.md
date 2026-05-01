---
id: number-of-islands
title: Number of Islands
difficulty: medium
patterns: [bfs, dfs, grid]
companies_known_to_ask: [amazon, google, meta, microsoft]
estimated_time: 25m
signature:
  name: numIslands
  params:
    - {name: grid, type: "List[List[str]]"}
  returns: int
languages: [python]
cases_source: canonical
---

# Number of Islands

## Problem

Given an `m x n` 2-D grid of characters where `"1"` is land and `"0"` is water, return the number of **islands**. An island is a maximal group of `"1"` cells connected **4-directionally** (up/down/left/right — not diagonally). The grid is surrounded by water on all sides.

- Example:
  ```
  1 1 0 0 0
  1 1 0 0 0
  0 0 1 0 0
  0 0 0 1 1
  ```
  → `3` (the top-left block, the lone center cell, the bottom-right pair).
- Constraints: `1 ≤ m, n ≤ 300`; each cell is the character `"0"` or `"1"`.

## Clarifying questions to expect

- Is connectivity 4-directional or 8-directional (do diagonals count)? (Here: 4-directional only.)
- Are the cells characters `"1"`/`"0"` or integers? (Characters in this variant.)
- Am I allowed to mutate the input grid? (Usually yes — sinking visited land is the simplest trick. Ask if it must stay intact.)
- Could the grid be empty? (Guard for it anyway.)

## Pattern & approach

This is the canonical **connected-components on a grid** problem, solved with **flood fill** (DFS or BFS). Scan every cell; when you hit an unvisited `"1"`, increment the island counter and flood-fill the entire connected blob, marking each reached land cell as visited so it is never counted again. Marking is the key idea — without it you'd re-traverse and over-count. The cheapest "visited" marker is to overwrite the land cell with `"0"` in place; if mutation is disallowed, use a separate visited set.

## Complexity

- Time: **O(m·n)** — each cell is visited a constant number of times.
- Space: **O(m·n)** worst case — recursion/queue depth on a grid that is all land.

## Hint ladder

1. How would you avoid counting the same island twice once you've started exploring it?
2. This is connected-components / flood fill — every new unvisited `"1"` starts one island.
3. Outer loop over all cells; on an unvisited `"1"`, bump the counter and run BFS/DFS that sinks every reachable land cell to `"0"`.
4. Sinking visited land in place *is* your visited-marker — the outer scan then naturally skips already-counted islands.

## Starter stub

```python
from typing import List

def numIslands(grid: List[List[str]]) -> int:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def numIslands(grid: List[List[str]]) -> int:
    if not grid or not grid[0]:
        return 0
    rows, cols = len(grid), len(grid[0])

    def sink(r, c):
        # iterative DFS to avoid recursion-depth limits on big grids
        stack = [(r, c)]
        grid[r][c] = "0"
        while stack:
            i, j = stack.pop()
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ni, nj = i + di, j + dj
                if 0 <= ni < rows and 0 <= nj < cols and grid[ni][nj] == "1":
                    grid[ni][nj] = "0"
                    stack.append((ni, nj))

    count = 0
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] == "1":
                count += 1
                sink(r, c)
    return count
```

## Follow-ups & variations

- "Count islands without mutating the grid." → carry a `visited` set of `(r, c)`.
- "Max area of an island." → have the flood fill return the size of the blob, track the max.
- "Number of distinct island shapes." → record each blob's normalized cell offsets and dedupe.
- "Streaming union of cells (Number of Islands II)." → switch to union-find and merge on each added land cell.

## Test cases

```json
{"function": "numIslands", "unordered": false,
 "cases": [
   {"args": [[["1","1","0","0","0"],["1","1","0","0","0"],["0","0","1","0","0"],["0","0","0","1","1"]]], "expected": 3},
   {"args": [[["0","0","0"],["0","0","0"]]], "expected": 0},
   {"args": [[["1"]]], "expected": 1},
   {"args": [[["1","1","1","1","1"]]], "expected": 1},
   {"args": [[["1","0","1","0","1"]]], "expected": 3}
 ]}
```
