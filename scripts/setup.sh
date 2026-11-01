#!/bin/bash
# Project setup script for new developers.
# Usage: bash scripts/setup.sh

set -e

echo "=== Project Setup ==="

# Check prerequisites
command -v git >/dev/null 2>&1 || { echo "ERROR: git is required"; exit 1; }

# Check the tools the skills need to build and render decks (README "Prerequisites"). The repository
# has no package manifest to install from, and the harness tests need none of these, so a missing
# tool is reported, not installed: npm -g and pip change the machine, not this repository.
echo "Checking skill runtime tools..."
MISSING=0
report() { if [ "$2" = ok ]; then echo "  ok       $1"; else echo "  MISSING  $1"; MISSING=1; fi; }
for tool in python3 node soffice pdftoppm; do
    command -v "$tool" >/dev/null 2>&1 && report "$tool" ok || report "$tool" missing
done
for pair in pptx:python-pptx lxml:lxml PIL:Pillow; do
    python3 -c "import importlib.util, sys; sys.exit(importlib.util.find_spec('${pair%%:*}') is None)" 2>/dev/null &&
        report "${pair#*:} (Python)" ok || report "${pair#*:} (Python)" missing
done
NODE_PATH="${NODE_PATH:+$NODE_PATH:}$(npm root -g 2>/dev/null)" node -e 'require.resolve("pptxgenjs")' >/dev/null 2>&1 &&
    report "pptxgenjs (Node.js)" ok || report "pptxgenjs (Node.js)" missing
{ command -v rsvg-convert || command -v magick ||
    python3 -c 'import importlib.util as u, sys; sys.exit(not (u.find_spec("playwright") or u.find_spec("cairosvg")))'; } >/dev/null 2>&1 &&
    report "SVG renderer (cairosvg, rsvg-convert, playwright, or ImageMagick)" ok ||
    report "SVG renderer (cairosvg, rsvg-convert, playwright, or ImageMagick)" missing
if [ "$MISSING" -eq 1 ]; then
    echo "To run the skills end to end, install what is missing:"
    echo "  npm install -g pptxgenjs                 # v4 or later"
    echo "  pip install python-pptx lxml Pillow cairosvg"
    echo "  LibreOffice (soffice) and Poppler (pdftoppm) from the OS package manager"
    echo "  bash plugins/aws-deck/skills/aws-ppt-skills/scripts/install_fonts.sh   # fonts for faithful QA renders"
fi

# Setup environment
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "IMPORTANT: Edit .env with your actual values"
fi

# Setup Claude Code hooks
if [ -f ".claude/hooks/check-doc-sync.sh" ]; then
    chmod +x .claude/hooks/*.sh
    echo "Claude hooks configured"
fi

# Install the commit-msg hook. `git rev-parse` also finds a linked worktree, where .git is a file.
# A hook manager (core.hooksPath) makes install-hooks.sh print the line to add instead; setup goes on.
if git rev-parse --git-dir >/dev/null 2>&1 && [ -f "scripts/install-hooks.sh" ]; then
    bash scripts/install-hooks.sh || echo "WARNING: commit-msg hook not installed; see the message above"
fi

echo "=== Setup Complete ==="
echo "Next steps:"
echo "  1. Edit .env with your configuration"
echo "  2. Read CLAUDE.md for project conventions"
echo "  3. Read docs/onboarding.md for development workflow"
