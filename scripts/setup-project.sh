#!/bin/bash
# setup-project.sh — Configura Claude Code en el proyecto actual
#
# Uso (desde la raiz del proyecto):
#   curl -fsSL https://raw.githubusercontent.com/[tu-empresa]/ai-standards/main/scripts/setup-project.sh | bash
#
# O desde el repo clonado:
#   bash path/to/ai-standards/scripts/setup-project.sh

set -e

BASE_URL="https://raw.githubusercontent.com/[tu-empresa]/ai-standards/main"
CLAUDE_DIR="$(pwd)/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
FORCE=false

# ─── Helpers ────────────────────────────────────────────────────────────────

ok()   { echo "  ✓  $1"; }
info() { echo "  →  $1"; }
warn() { echo "  ⚠  $1"; }

download() {
    local url="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    curl -fsSL "$url" -o "$dest"
}

# ─── Detección de tecnología ─────────────────────────────────────────────────

detect_tech() {
    if find . -maxdepth 1 -name "*.sln" | grep -q . 2>/dev/null; then echo "dotnet"; return; fi
    if find . -maxdepth 4 -name "*.csproj" | grep -q . 2>/dev/null; then echo "dotnet"; return; fi
    if [ -f "angular.json" ]; then echo "angular"; return; fi
    echo ""
}

# ─── Detección de metadatos .NET ─────────────────────────────────────────────

detect_dotnet_metadata() {
    PROJECT_NAME="$(basename "$(pwd)")"
    DOTNET_VERSION="8"
    CSHARP_VERSION="12"
    PROJECT_TYPE="ASP.NET Core Web API"
    DB_PROVIDER=""
    PACKAGES=""
    HAS_DOCKER=false

    # Nombre desde .sln
    local sln
    sln=$(find . -maxdepth 1 -name "*.sln" | head -1)
    if [ -n "$sln" ]; then
        PROJECT_NAME=$(basename "$sln" .sln)
    fi

    # Version de .NET desde global.json
    if [ -f "global.json" ] && command -v python3 &>/dev/null; then
        local v
        v=$(python3 -c "import json,sys; d=json.load(open('global.json')); print(d.get('sdk',{}).get('version','').split('.')[0])" 2>/dev/null)
        [ -n "$v" ] && DOTNET_VERSION="$v"
    fi

    # Analizar .csproj files
    while IFS= read -r csproj; do
        local content
        content=$(cat "$csproj" 2>/dev/null)

        # Tipo de proyecto
        echo "$content" | grep -q "Sdk.Worker" && PROJECT_TYPE="Worker Service"
        echo "$content" | grep -q "Sdk.Razor"  && PROJECT_TYPE="Blazor"

        # Version de .NET
        local tf
        tf=$(echo "$content" | grep -oP '(?<=<TargetFramework>net)[\d.]+(?=<)' | head -1)
        [ -n "$tf" ] && DOTNET_VERSION="$tf"

        # Version de C#
        local lv
        lv=$(echo "$content" | grep -oP '(?<=<LangVersion>)[\w.]+(?=<)' | head -1)
        [ -n "$lv" ] && CSHARP_VERSION="$lv"

        # Packages
        local pkgs
        pkgs=$(echo "$content" | grep -oP '(?<=PackageReference Include=")[^"]+')
        PACKAGES="$PACKAGES $pkgs"

    done < <(find . -maxdepth 4 -name "*.csproj" 2>/dev/null)

    # DB provider
    echo "$PACKAGES" | grep -qi "Npgsql"           && DB_PROVIDER="PostgreSQL"
    echo "$PACKAGES" | grep -qi "SqlServer\|SqlClient" && DB_PROVIDER="SQL Server"
    echo "$PACKAGES" | grep -qi "Sqlite"            && DB_PROVIDER="SQLite"
    echo "$PACKAGES" | grep -qi "MongoDB"           && DB_PROVIDER="MongoDB"

    # Docker
    [ -f "docker-compose.yml" ] && HAS_DOCKER=true
}

# ─── Personalizar CLAUDE.md ──────────────────────────────────────────────────

customize_claude_md() {
    local file="$1"

    # Reemplazos básicos con sed
    sed -i.bak \
        -e "s/\[NombreProyecto\]/$PROJECT_NAME/g" \
        -e "s/\[\.NET Version\]/NET $DOTNET_VERSION/g" \
        -e "s/\[C# Version\]/C# $CSHARP_VERSION/g" \
        "$file"

    # DB provider
    if [ -n "$DB_PROVIDER" ]; then
        sed -i.bak "s|\[SQL Server / PostgreSQL / SQLite / MongoDB\]|$DB_PROVIDER|g" "$file"
    fi

    # Tipo de proyecto
    sed -i.bak "s|\[ASP\.NET Core Web API / Worker Service / Blazor\].*|$PROJECT_TYPE|g" "$file"

    # Packages detectados (top 10 ignorando Microsoft.* y System.*)
    if [ -n "$PACKAGES" ]; then
        local clean_pkgs
        clean_pkgs=$(echo "$PACKAGES" | tr ' ' '\n' | grep -v "^$\|^Microsoft\.\|^System\." | sort -u | head -10 | sed 's/^/- /' | tr '\n' '|' | sed 's/|$//')
        # Reemplazar línea de packages
        sed -i.bak "s|- \[Completar: MediatR, Serilog, etc\.\]|$clean_pkgs|g" "$file"
    fi

    rm -f "$file.bak"
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "  Claude Code — Setup de proyecto"
echo "  =================================="
echo ""

# Detectar tecnología
TECH=$(detect_tech)

if [ -z "$TECH" ]; then
    warn "No se detectó tecnología conocida (.sln, .csproj, angular.json)."
    echo "  Tecnologías soportadas actualmente: dotnet"
    exit 1
fi

info "Tecnología detectada: $TECH"

# Verificar CLAUDE.md existente
if [ -f "CLAUDE.md" ] && [ "$FORCE" != "true" ]; then
    warn "Ya existe CLAUDE.md."
    printf "  ¿Sobreescribir? (s/N): "
    read -r confirm
    if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
        echo "  Cancelado."
        exit 0
    fi
fi

# Descargar y personalizar CLAUDE.md
info "Descargando plantilla CLAUDE.md..."
download "$BASE_URL/templates/$TECH/CLAUDE.md" "CLAUDE.md"

if [ "$TECH" = "dotnet" ]; then
    info "Analizando proyecto .NET..."
    detect_dotnet_metadata
    customize_claude_md "CLAUDE.md"

    ok "Proyecto: $PROJECT_NAME"
    ok ".NET $DOTNET_VERSION / C# $CSHARP_VERSION"
    ok "Tipo: $PROJECT_TYPE"
    [ -n "$DB_PROVIDER" ] && ok "Base de datos: $DB_PROVIDER"
    $HAS_DOCKER && ok "Docker Compose detectado"
fi

ok "CLAUDE.md generado"

# Descargar comandos
info "Descargando comandos..."
COMMANDS=("review" "pr" "task" "fix" "commit-message" "plan-implementation")
CMD_COUNT=0

for cmd in "${COMMANDS[@]}"; do
    url="$BASE_URL/templates/$TECH/.claude/commands/$cmd.md"
    dest="$COMMANDS_DIR/$cmd.md"
    if download "$url" "$dest" 2>/dev/null; then
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

# Verificar placeholders pendientes
PENDING=$(grep -oP '\[[^\]]+\]' CLAUDE.md 2>/dev/null | grep -v "^$" | sort -u | head -8 || true)

# Resumen
echo ""
echo "  ─────────────────────────────────────────"
echo "  Listo. Archivos generados:"
echo "    CLAUDE.md"
echo "    .claude/settings.json"
echo "    .claude/commands/  ($CMD_COUNT comandos)"

if [ -n "$PENDING" ]; then
    echo ""
    warn "Secciones por completar en CLAUDE.md:"
    echo "$PENDING" | while read -r line; do echo "    $line"; done
    echo ""
    echo "  Abre el proyecto en Claude Code — Claude completará"
    echo "  los placeholders analizando el código existente."
else
    echo ""
    echo "  CLAUDE.md completamente configurado."
fi

echo ""
