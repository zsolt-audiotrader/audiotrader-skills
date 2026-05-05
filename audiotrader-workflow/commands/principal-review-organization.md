---
description: Principal Python Engineer review of code organization and whether the existing folder structure still serves the codebase as it has grown
---

Act as a Principal Python Engineer reviewing the current feature branch for **code organization** — both the placement of new code AND whether the existing folder/module structure still serves the codebase as it has grown.

This review is *complementary* to `/principal-review-guidelines` — that command checks compliance with the documented rules (including the Dependency Rule). Here we ask: **is the current structure still right, and does it need further sophistication?**

## Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise**: **stop and ask the user** what range to review.

## Review

1. **Survey the current structure**:
   ```bash
   tree -L 3 packages/prism/app/ 2>/dev/null || find packages/prism/app -type d -maxdepth 3 | sort
   # File counts and sizes per directory:
   find packages/prism/app -type d -maxdepth 2 -exec sh -c 'echo "$0: $(find "$0" -maxdepth 1 -name "*.py" | wc -l) files, $(find "$0" -maxdepth 1 -name "*.py" -exec cat {} + | wc -l) lines"' {} \;
   ```
   Note the top-level packages, the depth of the hierarchy, file-count per directory, and which packages have grown notably. Use the **CodeGraphContext MCP** (`execute_cypher_query`, `analyze_code_relationships`) for impact and import-graph analysis.

2. **Place the new code** (from `git diff $BASELINE...HEAD --name-only -- '*.py'`):
   - For each new function, class, or module, ask: is it in the right module? A `payments` concern in a `users` module is a smell. A generic `helpers.py` accumulating unrelated functions is a god-module forming.
   - Is the granularity right? A 400-line `services.py` covering 8 unrelated concerns wants splitting; a 6-file directory for one operation is over-decomposed.
   - Is the naming truthful? `process`, `handle`, `manager`, `utils` are red flags.

3. **Critique the existing structure** — has the codebase outgrown its current shape?
   - Are any directories now over-loaded (file count, cumulative lines, mixed concerns)?
   - Are concepts scattered across packages that should consolidate? (e.g. payment logic spread across `services/`, `models/`, `api/`, `workers/` — could a `payments/` package own it cohesively?)
   - Are there packages so small they should fold into a parent?
   - Has a new boundary emerged that deserves its own package?
   - Is the depth still right? Too flat invites god-modules; too deep hides structure.

4. **Look for emerging sub-domains**:
   - Repeated cross-module imports — A imports from B and B imports from A is a smell
   - Names like `Foo*Service`, `Foo*Repository`, `Foo*Schema` clustered together — likely a `foo/` package waiting to happen
   - A growing `core/` or `shared/` becoming a junk drawer
   - Use CGC to find import-graph cliques: which modules form tight bidirectional clusters?

5. **Resist restructuring for symmetry**. Propose changes only when the *current* structure costs something concrete: harder navigation, repeated mistakes, painful imports, frequent merge conflicts, or onboarding friction.

## Output

- **New code placement** — well-placed (briefly) and misplaced (with proposed move, file:line)
- **Structural observations** — what's working, what's strained, with concrete evidence (file counts, import graphs, recent merge conflicts if known)
- **Proposed refactors** (if any) — for each: the cost it pays today, the proposed shape, the rough effort, the risk
- **Naming improvements**

Defer to the user before making any structural changes — these are architectural decisions, not mechanical fixes. If a proposal warrants formal capture, recommend `/adr-new`.
