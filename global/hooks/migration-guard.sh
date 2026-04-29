#!/usr/bin/env bash
# Runs before Bash tool. Blocks destructive EF Core operations and shows current state.

CMD=$(python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('command', ''))
except Exception:
    print('')
" <<< "$CLAUDE_TOOL_INPUT" 2>/dev/null)

if ! echo "$CMD" | grep -qE "ef database (update|drop)|ef migrations (remove|reset)"; then
    exit 0
fi

echo "⛔  Operación destructiva de EF bloqueada"
echo ""
echo "Comando interceptado:"
echo "  $CMD"
echo ""
echo "Migraciones actuales:"
dotnet ef migrations list 2>&1 | tail -20
echo ""
echo "Ejecuta el comando manualmente si es tu intención."
exit 2
