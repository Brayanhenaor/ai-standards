# Contributing to supercode

Thanks for helping. supercode must practice what it preaches: clean, simple, no over-engineering.

## Principles for contributions

- **Dogfood the hierarchy.** Correctness & safety first, then clean code, then *cut anything that
  doesn't earn its place today*. A new skill/agent/hook must solve a real, present need — not a
  hypothetical one.
- **Universal core vs pack vs profile.** Keep language-agnostic clean-code knowledge in the core.
  Stack-specific guidance goes in a pack (`skills/dotnet/…`). Org/vendor-specific bits go in a
  company profile, never in the core.
- **Frozen templates stay frozen.** The `adr`, `changelog`, and `tech-doc` output structures are
  official contracts — change wording, never the structure, without a deliberate decision.

## Authoring a skill

- One skill per directory: `skills/<name>/SKILL.md`, with frontmatter `name` + a precise,
  trigger-rich `description` (that's what drives auto-invocation).
- Use **progressive disclosure**: keep `SKILL.md` short; put depth in `reference/` loaded on demand.
- All content in English. Skills reply to the developer in the developer's language.
- Read-only deep work belongs in an `agents/<name>.md` subagent, restricted with `tools:`.

## Before you open a PR

```bash
claude plugin validate .          # manifest + frontmatter must pass
```

- Follow Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, …).
- Bump `version` in `.claude-plugin/plugin.json` (semver) and add a `CHANGELOG.md` entry.
- Run `/supercode:review --diff` on your own change. Practice the plugin.

## Scope to keep resisting (until real demand)

Vendor-specific backends, broad multi-language packs from day one, themes/output-styles, a custom MCP
server. Start small; grow on evidence of use.
