#!/usr/bin/env node
import {
  intro, outro, multiselect, note, spinner, cancel, isCancel,
} from '@clack/prompts';
import fs   from 'fs';
import path from 'path';
import os   from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT      = path.join(__dirname, '..');

const CLAUDE_DIR = path.join(os.homedir(), '.claude');
const CURSOR_DIR = path.join(process.cwd(), '.cursor');

// Frontmatter metadata for each Cursor rule
const CURSOR_RULE_META = {
  'csharp-conventions.md': {
    description: 'C# naming conventions, style, async patterns, and performance guidelines for .NET',
    globs: '**/*.cs',
  },
  'di-lifetimes.md': {
    description: 'Dependency injection lifetimes, SOLID principles, and interface abstractions',
    globs: '**/*.cs',
  },
  'testing.md': {
    description: 'Unit testing with xUnit, FluentAssertions, and NSubstitute — naming, structure, coverage',
    globs: '**/*Tests.cs,**/*Test.cs,**/*Specs.cs',
  },
  'security.md': {
    description: 'Security: JWT auth, authorization policies, PII protection, input validation',
    globs: '**/*.cs',
  },
  'docker.md': {
    description: 'Docker and Docker Compose best practices for .NET services',
    globs: '**/Dockerfile,**/docker-compose*.yml,**/*.dockerfile',
  },
  'resilience.md': {
    description: 'Resilience with Polly/Microsoft.Extensions.Resilience: timeouts, retries, circuit breakers',
    globs: '**/*.cs',
  },
  'ef-advanced.md': {
    description: 'Entity Framework Core: bulk operations, query optimization, index design, migrations',
    globs: '**/*.cs',
  },
  'observability.md': {
    description: 'Observability: Prometheus metrics with IMetrics, Serilog structured logging',
    globs: '**/*.cs',
  },
};

// ── Utilities ──────────────────────────────────────────────────────────────

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function short(p) {
  return p.startsWith(os.homedir()) ? '~' + p.slice(os.homedir().length) : p;
}

function copyFile(src, dest) {
  ensureDir(path.dirname(dest));
  fs.copyFileSync(src, dest);
}

function copyDir(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return 0;
  ensureDir(destDir);
  let n = 0;
  for (const file of fs.readdirSync(srcDir)) {
    copyFile(path.join(srcDir, file), path.join(destDir, file));
    n++;
  }
  return n;
}

function copyDirExecutable(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) return 0;
  ensureDir(destDir);
  let n = 0;
  for (const file of fs.readdirSync(srcDir)) {
    const dest = path.join(destDir, file);
    copyFile(path.join(srcDir, file), dest);
    fs.chmodSync(dest, 0o755);
    n++;
  }
  return n;
}

function mergeSettings(srcPath, destPath) {
  const incoming = JSON.parse(fs.readFileSync(srcPath, 'utf8'));
  let existing = {};
  if (fs.existsSync(destPath)) {
    try { existing = JSON.parse(fs.readFileSync(destPath, 'utf8')); } catch (_) {}
  }
  const merged = { ...existing };
  if (incoming.hooks) {
    merged.hooks = merged.hooks || {};
    for (const [event, newEntries] of Object.entries(incoming.hooks)) {
      merged.hooks[event] = merged.hooks[event] || [];
      for (const entry of newEntries) {
        const key = (entry.matcher ?? '') + '::' + (entry.hooks?.[0]?.command ?? '');
        const dup = merged.hooks[event].some(
          e => ((e.matcher ?? '') + '::' + (e.hooks?.[0]?.command ?? '')) === key
        );
        if (!dup) merged.hooks[event].push(entry);
      }
    }
  }
  fs.writeFileSync(destPath, JSON.stringify(merged, null, 2) + '\n');
}

function buildMdc(content, meta) {
  const lines = ['---'];
  if (meta.description)                 lines.push(`description: "${meta.description}"`);
  if (meta.globs)                       lines.push(`globs: "${meta.globs}"`);
  if (meta.alwaysApply !== undefined)   lines.push(`alwaysApply: ${meta.alwaysApply}`);
  lines.push('---', '');
  return lines.join('\n') + content;
}

// ── Installers ─────────────────────────────────────────────────────────────

function installClaude(components) {
  const log = [];

  if (components.includes('standards')) {
    const dest = path.join(CLAUDE_DIR, 'CLAUDE.md');
    if (fs.existsSync(dest)) {
      const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
      fs.copyFileSync(dest, `${dest}.${ts}.backup`);
    }
    copyFile(path.join(ROOT, 'global', 'CLAUDE.md'), dest);
    log.push(`${short(dest)}`);
  }

  if (components.includes('commands')) {
    const n = copyDir(path.join(ROOT, 'global', 'commands'), path.join(CLAUDE_DIR, 'commands'));
    log.push(`${short(path.join(CLAUDE_DIR, 'commands'))}/ (${n} comandos)`);
  }

  if (components.includes('rules')) {
    const n = copyDir(path.join(ROOT, 'global', 'rules'), path.join(CLAUDE_DIR, 'rules'));
    log.push(`${short(path.join(CLAUDE_DIR, 'rules'))}/ (${n} reglas)`);
  }

  if (components.includes('hooks')) {
    const n = copyDirExecutable(path.join(ROOT, 'global', 'hooks'), path.join(CLAUDE_DIR, 'hooks'));
    mergeSettings(path.join(ROOT, 'global', 'settings.json'), path.join(CLAUDE_DIR, 'settings.json'));
    log.push(`${short(path.join(CLAUDE_DIR, 'hooks'))}/ (${n} hooks)`);
    log.push(`${short(path.join(CLAUDE_DIR, 'settings.json'))}`);
  }

  return log;
}

function installCursor(components) {
  const log = [];

  if (components.includes('rules')) {
    const destDir = path.join(CURSOR_DIR, 'rules');
    ensureDir(destDir);

    // Global standards — always on
    const globalContent = fs.readFileSync(path.join(ROOT, 'global', 'CLAUDE.md'), 'utf8');
    fs.writeFileSync(
      path.join(destDir, 'global-standards.mdc'),
      buildMdc(globalContent, {
        description: 'Global .NET development standards, work rules, and language conventions',
        alwaysApply: true,
      })
    );

    // Per-topic rules with glob auto-attach
    let n = 1;
    const srcDir = path.join(ROOT, 'global', 'rules');
    for (const [file, meta] of Object.entries(CURSOR_RULE_META)) {
      const src = path.join(srcDir, file);
      if (!fs.existsSync(src)) continue;
      fs.writeFileSync(
        path.join(destDir, file.replace('.md', '.mdc')),
        buildMdc(fs.readFileSync(src, 'utf8'), meta)
      );
      n++;
    }
    log.push(`${short(destDir)}/ (${n} rules)`);
  }

  if (components.includes('commands')) {
    const n = copyDir(path.join(ROOT, 'global', 'commands'), path.join(CURSOR_DIR, 'commands'));
    log.push(`${short(path.join(CURSOR_DIR, 'commands'))}/ (${n} comandos — úsalos con /)`);
  }

  return log;
}

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  console.log('');
  intro(' ai-standards — instalador ');

  // Step 1: editors
  const editors = await multiselect({
    message: '¿Para qué editores deseas instalar?',
    options: [
      { value: 'claude', label: 'Claude Code', hint: '~/.claude/' },
      { value: 'cursor', label: 'Cursor',      hint: '.cursor/ en el proyecto actual' },
    ],
    initialValues: ['claude'],
    required: true,
  });

  if (isCancel(editors)) { cancel('Cancelado.'); process.exit(0); }

  // Step 2: components
  let claudeComponents = [];
  let cursorComponents = [];

  if (editors.includes('claude')) {
    claudeComponents = await multiselect({
      message: 'Claude Code — componentes:',
      options: [
        { value: 'standards', label: 'Estándares globales', hint: 'CLAUDE.md → ~/.claude/' },
        { value: 'commands',  label: 'Comandos',            hint: '16 comandos /user: → ~/.claude/commands/' },
        { value: 'rules',     label: 'Rules',               hint: 'csharp, security, testing, docker… → ~/.claude/rules/' },
        { value: 'hooks',     label: 'Hooks',               hint: 'build-check · migration-guard · test-runner' },
      ],
      initialValues: ['standards', 'commands', 'rules', 'hooks'],
      required: true,
    });
    if (isCancel(claudeComponents)) { cancel('Cancelado.'); process.exit(0); }
  }

  if (editors.includes('cursor')) {
    note(
      `Las reglas y comandos se instalarán en:\n  ${CURSOR_DIR}\n\nNota: Cursor no soporta reglas globales aún — la instalación es por proyecto.`,
      'Cursor'
    );
    cursorComponents = await multiselect({
      message: 'Cursor — componentes:',
      options: [
        { value: 'rules',    label: 'Rules',    hint: '9 archivos .mdc con frontmatter → .cursor/rules/' },
        { value: 'commands', label: 'Comandos', hint: '16 slash commands → .cursor/commands/ (úsalos con /)' },
      ],
      initialValues: ['rules', 'commands'],
      required: true,
    });
    if (isCancel(cursorComponents)) { cancel('Cancelado.'); process.exit(0); }
  }

  // Step 3: install
  const s = spinner();
  const summary = [];

  if (editors.includes('claude')) {
    s.start('Instalando Claude Code…');
    const log = installClaude(claudeComponents);
    s.stop('Claude Code listo');
    summary.push({ label: 'Claude Code', log });
  }

  if (editors.includes('cursor')) {
    s.start('Instalando Cursor…');
    const log = installCursor(cursorComponents);
    s.stop('Cursor listo');
    summary.push({ label: 'Cursor', log });
  }

  // Results
  for (const { label, log } of summary) {
    note(log.map(l => `  ✓  ${l}`).join('\n'), label);
  }

  // Next steps
  if (editors.includes('claude')) {
    note(
      [
        'Abre el proyecto en Claude Code y ejecuta:',
        '',
        '  /user:init-dotnet',
        '',
        'Hooks activos:',
        '  build-check     — compila tras editar .cs',
        '  migration-guard — bloquea ef database update',
        '  test-runner     — ejecuta tests tras *Tests.cs',
      ].join('\n'),
      'Próximos pasos — Claude Code'
    );
  }

  if (editors.includes('cursor')) {
    note(
      [
        'Abre el proyecto en Cursor y escribe / para ver los comandos:',
        '',
        '  /plan-dotnet    implementar autenticación JWT',
        '  /review-dotnet  revisar antes del PR',
        '  /scaffold-dotnet nueva feature',
        '',
        'Reglas que se activan solas por contexto:',
        '  csharp-conventions — al editar *.cs',
        '  testing            — al editar *Tests.cs',
        '  docker             — al editar Dockerfile',
        '',
        'Nota: instala en cada nuevo proyecto ejecutando este wizard desde su raíz.',
      ].join('\n'),
      'Próximos pasos — Cursor'
    );
  }

  outro('¡Listo!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
