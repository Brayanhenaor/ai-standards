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

## Response style
- Concise: do not explain what the code already says
- No trailing summaries at the end of each response
- No obvious comments in code
- Prefer editing existing files over creating new ones
- Flag deviations from standards without blocking the task

## .NET security baselines
- Connection strings always from `IConfiguration` / User Secrets / env vars — never hardcoded
- Never log tokens, passwords, PII, or any sensitive data
- Use `ILogger<T>` — never `Console.WriteLine` in production
- Validate inputs at the system boundary (controllers/endpoints), not inside services
