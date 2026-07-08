# audiotrader-skills

Audio Trader's Claude Code marketplace. Bundles the engineering workflow as installable skills and slash commands, so every dev gets the same pre-ship gates and review prompts on every project.

This repo is **public for read access** but **not licensed for reuse** — see [LICENSE](LICENSE). The contents reference Audio Trader internal conventions (`CODING_GUIDELINES.md`, the Prism codebase layout, our spec format) and aren't intended to be copied into other projects without permission.

## What's inside

A single plugin, **`audiotrader-workflow`**, containing:

- **8 auto-trigger skills** that fire when context matches (e.g. before claiming a feature is done, when an Alembic migration changes a shared table)
- **14 user-invoked slash commands** for verification reviews (Principal Engineer / QA review prompts, multi-hat spec review, ADR authoring, architecture deepening, diagnosis, local CI run)

See `audiotrader-workflow/README.md` for the full inventory and per-item details.

## Install (for teammates)

In any project where you want these tools available:

```
/plugin marketplace add zsolt-audiotrader/audiotrader-skills
/plugin install audiotrader-workflow@audiotrader-skills
```

Verify with:

```
/plugin list
```

You should see `audiotrader-workflow` listed. The slash commands appear under `/<plugin>:<command>` (e.g. `/audiotrader-workflow:principal-review-correctness`); skills auto-load when their `description` matches the current task.

## Update

Plugins auto-update when you re-run `/plugin install` or `/plugin update`. We bump the `version` field in `audiotrader-workflow/.claude-plugin/plugin.json` for material changes.

## Contributing

1. Branch off `main`: `git checkout -b feat/<short-name>`
2. Add or edit a skill (`audiotrader-workflow/skills/<name>/SKILL.md`) or command (`audiotrader-workflow/commands/<name>.md`).
3. **Test before merging**:
   - For skills: dispatch a fresh Claude subagent with a realistic scenario without the skill; observe what it does. Then load the skill and verify behaviour changes correctly. (See the `superpowers:writing-skills` skill — RED-GREEN-REFACTOR for documentation.)
   - For commands: invoke the command in a real project, verify the prompt produces useful output.
4. Bump `audiotrader-workflow/.claude-plugin/plugin.json` `version` for material changes.
5. Open a PR. Merge via squash.

## Status line

`statusline-command.sh` is a Claude Code [status line](https://docs.claude.com/en/docs/claude-code/statusline) script, tracked here so the team can share one consistent prompt.

**Purpose** — renders a compact, colour-coded status line at the bottom of the Claude Code TUI, so you can see at a glance which model you're on, where you are in git, how much context you've burned, and what the session has cost.

**Output** — reads the session JSON from stdin and prints a single line:

```
[Opus 4.8] audiotrader-skills | git:  main* ↑2 | ▰▰▰▱▱▱▱▱▱▱ 28% | $0.42 | 3m 12s
```

- **`[model]`** — the active model's display name (green).
- **`folder`** — the current working directory's basename (blue).
- **`git: branch`** — current branch (magenta), with `*` if the working tree is dirty (yellow), `↑N` commits ahead (green) and `↓N` commits behind upstream (red). Omitted outside a git repo.
- **context bar** — a 10-segment `▰▱` bar plus the percentage of the context window used; the percentage turns yellow at ≥70% and red at ≥90%.
- **`$cost`** — total session cost in USD (yellow).
- **duration** — wall-clock session time as `Xm Ys` (dim cyan).

Requires `jq` and `git` on `PATH`.

**Installation** — point your Claude Code settings at the script:

```json
// ~/.claude/settings.json (or a project .claude/settings.json)
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/audiotrader-skills/statusline-command.sh"
  }
}
```

Make sure it's executable (`chmod +x statusline-command.sh`), then start a new Claude Code session. The status line is per-user config — it is **not** distributed by the plugin install, so each dev wires it up once.

## Layout

```
audiotrader-skills/
├── .claude-plugin/
│   └── marketplace.json              # marketplace manifest
├── README.md                          # this file
├── LICENSE                            # all rights reserved
├── NOTICES.md                         # third-party attribution
├── statusline-command.sh              # shared Claude Code status line
└── audiotrader-workflow/              # the plugin
    ├── .claude-plugin/
    │   └── plugin.json                # plugin manifest + version
    ├── README.md                      # full inventory
    ├── skills/<name>/SKILL.md         # auto-trigger skills
    ├── commands/<name>.md             # user-invoked slash commands
    └── references/<name>.md           # shared reference docs for skills/commands
```

## Why a plugin marketplace and not a shared `.claude/skills/` directory?

Single source of truth, namespaced installation, automatic updates on commit. Submodules and symlinks were considered and rejected — see the original design discussion if curious.

## License

See [LICENSE](LICENSE). All rights reserved by Audio Trader. The source is published for transparency and as documentation; no licence is granted to copy, modify, distribute, or reuse the contents in any other project. Contact the repo owner for licensing inquiries.
