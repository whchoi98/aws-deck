<!-- Prune test: keep a line only if removing it would cause Claude to make a mistake. Leave out what Claude can read from the code or config. -->

# Project Context

## Overview
The `whchoi` Claude Code plugin marketplace. It ships one plugin, `aws-deck`, whose skills build AWS Korea PowerPoint decks: `aws-ppt-skills` (2026 black and white seminar templates), `consulting-ppt-white-ppt` (dense consulting-report style), and `pptx-template-fill` (fill a template the user supplies, in place).

## Tech Stack
- Claude Code plugin format: skills are `SKILL.md` files with YAML frontmatter; Claude routes on `description`
- Node.js with `pptxgenjs` v4+ builds decks; it is installed globally, so `require` may need `NODE_PATH="$(npm root -g)"`
- Python 3 with `python-pptx`, `lxml`, and `Pillow` edits and post-processes `.pptx` files
- LibreOffice (`soffice`) and Poppler (`pdftoppm`) render slides for visual QA

## Project Structure
```text
.claude-plugin/marketplace.json   - Marketplace manifest (name "whchoi"); each entry points at a plugin source dir
plugins/aws-deck/                 - The shipped plugin; everything under it is copied to every user who installs it
  .claude-plugin/plugin.json      - Plugin manifest; installed copies update only when its version changes
  skills/<skill>/                 - SKILL.md plus the scripts/, tools/, lib/, references/, assets/ it calls
tests/                            - Harness and plugin structure tests, sourced by tests/run-all.sh
```

## Conventions
- A skill runs with the user's project as the working directory, so SKILL.md calls its bundled files through `$SKILL_DIR` (the skill's base directory), never a relative path. `tests/structure/test-marketplace.sh` fails when a `$SKILL_DIR/<path>` does not exist.
- A user-visible skill change ships only when `version` in `plugins/aws-deck/.claude-plugin/plugin.json` is bumped and pushed. Bump it in the same commit as the change, with the release in both CHANGELOG.md halves and the README version badge; the SessionStart hook reports drift between them.
- Keep development output out of `plugins/aws-deck/` (scratch decks, renders, `__pycache__/`), because the whole directory ships. `examples/sample_output.pptx` is there on purpose.
- The `.pptx` templates under `assets/templates/` are the read-only source of the brand (backgrounds, logo, footer, page numbers); fix layout in the build helpers, not in the templates.
- `aws-ppt-skills` draws diagrams through the `aws-diagram` skill and the `aws-diagram-design` plugin, which live outside this repository.
- Test files are sourced by `tests/run-all.sh` under `set -euo pipefail`: guard every command that may fail, never call `exit`, and prefix variables per file.

## Key Commands
```bash
bash tests/run-all.sh                 # harness + plugin structure tests
bash tests/run-all.sh marketplace     # only test files whose name matches the filter
bash scripts/setup.sh                 # report missing skill runtime tools, install the commit-msg hook
claude --plugin-dir plugins/aws-deck  # try the plugin from this checkout, without the marketplace
```

Verify a change: `bash tests/run-all.sh`
Run it before reporting a change done. A syntax-only check, or a command that failed to start, does not count; if it cannot run here, say which check you skipped and why. It checks manifests, frontmatter, `$SKILL_DIR` paths, and script syntax, not deck output: for a change to a build script or helper, also build a deck with the skill, or say that the tools for it are missing.

---

## Auto-Sync Rules

Claude applies these while working; nothing runs automatically. Docs change in the same commit as the code they describe, so a reviewer sees both.

- Update `docs/architecture.md` when components or data flows change.
- Add an ADR (`/add-adr`) when a choice would be expensive to reverse or a future reader would ask why it was made.
- Add a module `CLAUDE.md` (`/add-module`) only for a module with rules or gotchas the code does not show.
- Write a runbook (`/add-runbook`) for a procedure someone will repeat under pressure: a deploy, a rollback, a migration.
- Update this file when a command, convention, or structure it describes changes.

### ADR Numbering
Find the highest number in `docs/decisions/ADR-*.md` and increment by 1.
Format: `ADR-NNN-concise-title.md`

## Implementation References
<!-- AUTO-MANAGED:references -->
Layer-by-layer implementation guides in `docs/reference/`. See [INDEX](docs/reference/INDEX.md).
- [Security](docs/reference/security.md)
<!-- /AUTO-MANAGED -->
