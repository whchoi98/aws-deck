# Plugins

## Role
Plugin sources listed in `.claude-plugin/marketplace.json`. This file sits above `plugins/aws-deck/`, not inside it, because the marketplace ships the plugin directory as-is and this guidance is for maintaining it, not for its users.

## Invariants and gotchas
- A skill's directory name, its frontmatter `name`, and the user's command `/aws-deck:<name>` are the same string; renaming the directory is a breaking change for everyone who invokes it.
- The `SKILL.md` body loads in full whenever the skill triggers, and `aws-ppt-skills/SKILL.md` is already large; put detail needed only for some decks in `references/*.md` and link it, so it loads on demand.
- The skills share no code. `aws-ppt-skills` keeps its pptxgenjs helpers inside `SKILL.md` ("Reusable Helper Functions", pasted into each build), `consulting-ppt-white-ppt` in `lib/consult_helpers.js`, and `pptx-template-fill` in `scripts/tfill.py`; fix a helper where its skill keeps it.
- A clean LibreOffice render does not prove the deck opens correctly in PowerPoint: `consulting-ppt-white-ppt/tools/fix_pptx.py` repairs cards and bullets that only PowerPoint drops. Keep such post-build fixes in the workflow when changing a build.

## Entry point
Read the skill's `SKILL.md` first: its workflow section names every script it runs, in order.
