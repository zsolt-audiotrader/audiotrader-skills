# Deepening Techniques: Python

How to deepen a cluster of shallow Modules safely, given Python-specific idioms and Prism's stack. Assumes the vocabulary in [`architecture-language.md`](./architecture-language.md).

## Dependency categories

When assessing a candidate for deepening, classify its dependencies. The category determines how the deepened Module is tested across its Seam.

### 1. In-process

Pure computation, in-memory state, no I/O. Always deepenable — merge the Modules and test through the new Interface directly. No Adapter needed.

**Examples in Prism**: utility functions in `app/utils/`, pure data transformations, ID generation, signature verification logic, scoring / matching functions.

### 2. Local-substitutable (DB-bound)

Dependencies that have local test stand-ins. **In Prism today**: in-memory SQLite via `TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"`. The Seam is the injected `AsyncSession`.

**Pros**: fast test startup (~milliseconds), supports `pytest-asyncio` cleanly, no Docker/container dependencies in local dev.

**Cons**: SQLite doesn't enforce all Postgres constraints — loose type checks, missing JSONB operators, different CTE behaviour, no advanced index support, no array types. Tests that pass on SQLite can fail on Postgres, and the divergence is often only noticed in CI or production.

**Recommendation shape**: for new deepened Modules with non-trivial SQL (JSONB queries, CTEs, window functions, advanced indexes, array operations), consider **`testcontainers-postgres` or `pytest-postgresql`** as a secondary test mode. Run fast SQLite tests for inner loops, real Postgres in CI. Acceptance of the testcontainers cost depends on the Module — it's worth it for migration-critical or query-heavy work.

### 3. Remote-owned (Ports & Adapters)

Your own services across a network boundary. **Not currently used in Prism** — Prism is a monolith. If a new internal service emerges (e.g. a separate `pricing-worker` that Prism calls), define a Port (Python `Protocol`) at the Seam, implement an HTTP / gRPC / queue Adapter for production and an in-memory Adapter for testing.

**Recommendation shape**: *"Define a `Protocol` at the Seam, implement an `httpx`-based Adapter for production and an in-memory Adapter for testing, so the logic sits in one deep Module even though it's deployed across a network."*

### 4. True external (Mock or Concrete Client)

Third-party services you don't control: eBay, Reverb, Shopify, GMC, Wise (and future Modulr), Anthropic, Google Ads, Meta Ads, Microsoft Ads, GA4, etc.

**In Prism**: these are wrapped in `*Client` classes — `EbayClient`, `ReverbClient`, `ShopifyHTTPClient`, `GmcClient`, `ClaudeClient`, `GoogleAdsClient`, etc. The Seam is the constructor-injected client instance. Tests provide a `MagicMock` / `AsyncMock` of the client, or a hand-rolled fake.

**Recommendation shape**: *"The deepened Module takes the `<XxxClient>` as an injected dependency. Tests provide an `AsyncMock` of the client OR a hand-rolled in-memory fake (preferred when behaviour beyond return values matters — rate-limiting, pagination, retry semantics)."*

## Seam discipline

- **Recognise existing Seams.** Constructor injection of `AsyncSession`, `httpx.AsyncClient`, `*Client` instances, and ABC subclassing — these are real Seams that earn their keep. Don't add a "Port" just to make a Seam more explicit if the Seam is already working.
- **Don't introduce a new Seam unless something varies across it.** A single-Adapter Seam is just indirection, unless the test-vs-prod variation is meaningful (it usually is for DB and HTTP — that's why those Seams earn their keep with one production Adapter and one test Adapter).
- **Internal Seams vs external Seams.** A deep Module can have internal Seams (private to its Implementation, used by its own tests) as well as the external Seam at its Interface. Don't expose internal Seams through the Interface just because tests use them.

## Protocol vs ABC

Python gives you two ways to express an Interface explicitly:

- **`typing.Protocol`** — *structural* typing. Any class with the right methods conforms — no inheritance required. Lighter, more flexible. **Preferred for new Interfaces.**
- **`abc.ABC` with `@abstractmethod`** — *nominal* typing. Subclasses must explicitly inherit. Heavier, but enforces conformance at class-definition time.

**In Prism today**: one ABC (`BaseChannelEventConsumer`), no Protocols. The ABC works because the consumers genuinely share a template method (`_dispatch`).

**For new deepening candidates**, prefer `Protocol` when:

- The Module has ≥2 concrete implementations (or will have soon)
- You want test fakes to conform without inheritance ceremony
- The contract is genuinely structural — *"anything with `.fetch()` and `.commit()` works"*

Use `ABC` when:

- A template method or shared base behaviour is genuinely valuable
- You want enforcement at class-definition time
- The contract is genuinely nominal — *"must be a `*Consumer`"*

## Async-as-Seam

Prism is heavily async. Async function boundaries are Seams of their own kind:

- **Cancellation propagates** across async boundaries. A deep async Module needs to be cancellation-correct — typically by avoiding partial side effects, or by structuring side effects to be idempotent (Prism already does this for event consumption via `ON CONFLICT DO NOTHING`).
- **Event-loop awareness**: synchronous I/O inside an async Module is a Seam violation — it blocks the loop.
- **Ordering**: async operations don't preserve invocation order unless awaited sequentially. A deep async Module should be explicit about whether its Interface guarantees ordering.

When designing a deep async Module's Interface, document:

- Is it cancellation-safe?
- Does it guarantee operation ordering, or are operations independent?
- Does it ever perform sync I/O? (If yes, why? Should it be `to_thread`-wrapped?)

## Testing strategy: replace, don't layer

- Old unit tests on shallow Modules become **waste** once tests at the deepened Module's Interface exist — delete them.
- Write new tests at the deepened Module's Interface. **The Interface is the test surface.**
- Tests assert on observable outcomes through the Interface, not internal state.
- Tests should survive internal refactors — they describe behaviour, not Implementation. If a test has to change when the Implementation changes, it's testing *past* the Interface.

**In Prism specifically**: tests that mock `*Service` internals are tests past the Interface — they're noise. Prefer tests that inject mocks/fakes of `*Client` and `AsyncSession`, then assert on the *visible side effects*: DB rows changed, events emitted to `channel_sync_event`, return values, metrics incremented.

## Dependency injection: how Adapters reach Seams

Prism uses two DI patterns:

1. **Constructor injection** — services take dependencies in `__init__`. Used everywhere for `AsyncSession` and `*Client` instances.
2. **FastAPI `Depends(...)`** — used at the API layer for request-scoped dependencies (auth, session).

When deepening, prefer **constructor injection** for the Module's own dependencies. Reach for `Depends` only when the dependency is genuinely request-scoped (per-user, per-request). Don't conflate the two patterns inside one Module.

---

Originally adapted from [`mattpocock/skills` — `improve-codebase-architecture/DEEPENING.md`](https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/DEEPENING.md). The dependency categories follow Matt's structure; the stack-specific examples (SQLite vs testcontainers, Protocol vs ABC, async-as-Seam, FastAPI `Depends`) are Prism-specific.
