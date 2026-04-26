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

detect_dotnet_metadata() {
    PROJECT_NAME="$(basename "$(pwd)")"
    DOTNET_VERSION="8"
    CSHARP_VERSION="12"
    PROJECT_TYPE="ASP.NET Core Web API"
    DB_PROVIDER=""
    PACKAGES=""
    HAS_DOCKER="false"

    # Nombre desde .sln
    local sln
    sln=$(find . -maxdepth 1 -name "*.sln" 2>/dev/null | head -1)
    if [ -n "$sln" ]; then
        PROJECT_NAME=$(basename "$sln" .sln)
    fi

    # Leer todos los .csproj en un archivo temporal para evitar process substitution
    local tmpfile
    tmpfile=$(mktemp /tmp/csproj_list.XXXXXX)
    find . -maxdepth 4 -name "*.csproj" 2>/dev/null > "$tmpfile"

    while IFS= read -r csproj; do
        local content
        content=$(cat "$csproj" 2>/dev/null) || continue

        # Tipo de proyecto
        if echo "$content" | grep -q "Sdk.Worker"; then PROJECT_TYPE="Worker Service"; fi
        if echo "$content" | grep -q "Sdk.Razor";  then PROJECT_TYPE="Blazor"; fi

        # Version de .NET
        local tf
        tf=$(echo "$content" | sed -n 's|.*<TargetFramework>net\([^<]*\)</TargetFramework>.*|\1|p' | head -1)
        if [ -n "$tf" ]; then DOTNET_VERSION="$tf"; fi

        # Version de C#
        local lv
        lv=$(echo "$content" | sed -n 's|.*<LangVersion>\([^<]*\)</LangVersion>.*|\1|p' | head -1)
        if [ -n "$lv" ]; then CSHARP_VERSION="$lv"; fi

        # Packages
        local pkgs
        pkgs=$(echo "$content" | sed -n 's/.*PackageReference Include="\([^"]*\)".*/\1/p' | tr '\n' ' ')
        PACKAGES="$PACKAGES $pkgs"

    done < "$tmpfile"
    rm -f "$tmpfile"

    # DB provider
    if echo "$PACKAGES" | grep -qi "Npgsql"; then
        DB_PROVIDER="PostgreSQL"
    elif echo "$PACKAGES" | grep -qi "SqlServer\|SqlClient"; then
        DB_PROVIDER="SQL Server"
    elif echo "$PACKAGES" | grep -qi "Sqlite"; then
        DB_PROVIDER="SQLite"
    elif echo "$PACKAGES" | grep -qi "MongoDB"; then
        DB_PROVIDER="MongoDB"
    fi

    if [ -f "docker-compose.yml" ]; then HAS_DOCKER="true"; fi
}

customize_claude_md() {
    local file="$1"

    sed -i.bak \
        -e "s/\[NombreProyecto\]/$PROJECT_NAME/g" \
        -e "s/\[\.NET Version\]/NET $DOTNET_VERSION/g" \
        -e "s/\[C# Version\]/C# $CSHARP_VERSION/g" \
        "$file"

    if [ -n "$DB_PROVIDER" ]; then
        sed -i.bak "s|\[SQL Server / PostgreSQL / SQLite / MongoDB\]|$DB_PROVIDER|g" "$file"
    fi

    sed -i.bak "s|\[ASP\.NET Core Web API / Worker Service / Blazor\].*|$PROJECT_TYPE|g" "$file"

    if [ -n "$PACKAGES" ]; then
        local clean_pkgs
        clean_pkgs=$(echo "$PACKAGES" | tr ' ' '\n' | grep -v "^$\|^Microsoft\.\|^System\." | sort -u | head -10 | sed 's/^/- /' | tr '\n' '|' | sed 's/|$//')
        if [ -n "$clean_pkgs" ]; then
            sed -i.bak "s|- \[Completar: MediatR, Serilog, etc\.\]|$clean_pkgs|g" "$file"
        fi
    fi

    rm -f "$file.bak"
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "  Claude Code — Setup de proyecto"
echo "  =================================="
echo ""

TECH=$(detect_tech)

if [ -z "$TECH" ]; then
    warn "No se detectó tecnología conocida (.sln, .csproj, angular.json)."
    exit 1
fi

info "Tecnología detectada: $TECH"

if [ -f "CLAUDE.md" ]; then
    warn "Ya existe CLAUDE.md — sobreescribiendo."
fi

info "Descargando plantilla CLAUDE.md..."
if ! download "$BASE_URL/templates/$TECH/CLAUDE.md" "CLAUDE.md"; then
    warn "Error descargando CLAUDE.md. Verifica la conexión."
    exit 1
fi

if [ "$TECH" = "dotnet" ]; then
    info "Analizando proyecto .NET..."
    detect_dotnet_metadata
    customize_claude_md "CLAUDE.md"

    ok "Proyecto: $PROJECT_NAME"
    ok ".NET $DOTNET_VERSION / C# $CSHARP_VERSION"
    ok "Tipo: $PROJECT_TYPE"
    if [ -n "$DB_PROVIDER" ]; then ok "Base de datos: $DB_PROVIDER"; fi
    if [ "$HAS_DOCKER" = "true" ]; then ok "Docker Compose detectado"; fi
fi

ok "CLAUDE.md generado"

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

if download "$BASE_URL/templates/$TECH/.claude/settings.json" "$CLAUDE_DIR/settings.json" 2>/dev/null; then
    ok ".claude/settings.json"
fi

PENDING=$(grep -o '\[[^]]*\]' CLAUDE.md 2>/dev/null | sort -u | head -8 || true)

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
