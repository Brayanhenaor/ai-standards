#!/bin/bash
# setup.sh — Instala estándares globales de Claude Code
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.sh | bash

BASE_URL="https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

ok()   { echo "  ✓  $1"; }
info() { echo "  →  $1"; }

download() {
    mkdir -p "$(dirname "$2")"
    if curl -fsSL "$1" -o "$2"; then ok "$2"; else echo "  ERROR descargando $1" >&2; exit 1; fi
}

echo ""
echo "  Claude Code — Setup global"
echo "  ============================"
echo ""

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.$TIMESTAMP.backup"
    echo "  Backup: ~/.claude/CLAUDE.md.$TIMESTAMP.backup"
fi

info "Descargando CLAUDE.md global..."
download "$BASE_URL/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

info "Descargando comandos globales..."
download "$BASE_URL/global/commands/standup.md" "$COMMANDS_DIR/standup.md"

echo ""
echo "  Listo."
echo ""
echo "  Comando global disponible:"
echo "    /user:standup  — genera resumen del trabajo del día"
echo ""
