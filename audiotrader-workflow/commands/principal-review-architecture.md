---
description: Principal Python Engineer review of the current branch for architecture conformance — ADR/pattern/boundary violations plus database schema shape with an ERD grafted onto the existing schema
---

Act as a Principal Python Engineer reviewing the current feature branch for **architecture conformance**: does what got built conform to the documented architecture, reuse existing mechanisms instead of reinventing them, and graft onto the existing database schema the way the author intended?

Third member of the review trinity, alongside `/principal-review-correctness` and `/principal-review-guidelines`.

## What this review does NOT cover

Defer these to their owners — do not double-report:

- **Code-level duplication** (same logic implemented twice) → `/principal-review-duplication`
- **File/module placement and folder structure fitness** → `/principal-review-organization`
- **The mechanical Dependency Rule** (layer import checks) → `/principal-review-guidelines`
- **Maintaining C4 diagrams** → the `update-architecture-md` skill. If this review finds drift between the code and `docs/ARCHITECTURE.md`, *recommend* that skill — never redraw the diagrams here.

## Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise**: **stop and ask the user** what range to review. Do not fabricate a scope.

## Section 1 — Pattern, boundary, and ADR conformance

**Evidence rule: no citation, no finding.** Every finding in this section must name its documented source — an ADR decision line, an `ARCHITECTURE.md` section, or the `file:line` of the existing mechanism being reinvented. A suspicion you cannot cite goes in the **Judgment calls** list, never among the findings.

1. **Read the baseline docs**: every `docs/adr/ADR-*.md` (or `docs/adr/*.md`) and `docs/ARCHITECTURE.md`. If neither exists, say so plainly — *"no recorded ADRs; ADR-conformance check skipped"* — run only step 3 (which cites code, not docs), route everything else to Judgment calls, and end by recommending the missing docs be bootstrapped (`/adr-new`). **Never infer an architecture and grade against your own invention** — same rule as the correctness review's ban on invented acceptance criteria.
2. **ADR conformance**: for each recorded ADR, check whether the diff contradicts its decision. A finding requires **both** the quoted decision line from `ADR-NNNN` **and** the diff `file:line` that violates it.
3. **Reinvented mechanisms**: for each *mechanism-shaped* addition in the diff — retry/backoff, caching, queueing or event dispatch, HTTP client construction, config reading, serialization, scheduling, ID generation — search the codebase for an established mechanism that already does this job. A finding requires the `file:line` of the **existing** wheel plus the new one in the diff. If you cannot point at the existing mechanism, there is no reinvention to report. (This is pattern-level reinvention — a second retry mechanism rarely *structurally* resembles the first, which is why `/principal-review-duplication` won't catch it.)
4. **Boundary conformance**: does the new code cross a boundary that an ADR or `ARCHITECTURE.md` deliberately drew (a bounded-context seam, a "only X talks to Y" rule, an ownership split)? Only boundaries *documented there* count — mechanical layer-import checks belong to the guidelines review.
5. **Vocabulary**: describe findings using [`../references/architecture-language.md`](../references/architecture-language.md) terms (Module, Interface, Seam, Depth, Adapter) for the shape and `CONTEXT.md` terms for the domain.

Recurring judgment calls across runs are a signal the missing ADR should be recorded — suggest `/adr-new "<decision>"` for them.

## Section 2 — Database schema review

**Gate**: if the diff contains no migration files and no ORM model changes, state *"no schema changes on this branch"* and skip this section entirely. No ERD of nothing.

1. **Scope from the migrations**: read the branch's migration files (`alembic/versions/*.py`, or whatever schema-change format the repo uses) only to determine **which tables** the branch adds or alters.
2. **Render the ERD from the ORM models** — models show the *resulting shape*; migrations only show the delta (three iterative migrations would otherwise produce diagrams of intermediate states nobody cares about). Produce a Mermaid `erDiagram`:
   - **New/changed tables in full**: every field with its type; mark PK/FK/UK.
   - **Existing tables one FK-hop away**: name and the referenced key only, attribute-free. They exist to answer *"here's where the new shape grafts on — is that the join you intended?"*
   - Everything beyond one hop is noise — leave it out.
   - If the models and the migrations disagree about the resulting shape, that drift **is itself a finding** — report it before the ERD.
3. **Field summary table** for each new/changed table: field, type, nullable, and its *purpose inferred from code usage*. Flag every purpose you had to guess at — a field whose purpose isn't discoverable from usage is a finding in its own right.
4. **Schema smell checklist** — check each and report only failures:
   - FK column without an index
   - Enum-as-free-string where the domain has a closed set of values
   - Nullable column with no code path that ever writes NULL (should it be `NOT NULL`?)
   - Timestamp without timezone
   - A uniqueness rule the domain implies but no constraint enforces
   - A change touching a table read/written by 2+ modules → route to the `migration-semantic-drift-audit` skill rather than auditing writers here
5. **Non-SQLAlchemy repos**: render from whatever schema definition exists (e.g. D1/SQL DDL files). If the repo has no schema definitions at all, say so and skip.

## Output

Transient review output — write nothing to disk.

- **Section 1 — Conformance findings**, grouped by severity (Critical / High / Medium / Low). Each: the citation (quoted ADR line, `ARCHITECTURE.md` section, or existing-mechanism `file:line`), the diff `file:line`, and the concrete fix. Then a separate, clearly-labelled **Judgment calls (no documented source)** list — visibly opinion, never mixed with findings.
- **Section 2 — Schema review**: the Mermaid `erDiagram` block, the field summary table(s), and any smell-checklist failures. End with: *"Want the ERD written to a scratch file or rendered as an artifact so you can view it properly?"* — a fenced mermaid block in a terminal is not a diagram.
- If the review found drift against `docs/ARCHITECTURE.md`, recommend running the `update-architecture-md` skill.
- If the branch is clean, say so explicitly — do not invent issues.

**Delivery:** the report is the deliverable — it must be the FINAL text of the
turn, with no fix/commit tool calls after it. Applying fixes, or invoking the
next review in a chain, happens in the next turn, after the user has seen the
report. Mid-turn text between tool calls may never render; a buried report is
an unread report.
