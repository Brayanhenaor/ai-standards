#!/usr/bin/env bash
# Runs after Write/Edit tool on .cs files.
# Compiles the solution and shows errors with surrounding code context.

FILE=$(python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('file_path', ''))
except Exception:
    print('')
" <<< "$CLAUDE_TOOL_INPUT" 2>/dev/null)

[[ "$FILE" != *.cs ]]           && exit 0
[[ "$FILE" == */Migrations/* ]] && exit 0
[[ "$FILE" == *.g.cs ]]         && exit 0
[[ "$FILE" == *.Designer.cs ]]  && exit 0

BUILD_OUTPUT=$(dotnet build --no-restore -v quiet 2>&1)

# Extract only error and warning lines
ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "(: error |: warning CS)" | head -20)

if [[ -z "$ERRORS" ]]; then
    echo "$BUILD_OUTPUT" | grep -E "(Build succeeded|Build FAILED)" | head -1
    exit 0
fi

echo "--- build errors ---"
echo "$BUILD_OUTPUT" | grep -E "(Build succeeded|Build FAILED)" | head -1
echo ""

# For each error/warning: show the message, then the code at that location
while IFS= read -r line; do
    echo "$line"

    # Parse: /path/to/File.cs(lineNum,col): error ...
    if [[ "$line" =~ ^([^(]+\.cs)\(([0-9]+),[0-9]+\) ]]; then
        ERR_FILE="${BASH_REMATCH[1]}"
        ERR_LINE="${BASH_REMATCH[2]}"

        if [[ -f "$ERR_FILE" ]]; then
            START=$(( ERR_LINE - 3 ))
            END=$(( ERR_LINE + 3 ))
            [[ $START -lt 1 ]] && START=1

            echo "  ┌─ $ERR_FILE"
            awk -v s="$START" -v e="$END" -v el="$ERR_LINE" \
                'NR>=s && NR<=e {
                    marker = (NR==el) ? "→" : " "
                    printf "  │%s %4d │  %s\n", marker, NR, $0
                }' "$ERR_FILE"
            echo "  └─"
        fi
    fi
    echo ""
done <<< "$ERRORS"

echo "---"
