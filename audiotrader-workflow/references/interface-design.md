# Interface Design — Parallel Exploration

When designing the Interface for a deepened Module, explore multiple shapes in parallel before settling. The "design it twice" approach: a single proposed shape is rarely the best one, and trade-offs only become visible when alternatives are concrete.

Assumes the vocabulary in [`architecture-language.md`](./architecture-language.md).

## When to use this

Use during the `/audiotrader-workflow:grill` session that follows a candidate being picked from `/audiotrader-workflow:architecture-deepening`. Specifically when:

- The deepened Module's Interface is **non-trivial** (≥4 methods, or carries non-obvious invariants like ordering / cancellation / idempotency)
- **Multiple plausible shapes exist** (e.g. method-per-operation vs single-method-with-dispatch, sync-API vs async-API, builder vs factory, exception-based vs result-type error handling)
- The choice will be **expensive to reverse** (callers throughout the codebase, or a stable public Interface)

Skip when the Interface is obvious or has only one sensible shape.

## Process

### Step 1: Frame the problem space

Present to the user:

- **Constraints** — what callers need, what dependencies impose, what tests must verify, what `CONTEXT.md` requires
- **Dependencies** — what's behind the Seam (DB, HTTP clients, other Modules)
- **An illustrative code sketch** that grounds the constraints

**The sketch is not a proposal.** It's just enough code to make the constraints concrete. Make this clear in the framing.

### Step 2: Spawn parallel exploration agents

Dispatch 3+ agents in parallel using the `Agent` tool (or the `superpowers:dispatching-parallel-agents` skill if available). Each agent optimises for a distinct constraint:

1. **Minimise Interface surface** — 1–3 entry points, maximise Leverage. *What if the Interface is one method?*
2. **Maximise flexibility** — many small operations, easy to extend, easy to compose. *What if the Interface is a builder or fluent chain?*
3. **Optimise for the common case** — what shape makes the most-common caller path shortest, even if rarer paths get more verbose?
4. **(Optional) Ports & Adapters** — what if the Module is a Port (Python `Protocol`) with explicit Adapters at the Seam? Useful when the deepening involves separating logic from transport.

Each agent brief includes:

- File paths involved (with line numbers where relevant)
- Coupling and dependency details
- Vocabulary from `architecture-language.md` and `CONTEXT.md`
- The constraints from Step 1
- A clear instruction to **propose a complete Interface shape** — types, method signatures, error modes, ordering guarantees, and **one paragraph of caller code** that uses it

Example agent dispatch shape:

```text
Agent({
  description: "Minimal-surface Interface for deepened Reconciler",
  subagent_type: "general-purpose",
  prompt: "Propose an Interface for a deepened Reconciler Module that minimises surface area — ideally 1–3 entry points. Context: <files, constraints, vocabulary>. Output: complete Interface (types, methods, error modes, async semantics), one paragraph of caller code, brief explanation of how all current Reconciler behaviour fits behind this surface. Use Module / Interface / Seam / Adapter from architecture-language.md and Reconciler / Anchor / Premise / Disposition from CONTEXT.md."
})
```

Dispatch all agents in a single message (parallel tool use), then wait for all to return before moving to Step 3.

### Step 3: Present and compare

Display each design sequentially, then contrast them along these axes:

- **Depth** — how much behaviour sits behind the Interface? (Leverage at the Interface.)
- **Locality** — where does change concentrate? Is one design more localised than another?
- **Seam placement** — does the Seam sit at a natural boundary? Does it expose internal structure that should stay private?
- **Caller ergonomics** — which is easier to use correctly? Which is harder to use incorrectly? Which produces clearer call sites?
- **Test surface** — which Interface lets tests assert observable outcomes most directly?

Conclude with a **reasoned recommendation** — potentially a hybrid pulling the best of two designs. **Not a neutral menu.** The user has more context than the agents and may overrule, but the recommendation should be substantive enough to defend.

## Vocabulary consistency

All proposed Interfaces use:

- **Module / Interface / Implementation / Depth / Seam / Adapter / Leverage / Locality** from `architecture-language.md`
- Domain nouns from `CONTEXT.md` (Listing, Stock, Channel, Reconciler, Emitter, Consumer, Anchor, Premise, Disposition, etc.)
- Prism's existing class-noun conventions: `Service`, `Client`, `Emitter`, `Consumer`, `Reconciler`, `Processor`

If an agent's output uses "component" or generic "service" or "handler", the dispatcher should rewrite to use the canonical vocabulary before presenting to the user. Vocabulary drift defeats the purpose.

## Limitations

- **This is exploratory, not exhaustive.** Three parallel proposals is enough to surface trade-offs; ten is overkill.
- **Agents may converge.** Sometimes the constraints leave little room for genuinely different shapes. That's a useful finding — present the one good shape and note that alternatives were explored but didn't differ meaningfully. Don't manufacture artificial divergence.
- **The harness's `Agent` tool is single-shot.** Each agent gets one prompt and returns one result. Don't design as if the agents can iterate — they can't.
- **Sub-agents don't share state.** Each agent reads files independently; budget for that in the prompts (give them the file paths and key snippets directly rather than expecting them to discover the context).

---

Originally adapted from [`mattpocock/skills` — `improve-codebase-architecture/INTERFACE-DESIGN.md`](https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/INTERFACE-DESIGN.md). Sub-agent dispatch adapted to use the Claude Code `Agent` tool and the `superpowers:dispatching-parallel-agents` skill when available.
