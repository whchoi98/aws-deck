#!/bin/bash
# SessionStart (optional): report local-environment facts that the code and git do not show.
# Claude Code already injects the branch, status, and recent commits, so this hook does not repeat
# them. Stdout reaches Claude's context; with nothing to report, the hook prints nothing.
# The event JSON on stdin is not read. Registered with `2>/dev/null || true` (observational).
# Keep only checks whose result changes what Claude should do; /init-project adds the ones it detects.

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" 2>/dev/null || exit 0
FACTS=()

# Tools the skills need to build and render a deck (README "Prerequisites"). Without them a skill
# change can only be checked statically with `bash tests/run-all.sh`, not run end to end.
MISSING=()
for tool in node soffice pdftoppm; do
    command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done
if command -v node >/dev/null 2>&1; then
    # SKILL.md falls back to the global modules, so check there too
    GLOBAL_MODULES=$(npm root -g 2>/dev/null)
    NODE_PATH="${NODE_PATH:+$NODE_PATH:}$GLOBAL_MODULES" node -e 'require.resolve("pptxgenjs")' >/dev/null 2>&1 ||
        MISSING+=("pptxgenjs")
fi
if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r name; do
        [ -n "$name" ] && MISSING+=("$name")
    done < <(python3 -c '
import importlib.util
for package, module in (("python-pptx", "pptx"), ("lxml", "lxml"), ("Pillow", "PIL")):
    if importlib.util.find_spec(module) is None:
        print(package)' 2>/dev/null)
else
    MISSING+=("python3")
fi
# svg_to_png.py (diagram previews) needs any one of: playwright, cairosvg, rsvg-convert, ImageMagick
command -v rsvg-convert >/dev/null 2>&1 || command -v magick >/dev/null 2>&1 ||
    python3 -c 'import importlib.util as u, sys; sys.exit(not (u.find_spec("playwright") or u.find_spec("cairosvg")))' 2>/dev/null ||
    MISSING+=("an SVG renderer (cairosvg or rsvg-convert)")
if [ ${#MISSING[@]} -gt 0 ]; then
    FACTS+=("Missing for building and rendering decks: $(printf '%s, ' "${MISSING[@]}" | sed 's/, $//'). Here a skill change can be checked only with bash tests/run-all.sh, not end to end; say so when reporting it.")
fi

# Version drift: installed copies update only when plugin.json's version moves, and the README badge
# and both CHANGELOG halves carry the same version (CLAUDE.md Conventions).
if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r line; do
        [ -n "$line" ] && FACTS+=("$line")
    done < <(python3 - <<'PY' 2>/dev/null
import json
import re


def read(path):
    try:
        with open(path, encoding="utf-8") as handle:
            return handle.read()
    except OSError:
        return ""


def latest_release(section):
    match = re.search(r"^## \[(\d+\.\d+\.\d+)\]", section, re.M)
    return match.group(1) if match else "missing"


for entry in json.loads(read(".claude-plugin/marketplace.json") or "{}").get("plugins", []):
    source = entry.get("source")
    if not isinstance(source, str) or not source.startswith("./"):
        continue  # a remote source (GitHub, git URL) has no manifest in this checkout
    manifest = source[2:].rstrip("/") + "/.claude-plugin/plugin.json"
    try:
        version = str(json.loads(read(manifest))["version"])
    except (ValueError, KeyError, TypeError):
        print("%s has no readable version" % manifest)
        continue
    badge = re.search(r"badge/Version-(\d+\.\d+\.\d+)-", read("README.md"))
    english, marker, korean = read("CHANGELOG.md").partition('<a id="korean"></a>')
    others = [
        ("README version badge", badge.group(1) if badge else "missing"),
        ("CHANGELOG English latest release", latest_release(english)),
        ("CHANGELOG Korean latest release", latest_release(korean) if marker else "missing"),
    ]
    drift = ["%s=%s" % (name, value) for name, value in others if value != version]
    if drift:
        print("Version drift (%s version=%s): %s" % (manifest, version, ", ".join(drift)))
PY
    )
fi

if [ ${#FACTS[@]} -gt 0 ]; then
    echo "=== Project Context ==="
    printf '%s\n' "${FACTS[@]}"
fi
