---
id: coin-change
title: Coin Change
difficulty: medium
patterns: [dynamic-programming]
companies_known_to_ask: [amazon, google, uber, bloomberg]
estimated_time: 25m
signature:
  name: coinChange
  params:
    - {name: coins, type: "List[int]"}
    - {name: amount, type: int}
  returns: int
languages: [python]
cases_source: canonical
---

# Coin Change

## Problem

Given a list of distinct positive coin denominations `coins` and a target `amount`, return the **fewest** number of coins that sum to exactly `amount`. You have an unlimited supply of each coin. If the amount cannot be made, return `-1`.

- Example: `coins = [1,2,5], amount = 11` → `3` (`5 + 5 + 1`).
- Example: `coins = [2], amount = 3` → `-1` (odd amount, only even coin).
- Example: `coins = [1], amount = 0` → `0` (zero coins make zero).
- Constraints: `1 ≤ len(coins) ≤ 12`; `1 ≤ coins[i] ≤ 2^31 - 1`; `0 ≤ amount ≤ 10^4`.

## Clarifying questions to expect

- Is the coin supply unlimited (unbounded knapsack) or one of each (0/1)? (Unlimited here.)
- Do I count the number of coins or the number of distinct ways? (Min **count** here; counting ways is a different DP — see follow-ups.)
- What's returned when the amount is unreachable? (`-1`.)
- Can `amount` be 0? (Yes — answer is `0`.)

## Pattern & approach

This is **unbounded-knapsack dynamic programming**. Greedily taking the largest coin fails (`[1,3,4], amount=6`: greedy → `4+1+1`=3, optimal → `3+3`=2), so you need DP. Define `dp[x]` = fewest coins to make `x`. Base case `dp[0] = 0`; everything else starts at "infinity" (unreachable). For each amount `x` from `1..amount`, try every coin `c ≤ x`: `dp[x] = min(dp[x], dp[x-c] + 1)`. The final answer is `dp[amount]`, or `-1` if it's still infinity. Because each coin is reusable, you iterate amounts outward and read smaller already-solved subproblems.

## Complexity

- Time: **O(amount · len(coins))** — one inner loop over coins per amount.
- Space: **O(amount)** — the 1-D DP table.

## Hint ladder

1. Why does grabbing the biggest coin that fits not always work? Build a small counterexample.
2. Optimal substructure: the best way to make `x` is `1 +` the best way to make `x - c` for some coin `c`.
3. Bottom-up DP: `dp[x] = min over coins c of dp[x-c] + 1`, with `dp[0] = 0` and unreachable = ∞.
4. After filling `dp[0..amount]`, return `dp[amount]` if it's finite, else `-1`.

## Starter stub

```python
from typing import List

def coinChange(coins: List[int], amount: int) -> int:
    # your code here
    pass
```

## Reference solution

```python
from typing import List

def coinChange(coins: List[int], amount: int) -> int:
    INF = amount + 1                      # sentinel larger than any real answer
    dp = [0] + [INF] * amount             # dp[x] = fewest coins to make x
    for x in range(1, amount + 1):
        for c in coins:
            if c <= x and dp[x - c] + 1 < dp[x]:
                dp[x] = dp[x - c] + 1
    return dp[amount] if dp[amount] != INF else -1
```

## Follow-ups & variations

- "Count the number of distinct ways to make the amount (Coin Change II)." → DP that loops coins outermost so each combination is counted once: `dp[x] += dp[x-c]`.
- "Each coin can be used at most once (0/1 knapsack)." → iterate the amount loop **downward** per coin.
- "Reconstruct which coins were used." → store a parent/choice array alongside `dp`.
- "Huge amount, few denominations." → BFS over reachable amounts can prune faster than the full table.

## Test cases

```json
{"function": "coinChange", "unordered": false,
 "cases": [
   {"args": [[1, 2, 5], 11], "expected": 3},
   {"args": [[2], 3], "expected": -1},
   {"args": [[1], 0], "expected": 0},
   {"args": [[1, 3, 4], 6], "expected": 2},
   {"args": [[2, 5, 10, 1], 27], "expected": 4}
 ]}
```
