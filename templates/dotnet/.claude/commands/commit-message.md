# Generate conventional commit message

Analyze staged changes and generate a professional commit message following Conventional Commits specification.

## Step 1 — Read the changes

Run `git diff --cached` to see staged changes.
If nothing is staged, run `git diff HEAD` instead and mention it.

## Step 2 — Analyze

Before writing anything, identify:
- **What changed**: which files, which layers (domain, application, infrastructure, api, config, tests, docs)
- **Why it changed**: infer intent from the code — a new feature, a bug fix, a refactor, a performance improvement
- **Scope**: which module, feature or component is affected
- **Breaking changes**: does this modify a public API contract, remove a field, change behavior in a non-backwards-compatible way

## Step 3 — Generate the commit message

**Format:**
```
type(scope): short imperative description

- Bullet explaining the main change and why
- Bullet for secondary changes if relevant
- Bullet for anything non-obvious

[BREAKING CHANGE: description if applicable]
[Closes #issue if detectable]
```

**Types:**
| Type | When to use |
|---|---|
| `feat` | New functionality visible to the user or consumer |
| `fix` | Bug fix |
| `refactor` | Code restructure without behavior change |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `docs` | Documentation only |
| `chore` | Build, config, dependencies, tooling |
| `ci` | CI/CD pipeline changes |

**Rules:**
- Title: imperative mood, lowercase after type, no period, max 72 characters
- Title describes WHAT, body explains WHY
- Scope is the module or feature name in kebab-case (`user-auth`, `order-processing`)
- If changes span multiple unrelated areas, suggest splitting into separate commits
- Never mention file names in the title — describe behavior, not implementation

## Step 4 — Output

Present the commit message ready to copy, then a one-line explanation of the type and scope chosen.
If the changes are too mixed to form a clean commit, say so and suggest how to split them.
