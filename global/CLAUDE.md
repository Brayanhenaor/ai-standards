# Global standards — [Company]

## Context
I am a developer at [Company]. Primary stack: .NET 8+, C#.
Each repo has its own CLAUDE.md with project-specific rules.

## Universal work rules
- Conventional Commits always: feat/fix/chore/refactor/docs/test/ci/perf
- Never force push to main/master — ask for explicit confirmation first
- Never commit `.env`, secrets, or connection strings
- Ask for confirmation before deleting files or making destructive changes
- Propose before implementing when the change affects architecture or shared contracts

## Language

- **Code, comments, identifiers, commit messages** → always English
- **Responses to the developer, documentation, plans, reviews, reports** → always Spanish
- This applies to: README.md, ADRs, PROJECT_STATUS.md, change control documents, code review output, implementation plans, test summaries, and any text shown to the user
- Exception: technical terms with no standard Spanish equivalent keep their English form (e.g. "endpoint", "middleware", "handler", "payload")

## Response style
- Concise: do not explain what the code already says
- No trailing summaries at the end of each response
- No obvious comments in code
- Prefer editing existing files over creating new ones
- Flag deviations from standards without blocking the task

## Debugging discipline

When the developer reports a compilation or runtime error, apply this protocol automatically — do not wait to be asked:

1. **Collect before acting** — read the full error output, every referenced file and line, and `git diff HEAD`. Never propose a fix without reading the exact location the error points to.
2. **One hypothesis, stated explicitly** — before touching any code, state what you believe the cause is and why. If uncertain, list 2–3 ranked hypotheses.
3. **One change per iteration** — make the minimum change to test hypothesis 1. Do not fix multiple things simultaneously. Do not refactor while debugging.
4. **Verify before moving on** — after each change, confirm the error is resolved. If not, state what the attempt revealed, revert, and move to the next hypothesis.
5. **Never guess in a loop** — if two hypotheses fail, stop and ask for more information rather than trying random changes.

## .NET security baselines
- Connection strings always from `IConfiguration` / User Secrets / env vars — never hardcoded
- Never log tokens, passwords, PII, or any sensitive data
- Use `ILogger<T>` — never `Console.WriteLine` in production
- Validate inputs at the system boundary (controllers/endpoints), not inside services
