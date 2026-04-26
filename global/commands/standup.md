# Generate standup summary

Generate a daily standup summary based on git activity.

## Steps

1. Run `git log --oneline --since="yesterday" --author="$(git config user.name)"` to get own commits
2. Run `git diff --stat HEAD~5..HEAD` if no recent commits found
3. Check for uncommitted work with `git status`

## Output format

**Yesterday:**
- [list of completed tasks based on commits]

**Today:**
- [infer from work in progress, or ask if unclear]

**Blockers:**
- [mention only if there are outdated branches, conflicts, or PRs waiting for review]

Keep it brief. 5 bullets maximum in total.
