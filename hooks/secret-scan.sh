#!/usr/bin/env bash
# Supercode — block git commits that contain likely secrets.
# Runs as a PreToolUse/Bash hook. Exit 2 blocks the command; exit 0 allows it.
# Language-agnostic: scans the staged diff for common secret shapes.
set -euo pipefail

payload=$(cat 2>/dev/null || printf '')

# Extract the command being run. Fall back to the whole payload so the
# "git commit" match below still works if JSON parsing isn't available.
command=$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null \
  || printf '%s' "$payload")

# Only act on git commits — everything else passes straight through.
case "$command" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

staged=$(git diff --cached 2>/dev/null || printf '')
[ -z "$staged" ] && exit 0

# Common high-signal secret patterns (POSIX ERE, low false-positive).
patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----'
patterns="$patterns|AKIA[0-9A-Z]{16}"
patterns="$patterns|aws_secret_access_key"
patterns="$patterns|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"
patterns="$patterns|[Pp]assword[[:space:]]*=[[:space:]]*['\"][^'\"]{6,}"
patterns="$patterns|Server=.*;[[:space:]]*Password="
patterns="$patterns|xox[baprs]-[0-9A-Za-z-]+"
patterns="$patterns|gh[pousr]_[0-9A-Za-z]{20,}"

if printf '%s' "$staged" | grep -Eiq "$patterns"; then
  echo "supercode: a potential secret was found in the staged changes — commit blocked." >&2
  echo "Remove the secret and use environment variables / a secret manager / a gitignored .env." >&2
  exit 2
fi

exit 0
