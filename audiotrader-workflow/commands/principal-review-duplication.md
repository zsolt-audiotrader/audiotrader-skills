---
description: Principal Python Engineer review of the current branch for code duplication against the whole codebase, using codebase-memory for structural matching
---

Act as a Principal Python Engineer reviewing the current feature branch for **code duplication** — both *within* the diff and *against the rest of the codebase*.

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

1. **List new/changed Python files**: `git diff $BASELINE...HEAD --name-only -- '*.py'`
2. **For each new function or class of non-trivial size (>10 lines)**:
   - Read its body. Extract the conceptual signature (what it does, its inputs, its side effects).
   - **Use the codebase-memory MCP** (`codebase-memory-mcp`) as the primary search tool. It indexes the call graph and AST, and it stores near-duplicate pairs as `SIMILAR_TO` edges, so it matches on function *shape* and *relationships*, not just text. Run these with `query_graph`:
     ```cypher
     // Near-duplicates the indexer already found for the new function
     MATCH (a:Function)-[:SIMILAR_TO]-(b:Function) WHERE a.name = '<new-function-name>' RETURN b.file_path, b.name

     // Functions with similar names across the codebase
     MATCH (f:Function) WHERE f.name CONTAINS '<token>' RETURN f.file_path, f.name, f.start_line ORDER BY f.file_path

     // Functions called by the new function — true duplicates often share callees
     MATCH (c:Function)-[:CALLS]->(d:Function) WHERE c.name = '<new-function-name>' RETURN d.file_path, d.name
     ```
     Also use `search_graph` with `--semantic-query` to find functions that do the same job under a different name.
   - **Also grep** when the tool returns nothing useful or you need a distinctive string literal. It does not link calls made through an object (`self._x.method()`), so a callee list can be incomplete:
     ```bash
     grep -rn '<distinctive snippet>' packages/prism/app/
     ```
3. **Categorise findings**:
   - **Exact duplicate** — same logic, two locations → consolidate
   - **Near duplicate** — same shape, different details → extract a parameterised helper
   - **Conceptual duplicate** — different code, same job (e.g. two ways of computing the same VAT amount) → reconcile to one source of truth
   - **False positive** — superficial similarity, different intent → leave alone, note why
4. **Check for duplicated *constants* and *config*** — magic numbers, currency codes, timeout values, threshold percentages. These are sneakier than function duplication.
5. **Don't flag legitimate per-layer translation**. DTO → domain → ORM mapping is not duplication; it's the layer boundary.

## Output

- **Real duplications** — for each: file:line for both copies, the proposed consolidation, which copy to keep
- **False positives** — briefly, with reasoning
- **Constants to centralise** — with proposed home (e.g. `app/core/constants.py`)
