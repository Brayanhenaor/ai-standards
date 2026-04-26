#!/usr/bin/env pwsh
# setup.ps1 — Instala estándares de Claude Code para [Empresa]
#
# Uso remoto (recomendado):
#   iwr https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/scripts/setup.ps1 | iex
#
# Uso local (desde el repo clonado):
#   pwsh scripts/setup.ps1

param(
    [string]$BaseUrl = "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master",
    [switch]$Force
)

$ClaudeDir   = Join-Path $HOME ".claude"
$CommandsDir = Join-Path $ClaudeDir "commands"
$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"

function Get-RemoteFile {
    param([string]$Url, [string]$Dest)
    $dir = Split-Path $Dest -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -ErrorAction Stop
        return $true
    } catch {
        Write-Host "  ERROR descargando $Url" -ForegroundColor Red
        Write-Host "  $_" -ForegroundColor Red
        return $false
    }
}

Write-Host ""
Write-Host "  Configurando Claude Code — [Empresa]" -ForegroundColor Cyan
Write-Host "  ======================================" -ForegroundColor Cyan
Write-Host ""

# Backup del CLAUDE.md global existente
$globalClaude = Join-Path $ClaudeDir "CLAUDE.md"
if ((Test-Path $globalClaude) -and -not $Force) {
    $backup = "$globalClaude.$Timestamp.backup"
    Copy-Item $globalClaude $backup
    Write-Host "  Backup creado: ~/.claude/CLAUDE.md.$Timestamp.backup" -ForegroundColor Yellow
}

# Descargar CLAUDE.md global
$ok = Get-RemoteFile "$BaseUrl/global/CLAUDE.md" $globalClaude
if ($ok) { Write-Host "  OK  ~/.claude/CLAUDE.md" -ForegroundColor Green }

# Descargar comandos globales
foreach ($cmd in @("init-repo", "standup")) {
    $dest = Join-Path $CommandsDir "$cmd.md"
    $ok = Get-RemoteFile "$BaseUrl/global/commands/$cmd.md" $dest
    if ($ok) { Write-Host "  OK  /user:$cmd" -ForegroundColor Green }
}

Write-Host ""
Write-Host "  Listo." -ForegroundColor Green
Write-Host ""
Write-Host "  Comandos globales disponibles en Claude Code:" -ForegroundColor White
Write-Host "    /user:init-repo  — inicializa CLAUDE.md en un repo .NET existente"
Write-Host "    /user:standup    — genera resumen del trabajo del día"
Write-Host ""
