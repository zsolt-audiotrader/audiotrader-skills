# Architecture Language

Shared vocabulary for every architectural suggestion this plugin makes. Use these terms exactly — don't substitute "component", "module" (in the file-system sense), or "boundary". Consistent language is the whole point.

This file is **stack-agnostic** — the concepts apply to Python, TypeScript, or any other language. For stack-specific patterns and idioms, see the sibling files:

- [`deepening-techniques-python.md`](./deepening-techniques-python.md) — Protocol vs ABC, async-as-Seam, Python testing Seams.

Sibling files for other stacks (TypeScript / Cloudflare Workers, etc.) live alongside as they're authored.

## Terms

**Module**
Anything with an Interface and an Implementation. Deliberately scale-agnostic — applies equally to a function, class, package, or tier-spanning slice.
_Avoid_: "unit", "component", generic "service".

> **In Prism (Python):** a Module is typically a `Service` class. Other Module shapes: `Client` (external API wrapper), `Emitter` / `Consumer` (event flow), `Reconciler` (cross-channel coordinator), `Processor` (workflow orchestrator). When making suggestions about Prism code, use the team's noun — don't say *"the FooService Module"*; say *"FooService"* if `Service` is already part of its name.

**Interface**
Everything a caller must know to use the Module correctly. Includes the type signature, but also invariants, ordering constraints, error modes, required configuration, and performance characteristics.
_Avoid_: "API", "signature" (too narrow — those refer only to the type-level surface).

> **In Python (Prism):** a formal Interface is a `Protocol` class (preferred) or an `ABC`. Prism currently has minimal explicit Interfaces — most contracts are implicit via constructor-injection. Adopting this vocabulary nudges toward making non-trivial Interfaces explicit via `Protocol` (≥2 methods or ≥2 implementations is a reasonable threshold).

**Implementation**
What's inside a Module — its body of code. Distinct from **Adapter**: a thing can be a small Adapter with a large Implementation (a Postgres repo), or a large Adapter with a small Implementation (an in-memory fake).

**Depth**
Leverage at the Interface — the amount of behaviour a caller (or test) can exercise per unit of Interface they have to learn. A Module is **deep** when a large amount of behaviour sits behind a small Interface. A Module is **shallow** when the Interface is nearly as complex as the Implementation.

**Seam** _(from Michael Feathers)_
A place where you can alter behaviour without editing in that place. The *location* at which a Module's Interface lives. Choosing where to put the Seam is its own design decision, distinct from what goes behind it.
_Avoid_: "boundary" — overloaded with DDD's bounded context (which Prism uses for cross-repo concerns, not Module-level concerns).

> **In Prism:** existing Seams include constructor-injected `AsyncSession`, constructor-injected HTTP clients (`httpx.AsyncClient`), the `BaseChannelEventConsumer._dispatch` template method, FastAPI dependency-injection points (`Depends(...)`). These are *real Seams*, not hypothetical.

**Adapter**
A concrete thing that satisfies an Interface at a Seam. Describes *role* (what slot it fills), not substance (what's inside).

> **In Prism:** external API wrappers are called `Client`, not `Adapter` — `ShopifyHTTPClient`, `ReverbClient`, `EbayClient`, `GmcClient`, etc. Use "Adapter" only when there's an explicit Port (Protocol or ABC) with ≥2 concrete implementations. Don't rename existing `Client` classes.

**Leverage**
What callers get from Depth — more capability per unit of Interface they have to learn. One Implementation pays back across N call sites and M tests.

**Locality**
What maintainers get from Depth — change, bugs, knowledge, and verification concentrate at one place rather than spreading across callers. Fix once, fixed everywhere.

## Principles

- **Depth is a property of the Interface, not the Implementation.** A deep Module can be internally composed of small, mockable, swappable parts — they just aren't part of the Interface. A Module can have **internal Seams** (private to its Implementation, used by its own tests) as well as the **external Seam** at its Interface.
- **The deletion test.** Imagine deleting the Module. If complexity vanishes, the Module wasn't hiding anything (it was a pass-through). If complexity reappears across N callers, the Module was earning its keep.
- **The Interface is the test surface.** Callers and tests cross the same Seam. If you want to test *past* the Interface, the Module is probably the wrong shape.
- **Don't introduce a new Seam just to feel testable.** Recognise the Seams that already exist via constructor injection and ABC subclassing — they count. But also don't add Ports/Protocols speculatively. If only one Adapter ever exists and the Seam isn't used for anything, it's just indirection.

## Domain-architectural bridge

Architecture vocabulary describes **shape**. Domain vocabulary describes **things**. Use both.

Prism's domain vocabulary lives in `CONTEXT.md` at the project root. When making architectural suggestions about a specific Module, prefer the domain noun: *"deepening the **Reconciler** Module's Interface"* reads better than *"deepening the event-coordination module"*.

Specific Prism domain terms that frequently come up in architecture sessions (full list in `CONTEXT.md` when it exists):

- **Listing**, **Stock**, **Channel** — inventory domain
- **Emitter**, **Consumer**, **Reconciler**, **Anchor**, **Premise**, **Disposition** — event-sourcing domain (ADR-0001, ADR-0006)
- **PIM**, **Master Product**, **Brand** — catalogue domain

If a candidate proposes to name a deepened Module after a concept *not* in `CONTEXT.md`, the grilling session should add the term to `CONTEXT.md` (handed off to `/audiotrader-workflow:grill`).

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout). Rewards padding the Implementation. We use depth-as-leverage instead.
- **"Interface" as the TypeScript `interface` keyword or a Python class's public methods.** Too narrow — Interface here includes every fact a caller must know.
- **"Boundary"** for Module-level concerns. Overloaded with DDD's bounded context (which we use for Prism / Wise-Payments / Collection / Warehouse / Website / Pricing-worker, not for Module-level concerns inside a single repo).

## Relationships

- A **Module** has exactly one **Interface** (the surface it presents to callers and tests).
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam** and satisfies the **Interface**.
- **Depth** produces **Leverage** for callers and **Locality** for maintainers.

---

Originally adapted from [`mattpocock/skills` — `improve-codebase-architecture/LANGUAGE.md`](https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/LANGUAGE.md). The core vocabulary is preserved verbatim; the in-text annotations (Service / Client / etc.) recognise Prism's established naming so suggestions stay native to the codebase rather than abstract.
