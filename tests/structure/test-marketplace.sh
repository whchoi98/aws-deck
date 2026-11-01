#!/bin/bash
# Tests for the marketplace and the plugins it lists: manifests, SKILL.md frontmatter, the files a
# SKILL.md calls through $SKILL_DIR, and the syntax of every bundled script.
# Sourced by run-all.sh under `set -euo pipefail`: every command that may fail is guarded.
# Static checks only: building a deck needs pptxgenjs, python-pptx, LibreOffice, and Poppler, which
# the harness does not require (.claude/hooks/session-context.sh reports the ones that are missing).

assert_json_valid "marketplace.json is valid JSON" ".claude-plugin/marketplace.json"

# One line per check from the manifest and skill scan: PASS|FAIL TAB <description> TAB <reason>
MK_RESULTS=$(python3 - <<'PY' 2>&1 || true
import json
import os
import re


def emit(ok, desc, reason=""):
    print("%s\t%s\t%s" % ("PASS" if ok else "FAIL", desc, reason))


def frontmatter(text):
    """Top-level `key: value` pairs, with quoted values unquoted and folded blocks (> |) joined."""
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---", 4)
    if end < 0:
        return None
    fields, key = {}, None
    for line in text[4:end].split("\n"):
        match = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", line)
        if match:
            key, value = match.group(1), match.group(2).strip()
            if value in (">", "|", ">-", "|-"):
                value = ""
            elif len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            fields[key] = value
        elif key and line[:1] in (" ", "\t"):
            fields[key] = (fields[key] + " " + line.strip()).strip()
    return fields


# $SKILL_DIR/<path>, ${SKILL_DIR}/<path>, and Python's f"{SKILL_DIR}/<path>"
SKILL_REF = re.compile(r"(?:\$\{|\$|\{)SKILL_DIR\}?/([\w.\-/]+)")
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")

marketplace = json.load(open(".claude-plugin/marketplace.json", encoding="utf-8"))
plugins = marketplace.get("plugins", [])
emit(bool(plugins), "marketplace.json lists at least one plugin", "plugins[] is empty")
meta_version = (marketplace.get("metadata") or {}).get("version")

for entry in plugins:
    name, source = entry.get("name", ""), entry.get("source")
    if not isinstance(source, str) or not source.startswith("./"):
        continue  # a remote source has nothing to check in this checkout
    root = source[2:].rstrip("/")
    manifest_path = os.path.join(root, ".claude-plugin", "plugin.json")
    try:
        manifest = json.load(open(manifest_path, encoding="utf-8"))
    except (OSError, ValueError) as err:
        emit(False, "%s: plugin.json is readable JSON" % name, "%s: %s" % (manifest_path, err))
        continue
    emit(manifest.get("name") == name, "%s: plugin.json name matches the marketplace entry" % name,
         "plugin.json name is %r" % manifest.get("name"))
    version = str(manifest.get("version", ""))
    emit(bool(SEMVER.match(version)), "%s: plugin.json version is X.Y.Z" % name, "got %r" % version)
    for label, other in (("plugins[].version", entry.get("version")), ("metadata.version", meta_version)):
        if other is not None:
            emit(str(other) == version, "%s: marketplace.json %s matches plugin.json" % (name, label),
                 "%s vs plugin.json %s" % (other, version))

    skills_dir = os.path.join(root, "skills")
    skills = sorted(d for d in os.listdir(skills_dir) if os.path.isdir(os.path.join(skills_dir, d))) \
        if os.path.isdir(skills_dir) else []
    emit(bool(skills), "%s: has at least one skill" % name, "no directories under %s" % skills_dir)
    for skill in skills:
        skill_dir = os.path.join(skills_dir, skill)
        skill_md = os.path.join(skill_dir, "SKILL.md")
        if not os.path.isfile(skill_md):
            emit(False, "%s/%s: SKILL.md exists" % (name, skill), "missing %s" % skill_md)
            continue
        text = open(skill_md, encoding="utf-8").read()
        fields = frontmatter(text)
        if fields is None:
            emit(False, "%s/%s: SKILL.md has YAML frontmatter" % (name, skill), "no leading --- block")
            continue
        emit(fields.get("name") == skill, "%s/%s: frontmatter name matches the directory" % (name, skill),
             "name is %r" % fields.get("name"))
        description = fields.get("description", "")
        emit(bool(description), "%s/%s: frontmatter has a description" % (name, skill), "empty or missing")
        # Claude Code truncates description + when_to_use at 1,536 characters in the skill listing,
        # and Claude routes on that text
        routing = len(description) + len(fields.get("when_to_use", ""))
        emit(routing <= 1536, "%s/%s: description fits the 1,536-character listing" % (name, skill),
             "%d characters" % routing)

        # Every file the skill's docs call through $SKILL_DIR must ship with the skill
        docs = [skill_md] + sorted(
            os.path.join(skill_dir, "references", f)
            for f in (os.listdir(os.path.join(skill_dir, "references"))
                      if os.path.isdir(os.path.join(skill_dir, "references")) else [])
            if f.endswith(".md"))
        missing = sorted({
            ref for doc in docs for ref in (m.rstrip(".,/") for m in SKILL_REF.findall(open(doc, encoding="utf-8").read()))
            if ref and not os.path.exists(os.path.join(skill_dir, ref))
        })
        emit(not missing, "%s/%s: every $SKILL_DIR path in its docs exists" % (name, skill),
             "missing: %s" % ", ".join(missing))
PY
)
while IFS=$'\t' read -r mk_status mk_desc mk_reason; do
    case "$mk_status" in
        PASS) pass "$mk_desc" ;;
        FAIL) fail "$mk_desc" "$mk_reason" ;;
        "") ;;
        *) fail "marketplace scan ran" "$mk_status $mk_desc $mk_reason" ;;   # a Python traceback line
    esac
done <<< "$MK_RESULTS"

# --- Script syntax under plugins/ ---

# Python: compile() rather than py_compile, so no __pycache__ lands in the shipped plugin directory
MK_PY_BAD=$(python3 - <<'PY' 2>&1 || true
import os
for top, dirs, files in os.walk("plugins"):
    for f in sorted(files):
        if f.endswith(".py"):
            path = os.path.join(top, f)
            try:
                compile(open(path, encoding="utf-8").read(), path, "exec")
            except SyntaxError as err:
                print("%s:%s: %s" % (path, err.lineno, err.msg))
PY
)
assert_eq "Python scripts under plugins/ compile" "" "$MK_PY_BAD"

if command -v node >/dev/null 2>&1; then
    MK_JS_BAD=""
    while IFS= read -r mk_js; do
        [ -n "$mk_js" ] || continue
        node --check "$mk_js" >/dev/null 2>&1 || MK_JS_BAD="$MK_JS_BAD $mk_js"
    done < <(find plugins -name '*.js' -not -path '*/node_modules/*' | sort)
    assert_eq "JavaScript under plugins/ passes node --check" "" "$MK_JS_BAD"
else
    skip "JavaScript under plugins/ passes node --check" "node is not installed"
fi

while IFS= read -r mk_sh; do
    [ -n "$mk_sh" ] || continue
    assert_bash_syntax "$mk_sh valid bash" "$mk_sh"
done < <(find plugins -name '*.sh' | sort)
