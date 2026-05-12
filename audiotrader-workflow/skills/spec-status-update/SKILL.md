---
name: spec-status-update
description: Use when work on a spec'd feature is shipping, just shipped, or wrapping up — natural cues include "we're done", "ship it", "shipping this", "merged", "merging to main", "let's wrap up", "EOD", "update the spec", "mark this done", and tool/command events like `gh pr merge`, squash to `main`, `git push origin main`, or deleting a feature branch. Also use at the start of a feature-branch session to pick up the matching spec, and to sweep specs whose Status already reads complete but are still sitting in `specs/` root instead of `specs/archive/YYYYMM/`. Pairs with `finishing-a-development-branch`.
---

# Spec Status Update

## Why this matters

The spec is the source of truth for what was promised vs delivered. A stale `Status:` line is worse than no status — it tells future-you (or a teammate) that work is done when it isn't, or that something is still in flight when it actually shipped. Per `CLAUDE.md`, completed specs must be archived to `specs/archive/YYYYMM/` *as soon as work ships* (not on a 30-day timer) — drift between docs and code is the failure mode this skill exists to prevent.

## When to invoke

Trigger on:
- A PR is merging, just merged, or about to merge (`gh pr merge`, squash to `main`, branch delete)
- The user wraps up a feature: "we're done", "ship it", "shipping", "deployed", "live", "EOD"
- A milestone or step was completed, de-scoped, or pushed to a follow-up
- The user explicitly says "update the spec" / "mark this done"
- Session start on a feature branch — so the active spec is identified upfront
- `finishing-a-development-branch` ran or is about to run

## Procedure

### 1. Determine review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:
- `$CURRENT` ≠ `$DEFAULT` (feature branch): `BASELINE=$DEFAULT`
- `$CURRENT` = `$DEFAULT` with unpushed commits: `BASELINE=@{u}`
- Otherwise: stop and ask the user which range to review.

### 2. Identify the active spec (deterministic mapping)

Derive a slug from the branch name and look for a matching spec file:

```bash
BRANCH=$(git branch --show-current)
SLUG=$(echo "$BRANCH" | sed -E 's@^(feature|feat|fix|bugfix|chore|refactor)/@@; s/-/_/g')
MATCHES=$(ls specs/specs_*_${SLUG}.md 2>/dev/null)
```

- **Exactly one match** → that's the active spec. Proceed.
- **Zero matches** → fall back to specs touched on this branch:
  ```bash
  git log $BASELINE..HEAD --name-only --pretty=format: -- 'specs/specs_*.md' | sort -u
  ```
  If still nothing, stop and ask the user.
- **Multiple matches** → stop, list them, ask the user to pick.

Never proceed with a guessed spec.

### 3. Verify what actually shipped

Don't infer "done" from code presence. Concretely check:

```bash
git log $BASELINE..HEAD --oneline
git diff $BASELINE...HEAD --stat
gh pr view 2>/dev/null      # if a PR exists
```

- For tests: run the relevant suite (e.g., `pytest packages/prism/tests/<area>/`) and confirm green output.
- For UI features: confirm the feature was exercised in the browser (per `CLAUDE.md`'s "Verify Before Done").

If you can't verify a milestone, say so explicitly in the Status update — don't tick a checkbox you didn't earn.

### 4. Update the spec

- Tick `[x]` on milestones whose tests/behaviour you verified.
- Mark `[~]` (or annotate "in progress") on partial work.
- Strike through and annotate de-scoped items with `(de-scoped: <reason>)`.
- Rewrite the `Status:` line to reflect today's reality, e.g.:
  - `Status: ✅ ALL COMPLETE — shipped to main 2026-05-12 via PR #143`
  - `Status: 4/7 milestones complete; payment-provider-selection done; Modulr client awaiting credentials`
- Add a short note at the bottom under `## Progress log` with today's date.

### 5. Archive if shipped (inline, in the same flow)

If your Status update flips the spec into a shipped / complete / merged state, propose the archive move in the *same invocation*:

```bash
SPEC=specs/specs_<YYYYMMDD>_<name>.md
YYYYMM=$(echo "$SPEC" | sed -E 's@^specs/specs_([0-9]{4})([0-9]{2})[0-9]{2}_.*@\1\2@')
mkdir -p specs/archive/$YYYYMM
git mv "$SPEC" "specs/archive/$YYYYMM/"
```

`YYYYMM` comes from the spec's *own* filename date prefix (preserves chronological archive order), not today's date.

**Always show the planned `git mv` and wait for "yes" before executing.** File moves aren't trivially reversible; one confirmation is cheap insurance.

**Refuse to archive any spec whose Status doesn't unambiguously say done.** Blockers:
- Status contains: `in progress`, `pending`, `awaiting`, `draft`, `implementing`, `investigating`
- Partial-completion phrasing: `phases 1-4 complete; phase 5 pending`
- Any remaining `- [ ]` unchecked milestone boxes in the file

### 6. Catch-up sweep (end of every invocation)

Before finishing, scan `specs/` root for already-shipped specs that never got archived:

```bash
for f in specs/specs_*.md; do
  STATUS=$(grep -m1 -i -E '^\*?\*?Status' "$f")
  UNCHECKED=$(grep -c '^- \[ \]' "$f")   # grep -c always prints a count, even when 0
  if echo "$STATUS" | grep -qiE 'shipped|merged|deployed|implemented|live in production|all complete|✅' \
     && ! echo "$STATUS" | grep -qiE 'in progress|pending|awaiting|draft|implementing|investigating|ready to|ready for|brainstorm|analysis|next:|todo' \
     && [ "$UNCHECKED" = "0" ]; then
    echo "ARCHIVE CANDIDATE: $f  —  $STATUS"
  fi
done
```

The positive regex deliberately excludes bare *"complete"* — phrases like *"Investigation complete, ready to implement"* or *"Brainstorm complete — ready for plan"* mark the *start* of work, not the end. Require an action verb (`shipped|merged|deployed|implemented`) or an unambiguous marker (`✅`, `all complete`, `live in production`) before treating a spec as archive-ready.

Present the list to the user as a batch with the proposed `git mv` commands. Approve in one go or skip individual entries. This cleans the historical backlog and any spec that someone else marked complete without invoking this skill.

## Output format

Use the Edit tool for status/checkbox changes. Show the user a diff summary:

```
specs/specs_20260430_orders_dashboard.md:
  - Status line: "Phase 3 in progress" → "✅ ALL COMPLETE — shipped to main 2026-05-12 via PR #143"
  - Milestones 4, 5, 6 marked complete
  - Progress log entry added for 2026-05-12

Proposed archive (awaiting confirmation):
  git mv specs/specs_20260430_orders_dashboard.md specs/archive/202604/

Catch-up sweep — 3 specs in root already read complete:
  specs/specs_20260406_pnl_automation.md   → specs/archive/202604/
  specs/specs_20260427_mint_condition.md   → specs/archive/202604/
  specs/specs_20260505_l6_fee_reversals.md → specs/archive/202605/
```

## Red flags

- Ticking `[x]` because "the code exists" — run the tests or observe the feature first.
- Silently dropping a milestone instead of marking it de-scoped — leaves no audit trail.
- Auto-moving files without explicit user confirmation — file moves aren't trivially reversible.
- Archiving a spec that still has unchecked boxes or a "pending" / "in progress" Status — defeats the rule's purpose.
- Using *today's* date for the `YYYYMM` archive folder — use the spec's filename date prefix so the archive stays chronologically ordered by spec age.
- Updating the spec without committing and pushing — the change is invisible to teammates.
