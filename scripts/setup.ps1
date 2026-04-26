#!/usr/bin/env pwsh
# setup.ps1 — Instala estándares globales de Claude Code
#
# Uso:
#   iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.ps1 | iex

$BaseUrl     = "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master"
$ClaudeDir   = Join-Path $HOME ".claude"
$CommandsDir = Join-Path $ClaudeDir "commands"
$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"

function ok($msg)   { Write-Host "  ✓  $msg" -ForegroundColor Green }
function info($msg) { Write-Host "  →  $msg" -ForegroundColor Cyan }

function Download([string]$Url, [string]$Dest) {
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Invoke-WebRequest -Uri $Url -OutFile $Dest -ErrorAction Stop
    ok $Dest
}

Write-Host ""
Write-Host "  Claude Code — Setup global" -ForegroundColor Cyan
Write-Host "  ============================" -ForegroundColor Cyan
Write-Host ""

$globalClaude = Join-Path $ClaudeDir "CLAUDE.md"
if (Test-Path $globalClaude) {
    Copy-Item $globalClaude "$globalClaude.$Timestamp.backup"
    Write-Host "  Backup: ~/.claude/CLAUDE.md.$Timestamp.backup" -ForegroundColor Yellow
}

info "Descargando CLAUDE.md global..."
Download "$BaseUrl/global/CLAUDE.md" $globalClaude

info "Descargando comandos globales..."
Download "$BaseUrl/global/commands/standup.md" (Join-Path $CommandsDir "standup.md")

Write-Host ""
Write-Host "  Listo." -ForegroundColor Green
Write-Host ""
Write-Host "  Comando global disponible:"
Write-Host "    /user:standup  — genera resumen del trabajo del día" -ForegroundColor Cyan
Write-Host ""
