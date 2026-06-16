---
name: commit
description: Write a Conventional Commits message for staged changes. Use when the developer wants to commit or asks for a commit message. Analyzes the actual diff, picks the right type and scope, and writes a clear, honest message — never a vague one.
---

# Commit

Generate a commit message that follows the Conventional Commits spec and tells the truth about the
change. A good message explains *what changed and why* so the history stays useful.

## 1. Read the actual changes

- Inspect what's staged: `git diff --cached --stat` then `git diff --cached`.
- If nothing is staged, look at the working changes (`git status`, `git diff`) and tell the developer
  what you'd stage — don't commit an empty or accidental set.
- Base the message on what the diff *actually does*, not on what was asked for. If they diverge, the
  diff wins (and flag the divergence).

## 2. Compose the message

```
<type>(<scope>): <subject>

<body>
```

- **type:** `feat` · `fix` · `refactor` · `perf` · `docs` · `test` · `chore` · `ci` · `build`
- **scope:** the area touched (optional but preferred) — a module, layer, or component.
- **subject:** imperative mood, lowercase, no trailing period, ≤ ~72 chars
  ("add retry to payment client", not "added retries").
- **body** (when the change isn't trivial): *why* the change exists and any consequence worth
  knowing. Wrap at ~72 cols. Skip the body for genuinely trivial changes.
- **breaking change:** add a `!` after type/scope and a `BREAKING CHANGE:` footer.

## 3. One commit = one logical change

- If the staged diff mixes unrelated changes (a feature *and* an unrelated fix), say so and suggest
  splitting into separate commits rather than writing one muddy message.

## Rules

- English, always — message, subject, and body.
- Never invent a scope or motive the diff doesn't support.
- Never commit secrets, `.env`, or generated artifacts — flag them if staged.
- Don't run `git commit` until the developer approves the message, unless they've told you to commit
  directly.
- Present the proposed message to the developer in their language, but keep the message itself in
  English.
