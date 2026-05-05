# audiotrader-skills

Audio Trader's Claude Code marketplace. Bundles the engineering workflow as installable skills and slash commands, so every dev gets the same pre-ship gates and review prompts on every project.

This repo is **public for read access** but **not licensed for reuse** — see [LICENSE](LICENSE). The contents reference Audio Trader internal conventions (`CODING_GUIDELINES.md`, the Prism codebase layout, our spec format) and aren't intended to be copied into other projects without permission.

## What's inside

A single plugin, **`audiotrader-workflow`**, containing:

- **5 auto-trigger skills** that fire when context matches (e.g. before claiming a feature is done, when an Alembic migration changes a shared table)
- **10 user-invoked slash commands** for verification reviews (Principal Engineer / QA review prompts, multi-hat spec review, ADR authoring, local CI run)

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

## Layout

```
audiotrader-skills/
├── .claude-plugin/
│   └── marketplace.json              # marketplace manifest
├── README.md                          # this file
└── audiotrader-workflow/              # the plugin
    ├── .claude-plugin/
    │   └── plugin.json                # plugin manifest + version
    ├── README.md                      # full inventory
    ├── skills/<name>/SKILL.md         # auto-trigger skills
    └── commands/<name>.md             # user-invoked slash commands
```

## Why a plugin marketplace and not a shared `.claude/skills/` directory?

Single source of truth, namespaced installation, automatic updates on commit. Submodules and symlinks were considered and rejected — see the original design discussion if curious.

## License

See [LICENSE](LICENSE). All rights reserved by Audio Trader. The source is published for transparency and as documentation; no licence is granted to copy, modify, distribute, or reuse the contents in any other project. Contact the repo owner for licensing inquiries.
