#!/usr/bin/env pwsh
# setup-project.ps1 — Configura Claude Code en el proyecto actual
#
# Uso (desde la raiz del proyecto):
#   iwr "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup-project.ps1?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" | iex

$BaseUrl  = "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master"
$Bust     = "?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
$ClaudeDir   = Join-Path (Get-Location) ".claude"
$CommandsDir = Join-Path $ClaudeDir "commands"

function ok($msg)   { Write-Host "  ✓  $msg" -ForegroundColor Green }
function info($msg) { Write-Host "  →  $msg" -ForegroundColor Cyan }
function warn($msg) { Write-Host "  ⚠  $msg" -ForegroundColor Yellow }
function fail($msg) { Write-Host "  ✗  $msg" -ForegroundColor Red; exit 1 }

function Download([string]$Url, [string]$Dest) {
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Invoke-WebRequest -Uri "$Url$Bust" -OutFile $Dest -ErrorAction Stop
}

function Detect-Tech {
    if (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue) { return "dotnet" }
    if (Get-ChildItem -Recurse -Filter "*.csproj" -Depth 4 -ErrorAction SilentlyContinue) { return "dotnet" }
    if (Test-Path "angular.json") { return "angular" }
    return $null
}

Write-Host ""
Write-Host "  Claude Code — Setup de proyecto" -ForegroundColor Cyan
Write-Host "  ==================================" -ForegroundColor Cyan
Write-Host ""

$Tech = Detect-Tech
if (-not $Tech) { fail "No se detectó tecnología conocida (.sln, .csproj, angular.json)." }
info "Tecnología detectada: $Tech"

if (Test-Path "CLAUDE.md") { warn "Ya existe CLAUDE.md — sobreescribiendo." }

info "Descargando CLAUDE.md..."
try { Download "$BaseUrl/templates/$Tech/CLAUDE.md" "CLAUDE.md"; ok "CLAUDE.md" }
catch { fail "Error descargando CLAUDE.md. Verifica que el repo sea público." }

info "Descargando comandos..."
$CmdCount = 0
foreach ($cmd in @("init-btw","review","pr","task","fix","commit-message","plan-implementation")) {
    try {
        Download "$BaseUrl/templates/$Tech/.claude/commands/$cmd.md" "$CommandsDir\$cmd.md"
        ok "/project:$cmd"
        $CmdCount++
    } catch {
        warn "No se pudo descargar: $cmd"
    }
}

try {
    Download "$BaseUrl/templates/$Tech/.claude/settings.json" "$ClaudeDir\settings.json"
    ok ".claude/settings.json"
} catch {}

Write-Host ""
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Listo. $CmdCount comandos instalados." -ForegroundColor White
Write-Host ""
Write-Host "  Siguiente paso:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Abre el proyecto en Claude Code"
Write-Host "  2. Escribe:  /project:init-btw" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Claude analizará el proyecto y completará"
Write-Host "  la configuración automáticamente."
Write-Host ""
