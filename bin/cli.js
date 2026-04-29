#!/usr/bin/env node

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const ROOT        = path.join(__dirname, '..');
const CLAUDE_DIR  = path.join(os.homedir(), '.claude');
const COMMANDS_DIR = path.join(CLAUDE_DIR, 'commands');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function copyFile(src, dest) {
  ensureDir(path.dirname(dest));
  fs.copyFileSync(src, dest);
  console.log(`  ✓  ${dest.replace(os.homedir(), '~')}`);
}

function copyDir(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return;
  ensureDir(destDir);
  for (const file of fs.readdirSync(srcDir)) {
    copyFile(path.join(srcDir, file), path.join(destDir, file));
  }
}

console.log('');
console.log('  Claude Code — ai-standards');
console.log('  ============================');
console.log('');

const globalClaude = path.join(CLAUDE_DIR, 'CLAUDE.md');
if (fs.existsSync(globalClaude)) {
  const ts     = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const backup = `${globalClaude}.${ts}.backup`;
  fs.copyFileSync(globalClaude, backup);
  console.log(`  Backup: ~/.claude/CLAUDE.md.${ts}.backup`);
  console.log('');
}

const RULES_DIR = path.join(CLAUDE_DIR, 'rules');

copyFile(path.join(ROOT, 'global', 'CLAUDE.md'), globalClaude);
copyDir(path.join(ROOT, 'global', 'commands'), COMMANDS_DIR);
copyDir(path.join(ROOT, 'global', 'rules'), RULES_DIR);

console.log('');
console.log('  Listo. Abre el proyecto en Claude Code y ejecuta:');
console.log('');
console.log('    /user:init-dotnet   — analiza el proyecto y genera el CLAUDE.md');
console.log('');
console.log('  Comandos disponibles:');
console.log('    /user:plan-dotnet   — planea un requerimiento antes de implementar');
console.log('    /user:review-dotnet — revisión completa de cambios antes de PR');
console.log('    /user:commit-dotnet — genera mensaje de commit en Conventional Commits');
console.log('    /user:test-dotnet   — genera unit tests de cambios pendientes o de un commit');
console.log('    /user:docker-dotnet    — revisa o genera configuración Docker/Compose');
console.log('    /user:changelog-dotnet — genera documento de control de cambios');
console.log('    /user:standup          — resumen del trabajo del día');
console.log('');
