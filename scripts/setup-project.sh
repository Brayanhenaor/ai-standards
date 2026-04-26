#!/bin/bash
# setup-project.sh — Configura Claude Code en el proyecto actual
#
# Uso (desde la raiz del proyecto):
#   curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.sh | bash

BASE_URL="https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master"
CLAUDE_DIR="$(pwd)/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"

ok()   { echo "  ✓  $1"; }
info() { echo "  →  $1"; }
warn() { echo "  ⚠  $1"; }
fail() { echo "  ✗  $1"; exit 1; }

download() {
    mkdir -p "$(dirname "$2")"
    curl -fsSL "$1" -o "$2"
}

detect_tech() {
    if find . -maxdepth 1 -name "*.sln" 2>/dev/null | grep -q .; then echo "dotnet"; return; fi
    if find . -maxdepth 4 -name "*.csproj" 2>/dev/null | grep -q .; then echo "dotnet"; return; fi
    if [ -f "angular.json" ]; then echo "angular"; return; fi
    echo ""
}

echo ""
echo "  Claude Code — Setup de proyecto"
echo "  =================================="
echo ""

TECH=$(detect_tech)
if [ -z "$TECH" ]; then
    fail "No se detectó tecnología conocida (.sln, .csproj, angular.json)."
fi
info "Tecnología detectada: $TECH"

# CLAUDE.md
info "Descargando CLAUDE.md..."
if ! download "$BASE_URL/templates/$TECH/CLAUDE.md" "CLAUDE.md"; then
    fail "Error descargando CLAUDE.md. Verifica que el repo sea público."
fi
ok "CLAUDE.md"

# Comandos
info "Descargando comandos..."
CMD_COUNT=0
for cmd in init review pr task fix commit-message plan-implementation; do
    if download "$BASE_URL/templates/$TECH/.claude/commands/$cmd.md" "$COMMANDS_DIR/$cmd.md" 2>/dev/null; then
        ok "/project:$cmd"
        CMD_COUNT=$((CMD_COUNT + 1))
    else
        warn "No se pudo descargar: $cmd"
    fi
done

# settings.json
if download "$BASE_URL/templates/$TECH/.claude/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null; then
    ok ".claude/settings.json"
fi

echo ""
echo "  ─────────────────────────────────────────"
echo "  Listo. $CMD_COUNT comandos instalados."
echo ""
echo "  Siguiente paso:"
echo ""
echo "  1. Abre el proyecto en Claude Code"
echo "  2. Escribe:  /project:init"
echo ""
echo "  Claude analizará el proyecto y completará"
echo "  la configuración automáticamente."
echo ""
