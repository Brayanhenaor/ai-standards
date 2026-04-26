# Initialize and adapt standards to the project

Run this analysis ONCE. The goal is to generate a CLAUDE.md that reflects both the company base standards and the reality of this specific project.

---

## Phase 1 — Analyze the solution

Explore the project thoroughly before writing anything.

### General structure
- Read the `.sln` and all `.csproj` files to understand projects and their dependencies
- Map the full folder structure (ignore bin/, obj/, .git/, .vs/, node_modules/)
- Identify how many projects exist and the role of each

### Stack and dependencies
- Extract all `PackageReference` entries from each `.csproj`
- Identify key libraries: ORM, messaging, logging, auth, mapping, etc.
- Detect the .NET and C# version of each project

### Real architecture
- Read `Program.cs` / `Startup.cs` to understand DI setup and middlewares
- Analyze namespaces to understand the real project layers
- Read 2–3 representative files per layer (controllers, services, repositories, entities)
- Detect patterns in use: CQRS? Repository pattern? Clean Architecture? Simple layers?
- Identify if there is an `ApiResponse<T>` or similar base response class
- Detect error handling approach: global middleware? try/catch per controller?

### Real code conventions
- Analyze actual naming of files and classes (Request/Response? Dto? ViewModel?)
- Detect how async methods are named (do they have the `Async` suffix?)
- Identify whether they use `var` or explicit types
- Detect injection style: constructor? `inject()`?
- Check if constants are organized in static classes or scattered as string literals

### Technical debt and deviations
- Identify parts of the project that do NOT follow the ideal architecture
- Detect common anti-patterns: business logic in controllers, exposed DbContext, etc.
- Note what is well implemented and what needs eventual refactoring

---

## Phase 2 — Download the base template and adapt it

**Download the full template first — never generate CLAUDE.md from scratch.**

```bash
curl -fsSL "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/templates/dotnet/CLAUDE.md" -o CLAUDE.md
```

The project will only have this file. Detailed rules (`docker.md`, `resilience.md`, `ef-advanced.md`, `testing.md`, `security.md`) are already installed globally in `~/.claude/rules/` by the `npx` setup — they are not needed in the project.

Then read the downloaded file and apply the following adaptations:

### Sections you MUST modify
- **Title** (`# [ProjectName]`) → real project name
- **Stack** → real versions and packages detected in the `.csproj` files
- **Architecture** → describe WHAT IS THERE: real layers, real folders, real patterns
- **C# conventions** → adjust only what the project already does differently (naming, var vs explicit type, etc.)

### Sections you must NOT touch
Everything else stays exactly as in the template:
- Error handling, logging, security, performance, resilience
- EF Core, Mapster, DTOs, testing, code quality
- Documentation, what NOT to do

### Balance: base rules vs adaptation

| Section | What to do |
|---|---|
| Quality, security, performance | Keep unchanged — non-negotiable |
| Ideal architecture | Adapt: describe the real architecture + indicate evolution direction |
| Naming and conventions | Adapt to the project's real style to avoid inconsistencies |
| Patterns (CQRS, Repository, etc.) | Include only those already in use or with clear adoption intent |
| Detected technical debt | Add `## Current project state` section with real findings |

### Mandatory additional section if there is debt

If you detect significant deviations from standards, add this section to CLAUDE.md:

```markdown
## Current project state

### What is working well
- [list of good practices already in place]

### Technical debt detected
- [CRITICAL] description — affects correctness or security
- [IMPROVEMENT] description — standards violation, medium priority
- [TECHNICAL] minor debt — for a future refactor sprint

### Evolution direction
- [recommended gradual refactors and suggested order]
```

---

## Phase 3 — Write CLAUDE.md and generate PROJECT_STATUS.md

### 3a — Write CLAUDE.md
1. Write the adapted CLAUDE.md over the downloaded file
2. If there is significant technical debt, add the `## Current project state` section before `## Available commands`

### 3b — Generate docs/PROJECT_STATUS.md

Create `docs/PROJECT_STATUS.md` as a living snapshot of the project's health. This file is for the team — not for Claude rules. Use the findings from Phase 1.

```markdown
# Project Status — [ProjectName]

> Analysis date: [current date]
> Analyzed by: `/user:init-dotnet`

## Overview
[What the project does, its purpose, and type of system — inferred from the code]

## Architecture
[Description of the actual architecture found: layers, patterns, dependency direction]

## Stack
| Component | Version / Package |
|---|---|
| .NET | X.X |
| [Key package] | X.X.X |
| ... | ... |

## Technical debt

### 🔴 Critical
Items that affect security, correctness, or cause silent bugs.
- [description] — [affected files or areas]

### 🟡 Improvements
Standards violations or design issues that should be addressed in upcoming sprints.
- [description] — [affected files or areas]

### 🔵 Technical
Minor cleanup, naming, or structural issues.
- [description]

## Security observations
[Any auth gaps, hardcoded secrets, missing input validation, exposed IDs, etc. — or "None detected"]

## Performance observations
[N+1 risks, missing pagination, unbounded queries, socket issues, etc. — or "None detected"]

## Test coverage
[What is tested, what is missing, whether critical paths are covered]

## Missing documentation
[Missing README sections, ADRs that should exist, undocumented config, etc. — or "None detected"]

## Recommended evolution roadmap
Ordered by priority:
1. [First thing to fix — why]
2. [Second thing — why]
3. ...
```

If a section has nothing to report, write `None detected` rather than omitting the section — this confirms the area was checked.

---

## Phase 4 — Confirm

Present the following summary to the dev:

```
✅ Project initialized: [ProjectName]

Stack detected:
  • .NET X / C# X
  • [project type]
  • [DB and ORM]
  • [key packages]

Architecture detected:
  • [1–2 line description of what you found]

Files generated:
  • CLAUDE.md              — rules adapted to this project
  • docs/PROJECT_STATUS.md — project health snapshot

[If debt exists]: ⚠️ N technical debt items detected — see docs/PROJECT_STATUS.md

Available commands:
  /user:init-dotnet   — this command (already executed)
  /user:plan-dotnet   — plan a requirement before implementing
  /user:review-dotnet — full review of branch changes before PR
  /user:commit-dotnet — generate commit message in Conventional Commits
  /user:test-dotnet   — generate unit tests for pending changes or a commit
  /user:docker-dotnet — review or generate Docker/Compose configuration
```
