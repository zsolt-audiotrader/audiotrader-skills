---
description: Author a new ADR following the project's docs/adr template
argument-hint: <short title for the decision>
---

Author a new Architectural Decision Record following the Audio Trader Prism conventions.

If `$ARGUMENTS` is empty, ask the user for a short title and stop.

## Procedure

1. **Read the template** at `docs/adr/adr.template.md` if it exists; otherwise use the standard ADR structure (Context, Decision, Status, Consequences, Alternatives Considered).
2. **Determine the next ADR number**:
   ```bash
   ls docs/adr/ADR-*.md 2>/dev/null | grep -oE 'ADR-[0-9]+' | sort -V | tail -1
   ```
   Increment by 1. Use 4-digit zero-padded format (e.g. `0042`).
3. **Slugify the title** for the filename: lowercase, hyphens, no punctuation. Example: "Switch payments from Wise to Modulr" → `switch-payments-from-wise-to-modulr`.
4. **Filename**: `docs/adr/ADR-<NNNN>-<slug>.md` per the project naming convention.
5. **Fill the ADR with substance**, not placeholders:
   - **Context** — what's true about the world that makes this decision necessary now? Cite specs, incidents, constraints. Not generic.
   - **Decision** — the actual decision in active voice ("We will use Modulr for outgoing bank transfers"). One sentence ideal.
   - **Status** — `Proposed` (default), or `Accepted` if the user confirms it's already settled.
   - **Consequences** — both positive and negative. What gets easier? What gets harder? What new risks?
   - **Alternatives Considered** — at least 2, with the reason each was rejected. "We didn't consider alternatives" is a code smell.
6. **Date the ADR**: include `Date: YYYY-MM-DD` near the top, today's date.
7. **Cross-reference**: if this ADR supersedes or relates to an existing one, link it.
8. **Update `docs/ARCHITECTURE.md`** if the decision changes a structural choice (new container, new integration, new pattern) — link to the new ADR.

Write the file via the Write tool. Show the user the path of the new file and a 2-sentence summary of what was decided.
