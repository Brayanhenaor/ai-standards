#!/usr/bin/env bash
# Supercode — nudge clean-code-core + anti-overengineering into context before code edits.
# Runs as a PreToolUse/Write|Edit hook. Never blocks: only injects additionalContext, so a
# missing python3 or an unparseable payload just means no nudge, not a broken edit.
set -euo pipefail

payload=$(cat 2>/dev/null || printf '')

file_path=$(printf '%s' "$payload" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null \
  || printf '')

# Skip non-code files — docs/config/data don't need a clean-code nudge.
case "$file_path" in
  *.md|*.mdx|*.txt|*.json|*.yml|*.yaml|*.lock|*.csv|*.svg|"") exit 0 ;;
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Supercode: apply clean-code-core (zero unnecessary comments — never narrate what the code does or address the developer in-code, only a non-obvious why; SOLID; short single-purpose functions) and anti-overengineering (YAGNI — no structure, abstraction, or dependency without present, real value) to this edit. Invoke those skills now if not already active this turn."}}
JSON
exit 0
