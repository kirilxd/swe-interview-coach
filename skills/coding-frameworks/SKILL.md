---
name: coding-frameworks
description: Reference frameworks for coding interviews — the UMPIRE method, a pattern taxonomy (two-pointers, sliding-window, BFS/DFS, backtracking, dynamic-programming, graphs, and more), a Big-O cheatsheet, Python idioms, communication guidance, and anti-patterns. Used by the coding commands (/coding-explain, /practice-coding, /mock-coding, /coding-drill, /debrief-coding) to ground teaching and scoring; not read aloud verbatim.
---

# Coding Frameworks

## UMPIRE method

The default scaffold for a 35-45 minute algorithmic question — the coding analog of RESHADED. Six phases, run top to bottom: **U**nderstand, **M**atch, **P**lan, **I**mplement, **R**eview, **E**valuate. The signal an interviewer scores is the process, not just a passing solution — narrate every phase transition out loud. The single most common failure is jumping straight to Implement; the first three phases are where senior signal lives.

### Understand

- Restate the problem in your own words and get the interviewer to confirm before touching the keyboard.
- Ask the constraint questions that change the algorithm: input size (`n` up to 10? 10^5? 10^9?), value ranges (negatives? overflow?), duplicates, empty/single-element input, sorted-ness, and the return shape (index vs value, in-place vs new, all answers vs one). Then work one tiny example by hand so you and the interviewer share the same notion of "correct".

**Weak:** "Two-sum, got it — I'll loop and check pairs." (Never asked sorted-ness, duplicates, or indices-vs-values.)
**Strong:** "Restating: return the *indices* of the two numbers summing to target. Exactly one solution? Negatives or duplicates? Is `n` up to 10^5? Can I reuse an element? Good — indices, one solution, unsorted, no reuse."

### Match

- Name the pattern this problem resembles before designing anything: "pair summing to a target in a sorted array → two-pointers"; "longest window under a constraint → sliding-window". Recognition is mostly pattern-matching on input shape and asked-for output — say the candidate pattern aloud; being wrong out loud is cheap and invites a hint.

**Weak:** Silently starts writing nested loops with no name for what they're doing.
**Strong:** "This smells like sliding-window: contiguous subarray, longest-under-a-constraint. If the window invariant doesn't hold I'll fall back to prefix-sum + hashmap."

### Plan

- State the approach AND its time/space complexity BEFORE writing code. This is the phase candidates skip and lose the most points on.
- Start from the brute force, name its cost, then state the optimization and its cost — "brute force is O(n²); with a hashmap I get O(n) time, O(n) space". Sketch the data structures and the core loop in words; get a nod before implementing.

**Weak:** Starts typing immediately and discovers the approach is O(n²) only when the interviewer asks about scale.
**Strong:** "Plan: one pass, a hashmap of value → index; for each `x` check if `target - x` was seen. O(n) time, O(n) space. Brute force is O(n²); the hashmap trades space for the inner loop."

### Implement

- Write the plan you just stated — no improvising a different algorithm mid-stream.
- Code in small testable chunks, narrating as you go; use clear names and handle the edge cases you surfaced in Understand as you reach them. If you get stuck, say what you're stuck on rather than going silent — a voiced partial idea is recoverable signal.

**Weak:** Codes in silence for five minutes, then presents a wall of code that doesn't compile.
**Strong:** "I'll set up the hashmap, then the single pass — lookup before insert so I don't match an element with itself…" (typing, narrating, names readable).

### Review

- Dry-run the code by hand on a small input — trace variables line by line, out loud. Don't claim it works; show it.
- Then run it on at least one edge case you identified earlier (empty, single element, duplicates, all-negative, cycle/overflow), and fix bugs you find by reasoning — not by randomly mutating lines until the example passes.

**Weak:** "I think that's right." (No trace, no edge case.)
**Strong:** "Trace `[2,7,11], target 9`: i=0 store 2→0; i=1 need 2, hit → return [0,1]. Edge case `[]` → loop never runs, returns []. Correct."

### Evaluate

- State the final time and space complexity explicitly, separating auxiliary space from output and recursion-stack space. Then name the next optimization or the tradeoff you'd revisit with more time, even if you wouldn't implement it ("O(n) time now; if memory were tight, two-pointers on a sorted copy gives O(1) extra space at O(n log n) time").

**Weak:** "Done." (No complexity, no next step.)
**Strong:** "Final: O(n) time, O(n) space for the map. If the input were pre-sorted, two-pointers gives O(1) extra space at O(n) time. The space-for-time trade is worth it on unsorted input."

## Pattern taxonomy

One section per pattern: recognition cues → a Python template skeleton → complexity → classic problems → pitfalls. Pattern names match the `patterns:` frontmatter in `library/coding/` (e.g. `sliding-window`, `two-pointers`, `dynamic-programming`, `topological-sort`).

### Two-pointers

When you see a **sorted array** and need a pair/triple summing to a target, or you're partitioning/dedup in place, reach for two indices moving toward each other or in tandem.

```python
def two_sum_sorted(a, target):
    lo, hi = 0, len(a) - 1
    while lo < hi:
        s = a[lo] + a[hi]
        if s == target: return [lo, hi]
        lo, hi = (lo + 1, hi) if s < target else (lo, hi - 1)
    return []
```

Complexity: O(n) time, O(1) space. Classic: Two Sum II, 3Sum, Trapping Rain Water (`two-pointers`), Valid Palindrome. Pitfalls: only valid on sorted data (or after an O(n log n) sort, which may dominate); off-by-one at the `lo < hi` boundary; forgetting to skip duplicates in 3Sum.

### Sliding-window

When you see "longest/shortest/count of **contiguous** subarray/substring" under a constraint, grow a window with `right` and shrink from `left` when the invariant breaks.

```python
def longest_no_repeat(s):
    seen, left, best = {}, 0, 0
    for right, c in enumerate(s):
        if seen.get(c, -1) >= left: left = seen[c] + 1   # shrink past dup
        seen[c], best = right, max(best, right - left + 1)
    return best
```

Complexity: O(n) time, O(k) space (k = alphabet/window keys). Classic: Longest Substring Without Repeating Characters (`sliding-window`), Minimum Window Substring, Max Consecutive Ones III. Pitfalls: moving `left` past a stale index (guard `seen[c] >= left`); confusing fixed-size vs variable-size windows.

### Fast-and-slow-pointers

When you need cycle detection, the middle of a list, or the k-th-from-end node in a linked list (or a cycle in a functional sequence), advance two pointers at different speeds.

```python
def has_cycle(head):
    slow = fast = head
    while fast and fast.next:                     # guard before .next.next
        slow, fast = slow.next, fast.next.next
        if slow is fast: return True
    return False
```

Complexity: O(n) time, O(1) space. Classic: Linked List Cycle, Find Cycle Start (Floyd), Middle of the List, Happy Number. Pitfalls: dereferencing `fast.next` without the `fast and fast.next` guard; off-by-one on which pointer is the answer for "middle".

### Hashing / frequency-map

When you need O(1) membership, counting, or grouping-by-key, reach for a `set` or a `dict`/`Counter`. The default tool for "have I seen this" and "how many of each".

```python
from collections import Counter
def top_k_frequent(nums, k):
    return [v for v, _ in Counter(nums).most_common(k)]
```

Complexity: O(n) build; lookups O(1) average, O(n) worst (pathological collisions). Classic: Two Sum (`hashing`), Group Anagrams, Top K Frequent (`heap, hashing`). Pitfalls: assuming O(1) is worst-case; mutating a dict while iterating it; using a list where a set would make membership O(1).

### Prefix-sum

When you see repeated range-sum queries or "subarray summing to k", precompute cumulative sums so any range is one subtraction; pair with a hashmap for the "count subarrays" variant.

```python
def subarray_sum_equals_k(nums, k):
    count, run, seen = 0, 0, {0: 1}   # seed {0:1} for subarrays from index 0
    for x in nums:
        run += x
        count += seen.get(run - k, 0)
        seen[run] = seen.get(run, 0) + 1
    return count
```

Complexity: O(n) time, O(n) space. Classic: Subarray Sum Equals K, Range Sum Query Immutable, Pivot Index. Pitfalls: forgetting the `{0: 1}` seed (misses subarrays starting at index 0); off-by-one on inclusive vs exclusive prefix indices.

### Binary-search

When the search space is **monotonic** — sorted array, or a predicate that flips false→true exactly once — halve it each step. Includes *binary-search-on-the-answer*: when you can cheaply check "is value `x` feasible?" and feasibility is monotonic in `x`, binary-search over the answer range itself.

```python
def lower_bound(a, target):           # first index with a[i] >= target
    lo, hi = 0, len(a)
    while lo < hi:
        mid = (lo + hi) // 2
        if a[mid] < target: lo = mid + 1
        else: hi = mid
    return lo
```

Complexity: O(log n) per search. Classic: Search in Rotated Sorted Array (`binary-search`), Koko Eating Bananas (search-on-answer), Find Minimum in Rotated Array. Pitfalls: inconsistent interval convention (`[lo, hi]` vs `[lo, hi)`) causing infinite loops; wrong half kept on the rotated/duplicate case; computing `mid` after the loop instead of `lo`.

### Linked-list manipulation

When you splice, reverse, or merge nodes, use a **dummy/sentinel** head so the first node needs no special case, and rewire pointers carefully.

```python
def reverse_list(head):
    prev, cur = None, head
    while cur:
        cur.next, prev, cur = prev, cur, cur.next   # rewire, then advance both
    return prev
```

Complexity: O(n) time, O(1) space (iterative). Classic: Reverse Linked List (`linked-list`), Merge Two Sorted Lists, Remove Nth From End, Reorder List. Pitfalls: losing the rest of the list by reassigning `next` before saving it; returning `dummy` instead of `dummy.next`; recursion stack making "O(1) space" actually O(n).

### Stack & monotonic-stack

When you see matching/nesting (parentheses, undo) reach for a plain stack. When you need "next greater/smaller element" or to bound a histogram, use a **monotonic stack** that pops while the invariant breaks.

```python
def daily_temperatures(t):
    res, stack = [0] * len(t), []     # stack holds indices, temps decreasing
    for i, temp in enumerate(t):
        while stack and t[stack[-1]] < temp:
            j = stack.pop(); res[j] = i - j
        stack.append(i)
    return res
```

Complexity: O(n) time (each index pushed/popped once), O(n) space. Classic: Valid Parentheses (`stack`), Daily Temperatures, Largest Rectangle in Histogram, Trapping Rain Water (`monotonic-stack`). Pitfalls: pushing values when you need indices (or vice versa); wrong strict/non-strict comparison admitting equal elements incorrectly.

### BFS

When you need the **shortest path in an unweighted graph/grid** or level-order traversal, use a queue and expand frontier by frontier.

```python
from collections import deque
def bfs_shortest(start, goal, neighbors):
    q, seen = deque([(start, 0)]), {start}
    while q:
        node, d = q.popleft()
        if node == goal: return d
        for nxt in neighbors(node):
            if nxt not in seen:                   # mark at enqueue, not dequeue
                seen.add(nxt); q.append((nxt, d + 1))
    return -1
```

Complexity: O(V + E) time, O(V) space for the queue/visited set. Classic: Number of Islands (`bfs, dfs, grid`), Word Ladder, Rotting Oranges. Pitfalls: marking visited at dequeue instead of enqueue (nodes enqueued many times); using a list `.pop(0)` (O(n)) instead of `deque.popleft()` (O(1)).

### DFS

When you need to explore connected components, tree paths, or all reachable nodes (and shortest-path is irrelevant), recurse or use an explicit stack; mark visited to avoid revisiting.

```python
def num_islands(grid):
    R, C = len(grid), len(grid[0])
    def dfs(r, c):
        if not (0 <= r < R and 0 <= c < C) or grid[r][c] != '1': return
        grid[r][c] = '0'                          # mark visited in place
        for dr, dc in ((1,0),(-1,0),(0,1),(0,-1)): dfs(r + dr, c + dc)
    return sum(dfs(r, c) or 1 for r in range(R) for c in range(C) if grid[r][c] == '1')
```

Complexity: O(V + E) time; O(V) recursion-stack space (grid depth up to `rows*cols`). Classic: Number of Islands (`dfs`), Clone Graph, Course Schedule cycle-check. Pitfalls: missing the visited mark → infinite recursion on cycles; recursion depth exceeding Python's ~1000 default limit on large grids.

### Backtracking

When you must enumerate all combinations/permutations/subsets or fill a board under constraints, build a partial solution, recurse, and **undo the choice** on the way back up.

```python
def subsets(nums):
    res = []
    def bt(start, path):
        res.append(path[:])                       # record (copy, don't alias)
        for i in range(start, len(nums)):
            path.append(nums[i])                  # choose
            bt(i + 1, path)
            path.pop()                            # undo
    bt(0, [])
    return res
```

Complexity: exponential — O(2^n) subsets, O(n!) permutations — times O(n) to copy each. Classic: Subsets, Permutations, Word Search (`backtracking, grid`), N-Queens, Combination Sum. Pitfalls: appending `path` instead of `path[:]` (all results alias one list); forgetting the `path.pop()` undo; no pruning so feasible branches aren't cut early.

### Dynamic-programming

When the problem has **overlapping subproblems and optimal substructure** — "count ways", "min/max cost", "longest/shortest" with choices — define a state and a transition, then fill a table (or memoize). 1-D state (one axis) vs 2-D/grid state (two axes — strings, grids, knapsack capacity):

```python
def coin_change(coins, amount):                  # 1-D: dp[a] = fewest coins for a
    dp = [0] + [float('inf')] * amount
    for a in range(1, amount + 1):
        dp[a] = min((dp[a - c] + 1 for c in coins if c <= a), default=float('inf'))
    return dp[amount] if dp[amount] != float('inf') else -1

def unique_paths(m, n):                           # 2-D: dp[r][c] from top + from left
    dp = [[1] * n for _ in range(m)]
    for r in range(1, m):
        for c in range(1, n): dp[r][c] = dp[r-1][c] + dp[r][c-1]
    return dp[-1][-1]
```

Complexity: typically O(states × transition) — coin change O(amount × coins); grid DP O(m × n). Classic: Coin Change (`dynamic-programming`), Longest Common Subsequence, Edit Distance, 0/1 Knapsack, House Robber. Pitfalls: wrong base case / off-by-one on table size; iterating dimensions in an order that reads a not-yet-computed cell; missing that O(n) space suffices when only the previous row is needed.

### Greedy

When a **locally optimal choice provably leads to the global optimum** (and you can argue why), sort or scan once and commit to the best step each time — no backtracking.

```python
def jump_game(nums):                 # can you reach the last index?
    reach = 0
    for i, n in enumerate(nums):
        if i > reach: return False
        reach = max(reach, i + n)
    return True
```

Complexity: often O(n) or O(n log n) with a sort. Classic: Jump Game, Activity Selection / Non-overlapping Intervals, Gas Station, Huffman coding. Pitfalls: assuming greedy works without an exchange-argument proof (many problems need DP instead); choosing the wrong sort key.

### Heap / top-k

When you need the k largest/smallest, a running median, or repeated "min/max so far" with insertions, use a heap. For top-k, keep a **size-k heap** rather than sorting everything.

```python
import heapq
def k_largest(nums, k):
    return heapq.nlargest(k, nums)   # or maintain a size-k min-heap manually
```

Complexity: push/pop O(log n); building a size-k heap over n items is O(n log k); `heapify` a list is O(n). Classic: Kth Largest Element (`heap, quickselect`), Top K Frequent (`heap, hashing`), Merge K Sorted Lists, Find Median From Data Stream. Pitfalls: `heapq` is a **min-heap only** — negate values for a max-heap; sorting fully (O(n log n)) when a size-k heap (O(n log k)) suffices.

### Intervals (merge-and-sweep)

When you see overlapping ranges — merging, inserting, counting concurrent events — **sort by start**, then sweep, comparing each interval to the last kept one.

```python
def merge(intervals):
    intervals.sort(key=lambda x: x[0])            # sort by start
    out = [intervals[0]]
    for s, e in intervals[1:]:
        if s <= out[-1][1]: out[-1][1] = max(out[-1][1], e)   # overlap → extend
        else: out.append([s, e])
    return out
```

Complexity: O(n log n) for the sort, O(n) sweep. Classic: Merge Intervals (`intervals, sorting`), Insert Interval, Meeting Rooms II (min rooms via a sweep / min-heap of end times). Pitfalls: sorting by end when you needed start (or vice versa); wrong overlap test (`<` vs `<=` decides whether touching intervals merge).

### Graph: topological sort (Kahn) and union-find

When you order tasks under dependencies (a DAG), use **Kahn's algorithm**: repeatedly emit zero-in-degree nodes. When you query/merge connected components incrementally, use **union-find** (disjoint-set) with path compression + union by rank.

```python
from collections import deque
def topo_sort(n, edges):                          # edges as (u -> v) pairs
    indeg, adj = [0] * n, [[] for _ in range(n)]
    for u, v in edges: adj[u].append(v); indeg[v] += 1
    q, order = deque(i for i in range(n) if not indeg[i]), []
    while q:
        u = q.popleft(); order.append(u)
        for v in adj[u]:
            indeg[v] -= 1
            if not indeg[v]: q.append(v)
    return order if len(order) == n else []       # [] means a cycle exists
```

Complexity: Kahn O(V + E); union-find near O(α(n)) ≈ O(1) amortized per op with both optimizations. Classic: Course Schedule (`topological-sort, graph`), Alien Dictionary, Number of Connected Components, Redundant Connection. Pitfalls: not detecting a cycle (`len(order) < n`); union-find without path compression degrading to O(n) chains; confusing edge direction.

### Trie

When you do many **prefix** queries over a set of strings — autocomplete, word-dictionary search, prefix counting — build a trie of character-keyed children.

```python
class Trie:                                       # node = dict of char -> child; '$' ends a word
    def __init__(self): self.root = {}
    def insert(self, word):
        node = self.root
        for ch in word: node = node.setdefault(ch, {})
        node['$'] = True
    def starts_with(self, prefix):                # full-word search: also check '$' in node
        node = self.root
        for ch in prefix:
            if ch not in node: return False
            node = node[ch]
        return True
```

Complexity: insert/search O(L) for word length L; space O(total characters). Classic: Implement Trie, Word Search II (trie + backtracking), Replace Words, Design Add and Search Words. Pitfalls: forgetting the end-of-word marker (so `"app"` matches when only `"apple"` was inserted); reusing children dicts across nodes.

### Bit-manipulation

When you toggle/test flags, build subset bitmasks, or exploit XOR's self-cancelling property, work directly on bits.

```python
def single_number(nums):             # every element appears twice but one
    x = 0
    for n in nums:
        x ^= n                       # pairs cancel; the loner remains
    return x
```

Complexity: O(n) time, O(1) space here; bitmask-DP is O(2^n × n). Classic: Single Number, Number of 1 Bits, Counting Bits, Subsets (via bitmask), Sum of Two Integers. Pitfalls: Python ints are arbitrary-precision so there's no fixed-width overflow — mask with `& 0xFFFFFFFF` when emulating 32-bit; confusing `&`/`|`/`^`; operator precedence (bitwise binds looser than comparison — parenthesize).

## Big-O cheatsheet

This is a factual reference; keep the numbers right.

### Reading complexity off code

- Sequential statements add: O(a) + O(b) → O(a + b), dominated by the larger.
- Nested loops over the same `n` multiply: two nested → O(n²), three → O(n³).
- Halving the search space each step → O(log n); halving inside a loop over n → O(n log n).
- Recursion: time ≈ (number of nodes in the call tree) × (work per node). A branching factor of 2 and depth `n` is O(2^n); divide-and-conquer that halves and does linear merge work (`T(n) = 2T(n/2) + O(n)`) is O(n log n).

### Standard operation costs

| Operation | Time |
|---|---|
| Comparison sort (Timsort, mergesort, heapsort) | O(n log n) |
| Hash insert / lookup / membership | O(1) average, O(n) worst case |
| Heap push / pop | O(log n) |
| `heapify` an existing list | O(n) |
| Binary search / balanced-BST insert & search | O(log n) |
| Array index access | O(1); unsorted search O(n) |
| `list.insert(0, x)` / `list.pop(0)` (shifts all) | O(n) |
| `deque.appendleft` / `popleft` | O(1) |

### Space accounting

- Distinguish **auxiliary** space (extra structures you allocate) from output space and from the input.
- The **recursion stack counts as space**: a recursion of depth `n` is O(n) space even if each frame is O(1) — an "in-place" recursive reversal is still O(n). An "O(1) space" claim must survive this test: iterative two-pointers is genuinely O(1); the recursive version is O(n).
- A size-k auxiliary structure (top-k heap, fixed window) is O(k) space regardless of n.

### Amortized analysis

- Dynamic-array append is **O(1) amortized**: most appends are O(1), the occasional resize copies all n elements (O(n)), but the cost averaged over a sequence of appends is constant.
- Union-find with path compression + union by rank is O(α(n)) amortized per operation — α (inverse Ackermann) is ≤ 4 for any practical n, so effectively O(1).
- Amortized ≠ average: amortized is a worst-case guarantee over a *sequence* of operations, not a probabilistic claim about one.

## Python idioms

Language-first guidance — the standard-library reach-for in an interview, with *when* to use each.

- **`collections.Counter`** — when you need a frequency map; `Counter(s)` tallies in one pass and `.most_common(k)` gives top-k. Reach for it any time you'd otherwise write `d[x] = d.get(x, 0) + 1`.
- **`collections.defaultdict`** — when building an adjacency list or grouping, so missing keys auto-initialize: `defaultdict(list)` for graphs, `defaultdict(int)` for counts. Avoids `KeyError` boilerplate.
- **`heapq`** — when you need a priority queue / top-k / streaming min. Note it's a **min-heap only**: push `-x` (or `(-priority, item)` tuples) to get max-heap behavior. `heapify(lst)` turns a list into a heap in O(n).
- **`bisect`** — when maintaining a sorted list with fast inserts/queries: `bisect_left(a, x)` finds the insertion point in O(log n); `insort(a, x)` inserts keeping order. Reach for it for "count elements < x" or sorted-stream problems.
- **`collections.deque`** — when you need a queue (BFS) or a sliding-window deque. Use it over a plain list whenever you pop from the front: `popleft()`/`appendleft()` are O(1), `list.pop(0)` is O(n).
- **Comprehensions** — when transforming/filtering a sequence: `[f(x) for x in xs if pred(x)]` is faster and clearer than an append loop. Set/dict comprehensions (`{x for x in xs}`) build sets/maps inline.
- **`enumerate` / `zip`** — `enumerate(xs)` when you need index and value together (no manual counter); `zip(a, b)` to walk two sequences in lockstep (pairwise comparisons, building dicts from key/value lists).
- **Dummy `ListNode` sentinels** — when building or splicing a linked list, start with `dummy = ListNode(0); tail = dummy` so the head needs no special case, then return `dummy.next`.
- **Tuple-unpacking swaps** — `a, b = b, a` to swap without a temp; `prev, cur = cur, nxt` to advance multiple pointers atomically (no clobbering). The idiomatic way to step linked-list and DP pointers.
- **`float('inf')` / `float('-inf')` sentinels** — when initializing a running min/max or an unreachable DP cell, so the first real value always wins the comparison without a special first-iteration case.
- **`set` for seen-tracking** — when you need O(1) membership: visited nodes in BFS/DFS, dedup, cycle detection. Reach for a set the moment you find yourself scanning a list to check "have I seen this".

## Communication

The transcript is scored, not just the final code — narrate throughout.

- **State approach and complexity before coding.** Say the algorithm and its time/space in the Plan phase; never let the interviewer discover the approach by reading your code.
- **Narrate tradeoffs as you choose.** "I'll use a hashmap — that's O(n) space but turns the inner loop into an O(1) lookup" beats silently picking a structure.
- **Test out loud.** In Review, dry-run a concrete input and an edge case aloud, tracing variables — demonstrate correctness instead of asserting it.
- **Announce final complexity.** Close every solution by stating its time and space and naming the next optimization, so the interviewer hears the loop close.
- When stuck, **think out loud** — voice the partial idea and the obstacle; a hint usually follows. Silence reads as being lost.

## Anti-patterns

- **Coding before clarifying constraints** — typing before asking about input size, value ranges, duplicates, empties, and return shape; the algorithm often hinges on an unasked question.
- **Never stating complexity** — solving without ever saying the time/space cost, so the interviewer can't tell you understand what you wrote.
- **Never testing** — declaring "done" with no dry-run; bugs that a 30-second trace would catch sink the solution.
- **Premature optimization** — reaching for a clever O(n) trick before a correct brute force exists; a working O(n²) you can optimize beats a broken O(n) you can't finish.
- **Silent debugging** — mutating lines at random until the example passes, instead of reasoning about why it's wrong; the interviewer can't follow and you usually re-break it.
- **Unacknowledged brute force** — presenting the naive solution as if it were the intended one, with no "this is my O(n²) baseline; here's how I'd improve it".
- **Neglecting edge cases** — no handling for empty, single-element, duplicates, negatives, integer overflow, or cycles; these are the inputs interviewers test first.
- **Freezing silently** — going quiet when stuck instead of voicing a partial approach and the specific obstacle; an interviewer can hint on a spoken idea but not on silence.
