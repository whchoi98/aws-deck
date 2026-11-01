# Developer Onboarding

## Quick Start

### 1. Prerequisites
- [ ] Git and Python 3: enough for the harness tests and hooks
- [ ] Claude Code, to load the plugin from this checkout
- [ ] To run the skills end to end: Node.js with `pptxgenjs` v4+, Python `python-pptx`, `lxml`, and `Pillow`, LibreOffice (`soffice`), Poppler (`pdftoppm`), and `cairosvg` or `rsvg-convert`
- [ ] For `aws-ppt-skills` diagrams: the `aws-diagram` skill and the `aws-diagram-design` plugin
- [ ] Push access to `whchoi98/aws-deck`, or a fork

### 2. Setup
```bash
git clone https://github.com/whchoi98/aws-deck.git
cd aws-deck
bash scripts/setup.sh    # lists missing skill runtime tools, installs the commit-msg hook
```

`setup.sh` reports missing tools instead of installing them, because `npm install -g` and `pip install` change the machine rather than the repository. It prints the install commands.

### 3. Verify
```bash
bash tests/run-all.sh                    # harness and plugin structure tests
claude --plugin-dir plugins/aws-deck     # then invoke /aws-deck:aws-ppt-skills in the session
```

## Project Overview
- Read `CLAUDE.md` for project context and conventions
- Read `docs/architecture.md` for the skills, their scripts, and the build-to-QA flow
- Read `plugins/CLAUDE.md` before changing a skill
- Review `docs/decisions/` for architectural decisions

## Development Workflow
- Commits go to `main`, with short imperative subjects ("Add aws-deck plugin"). The commit-msg hook that `scripts/setup.sh` installs removes `Co-Authored-By` lines.
- A release is a `version` bump in `plugins/aws-deck/.claude-plugin/plugin.json`, pushed to `main`, with the same version in both CHANGELOG.md halves and the README badge. Installed copies pick it up after `claude plugin marketplace update whchoi` and `/reload-plugins`.
- Run `bash tests/run-all.sh` before each commit; `/review` reviews the diff.

## Key Concepts
- **Marketplace, plugin, skill**: `.claude-plugin/marketplace.json` lists plugins; `plugins/aws-deck/` is the one plugin; each directory under its `skills/` is a skill that users invoke as `/aws-deck:<skill>`.
- **`$SKILL_DIR`**: a skill runs in the user's project, so `SKILL.md` reaches its scripts, templates, and fonts through the skill's base directory.
- **Two-stage build** (`aws-ppt-skills`): pptxgenjs builds slides on empty masters, then `apply_template.py` moves them onto the real template, which supplies backgrounds, logo, footer, and page numbers.
- **In-place fill** (`pptx-template-fill`): text runs, table cells, and chart caches are edited where they are, so the user's template keeps its formatting.

## Troubleshooting
- `Cannot find module 'pptxgenjs'`: pptxgenjs is installed globally; run `export NODE_PATH="$(npm root -g)"`.
- QA renders use substitute fonts: run `bash plugins/aws-deck/skills/aws-ppt-skills/scripts/install_fonts.sh`.
- A consulting deck renders correctly in LibreOffice, but cards or bullets disappear in PowerPoint: the build skipped `tools/fix_pptx.py`.
- Users do not see a change: `version` in `plugin.json` was not bumped, or they have not run `claude plugin marketplace update whchoi`.

## Resources
- `README.md`: installation and runtime requirements for users
- `plugins/aws-deck/skills/*/SKILL.md`: each skill's workflow, rules, and bundled resources
