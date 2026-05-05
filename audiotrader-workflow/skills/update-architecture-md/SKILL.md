---
name: update-architecture-md
description: Use when the diff adds or removes a service, package, layer, external integration, or significantly reshapes module boundaries, to keep docs/ARCHITECTURE.md and its C4 diagrams current. Skip for internal refactors that don't change visible structure.
---

# Update ARCHITECTURE.md

## Why this matters

`docs/ARCHITECTURE.md` documents the L1 (system context) and L2 (container) C4 views of Prism. When new services, integrations, or major modules ship without updating it, the diagram drifts and onboarding suffers.

This skill is the post-implementation gate that keeps the architecture doc honest.

## When to use

Trigger on diffs that:
- Add a new package under `packages/` or new top-level service
- Add a new external integration (3rd-party API client, message broker, vendor)
- Add a new persistence store (DB, cache, queue, object store)
- Add or remove a deployment unit (Cloudflare Worker, Hetzner container, scheduled job)
- Move a major capability across layer boundaries
- Add or remove an internal module that other modules import

Skip for: bug fixes, internal refactors that preserve the L2 view, test-only changes, doc-only changes.

## Procedure

### Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise**: **stop and ask the user** what range to review.

### Update the doc

1. **Read `docs/ARCHITECTURE.md`**. Note the current L1 and L2 diagram contents and the prose around them.
2. **Identify what the diff changes structurally**:
   ```bash
   git diff $BASELINE...HEAD --stat
   git diff $BASELINE...HEAD --name-only | grep -E '(pyproject|requirements|docker-compose|wrangler|terraform|packages/[^/]+/$)'
   ```
3. **For each structural change, decide**:
   - **L1 (system context)** — does the new thing interact with an outside actor (user, 3rd-party service, partner system)? Update L1.
   - **L2 (container)** — does it add a new deployment unit or change which container owns a capability? Update L2.
   - Internal-only? L3/L4 isn't in this doc — skip.
4. **Update the Mermaid (or graphviz) diagram source** in `docs/ARCHITECTURE.md`. Match the existing notation style — don't rewrite.
5. **Update the prose** that explains the diagram. Don't just edit the picture.
6. **Decide if an ADR is warranted**. If the change reflects a deliberate architectural decision (provider switch, new pattern, new boundary), recommend `/adr-new` and link it from `ARCHITECTURE.md`.

## Output format

Edit the file via Edit tool. Summarise to user:

```
ARCHITECTURE.md updated:
  - L2 diagram: added "Modulr Payment Provider" external box, arrow from prism-worker
  - Prose updated under "## Payments" section
  - ADR recommended: /adr-new "Switch payments from Wise to Modulr"
```

## Red flags

- Editing the diagram without editing the prose. The two must agree.
- Making the C4 diagram exhaustive. L2 is for *containers*, not classes. Resist drift toward L3.
- Skipping the doc update because "I'll do it later". Same incident pattern as observability.
