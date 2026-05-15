# CONTEXT.md Format

`CONTEXT.md` is the canonical glossary for an Audio Trader project's domain language. It lives at the project root (the repo you're currently in). Every Audio Trader repo gets its own — Prism, Wise-Payments, Collection, Warehouse, Website, Pricing-worker.

## Structure

```md
# <Project name>

<One or two sentences: what this context is and why it exists.>

## Language

**Listing**:
A specific offering on a sales channel (eBay, Reverb, Discogs, the Audio Trader website). One Stock unit can produce many Listings.
_Avoid_: Item, ad, post

**Stock**:
A physical unit of inventory in the warehouse, identified by a SKU.
_Avoid_: Item, product, asset

**Channel**:
A sales destination (eBay, Reverb, Discogs, Audio Trader website). Distinct from a payment provider.
_Avoid_: Platform, marketplace

**Reconciler event**:
An anchored discrepancy between expected and observed Stock that requires resolution.
_Avoid_: Sync error, drift, mismatch

## Relationships

- One **Stock** can produce many **Listings** (one per **Channel**)
- A **Sale** consumes exactly one **Listing**
- A **Reconciler event** anchors a discrepancy between expected and observed **Stock**

## Example dialogue

> **Dev:** "When a **Listing** sells on eBay, do we mark the **Stock** as reserved immediately?"
> **Domain expert:** "No — we wait for the **Reconciler** to confirm payment first, otherwise we over-reserve on cancelled orders."

## Flagged ambiguities

- "item" was used to mean both **Stock** and **Listing** — resolved: distinct concepts (Stock is the physical unit, Listing is the channel-specific offer).
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in *Flagged ambiguities* with a clear resolution.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Only domain terms.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the codebase uses them extensively. Before adding a term, ask: is this a concept unique to the domain, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge (e.g. *Inventory*, *Sales*, *Reconciliation*, *Payments*). If a flat list works, use it.
- **Write an example dialogue** between a dev and a domain expert that demonstrates how the terms interact naturally and clarifies boundaries between related concepts.

## Single-context for now

Audio Trader has multiple repos, each with its own `CONTEXT.md` at root. If cross-repo glossary drift becomes louder than the cross-repo plumbing, lift to a workspace-level `CONTEXT-MAP.md` that points at the per-repo files:

```md
# Audio Trader Context Map

## Contexts

- [Prism](./audiotrader-prism/CONTEXT.md) — central system for inventory, listings, reconciliation
- [Wise-Payments](./audiotrader-prism-wise-payments/CONTEXT.md) — outgoing bank transfers
- [Collection](./audiotrader-collection/CONTEXT.md) — vendor intake and consignment
- [Warehouse](./warehouse-system/CONTEXT.md) — physical stock movement and picking
- [Website](./audio-trader-website/CONTEXT.md) — customer-facing storefront

## Relationships

- **Collection → Prism**: Collection emits intake events; Prism consumes them to create Stock
- **Prism → Wise-Payments**: Prism emits payout-due events; Wise-Payments executes the transfer
- **Prism ↔ Warehouse**: Shared SKU identity; Prism owns Listing state, Warehouse owns location
```

Defer this until cross-repo drift forces it.

---

Originally adapted from [`mattpocock/skills` — `grill-with-docs/CONTEXT-FORMAT.md`](https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md).
