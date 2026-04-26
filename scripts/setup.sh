#!/bin/bash
# setup.sh — Instala estándares de Claude Code para [Empresa]
#
# Uso remoto (recomendado):
#   curl -fsSL https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.sh | bash
#
# Uso local (desde el repo clonado):
#   bash scripts/setup.sh

set -e

BASE_URL="https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master"
CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

download() {
    local url="$1"
    local dest="$2"
    mkdir -p "$(dirname "$dest")"
    if curl -fsSL "$url" -o "$dest"; then
        echo "  OK  $dest"
    else
        echo "  ERROR descargando $url" >&2
        exit 1
    fi
}

echo ""
echo "  Configurando Claude Code — [Empresa]"
echo "  ======================================"
echo ""

# Backup del CLAUDE.md global existente
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.$TIMESTAMP.backup"
    echo "  Backup creado: ~/.claude/CLAUDE.md.$TIMESTAMP.backup"
fi

# Descargar CLAUDE.md global
download "$BASE_URL/global/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Descargar comandos globales
for cmd in init-repo standup; do
    download "$BASE_URL/global/commands/$cmd.md" "$COMMANDS_DIR/$cmd.md"
done

echo ""
echo "  Listo."
echo ""
echo "  Comandos globales disponibles en Claude Code:"
echo "    /user:init-repo  — inicializa CLAUDE.md en un repo .NET existente"
echo "    /user:standup    — genera resumen del trabajo del día"
echo ""
