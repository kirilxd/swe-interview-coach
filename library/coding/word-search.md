---
id: word-search
title: Word Search
difficulty: medium
patterns: [backtracking, grid]
companies_known_to_ask: [amazon, microsoft, bloomberg, facebook]
estimated_time: 30m
signature:
  name: exist
  params:
    - {name: board, type: "List[List[str]]"}
    - {name: word, type: str}
  returns: bool
languages: [python]
cases_source: canonical
---

# Word Search

## Problem

Given an `m x n` grid `board` of characters and a string `word`, return `true` if `word` can be spelled out by a path of **adjacent** cells (horizontally or vertically neighboring), where each cell is used **at most once** per path.

- Example board:
  ```
  A B C E
  S F C S
  A D E E
  ```
  - `"ABCCED"` → `true`
  - `"SEE"` → `true`
  - `"ABCB"` → `false` (the second `B` would reuse the first `B`'s cell — not allowed).
- Constraints: `1 ≤ m, n ≤ 6` (classic); `1 ≤ len(word) ≤ 15`; letters are uppercase/lowercase ASCII.

## Clarifying questions to expect

- Can a cell be reused within the same path? (No — each cell used at most once.)
- Are diagonal moves allowed? (No — only the 4 orthogonal neighbors.)
- Can the path start anywhere? (Yes — any cell whose letter matches `word[0]`.)
- Is matching case-sensitive? (Assume yes unless told otherwise.)

## Pattern & approach

This is **DFS backtracking** over the grid. From every cell that matches the first letter, recurse: at depth `i` you're trying to match `word[i]`. Mark the current cell visited (temporarily overwrite it with a sentinel like `"#"`), explore all four neighbors for `word[i+1]`, then **unmark on the way out** so the cell is available to other paths. Success is reaching `i == len(word)`. The unmark step is the heart of backtracking — without it, branches would falsely block each other.

## Complexity

- Time: **O(m·n·4^L)** worst case, `L = len(word)` — each start cell launches a 4-way branching search of depth `L` (the visited-pruning makes it far less in practice).
- Space: **O(L)** — recursion depth equals the word length (in-place marking uses no extra grid).

## Hint ladder

1. You need to try every possible starting position and explore outward — what search explores one path fully then rewinds?
2. DFS + backtracking: at each step you're matching `word[i]`; recurse into neighbors for `word[i+1]`.
3. Mark the current cell so the path can't reuse it, recurse the 4 neighbors, then **restore** the cell before returning.
4. Base case: if you've matched all letters (`i == len(word)`), return `true`; prune immediately when the cell's letter ≠ `word[i]`.

## Starter stub

```python
from typing import List

def exist(board: List[List[str]], word: str) -> bool:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def exist(board: List[List[str]], word: str) -> bool:
    if not word:
        return True
    if not board or not board[0]:
        return False
    rows, cols = len(board), len(board[0])

    def dfs(r, c, i):
        if i == len(word):
            return True
        if r < 0 or r >= rows or c < 0 or c >= cols or board[r][c] != word[i]:
            return False
        saved = board[r][c]
        board[r][c] = "#"                 # mark visited
        found = (dfs(r + 1, c, i + 1) or dfs(r - 1, c, i + 1)
                 or dfs(r, c + 1, i + 1) or dfs(r, c - 1, i + 1))
        board[r][c] = saved               # backtrack / unmark
        return found

    for r in range(rows):
        for c in range(cols):
            if dfs(r, c, 0):
                return True
    return False
```

## Follow-ups & variations

- "Find *all* words from a dictionary present in the board (Word Search II)." → build a trie of the words and DFS once, pruning by trie edges.
- "Allow cell reuse." → drop the marking; becomes a much larger search (often needs memo on `(cell, index)`).
- "8-directional movement." → add the four diagonal neighbor offsets.
- "Return the path, not just a boolean." → accumulate `(r, c)` coordinates and copy on success.

## Test cases

```json
{"function": "exist", "unordered": false,
 "cases": [
   {"args": [[["A","B","C","E"],["S","F","C","S"],["A","D","E","E"]], "ABCCED"], "expected": true},
   {"args": [[["A","B","C","E"],["S","F","C","S"],["A","D","E","E"]], "SEE"], "expected": true},
   {"args": [[["A","B","C","E"],["S","F","C","S"],["A","D","E","E"]], "ABCB"], "expected": false},
   {"args": [[["A"]], "A"], "expected": true},
   {"args": [[["A","B"],["C","D"]], "ABDC"], "expected": true}
 ]}
```
