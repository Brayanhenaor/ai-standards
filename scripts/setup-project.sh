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

# ─── Detección de tecnología ───────────────────────────────���──────────────────

detect_tech() {
    if find . -maxdepth 1 -name "*.sln" 2>/dev/null | grep -q .; then echo "dotnet"; return; fi
    if find . -maxdepth 4 -name "*.csproj" 2>/dev/null | grep -q .; then echo "dotnet"; return; fi
    if [ -f "angular.json" ]; then echo "angular"; return; fi
    echo ""
}

# ─── Recolectar contexto del proyecto ───────────────────────────────���────────

collect_project_context() {
    # .csproj files
    CSPROJ_CONTENT=""
    local tmpfile
    tmpfile=$(mktemp /tmp/csproj_list.XXXXXX)
    find . -maxdepth 4 -name "*.csproj" 2>/dev/null > "$tmpfile"
    while IFS= read -r f; do
        CSPROJ_CONTENT="$CSPROJ_CONTENT
=== $f ===
$(cat "$f" 2>/dev/null)"
    done < "$tmpfile"
    rm -f "$tmpfile"

    # Estructura de carpetas (ignorando bin/obj/.git)
    FOLDER_STRUCT=$(find . -maxdepth 4 -type d \
        ! -path "*/bin/*" ! -path "*/obj/*" ! -path "*/.git/*" \
        ! -path "*/.vs/*" ! -path "*/node_modules/*" 2>/dev/null | sort | head -50)

    # Program.cs principal
    PROGRAM_CS=$(find . -maxdepth 4 -name "Program.cs" 2>/dev/null | head -1 | xargs cat 2>/dev/null | head -100)

    # appsettings.json (sin valores sensibles)
    APPSETTINGS=$(find . -maxdepth 4 -name "appsettings.json" 2>/dev/null | head -1 | xargs cat 2>/dev/null | head -60)
}

# ─── Completar CLAUDE.md con Claude CLI ──────────────────────────────────────

complete_with_claude() {
    local template
    template=$(cat CLAUDE.md)

    local prompt
    prompt="You are setting up a .NET project's CLAUDE.md configuration file.

The CLAUDE.md below has placeholders in [brackets] that need to be filled with real values from this project.

YOUR TASK:
- Replace every [placeholder] with the actual value detected from the project files
- If you cannot determine a value, replace it with a sensible default based on the project type
- Keep all rules, sections and formatting exactly as-is
- Return ONLY the completed CLAUDE.md raw content — no explanations, no code blocks, nothing else

--- CURRENT CLAUDE.md (with placeholders) ---
$template

--- .CSPROJ FILES ---
$CSPROJ_CONTENT

--- FOLDER STRUCTURE ---
$FOLDER_STRUCT

--- PROGRAM.CS ---
$PROGRAM_CS

--- APPSETTINGS.JSON ---
$APPSETTINGS"

    local result
    result=$(claude -p "$prompt" 2>/dev/null)

    if [ -n "$result" ]; then
        echo "$result" > CLAUDE.md
        return 0
    fi
    return 1
}

# ─── Main ─────────────────────────────���───────────────────────────────────────

echo ""
echo "  Claude Code — Setup de proyecto"
echo "  =================================="
echo ""

TECH=$(detect_tech)
if [ -z "$TECH" ]; then
    fail "No se detectó tecnología conocida (.sln, .csproj, angular.json)."
fi
info "Tecnología detectada: $TECH"

# Descargar CLAUDE.md template
info "Descargando plantilla..."
if ! download "$BASE_URL/templates/$TECH/CLAUDE.md" "CLAUDE.md"; then
    fail "Error descargando CLAUDE.md. Verifica la conexión y que el repo sea público."
fi

# Descargar comandos
info "Descargando comandos..."
CMD_COUNT=0
for cmd in review pr task fix commit-message plan-implementation; do
    if download "$BASE_URL/templates/$TECH/.claude/commands/$cmd.md" "$COMMANDS_DIR/$cmd.md" 2>/dev/null; then
        ok "/project:$cmd"
        CMD_COUNT=$((CMD_COUNT + 1))
    else
        warn "No se pudo descargar: $cmd"
    fi
done

# Descargar settings.json
if download "$BASE_URL/templates/$TECH/.claude/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null; then
    ok ".claude/settings.json"
fi

# Completar CLAUDE.md
if command -v claude &>/dev/null; then
    info "Analizando proyecto con Claude..."
    collect_project_context

    if complete_with_claude; then
        ok "CLAUDE.md completado con análisis inteligente"
        SMART=true
    else
        warn "Claude no pudo completar el análisis. El CLAUDE.md tiene placeholders pendientes."
        SMART=false
    fi
else
    warn "claude CLI no encontrado — CLAUDE.md quedará con placeholders."
    warn "Instala Claude Code CLI para análisis automático: https://claude.ai/download"
    SMART=false
fi

# Resumen
echo ""
echo "  ─────────────────────────────────────────"
echo "  Listo. Archivos generados:"
echo "    CLAUDE.md"
echo "    .claude/settings.json"
echo "    .claude/commands/  ($CMD_COUNT comandos)"

if [ "$SMART" = "true" ]; then
    echo ""
    echo "  El proyecto está listo para usar Claude Code."
else
    PENDING=$(grep -o '\[[^]]*\]' CLAUDE.md 2>/dev/null | sort -u | head -8 || true)
    if [ -n "$PENDING" ]; then
        echo ""
        warn "Placeholders pendientes en CLAUDE.md:"
        echo "$PENDING" | while read -r line; do echo "    $line"; done
        echo ""
        echo "  Abre el proyecto en Claude Code y Claude los completará"
        echo "  analizando el código al inicio de la conversación."
    fi
fi

echo ""
