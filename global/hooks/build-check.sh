#!/usr/bin/env bash
# Runs at end of Claude turn (Stop hook). Finds nearest .sln or .csproj and builds.
# Only runs when cs-dirty-flag.sh set the dirty flag (i.e. a .cs file was written this turn).
# Silent on success — only emits output when there are errors.

FLAG="${TMPDIR:-/tmp}/claude-build-dirty"
[[ ! -f "$FLAG" ]] && exit 0
rm -f "$FLAG"

# Find nearest solution or project file walking up from CWD
DIR="$PWD"
TARGET=""
while [[ "$DIR" != "/" && -n "$DIR" ]]; do
    FOUND=$(find "$DIR" -maxdepth 1 -name "*.sln" 2>/dev/null | head -1)
    if [[ -n "$FOUND" ]]; then
        TARGET="$FOUND"
        break
    fi
    FOUND=$(find "$DIR" -maxdepth 1 -name "*.csproj" 2>/dev/null | head -1)
    if [[ -n "$FOUND" ]]; then
        TARGET="$FOUND"
        break
    fi
    DIR=$(dirname "$DIR")
done

[[ -z "$TARGET" ]] && exit 0

BUILD_OUTPUT=$(dotnet build "$TARGET" --no-restore -v quiet 2>&1)
ERRORS=$(echo "$BUILD_OUTPUT" | grep -E "(: error |: warning CS)" | head -20)

[[ -z "$ERRORS" ]] && exit 0

echo "--- build errors ---"
echo "$BUILD_OUTPUT" | grep -E "(Build succeeded|Build FAILED)" | head -1
echo ""

while IFS= read -r line; do
    echo "$line"

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
