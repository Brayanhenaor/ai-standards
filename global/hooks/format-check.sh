#!/usr/bin/env bash
# Stop hook. Checks dotnet format after turns that modified .cs files.
# Silent on pass — only emits output when formatting issues are found.
# Requires: cs-dirty-flag.sh running on PostToolUse (Write + Edit).

FLAG="${TMPDIR:-/tmp}/claude-build-dirty"
[[ ! -f "$FLAG" ]] && exit 0

# Find nearest solution or project file
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

# Check format without applying changes
FORMAT_OUTPUT=$(dotnet format "$TARGET" --verify-no-changes --verbosity diagnostic 2>&1)
EXIT_CODE=$?

[[ $EXIT_CODE -eq 0 ]] && exit 0

# Extract files with issues
ISSUES=$(echo "$FORMAT_OUTPUT" | grep -E "^  Formatted|Run dotnet format|warning:" | head -20)

echo "--- dotnet format: archivos con problemas de formato ---"
echo ""
echo "$ISSUES"
echo ""
echo "Corregir con: dotnet format $(basename "$TARGET")"
echo "---"
