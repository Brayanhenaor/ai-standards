#!/usr/bin/env bash
# Runs after Write tool on test files. Finds the containing test project and runs it.

FILE=$(python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('file_path', ''))
except Exception:
    print('')
" <<< "$CLAUDE_TOOL_INPUT" 2>/dev/null)

# Only act on test files
[[ "$FILE" != *Tests.cs && "$FILE" != *Test.cs && "$FILE" != *Specs.cs ]] && exit 0

# Walk up from the file to find the nearest .csproj that contains "Test"
DIR=$(dirname "$FILE")
PROJ=""
while [[ "$DIR" != "/" && "$DIR" != "." ]]; do
    FOUND=$(find "$DIR" -maxdepth 1 -name "*.csproj" | grep -iE "Test|Spec" | head -1)
    if [[ -n "$FOUND" ]]; then
        PROJ="$FOUND"
        break
    fi
    DIR=$(dirname "$DIR")
done

if [[ -z "$PROJ" ]]; then
    echo "⚠️  No se encontró proyecto de tests para: $(basename "$FILE")"
    exit 0
fi

RESULTS=$(dotnet test "$PROJ" --no-build -v quiet 2>&1 \
  | grep -E "(Passed|Failed|Skipped|Error|FAILED|passed|failed)" \
  | tail -20)

if echo "$RESULTS" | grep -qiE "(failed|error)"; then
    echo "--- tests: $(basename "$PROJ") ---"
    echo "$RESULTS"
    echo "---"
fi
