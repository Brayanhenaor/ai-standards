#!/usr/bin/env bash
# Runs after Write/Edit tool. Compiles the solution and feeds errors back to Claude.

FILE=$(python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('file_path', ''))
except Exception:
    print('')
" <<< "$CLAUDE_TOOL_INPUT" 2>/dev/null)

# Only act on hand-written C# source files
[[ "$FILE" != *.cs ]]                   && exit 0
[[ "$FILE" == */Migrations/* ]]         && exit 0
[[ "$FILE" == *.g.cs ]]                 && exit 0
[[ "$FILE" == *.Designer.cs ]]          && exit 0

echo "--- build ---"
dotnet build --no-restore -v quiet 2>&1 \
  | grep -E "(: error |: warning CS|Build succeeded|Build FAILED)" \
  | head -40
echo "-------------"
