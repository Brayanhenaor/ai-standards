# Plan implementation

Receive a requirement and produce a professional implementation plan before writing any code.

## Requirement
$ARGUMENTS

---

## Phase 1 — Understand before planning

Before proposing anything, ask all necessary questions to avoid building on wrong assumptions.

Identify what is unclear or ambiguous:
- Business rules and edge cases not specified
- Expected behavior under error conditions
- Volume / scale expectations (affects design decisions)
- Integration with existing components
- Non-functional requirements (latency, consistency, availability)
- Whether this is greenfield or modifying existing code

**Ask all questions in a single message** — do not ask one at a time. Wait for answers before proceeding to Phase 2.

If the requirement is clear enough to proceed without questions, state your assumptions explicitly instead.

---

## Phase 2 — Explore the codebase

Read relevant existing code before designing the solution:
- Find the affected domain area, existing entities, services and repositories
- Understand the current architecture state of this part of the project
- Identify reusable components vs what needs to be created
- Note any existing technical debt that affects the solution

---

## Phase 3 — Propose options

Present **at least two solution options**. For complex requirements, three.

For each option:

```
### Option N — Name

**Summary:** One sentence describing the approach.

**How it works:** Brief description of the design.

**Pros:**
- ...

**Cons:**
- ...

**Best for:** When this option is the right choice.
**Complexity:** Low / Medium / High
**Reversibility:** Easy to change later / Hard to undo
```

Evaluate options across:
- Correctness and completeness
- Alignment with the project's current architecture
- Performance and resource usage
- Testability
- Maintainability and readability
- Implementation effort

---

## Phase 4 — Recommendation

State which option you recommend and why, considering:
- The current state of the codebase (not the ideal state)
- The team's apparent conventions from the existing code
- Long-term maintainability vs implementation speed

If the project has architectural debt that affects the solution, mention it as a `⚠️ Refactor opportunity` without making it a blocker.

---

## Phase 5 — Implementation plan

For the recommended option, produce a step-by-step plan:

```
## Implementation Plan — [Option name]

### Steps

1. [Step name]
   - Files to create or modify: `path/to/file.cs`
   - What to implement: specific description
   - Depends on: step N (if applicable)

2. ...

### Files summary
| Action | File | Description |
|---|---|---|
| Create | `Domain/Entities/X.cs` | ... |
| Modify | `Application/Services/XService.cs` | ... |

### Testing strategy
- Unit tests needed for: [list handlers, services, domain logic]
- Integration tests needed for: [list endpoints or repositories]
- Critical paths to cover: [happy path, error cases, edge cases]

### ADR required
[Yes — decision about X / No]

### README update required
[Yes — new env vars: X, Y / new endpoint: Z / No]

### Estimated complexity
[Small < 2h / Medium ~half day / Large > 1 day — should be split]

### Risks and open questions
- [Any remaining uncertainty or risk that could affect the plan]
```

---

**Do not write any code until the dev confirms the plan.**
If the dev selects a different option, rebuild the implementation plan for that option before coding.
