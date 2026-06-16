---
name: review
description: Audit code against the full Supercode ruleset and report real problems and clean-code improvements by severity. Use when asked to review code, audit a change, check quality before a PR, or find clean-code issues. Scope is the current diff (default) or the whole project.
---

# Review

Audit code against the whole Supercode ruleset — `clean-code-core`, `anti-overengineering`, and the
active stack pack (e.g. .NET) — and report **real** findings, not nitpicks. The heavy, isolated work
runs in the `code-reviewer` subagent; this skill picks the scope, dispatches, and consolidates.

## Usage

```
/supercode:review            # default: the current diff (uncommitted changes vs HEAD)
/supercode:review --diff     # explicit diff scope
/supercode:review --full     # the whole project (or a path: --full src/payments)
```

## 1. Resolve scope

- **`--diff` (default):** the working changes. Collect them with:
  - `git diff --name-only HEAD` (staged + unstaged)
  - `git ls-files --others --exclude-standard` (new untracked files)
  - If the tree is clean, tell the developer there's nothing to review and offer `--full`.
- **`--full`:** all source files under the repo root, or under the given path. Respect `.gitignore`;
  skip vendored/generated/build dirs (`node_modules`, `bin`, `obj`, `dist`, `.git`). For a large
  tree, review by module and **state what you covered and what you deferred** — never imply full
  coverage you didn't do.

## 2. Detect the active stack

Identify the language/stack from the files and project markers (`*.csproj`, `package.json`,
`pyproject.toml`, `go.mod`…). If a Supercode stack pack matches, the reviewer applies its rules on
top of the core. If none matches, the universal core still fully applies.

## 3. Dispatch the reviewer

Launch the **`code-reviewer`** subagent with the resolved file set and stack. For a large `--full`
run, split by module and launch reviewers in parallel, one per module. Pass each the exact files to
read so it doesn't wander the whole tree.

## 4. Consolidate and report

Merge the subagent findings, drop duplicates, and present grouped by severity, highest first:

```
[CRITICAL]    file:line — problem · why it matters · suggested fix
[IMPROVEMENT]  file:line — problem · why · suggested fix
[TECHNICAL]   file:line — problem · why · suggested fix
```

- Lead with a one-line verdict (e.g. "3 critical, 7 improvements across 12 files").
- Report only findings you can justify against a rule — no style preferences dressed up as defects.
- Do **not** edit code here; review reports, it doesn't fix. (A fix pass is a separate, explicit step.)
- Reply in the developer's language; keep code, identifiers, and snippets in English.
