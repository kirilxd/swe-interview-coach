---
name: system-design-frameworks
description: Reference frameworks (RESHADED, the 4S shorthand), capacity estimation cheatsheet, core building blocks (load balancing, caching, queues, sharding, replication, CAP), common tradeoffs, and anti-patterns for system design interview prep. Use when running /mock-sysdesign, /practice-sysdesign, /sysdesign-explain, or /debrief-sysdesign, or whenever discussing architecture, capacity estimation, or design tradeoffs.
---

# System Design Frameworks

## RESHADED framework

Default structure for a 45-60 minute open-ended design question. Budget roughly 10 minutes for Requirements + Estimation, 20-25 for Storage through Detailed design, 10 for Evaluation + wrap-up. Announce each stage transition out loud — interviewers score process, not just the final diagram.

### Requirements

- Split functional (what the system does) from non-functional (latency, availability, consistency, durability targets).
- Ask scoping questions before drawing anything: who uses it, what ships in v1, read-heavy or write-heavy?
- Attach numbers to non-functional requirements: "redirect p99 < 100 ms", "99.9% available" — never "fast and reliable".
- Restate the agreed scope and get explicit interviewer sign-off before moving on.

**Weak:** "A URL shortener — okay. I'll hash the URL, store the mapping in a database, and redirect on lookup."

**Strong:** "Scope check first: shorten and redirect are v1; custom aliases and analytics are out. I'll assume ~100:1 read:write. Non-functional targets: redirect p99 < 100 ms, 99.9% availability, and no mapping may ever be lost — durability beats freshness here."

### Estimation

- Produce three numbers minimum: QPS (read and write), storage growth, bandwidth — each rounded to one significant figure.
- Derive them from stated assumptions (DAU, actions per user per day) so the interviewer can correct your inputs, not your math.
- Use the shortcuts: 86,400 s/day, 1M requests/day ≈ 12 RPS, ~2.5M s/month.
- State peak vs average (peak ≈ 2-3× average) and size for peak.
- Don't skip bandwidth (RPS × object size) — for media-heavy systems it shapes the design more than request count does.

**Weak:** "It'll be a lot of traffic, so we'll need to scale horizontally from day one."

**Strong:** "100M DAU × 10 timeline reads/day = 1B reads/day ≈ 12K RPS average, ~30K peak. Writes: 100M posts/day ≈ 1.2K RPS. At ~1 KB per post that's ~100 GB/day of new data, ~36 TB/year before replication."

### Storage

- Sketch the data model before naming a technology: core entities, key fields, relationships, and the access patterns against each.
- Let volume plus access pattern drive the store choice — relational joins and transactions vs key-based access at horizontal-write scale.
- Mark which data needs transactions and which tolerates eventual consistency.
- Plan growth: hot vs cold data, retention, archival tier.

**Weak:** "I'll put everything in MongoDB because it scales well."

**Strong:** "Users and follow-edges are relational and join-heavy — Postgres. Posts are append-heavy at 100M/day with key-based reads — a wide-column store keyed by user_id, time-bucketed so no partition grows unbounded."

### High-level design

- Draw the end-to-end path first: client → load balancer → services → cache/DB → async consumers. 5-8 boxes at this altitude.
- Give every box one responsibility you can state in a sentence.
- Trace one read and one write through the diagram aloud.
- Flag deep dives and defer them: "I'll come back to the fan-out service."

**Weak:** "We'll have Kubernetes, Kafka, Redis, Cassandra, and Elasticsearch." (A shopping list, not a design.)

**Strong:** "Write path: client → L7 LB → post service → queue → fan-out workers → followers' timeline caches. Read path: timeline service reads the cache, falls back to the post store on miss. Fan-out is the hard part — I'll detail it later."

### API design

- Define the 3-5 core endpoints: method, path, key params, response shape, error cases.
- Make mutations idempotent — client-generated idempotency keys make retries safe.
- Paginate every list endpoint; prefer cursor over offset at scale.
- Note where authn/authz and rate limiting sit (usually the gateway).

**Weak:** "There'll be a REST API for posting and for reading timelines."

**Strong:** "POST /v1/posts with a client idempotency key returns 201 + post_id; retries are no-ops. GET /v1/timeline?cursor=…&limit=50 is cursor-paginated — offset pagination degrades on deep pages and shifts under concurrent inserts."

### Detailed design

- Zoom into the 1-2 components the requirements make hardest; invite the interviewer to pick.
- Specify the concrete choices: partition key, cache pattern and eviction, queue delivery semantics, replication mode — each with a reason.
- Quantify each choice against your estimation numbers.
- State the consistency model per path, not for the system as a whole.

**Weak:** "The cache layer will make reads fast."

**Strong:** "Timeline cache: Redis, cache-aside, LRU eviction, 1-hour TTL, keyed by user_id, holding the latest 800 post IDs. At 12K read RPS and a 90% hit rate the post store sees ~1.2K RPS — comfortable for one primary with replicas."

### Evaluation & edge cases

- Walk back through each non-functional requirement and show it is met — or say plainly where it is not.
- Probe failure modes: cache tier down, DB primary fails over, queue backlog, region loss. What degrades vs what breaks?
- Cover the hot-key/celebrity case and the thundering-herd case explicitly.
- Name the first bottleneck at 10× traffic and the lever you'd pull.

**Weak:** "I think this design covers everything we discussed."

**Strong:** "If the cache tier dies we'd thundering-herd the post store, so: request coalescing plus serve-stale-on-error. At 10× the bottleneck is fan-out for >1M-follower accounts — those switch to fan-out-on-read."

### Done

*(Canonical RESHADED calls this final D "Distinctive component"; this adaptation folds that into Detailed design and uses Done for the wrap-up.)*

- Close with a 60-second recap: the design in one breath, the top 2-3 tradeoffs you made, and what you'd tackle next with more time.
- Map the recap back to the requirements so the interviewer hears the loop close.
- Offer extension paths (multi-region, analytics pipeline, abuse prevention) rather than waiting silently for the next question.
- If minutes remain, ask which area the interviewer wants deeper — don't monologue past the buzzer.

**Weak:** "…so yeah, that's pretty much the design." (Trails off mid-component.)

**Strong:** "Recap: cache-aside timelines for read scale, hybrid fan-out to absorb celebrities, eventual consistency on timelines but strong on the posts themselves. Next I'd add multi-region active-passive and an abuse/dedup pipeline."

## The 4S shorthand

Scenario (clarify the use cases and constraints), Service (split the system into services and draw the boxes), Storage (data model and store choice), Scale (estimate load, then cache, shard, and replicate to meet it). Same muscles as RESHADED, compressed into four beats: estimation folds into Scale, API design into Service.

- Prefer 4S for 30-minute screens, scope-constrained single-component questions ("design a rate limiter"), or follow-up rounds where requirements are already fixed.
- Prefer RESHADED for 45+ minute open-ended designs: its explicit Estimation and Evaluation stages are where senior signal lives, and 4S makes them easy to skip.

## Capacity estimation cheatsheet

Arithmetic shortcuts:

- 86,400 seconds/day; ~2.5M seconds/month (30 × 86,400 = 2,592,000).
- 1M requests/day ≈ 12 RPS. Scale linearly: 100M/day ≈ 1,200 RPS, 1B/day ≈ 12K RPS.
- Peak ≈ 2-3× average. Size for peak.
- Powers of two: 2^10 = 1,024 ≈ 10^3 (KB ↔ thousand), 2^20 ≈ 10^6 (MB ↔ million), 2^30 ≈ 10^9 (GB ↔ billion). So 1M items × 1 KB ≈ 1 GB.
- Availability math: 99.9% allows ~43 min downtime/month, 99.99% ~4.3 min (43,200 min/month × 0.1% and 0.01%).
- Round every input to one significant figure. Precision theater burns interview minutes.

Latency reference (memorize):

| Operation | Latency |
|---|---|
| L1/L2 cache hit | ~1–10 ns (< 0.01 ms) |
| RAM read | ~0.0001 ms (100 ns) |
| SSD random read | ~0.1 ms |
| Intra-datacenter network RTT | ~0.5 ms |
| HDD seek | ~10 ms |
| Cross-region network RTT | 60-150 ms |

Rules of thumb that fall out of the table:

- SSD is ~1,000× slower than RAM (0.1 ms vs 0.0001 ms); HDD seek is ~100× slower than SSD random read.
- One cross-region round trip (60-150 ms) costs more than 100 intra-DC round trips (~0.5 ms each) — keep chatty call chains inside one region.
- A 200 ms latency budget affords at most one cross-region hop at worst-case (150 ms) RTT.

Worked example — photo app, 50M DAU, 2 uploads/user/day, 5 MB average photo:

- Writes: 100M uploads/day ≈ 1,200 RPS average, ~3,600 RPS peak (3×).
- Reads at an assumed 10:1 read:write ratio: 1B views/day ≈ 12K RPS — the CDN, not the origin, must absorb this.
- Ingest bandwidth: 100M × 5 MB = 500 TB/day ÷ 86,400 s ≈ 5.8 GB/s.
- Storage: 500 TB/day ≈ 180 PB/year raw, ~550 PB/year with 3× replication.

## Building blocks

### Load balancers

- L4 (transport layer): routes on IP/port without reading payloads. Cheaper per connection, protocol-agnostic — use for raw throughput, non-HTTP traffic, TLS passthrough.
- L7 (application layer): parses HTTP — path/header/cookie routing, TLS termination, retries, sticky sessions. Use for microservice routing and canary/A-B traffic splits.
- Algorithms: round-robin (default), least-connections (uneven request costs), consistent hash (cache affinity).
- Health checks eject bad backends; connection draining for deploys. The LB itself is made HA via a redundant pair or anycast.

### Caching

The four standard patterns:

- Cache-aside (lazy loading): app reads cache, on miss loads from DB and populates. Most common; survives cache failure; first hit per key is slow; stale until TTL or invalidation.
- Write-through: write to cache and DB synchronously. Reads always warm; costs write latency and caches data that may never be read.
- Write-back (write-behind): write to cache, flush to DB asynchronously. Fastest writes, absorbs bursts; risks losing acked writes if the cache dies before flush — needs replication or a WAL.
- Write-around: write to DB only; cache fills on later reads. Good for write-heavy data that is rarely re-read soon after writing.

Eviction and hot keys:

- Eviction policies: LRU (sane default), LFU (stable popularity distributions), TTL (bounds staleness — the freshness knob for cache-aside).
- For hot keys, use a local cache replica — a per-process in-memory copy of the hot row — so one cache shard doesn't absorb every read for a celebrity key.

### Message queues

- Decouple producers from consumers, absorb bursts, enable retry with backoff plus a dead-letter queue for poison messages.
- At-least-once delivery: ack after processing; duplicates possible on redelivery, so consumers must be idempotent. The default choice.
- At-most-once delivery: ack before processing; messages can be lost but never duplicated. Only for loss-tolerant data (metrics, logs).
- "Exactly-once" is effectively-once: at-least-once delivery plus idempotent consumers or dedup keys (e.g., Kafka transactional IDs). True exactly-once delivery over an unreliable network is impossible — say this in the interview.
- Ordering is usually guaranteed only per partition/key, not globally — pick the partition key so events that must stay ordered share it.
- Watch consumer lag; a growing backlog is the failure signal that triggers scaling consumers or shedding load.

### Consistent hashing

- Keys and nodes hash onto the same ring; each key belongs to the next node clockwise.
- Why it matters: adding or removing a node reshuffles only ~1/N of keys — bounded reshuffle — versus nearly all keys under mod-N hashing.
- Virtual nodes: each physical node takes many ring positions, smoothing load variance and letting bigger machines own proportionally more of the ring.
- Where it shows up: distributed caches, Cassandra/DynamoDB-style partitioning, sticky load balancing.

### Sharding

- Range sharding: keeps order, so range scans are cheap; risks hot ranges (time-ordered keys hammer the newest shard).
- Hash sharding: uniform spread; range queries become scatter-gather.
- Choose the shard key from the dominant access pattern; resharding is the expensive event, so plan it (consistent hashing or a directory service).
- Hot-shard mitigation: split the hot shard, salt the key (random suffix fan-out), and for celebrity keys serve reads from a local cache replica in each app process.

### Replication

- Leader/follower: writes to the leader, reads from followers. Simple; replication lag means followers serve stale reads; failover requires leader election.
- Quorum (leaderless): write to W replicas, read from R; R + W > N guarantees the read set overlaps the latest write (e.g., N=3, W=2, R=2). Trade W against R for latency while keeping R+W>N — lowering one means raising the other.
- Sync replication survives failover without losing acked writes but raises write latency; async is fast but can drop the latest writes on failover. Say which you picked and why.
- Multi-leader (write in every region) buys local write latency at the cost of conflicts — if you propose it, name the resolution policy (last-write-wins, CRDTs, app-level merge).

### CAP theorem

During a network partition you choose consistency or availability — partition tolerance is not optional in a distributed system. Without a partition you can have both.

| Choice | Behavior during partition | Examples |
|---|---|---|
| CP | Returns error or times out rather than serving inconsistent data | MongoDB (single-primary), HBase, ZooKeeper |
| AP | Returns possibly stale data rather than error | Cassandra, DynamoDB, CouchDB |
| CA | Assumes no partitions — meaningful only single-node | Single-node RDBMS |

Real systems choose per operation: many stores expose tunable consistency (e.g., quorum reads on an AP store for the paths that need freshness).

### ACID vs BASE

- ACID (atomicity, consistency, isolation, durability): single-system transactions with invariants enforced. Pick for money, inventory, uniqueness constraints.
- BASE (basically available, soft state, eventually consistent): availability and scale-out first. Pick for feeds, counters, presence — data where brief staleness is invisible.
- Not a binary: NewSQL (Spanner, CockroachDB) offers distributed ACID at a latency cost, and BASE stores bolt on per-operation consistency knobs.

### CDN

- Edge servers cache content near users, cutting origin load and replacing a 60-150 ms cross-region RTT with a nearby edge hop.
- The operational knobs are Cache-Control headers (max-age, s-maxage, stale-while-revalidate) for freshness policy, and the purge/invalidation API for immediate removal.
- Fingerprinted asset URLs (app.3f9a2c.js) allow year-long TTLs — a deploy changes the URL instead of requiring a purge.
- Pull CDN (edge fetches from origin on first miss) is the default; push (pre-upload) only for predictable large releases.

## Common tradeoffs

**SQL vs NoSQL.**
- Choose SQL when data is relational and you need joins, transactions, or ad-hoc queries — and volume fits one primary plus read replicas, which carries further than people assume (TB-scale, thousands of RPS).
- Choose NoSQL when access is key-shaped at volumes that force horizontal write scaling, the schema is denormalized by design, or you need a specific model (document, wide-column, graph).
- "NoSQL because scale" without a write-volume number is a red flag — so is "SQL because familiar" at 100K write RPS.

**Fan-out-on-write vs fan-out-on-read.**
- Choose fan-out-on-write (push) when reads dominate and follower counts are bounded: each feed is precomputed at post time, so reads are O(1) cache hits.
- Choose fan-out-on-read (pull) for write-heavy or highly skewed graphs: writes stay cheap; each read merges followees' posts at request time. A celebrity post under push triggers millions of timeline writes — pull avoids that.
- Production answer is usually hybrid: push for normal users, pull for celebrity authors, merge at read time.

**Push vs pull.**
- Choose push (WebSockets/SSE) when freshness is the product — chat, live scores, collaborative editing — and you can afford per-client connection state.
- Choose pull (polling) when seconds of staleness are fine: simpler, stateless, cache-friendly, self-rate-limiting.
- Long-polling is the middle ground when full WebSocket infrastructure isn't justified.

**Sync vs async processing.**
- Choose sync when the caller cannot proceed without the result (auth check, payment authorization) and the latency budget covers it.
- Choose async (queue + workers) when work is slow, bursty, or retryable — email, transcoding, fan-out — buying burst absorption and failure isolation.
- Async's bill: job-status tracking, results that appear later than the request, harder debugging. Budget for all three.

**Strong vs eventual consistency.**
- Choose strong when violating an invariant has real cost — balances, inventory, unique usernames — and accept the price in latency, and in availability during partitions.
- Choose eventual when staleness is invisible or tolerable — like counts, view counters, timelines — and accept conflict resolution plus "where did my write go" UX; mitigate with read-your-own-writes sessions.
- State the choice per data path, not per system — most designs need both.

## Anti-patterns

- Designing before requirements — naming components before asking who uses the system and at what scale.
- No numbers anywhere — zero QPS, storage, or latency figures, so every sizing decision is a guess.
- "Just add more servers" — scaling answered without naming the actual bottleneck (write throughput? hot key? bandwidth?).
- Ignoring failure modes — no answer for cache loss, primary failover, queue backlog, or a lost region.
- Name-dropping tech without justification — "Kafka, Redis, Cassandra" as nouns, with no tradeoff tied to a requirement.
- Skipping the wrap-up — ending mid-component with no recap of the design, its tradeoffs, and next steps.
