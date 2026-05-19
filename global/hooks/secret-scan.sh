#!/usr/bin/env bash
# PreToolUse hook (Bash). Blocks git commit when staged files contain secret patterns.
# Scans for: API keys, JWTs, AWS keys, connection strings with embedded passwords,
# bearer tokens, and common secret variable assignments.

CMD=$(python3 -c "
import sys, json
try:
    print(json.load(sys.stdin).get('command', ''))
except Exception:
    print('')
" <<< "$CLAUDE_TOOL_INPUT" 2>/dev/null)

# Only intercept git commit commands
if ! echo "$CMD" | grep -qE "git commit|git add"; then
    exit 0
fi

# Get staged file contents
STAGED_DIFF=$(git diff --cached 2>/dev/null)
[[ -z "$STAGED_DIFF" ]] && exit 0

# Pattern definitions
declare -A PATTERNS
PATTERNS["JWT token"]='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
PATTERNS["AWS access key"]='AKIA[0-9A-Z]{16}'
PATTERNS["AWS secret key"]='[Aa][Ww][Ss][_-]?[Ss][Ee][Cc][Rr][Ee][Tt][_-]?[Kk][Ee][Yy]\s*[:=]\s*["\x27][A-Za-z0-9/+]{40}'
PATTERNS["Private key header"]='-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
PATTERNS["Password in connection string"]='(Password|pwd|Pwd)\s*=\s*[^;}{"\x27\s]{4,}'
PATTERNS["Hardcoded password assignment"]='(password|passwd|secret|api_key|apikey|token)\s*=\s*["\x27][^"\x27]{6,}["\x27]'
PATTERNS["Slack webhook"]='https://hooks\.slack\.com/services/T[A-Z0-9]{8,}/B[A-Z0-9]{8,}/'
PATTERNS["GitHub token"]='gh[pousr]_[A-Za-z0-9_]{36,}'
PATTERNS["Generic secret variable"]='(SECRET|TOKEN|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY)\s*[:=]\s*["\x27][^"\x27]{8,}'

FOUND=0
FINDINGS=""

for LABEL in "${!PATTERNS[@]}"; do
    PATTERN="${PATTERNS[$LABEL]}"
    MATCHES=$(echo "$STAGED_DIFF" | grep -E "^\+" | grep -v "^+++" | grep -oE "$PATTERN" 2>/dev/null | head -3)
    if [[ -n "$MATCHES" ]]; then
        FOUND=1
        FINDINGS+="  • ${LABEL}\n"
        # Show partial match (truncated to avoid leaking actual secret)
        while IFS= read -r match; do
            TRUNCATED="${match:0:20}..."
            FINDINGS+="    → ${TRUNCATED}\n"
        done <<< "$MATCHES"
    fi
done

[[ $FOUND -eq 0 ]] && exit 0

echo "🔴  Posibles secretos detectados en archivos staged"
echo ""
echo "Patrones encontrados:"
echo -e "$FINDINGS"
echo "Acciones recomendadas:"
echo "  1. Elimina el secreto del archivo"
echo "  2. Agrega a User Secrets o variable de entorno"
echo "  3. Si es falso positivo: git commit --no-verify (bajo tu responsabilidad)"
echo ""
echo "Nunca commitear: passwords, tokens, API keys, connection strings con credenciales."
exit 2
