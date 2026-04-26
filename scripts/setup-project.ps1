#!/usr/bin/env pwsh
# setup-project.ps1 — Configura Claude Code en el proyecto actual
#
# Uso (desde la raiz del proyecto):
#   iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.ps1 | iex
#
# O desde el repo clonado:
#   pwsh path/to/ai-standards/scripts/setup-project.ps1

param(
    [string]$BaseUrl = "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ClaudeDir   = Join-Path (Get-Location) ".claude"
$CommandsDir = Join-Path $ClaudeDir "commands"

# ─── Helpers ────────────────────────────────────────────────────────────────

function Get-RemoteFile([string]$Url, [string]$Dest) {
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Invoke-WebRequest -Uri $Url -OutFile $Dest -ErrorAction Stop
}

function Write-Ok([string]$msg)   { Write-Host "  ✓  $msg" -ForegroundColor Green }
function Write-Info([string]$msg) { Write-Host "  →  $msg" -ForegroundColor Cyan }
function Write-Warn([string]$msg) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }

# ─── Detección de tecnología ─────────────────────────────────────────────────

function Detect-Tech {
    $sln      = Get-ChildItem -Filter "*.sln"    -ErrorAction SilentlyContinue | Select-Object -First 1
    $csproj   = Get-ChildItem -Recurse -Filter "*.csproj" -Depth 4 -ErrorAction SilentlyContinue | Select-Object -First 1
    $angular  = Test-Path "angular.json"

    if ($sln -or $csproj) { return "dotnet" }
    if ($angular)          { return "angular" }
    return $null
}

# ─── Detección de metadatos .NET ─────────────────────────────────────────────

function Get-DotnetMetadata {
    $meta = @{
        ProjectName  = (Get-Item .).Name
        DotnetVersion = "8"
        CsharpVersion = "12"
        ProjectType  = "ASP.NET Core Web API"
        Packages     = @()
        DbProvider   = ""
        HasDocker    = Test-Path "docker-compose.yml"
        HasMediatR   = $false
        HasSerilog   = $false
    }

    # Nombre desde .sln
    $sln = Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($sln) { $meta.ProjectName = [System.IO.Path]::GetFileNameWithoutExtension($sln.Name) }

    # Version de .NET desde global.json
    if (Test-Path "global.json") {
        $global = Get-Content "global.json" | ConvertFrom-Json
        if ($global.sdk.version) {
            $meta.DotnetVersion = $global.sdk.version.Split(".")[0]
        }
    }

    # Analizar .csproj files
    $csprojFiles = Get-ChildItem -Recurse -Filter "*.csproj" -Depth 4 -ErrorAction SilentlyContinue
    $allPackages = @()

    foreach ($file in $csprojFiles) {
        $content = Get-Content $file.FullName -Raw

        # Tipo de proyecto
        if ($content -match "Microsoft\.NET\.Sdk\.Web")    { $meta.ProjectType = "ASP.NET Core Web API" }
        if ($content -match "Microsoft\.NET\.Sdk\.Worker") { $meta.ProjectType = "Worker Service" }
        if ($content -match "Microsoft\.NET\.Sdk\.Razor")  { $meta.ProjectType = "Blazor" }

        # Version de C#
        if ($content -match "<LangVersion>(.*?)</LangVersion>") { $meta.CsharpVersion = $Matches[1] }

        # Version de .NET desde TargetFramework
        if ($content -match "<TargetFramework>net(\d+\.\d+)<") { $meta.DotnetVersion = $Matches[1] }

        # Packages
        $pkgMatches = [regex]::Matches($content, '<PackageReference Include="([^"]+)"')
        foreach ($m in $pkgMatches) { $allPackages += $m.Groups[1].Value }
    }

    $meta.Packages = $allPackages | Sort-Object -Unique

    # Detectar librerías clave
    $meta.HasMediatR = $allPackages -match "MediatR"
    $meta.HasSerilog = $allPackages -match "Serilog"

    # DB provider
    if ($allPackages -match "Npgsql")                     { $meta.DbProvider = "PostgreSQL" }
    elseif ($allPackages -match "Microsoft\.Data\.SqlClient|SqlServer") { $meta.DbProvider = "SQL Server" }
    elseif ($allPackages -match "Sqlite")                 { $meta.DbProvider = "SQLite" }
    elseif ($allPackages -match "MongoDB")                { $meta.DbProvider = "MongoDB" }

    return $meta
}

# ─── Generar CLAUDE.md ───────────────────────────────────────────────────────

function Build-ClaudeMd([hashtable]$meta, [string]$template) {

    $packageList = if ($meta.Packages.Count -gt 0) {
        "- " + ($meta.Packages | Where-Object { $_ -notmatch "^Microsoft\.|^System\." } | Select-Object -First 12) -join "`n- "
    } else { "- [Completar paquetes principales]" }

    $dbLine = if ($meta.DbProvider) { $meta.DbProvider } else { "[SQL Server / PostgreSQL / SQLite / MongoDB]" }

    $content = $template
    $content = $content -replace "\[NombreProyecto\]",             $meta.ProjectName
    $content = $content -replace "\[\.NET Version\]",              "NET $($meta.DotnetVersion)"
    $content = $content -replace "\[C# Version\]",                 "C# $($meta.CsharpVersion)"
    $content = $content -replace "\[ASP\.NET Core Web API / Worker Service / Blazor\].*\n", "$($meta.ProjectType)`n"
    $content = $content -replace "Entity Framework Core \+ \[SQL Server.*?\]", "Entity Framework Core + $dbLine"
    $content = $content -replace "\[Completar: MediatR, Serilog, etc\.\]", $packageList

    return $content
}

# ─── Main ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Claude Code — Setup de proyecto" -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en la raiz de un proyecto
if (-not (Test-Path (Get-Location))) {
    Write-Host "  ERROR: Ejecutar desde la raiz del proyecto." -ForegroundColor Red
    exit 1
}

# Detectar tecnología
$tech = Detect-Tech

if (-not $tech) {
    Write-Warn "No se detectó tecnología conocida (.sln, .csproj, angular.json)."
    Write-Host "  Tecnologías soportadas actualmente: dotnet" -ForegroundColor Gray
    exit 1
}

Write-Info "Tecnología detectada: $tech"

# Verificar CLAUDE.md existente
$claudeMdPath = Join-Path (Get-Location) "CLAUDE.md"
if ((Test-Path $claudeMdPath) -and -not $Force) {
    Write-Warn "Ya existe CLAUDE.md. Usa -Force para sobreescribir."
    $confirm = Read-Host "  ¿Sobreescribir? (s/N)"
    if ($confirm -notmatch "^[sS]$") { Write-Host "  Cancelado."; exit 0 }
}

# Descargar template CLAUDE.md
Write-Info "Descargando plantilla CLAUDE.md..."
$templateUrl  = "$BaseUrl/templates/$tech/CLAUDE.md"
$templateFile = New-TemporaryFile
Get-RemoteFile $templateUrl $templateFile.FullName
$templateContent = Get-Content $templateFile.FullName -Raw
Remove-Item $templateFile.FullName

# Personalizar según el proyecto
if ($tech -eq "dotnet") {
    Write-Info "Analizando proyecto .NET..."
    $meta    = Get-DotnetMetadata
    $content = Build-ClaudeMd $meta $templateContent

    Write-Ok "Proyecto: $($meta.ProjectName)"
    Write-Ok ".NET $($meta.DotnetVersion) / C# $($meta.CsharpVersion)"
    Write-Ok "Tipo: $($meta.ProjectType)"
    if ($meta.DbProvider) { Write-Ok "Base de datos: $($meta.DbProvider)" }
    if ($meta.Packages.Count -gt 0) { Write-Ok "Paquetes detectados: $($meta.Packages.Count)" }
    if ($meta.HasDocker) { Write-Ok "Docker Compose detectado" }
} else {
    $content = $templateContent
}

# Escribir CLAUDE.md
Set-Content -Path $claudeMdPath -Value $content -Encoding UTF8
Write-Ok "CLAUDE.md generado"

# Descargar comandos
Write-Info "Descargando comandos..."
$commands = @("review", "pr", "task", "fix", "commit-message", "plan-implementation")
foreach ($cmd in $commands) {
    $url  = "$BaseUrl/templates/$tech/.claude/commands/$cmd.md"
    $dest = Join-Path $CommandsDir "$cmd.md"
    try {
        Get-RemoteFile $url $dest
        Write-Ok "/project:$cmd"
    } catch {
        Write-Warn "No se pudo descargar: $cmd"
    }
}

# Descargar settings.json
$settingsUrl  = "$BaseUrl/templates/$tech/.claude/settings.json"
$settingsDest = Join-Path $ClaudeDir "settings.json"
try {
    Get-RemoteFile $settingsUrl $settingsDest
    Write-Ok ".claude/settings.json"
} catch {
    Write-Warn "No se pudo descargar settings.json"
}

# Verificar placeholders pendientes
$pending = [regex]::Matches($content, '\[COMPLETAR[^\]]*\]|\[[^\]]+\]') |
    Where-Object { $_.Value -notmatch '^\[Completar:' } |
    Select-Object -ExpandProperty Value | Sort-Object -Unique

# Resumen final
Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Listo. Archivos generados:" -ForegroundColor White
Write-Host "    CLAUDE.md"
Write-Host "    .claude/settings.json"
Write-Host "    .claude/commands/  ($($commands.Count) comandos)"

if ($pending.Count -gt 0) {
    Write-Host ""
    Write-Warn "Secciones por completar en CLAUDE.md ($($pending.Count)):"
    $pending | Select-Object -First 8 | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "  Abre el proyecto en Claude Code — Claude completará" -ForegroundColor Cyan
    Write-Host "  los placeholders analizando el código existente." -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "  CLAUDE.md completamente configurado." -ForegroundColor Green
}

Write-Host ""
