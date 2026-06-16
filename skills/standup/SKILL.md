---
name: standup
description: Generate a daily standup summary from recent git activity. Use when the developer asks for a standup, a summary of what they did, or a daily/weekly work recap. Reports what was done from real commits — concise, honest, no padding.
---

# Standup

Summarize recent work from the git history into a short standup — grounded in what actually happened,
not an aspirational narrative.

## Gather

```bash
git log --since="yesterday" --author="$(git config user.name)" --oneline
git log --since="yesterday" --author="$(git config user.name)" --stat
```

Adjust the window to what's asked (today, since last standup, this week). If the developer works under
a different committer name/email, ask or widen the filter.

## Summarize

Group related commits into themes — don't list raw commit messages one by one. Translate them into
plain accomplishments a teammate would understand.

```
Standup — [date]

Done:
- [theme: what was accomplished and where, plain language]
- [...]

In progress / next:
- [uncommitted work-in-progress, or the obvious next step]

Blockers:
- [anything that stalled — only if real; otherwise "none"]
```

## Rules

- Honest and concise. Don't inflate small changes into big ones, and don't pad to look productive.
- Infer "in progress" from uncommitted changes (`git status`) when relevant.
- If there's no activity in the window, say so — don't invent work.

Reply in the developer's language; keep code identifiers in English.
