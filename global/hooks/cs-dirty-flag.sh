#!/usr/bin/env bash
# PostToolUse hook (Write + Edit). Sets dirty flag when a .cs file is written.
# build-check.sh reads this flag at Stop to skip builds on turns with no code changes.

[[ -z "$CLAUDE_TOOL_INPUT" ]] && exit 0

FILE_PATH=$(python3 -c "
import sys, json
try:
    d = json.loads(sys.argv[1])
    print(d.get('file_path', ''))
except Exception:
    pass
" "$CLAUDE_TOOL_INPUT" 2>/dev/null)

[[ "$FILE_PATH" == *.cs ]] && touch "${TMPDIR:-/tmp}/claude-build-dirty"

exit 0
