# supercode

**Universal clean-code intelligence for Claude Code.** A plugin of skills, agents, and hooks that
push every change toward the cleanest, simplest, most maintainable form — in any language —
questioning the developer and itself, verifying before claiming done, and refusing to over-engineer.

Deep **.NET** pack today; a language-agnostic core for everything else.

---

## Install

In Claude Code:

```bash
# 1. Add this repo as a plugin marketplace
/plugin marketplace add Brayanhenaor/ai-standards

# 2. Install the plugin
/plugin install supercode@supercode

# 3. Check it's active
/plugin
```

That's it. No per-project setup. To work better in a specific repo, run `/supercode:init` once — it
detects your stack and conventions and writes a short project profile so every skill adapts to *your*
codebase.

---

## How it works — two modes

supercode works in **two ways at the same time**, and you don't choose between them:

### 1. Automatic — it works in the background as you code

Most skills activate **on their own** when the context calls for them, because Claude reads each
skill's description and invokes the right one at the right moment. You don't type anything.

- Writing or editing code → the **clean-code core** and **anti-over-engineering** shape it toward
  clean, simple structure, and flag smells.
- Writing `async`/concurrent code → the **concurrency** lens watches for races and deadlocks.
- Writing a loop over lots of data, or a query → the **performance** lens watches for N+1 and waste.
- Working in a `.NET` project → the **dotnet** pack layers on the .NET-specific rules.
- Hitting a compile/runtime error → **debug** kicks in with a methodical protocol instead of guessing.
- Finishing a change → **verify** runs the real build/tests before anything is called "done."

You can also just describe what you want ("review this", "plan how to add X", "is this ready to
ship?") and Claude picks the matching skill automatically — no exact command needed.

### 2. Manual — you invoke a skill by name

When you want a specific skill on demand, call it with `/supercode:<skill>`. Anything after the name
is passed as input.

```bash
/supercode:review --diff                      # audit the current changes
/supercode:review --full src/payments         # audit a whole area
/supercode:plan add idempotent payment retries
/supercode:security-audit --diff
/supercode:gate                               # pre-PR go / no-go
/supercode:adr use the outbox pattern for order events
```

Every skill works both ways. The list below groups them by how you'll *usually* reach for them.

---

## Manual commands you'll use most

| Command | What it does |
|---|---|
| `/supercode:review [--diff\|--full [path]]` | Audit code against the full ruleset; findings by severity with file:line + fix. Default `--diff`. |
| `/supercode:security-audit [--diff\|--full]` | OWASP-aligned security audit with the exploit path for each finding. |
| `/supercode:plan <what you want to build>` | Architectural consultant — options, trade-offs, challenges you, no code until agreed. |
| `/supercode:grill` | Pressure-tests your plan one sharp question at a time. |
| `/supercode:gate` | Pre-PR orchestrator: build, tests, review, security, migration, hygiene → go/no-go. |
| `/supercode:scaffold <feature>` | Lays down a feature mirroring your project's real architecture. |
| `/supercode:test <target>` | Generates behavior-focused tests in your project's own stack. |
| `/supercode:refactor <target>` | Behavior-preserving cleanup in small, test-backed steps. |
| `/supercode:commit` | A Conventional Commits message from your real staged diff. |
| `/supercode:adr <decision>` | Architecture Decision Record (official template), after challenging you on it. |
| `/supercode:changelog [commits]` | Formal change-control document (official template). |
| `/supercode:tech-doc` | Full technical-manual JSON extracted from the codebase. |
| `/supercode:migrate` | Checks a DB migration for locks, data loss, and zero-downtime safety. |
| `/supercode:zoom-out` | Maps an unfamiliar area of code before you dive in. |
| `/supercode:standup` | A standup summary from your recent git activity. |
| `/supercode:init` | One-time: detect stack + conventions, write a project profile. |

## What runs automatically (no command needed)

These work as background lenses while you code, and you can still call any of them by name:

- **`clean-code-core`** — SOLID, naming, function design, cohesion/coupling, smells.
- **`anti-overengineering`** — keeps solutions as simple as they can cleanly be.
- **`verify`** — runs the real build/tests before claiming success.
- **`concurrency`** · **`performance`** · **`architect`** · **`domain`** — deep-analysis lenses that
  fire in the situations they matter (async code, hot paths, cross-boundary design, domain modeling).
- **`dotnet`** — the .NET pack, active when you're in a .NET codebase.
- **`debug`** — the structured debugging protocol, on any error.

### Agents (deep, isolated, read-only)

`review` and `security-audit` hand the heavy lifting to background subagents — **`code-reviewer`** and
**`security-auditor`** — so a large audit runs thoroughly without cluttering your main session.

### Hook (fully automatic)

- **`secret-scan`** — before any `git commit`, it scans the staged changes and **blocks the commit**
  if it finds a likely secret (private key, AWS/GitHub token, JWT, password, connection string).

---

## The philosophy it enforces

A strict hierarchy resolves every conflict: **correctness & safety > clean code > avoid
over-engineering.** It steers between the two opposite failures — the god-method and the speculative
framework — by one test: *does this earn its place with real value today?* It questions you (trade-offs,
risks), questions itself (self-review), verifies with teeth, adapts to your project's conventions, and
replies in your language while keeping code in English.

## Architecture — three layers

- **Universal core** — clean-code knowledge for every language.
- **Stack packs** — depth for a stack on top of the core. `dotnet` ships today (8–10, .NET 10 LTS).
- **Company profile** — optional overlay for org-specific bits (official ADR/changelog/tech-doc
  templates, language for generated docs). Never hardcoded in the core.

## Managing the plugin

```bash
/plugin                              # list / enable / disable / configure
/plugin update supercode@supercode   # pull the latest version
/plugin uninstall supercode          # remove it
```

## Documentation & license

Full design and principles: [`docs/PLUGIN_VISION.md`](docs/PLUGIN_VISION.md). Licensed MIT — see
[LICENSE](LICENSE). Contributions: [CONTRIBUTING.md](CONTRIBUTING.md).
