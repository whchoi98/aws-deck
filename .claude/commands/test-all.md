---
description: Run the harness and plugin structure tests, then report failures. Use after a change, or when asked to run the tests.
allowed-tools: Read, Grep, Bash(bash tests/run-all.sh *)
argument-hint: "[test file or pattern]"
effort: low
---

Run `bash tests/run-all.sh` (pass $ARGUMENTS to it as the test-file filter if given). It covers the harness (hooks, secret patterns, structure) and the plugin itself (manifests, SKILL.md frontmatter, the files each SKILL.md calls through `$SKILL_DIR`, script syntax); it does not build a deck.

Report the totals for each suite first (passed, failed, skipped), then each failure with `file:line` and the assertion message. When a suite's command could not start, for example because a tool or the project's dependencies are missing, report it as not run, with the error, never as passed. If the cause is evident from the output, name it in one line. Do not change code unless asked, because the user decides whether a red test is a bug or a stale test.
