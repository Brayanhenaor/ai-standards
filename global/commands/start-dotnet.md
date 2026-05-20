# Feature kickoff

Guide the start of a new feature from zero. Orchestrates: understanding requirements, choosing an implementation approach, setting up the branch, and scaffolding the structure — so the developer starts from a solid foundation rather than a blank file.

**Usage:**
- `/user:start-dotnet [feature description]` — guided kickoff for a new feature
- `/user:start-dotnet` — interactive mode: Claude will ask for the feature description

---

## Step 0 — Understand the feature

If the developer has not provided a full description, ask:

1. **What is the user-facing goal?** (what business problem does this solve?)
2. **What entities or aggregates are involved?** (new or existing?)
3. **What are the inputs and outputs?** (HTTP request? event? scheduled job?)
4. **What are the main business rules or constraints?**
5. **What does "done" look like?** (happy path, edge cases, error scenarios)

Do not proceed to design until all 5 questions are answered.

---

## Step 1 — Load project context

Read `CLAUDE.md` fully. Extract:
- Architecture: layer names and responsibilities
- Stack: ORM, messaging, caching, auth in use
- Existing patterns: CQRS or direct service, Result<T> or exceptions
- Test framework in use

Examine existing code in the relevant domain area:
```bash
find . -name "*.cs" | head -5  # understand naming conventions
git log --oneline -10           # recent work context
```

---

## Step 2 — Identify cross-cutting concerns

Based on the feature description, determine which expert lenses apply:

| Concern | Applies if |
|---------|-----------|
| **Architecture** | Feature crosses multiple services or layers; integration with external system |
| **Domain model** | New entity, aggregate, or value object needed |
| **Caching** | Read-heavy data, expensive computation, reference data |
| **Messaging** | State change must notify other services; async processing |
| **Security** | New endpoint, auth requirement, sensitive data |
| **Migrations** | New table, column, or index in EF Core |
| **Performance** | Expected high traffic, bulk data processing |

Explicitly state which lenses are active for this feature.

---

## Step 3 — Present implementation options

Offer **2 architectural approaches** for the feature. For each, analyze:

- What it involves structurally (layers, new files, patterns)
- Complexity: Low / Medium / High
- Testability: Easy / Medium / Hard
- Alignment with existing project conventions
- When to choose it

Format:

```
### Opción A — [Name]
**Enfoque:** [2-3 sentences describing the approach]

| Dimensión | Evaluación |
|-----------|-----------|
| Complejidad | Baja / Media / Alta |
| Testabilidad | Fácil / Media / Difícil |
| Alineación con proyecto | Alta / Media / Baja |

**Cuándo elegir:** [specific conditions]
**Trade-off:** [what you give up]

### Opción B — [Name]
[Same structure]

### Recomendación
[Which option and why, given the project's CLAUDE.md context]
```

---

## Step 4 — Confirm approach

Wait for the developer to choose an option (A, B, or a hybrid). Do not proceed to scaffold until the developer explicitly confirms.

---

## Step 5 — Branch setup

Suggest the branch name following project convention:

```bash
# Conventional branch naming
git checkout -b feat/[kebab-case-feature-name]

# Examples
git checkout -b feat/order-cancellation
git checkout -b feat/payment-webhook-consumer
git checkout -b feat/user-profile-caching
```

---

## Step 6 — Scaffold outline

Based on the chosen approach, describe exactly what `/user:scaffold-dotnet` will generate. Do NOT generate code yet — give the developer a chance to review what will be created.

```
### Archivos que se crearán

Domain/
  Entities/
    [EntityName].cs                    ← aggregate root with invariants
  Events/
    [EntityName]CreatedEvent.cs        ← domain event (if applicable)

Application/
  [Feature]/
    Commands/
      [ActionName]Command.cs           ← command record
      [ActionName]CommandHandler.cs    ← handler
    Queries/ (if applicable)
      Get[Entity]Query.cs
      Get[Entity]QueryHandler.cs
    DTOs/
      [Entity]Response.cs
    Validators/
      [ActionName]CommandValidator.cs  ← FluentValidation

Infrastructure/
  Repositories/
    [Entity]Repository.cs              ← IEntityRepository implementation
  Persistence/
    Configurations/
      [Entity]Configuration.cs        ← IEntityTypeConfiguration<T>

API/
  Controllers/
    [Entity]Controller.cs              ← thin controller

Tests/
  [Entity]Tests/
    [ActionName]CommandHandlerTests.cs ← unit tests
```

### Preguntas finales antes de scaffold

Before generating code, confirm any project-specific decisions:
- Does this feature use CQRS (MediatR) or direct service calls?
- Is there an existing base class for entities/repositories?
- What is the naming convention for the new entity (matches existing)?
- Is this behind a feature flag?

---

## Step 7 — Execute scaffold

Once confirmed: run `/user:scaffold-dotnet` with the chosen option and all collected context.

The scaffold call must include:
- Feature name
- Entity / aggregate name
- Chosen architectural approach
- Active cross-cutting concerns (messaging? caching? migrations?)
- Layer names as defined in CLAUDE.md

---

## Step 8 — Post-scaffold checklist

After scaffold runs, provide:

```
### Checklist post-scaffold

- [ ] Registrar IEntityRepository + EntityRepository en DI (Host/Extensions)
- [ ] Agregar EntityConfiguration a DbContext.OnModelCreating
- [ ] Crear migration: dotnet ef migrations add [MigrationName]
- [ ] Revisar migration generada: /user:migrate-dotnet
- [ ] Configurar consumer/publisher en bus (si messaging aplica)
- [ ] Agregar auth policy al controller (si endpoint protegido)
- [ ] Ejecutar tests: dotnet test
- [ ] Abrir PR cuando esté listo: /user:gate-dotnet
```

---

## Output rules

- Never skip the requirements clarification (Step 0) — incomplete understanding leads to wrong scaffold
- Never generate code before the developer confirms the approach (after Step 4)
- When messaging applies, always mention outbox requirement explicitly
- When caching applies, confirm TTL and key strategy before scaffold
- When migrations apply, remind the developer to run `/user:migrate-dotnet` after generating the migration
- The post-scaffold checklist is mandatory — it prevents forgotten DI registrations and DbContext wiring
- The command ends at scaffold setup — actual implementation is the developer's responsibility
