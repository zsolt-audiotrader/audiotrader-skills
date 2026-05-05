---
name: spec-status-update
description: Use when implementation work tied to a spec in specs/specs_*.md is completed, in-progress, or de-scoped, to keep the spec's Status line and milestone checkboxes current. Triggers on PR-merge, end-of-day wrap-up, or when the user says "update the spec".
---

# Spec Status Update

## Why this matters

The spec is the source of truth for what was promised vs delivered. A stale spec is worse than no spec — it tells future-you (or a teammate) that work is done when it isn't, or vice versa.

This skill keeps `specs/specs_yyyyMMDD_*.md` honest after implementation moves forward.

## When to use

Trigger on:
- A milestone or step was completed
- A step was de-scoped or pushed to a follow-up
- End of a working session on a spec'd feature
- User says "update the spec" or "mark this done"

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

### Update the spec

1. **Identify the active spec**. Either explicit from the user, or:
   ```bash
   ls -t specs/specs_*.md | head -5
   git log --since='1 month ago' --name-only --pretty=format: -- 'specs/specs_*.md' | sort -u
   ```
   Pick the one matching the current branch / feature.
2. **Read the spec**. Find:
   - The `Status:` line near the top
   - Milestone checkboxes (`- [ ]` / `- [x]`)
3. **Compare to current branch reality**:
   ```bash
   git log $BASELINE..HEAD --oneline
   git diff $BASELINE...HEAD --stat
   ```
4. **Update**:
   - Tick `[x]` on completed milestones
   - Mark `[~]` (or note "in progress") on partial work
   - Strike through and annotate de-scoped items with `(de-scoped: <reason>)`
   - Update the `Status:` line: e.g. `Status: 4/7 milestones complete; payment-provider-selection done; Modulr client awaiting credentials`
5. **Add a short progress note** at the bottom under a `## Progress log` heading with today's date and what changed.

## Output format

Produce the edited file via the Edit tool. Show the user a diff summary:

```
specs/specs_20260401_modulr_client.md:
  - Status line updated: "Code complete, awaiting credentials" → "Deployed to staging, prod pending"
  - Milestone 3 (auth flow) marked complete
  - Milestone 5 (webhook handler) marked in-progress
  - Added progress log entry for 2026-05-05
```

## Red flags

- Marking a milestone complete because "the code exists" — verify tests pass and behaviour is observed.
- Silently dropping a milestone instead of marking it de-scoped — leaves no audit trail.
- Updating the spec without committing — the change is invisible to teammates until pushed.
