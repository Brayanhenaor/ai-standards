#!/usr/bin/env node

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const ROOT         = path.join(__dirname, '..');
const CLAUDE_DIR   = path.join(os.homedir(), '.claude');
const COMMANDS_DIR = path.join(CLAUDE_DIR, 'commands');
const RULES_DIR    = path.join(CLAUDE_DIR, 'rules');
const HOOKS_DIR    = path.join(CLAUDE_DIR, 'hooks');
const SETTINGS     = path.join(CLAUDE_DIR, 'settings.json');

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

function copyDirExecutable(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return;
  ensureDir(destDir);
  for (const file of fs.readdirSync(srcDir)) {
    const dest = path.join(destDir, file);
    copyFile(path.join(srcDir, file), dest);
    fs.chmodSync(dest, 0o755);
  }
}

// Merge incoming hooks into existing settings.json without overwriting user config.
// Deduplicates entries by matcher + first command string.
function mergeSettings(srcPath, destPath) {
  const incoming = JSON.parse(fs.readFileSync(srcPath, 'utf8'));

  let existing = {};
  if (fs.existsSync(destPath)) {
    try { existing = JSON.parse(fs.readFileSync(destPath, 'utf8')); }
    catch (_) { /* corrupted — start from incoming */ }
  }

  const merged = { ...existing };

  if (incoming.hooks) {
    merged.hooks = merged.hooks || {};
    for (const [event, newEntries] of Object.entries(incoming.hooks)) {
      merged.hooks[event] = merged.hooks[event] || [];
      for (const entry of newEntries) {
        const key = (entry.matcher ?? '') + '::' + (entry.hooks?.[0]?.command ?? '');
        const duplicate = merged.hooks[event].some(
          e => ((e.matcher ?? '') + '::' + (e.hooks?.[0]?.command ?? '')) === key
        );
        if (!duplicate) merged.hooks[event].push(entry);
      }
    }
  }

  fs.writeFileSync(destPath, JSON.stringify(merged, null, 2) + '\n');
  console.log(`  ✓  ~/.claude/settings.json`);
}

// ── Install ──────────────────────────────────────────────────────────────────

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

copyFile(path.join(ROOT, 'global', 'CLAUDE.md'), globalClaude);
copyDir(path.join(ROOT, 'global', 'commands'), COMMANDS_DIR);
copyDir(path.join(ROOT, 'global', 'rules'), RULES_DIR);
copyDirExecutable(path.join(ROOT, 'global', 'hooks'), HOOKS_DIR);
mergeSettings(path.join(ROOT, 'global', 'settings.json'), SETTINGS);

console.log('');
console.log('  Listo. Abre el proyecto en Claude Code y ejecuta:');
console.log('');
console.log('    /user:init-dotnet');
console.log('');
console.log('  Hooks activos:');
console.log('    build-check     — compila tras editar .cs, errores visibles de inmediato');
console.log('    migration-guard — bloquea ef database update / ef migrations remove');
console.log('    test-runner     — ejecuta tests tras escribir archivos *Tests.cs');
console.log('');
