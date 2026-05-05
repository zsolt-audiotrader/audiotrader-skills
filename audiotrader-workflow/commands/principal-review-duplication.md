---
description: Principal Python Engineer review of the current branch for code duplication against the whole codebase
---

Act as a Principal Python Engineer reviewing the current feature branch for **code duplication** — both *within* the diff and *against the rest of the codebase*.

1. **List new/changed Python files**:
   ```bash
   git diff main...HEAD --name-only -- '*.py'
   ```
2. **For each new function or class of non-trivial size (>10 lines)**:
   - Read its body. Extract the conceptual signature (what it does).
   - Search the codebase for similar logic:
     ```bash
     # By identifier
     grep -rn 'def <similar_name>' packages/prism/app/
     # By distinctive substring (a unique-ish phrase from inside the function)
     grep -rn '<distinctive snippet>' packages/prism/app/
     ```
   - Use the CodeGraphContext MCP `execute_cypher_query` to find structurally similar functions if available.
3. **Categorise findings**:
   - **Exact duplicate**: same logic, two locations → consolidate
   - **Near duplicate**: same shape, different details → extract a parameterised helper
   - **Conceptual duplicate**: different code, same job (e.g. two ways of computing the same VAT amount) → reconcile to one source of truth
   - **False positive**: superficial similarity, different intent → leave alone, note why
4. **Check for duplicated *constants* and *config*** — magic numbers, currency codes, timeout values, threshold percentages. These are sneakier than function duplication.
5. **Don't flag legitimate per-layer translation**. DTO → domain → ORM mapping is not duplication; it's the layer boundary.

Produce a report: **Real duplications** (with file:line for both copies and the proposed consolidation), **False positives** (briefly), **Constants to centralise**.
