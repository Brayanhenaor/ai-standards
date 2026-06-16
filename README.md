# supercode

**Universal clean-code intelligence for Claude Code.** A plugin of skills, agents, and hooks that
push every change toward the cleanest, simplest, most maintainable form — in any language —
questioning the developer and itself, verifying before claiming done, and refusing to over-engineer.

Deep **.NET** pack today; a language-agnostic core for everything else.

---

## Install

```bash
/plugin marketplace add Brayanhenaor/ai-standards
/plugin install supercode@supercode
```

Then just work. Skills auto-activate when relevant, and you can invoke any of them by hand
(`/supercode:review`, `/supercode:plan`, …).

## What makes it different

- **Clean code wins, but never over-engineering.** A strict hierarchy resolves every conflict:
  *correctness & safety > clean code > avoid over-engineering*. It steers between the two opposite
  failures — the god-method and the speculative framework — by one test: *does this earn its place
  with real value today?*
- **It questions you, not just obeys.** Surfaces trade-offs and risks, challenges shaky assumptions,
  and asks instead of guessing.
- **It questions itself.** Self-reviews its output before handing it over.
- **It verifies with teeth.** Runs the real build/tests before saying something works.
- **It adapts.** Respects your project's existing conventions instead of imposing; replies in your
  language while keeping code in English.

## What's inside

**Reason & collaborate** — `plan` · `grill` · `zoom-out` · `architect` · `domain`
**Write clean code** — `clean-code-core` · `anti-overengineering` · `refactor` · `scaffold` · `dotnet`
**Verify & review** — `review` · `security-audit` · `verify` · `concurrency` · `performance` · `test` · `gate`
**Ship & document** — `commit` · `changelog` · `adr` · `tech-doc` · `standup` · `migrate` · `init`

**Agents** (deep, isolated, read-only) — `code-reviewer` · `security-auditor`
**Hooks** — `secret-scan` (blocks commits containing likely secrets)

## Architecture

Three layers, so the same plugin serves any team:

- **Universal core** — clean-code knowledge that holds for every language (`clean-code-core` and its
  `reference/`: SOLID, naming, functions, abstraction, smells).
- **Stack packs** — depth for a specific stack on top of the core. `dotnet` ships today (8–10, .NET 10
  LTS): conventions, DI, errors, EF Core, APIs, resilience, observability, caching, messaging,
  security, testing, Docker.
- **Company profile** — optional overlay for org-specific bits (official ADR / changelog /
  technical-doc templates, language for generated docs). Never hardcoded in the core.

## Examples

```
/supercode:review --diff          # audit the current changes
/supercode:review --full src/      # audit a whole area
/supercode:plan add idempotent payment retries
/supercode:security-audit --diff
/supercode:gate                    # pre-PR go/no-go
```

## Documentation

The full design and principles live in [`docs/PLUGIN_VISION.md`](docs/PLUGIN_VISION.md).

## License

MIT — see [LICENSE](LICENSE).
