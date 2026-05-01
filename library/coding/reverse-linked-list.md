---
id: reverse-linked-list
title: Reverse Linked List
difficulty: easy
patterns: [linked-list]
companies_known_to_ask: [amazon, microsoft, apple, adobe]
estimated_time: 15m
signature:
  name: reverse_linked_list
  params:
    - {name: values, type: "List[int]"}
  returns: "List[int]"
languages: [python]
cases_source: canonical
---

# Reverse Linked List

## Problem

Reverse a singly linked list and return the reversed list. In LeetCode the input/output are `ListNode` objects, but this harness passes JSON, so the function receives the node values as a list and returns the reversed values as a list — the scaffolding (`_build`/`_dump`) converts between the two and is provided for you. **You only fill in `reverseList`, which operates on real `ListNode`s.**

- Example: `[1,2,3,4,5]` → `[5,4,3,2,1]`.
- Example: `[]` → `[]` (empty list).
- Example: `[1]` → `[1]` (single node).
- Constraints: `0 ≤ number of nodes ≤ 5000`; `-5000 ≤ Node.val ≤ 5000`.

## Clarifying questions to expect

- Singly or doubly linked? (Singly here.)
- Reverse in place (rewire pointers) or build a new list? (In place — O(1) extra space is the point.)
- Can the list be empty or a single node? (Yes — both are valid, return as-is.)
- Iterative or recursive — any preference? (Both are accepted; iterative is O(1) space.)

## Pattern & approach

The core **linked-list pointer-reversal** idiom: walk the list with `cur`, and at each node redirect its `next` pointer to the node you just came from (`prev`). You must cache `cur.next` *before* overwriting it, or you lose the rest of the list. After the loop, `prev` points at the old tail, now the new head.

```
prev=None  cur=1 -> 2 -> 3 -> ...
each step:  nxt = cur.next; cur.next = prev; prev = cur; cur = nxt
```

The recursive variant reverses the tail first, then fixes the two pointers between the head and its successor — elegant but O(n) stack.

## Complexity

- Time: **O(n)** — one pass, constant work per node.
- Space: **O(1)** — iterative pointer juggling uses three pointers, no extra structures.

## Hint ladder

1. To reverse links you must flip each `next` pointer to point backward — what do you risk losing when you do that?
2. Keep three references: `prev`, `cur`, and a saved `nxt = cur.next` so you don't lose the remainder.
3. Per step: `nxt = cur.next; cur.next = prev; prev = cur; cur = nxt`. Start `prev = None`.
4. When `cur` falls off the end, `prev` is the new head — return it.

## Starter stub

```python
from typing import List, Optional

class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def _build(values):
    head = None
    for v in reversed(values):
        head = ListNode(v, head)
    return head

def _dump(node):
    out = []
    while node:
        out.append(node.val)
        node = node.next
    return out

def reverseList(head: Optional[ListNode]) -> Optional[ListNode]:
    # your code here
    pass

def reverse_linked_list(values: List[int]) -> List[int]:
    return _dump(reverseList(_build(values)))
```

## Reference solution

```python
from typing import List, Optional

class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def _build(values):
    head = None
    for v in reversed(values):
        head = ListNode(v, head)
    return head

def _dump(node):
    out = []
    while node:
        out.append(node.val)
        node = node.next
    return out

def reverseList(head: Optional[ListNode]) -> Optional[ListNode]:
    prev = None
    cur = head
    while cur:
        nxt = cur.next      # cache before we overwrite
        cur.next = prev     # reverse the link
        prev = cur          # advance prev
        cur = nxt           # advance cur
    return prev             # new head = old tail

def reverse_linked_list(values: List[int]) -> List[int]:
    return _dump(reverseList(_build(values)))
```

## Follow-ups & variations

- "Reverse recursively." → reverse the tail, then set `head.next.next = head; head.next = None`.
- "Reverse only nodes between positions m and n (Reverse Linked List II)." → walk to position m, reverse a window of `n-m+1` nodes, reconnect.
- "Reverse in groups of k (Reverse Nodes in k-Group)." → reverse k at a time, leaving a leftover tail untouched.
- "Detect/handle a cycle first." → Floyd's tortoise-and-hare before reversing.

## Test cases

```json
{"function": "reverse_linked_list", "unordered": false,
 "cases": [
   {"args": [[1, 2, 3, 4, 5]], "expected": [5, 4, 3, 2, 1]},
   {"args": [[]], "expected": []},
   {"args": [[1]], "expected": [1]},
   {"args": [[1, 2]], "expected": [2, 1]},
   {"args": [[7, 7, 8]], "expected": [8, 7, 7]}
 ]}
```
