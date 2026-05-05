---
name: env-example-sync-check
description: Use when the diff modifies .env, settings.py, config.py, environment-variable reads (os.environ, os.getenv, BaseSettings), or before opening a PR. Catches missing entries in .env.example that would break a teammate's first-run setup.
---

# .env.example Sync Check

## Why this matters

`.env` is gitignored. `.env.example` is the contract teammates and CI rely on for first-run setup. When new env vars are added but `.env.example` isn't updated, the next `git pull` breaks for everyone.

## When to use

Run when:
- The diff modifies `.env` (locally, even though gitignored — your shell session sees it)
- New keys appear in `os.environ`, `os.getenv`, `Settings(...)`, or `BaseSettings` subclasses
- Before opening a PR that touches config

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

### Run the check

1. **Find all env vars referenced in code on this branch**:
   ```bash
   git diff $BASELINE...HEAD -- '*.py' | grep -oE '(os\.environ\[|os\.getenv\(|os\.environ\.get\()["\047][A-Z_][A-Z0-9_]+' \
     | grep -oE '[A-Z_][A-Z0-9_]+' | sort -u
   ```
2. **Find env vars declared in Settings classes** in the diff:
   ```bash
   git diff $BASELINE...HEAD -- '*settings*.py' '*config*.py' | grep -E '^\+\s+[a-z_]+:' | grep -oE '[a-z_]+:'
   ```
   Translate snake_case → SCREAMING_SNAKE_CASE for env var names (Pydantic Settings convention).
3. **Read the current `.env.example`**:
   ```bash
   grep -oE '^[A-Z_][A-Z0-9_]+' .env.example | sort -u
   ```
4. **Diff** the two sets. Anything in code but missing from `.env.example` is a gap.
5. **For each gap**, propose a line for `.env.example` with:
   - The key
   - A safe placeholder value (never a real secret)
   - A one-line comment explaining what it is

## Output format

```
Missing from .env.example:
- MODULR_API_KEY        # Modulr payment provider API key (placeholder)
- GA4_PROPERTY_ID       # Google Analytics 4 property ID

Proposed addition (paste into .env.example):

# Modulr — payment provider
MODULR_API_KEY=your-modulr-key-here

# Google Analytics 4
GA4_PROPERTY_ID=123456789
```

If zero gaps: say "`.env.example` is in sync" and stop.

## Red flags

- Pasting real secrets as the placeholder. Never. Use `your-key-here` or `replace-me`.
- Skipping vars that "are only set in production" — they still need a documented placeholder.
