# DDD & Domain Modeling Expert

Act as a senior domain-driven design practitioner. Analyze or design domain models with focus on aggregate boundaries, invariant enforcement, and correct separation between domain logic and infrastructure concerns.

**Usage:**
- `/user:domain-dotnet <entity, aggregate, or domain area to review>` — review existing model
- `/user:domain-dotnet <requirement description>` — design a domain model from scratch

## $ARGUMENTS

---

## Step 1 — Load context

Read `CLAUDE.md` to understand the project's architecture, current patterns, and any DDD-specific conventions.

Read the relevant domain files:
- Entities and their properties and methods
- Value objects if they exist
- Domain events if they exist
- Repository interfaces
- Any validators or business rule classes
- Service interfaces in the Application layer that touch this domain area

---

## Step 2 — Analyze the domain model

### Aggregate boundaries and consistency

- Is each aggregate responsible for enforcing its own invariants, or are invariants spread across services?
- Can an aggregate be loaded, modified, and saved without loading other aggregates?
- Are there references between aggregates using object references (wrong) instead of IDs (correct)?
- Is the aggregate root the only entry point for modifications — no direct access to child entities from outside?
- Is the aggregate too large? Does a single transaction modify data from multiple business concepts?
- Is the aggregate too small? Are invariants being enforced in the application service instead of the domain?

### Entity vs Value Object

Look for **primitive obsession** — concepts expressed as primitives that deserve their own type:
- Email address as `string` — no validation, no behavior, no type safety
- Money / price as `decimal` — no currency, allows subtraction across currencies
- Phone number, IBAN, document ID, URL as `string` — no format enforcement
- Status/state as `int` or raw `string` — no domain meaning, no exhaustive handling
- Date ranges, time windows as two separate `DateTime` fields — no validation that start < end

A value object is the right choice when: the concept has business rules, should be immutable, and is identified by its value not its identity.

### Invariant enforcement

- Are business rules enforced in the entity constructor and public methods, or only in the service layer?
- Can an entity be created in an invalid state (e.g., via parameterless constructor + property setters)?
- Are `private set` / `init` used on properties that must not change after creation?
- Are guard clauses throwing domain-specific exceptions (not `ArgumentException`) with meaningful messages?
- Are collections exposed as `IReadOnlyList<T>` with private backing fields — no external `Add`/`Remove`?

### Domain events

- Are significant business facts (OrderPlaced, PaymentProcessed, UserRegistered) modeled as domain events?
- Are domain events raised by the aggregate, not by application services?
- Are side effects (emails, notifications, projections) triggered by domain events — not inline in the command handler?
- Are domain events dispatched after `SaveChanges` (not before) to avoid raising events for failed transactions?

### Repository design

- Is there exactly one repository per aggregate root — not per entity?
- Does the repository interface live in the Domain or Application layer (not Infrastructure)?
- Does the repository only expose methods that the domain actually needs — not generic CRUD?
- Are read-side queries (reporting, listings) separated from the write-side repository?

### Ubiquitous language

- Do class names, method names, and properties reflect the language of the business domain?
- Are there technical names (`UserManager`, `DataProcessor`, `Helper`) where domain names should be?
- Are there generic verbs (`Update`, `Process`, `Handle`) where specific domain verbs should be (`Approve`, `Dispatch`, `Settle`)?

---

## Step 3 — Output format

```
## Análisis de dominio — [nombre del área o aggregate]

### Modelo actual
[Descripción de lo que encontraste: aggregates, entities, value objects, eventos — o ausencia de ellos]

### 🔴 Violaciones críticas de modelo
Problemas que dejan invariantes sin protección o mezclan responsabilidades fundamentalmente.

- **[clase:línea]** — [descripción]
  - *Consecuencia:* [qué regla de negocio puede violarse en producción]
  - *Corrección:* [diseño correcto con código si aplica]

### 🟡 Primitive obsession y oportunidades de Value Object
Conceptos del dominio expresados como primitivos que merecen su propio tipo.

- **`[tipo primitivo]` en `[clase]`** → debería ser `[nombre del Value Object]`
  - *Validaciones que encapsularía:* [lista]
  - *Comportamiento que ganaría:* [lista]

### 🔵 Mejoras de expresividad y lenguaje ubicuo
Nombres técnicos o genéricos que deberían reflejar el dominio.

- `[nombre actual]` → `[nombre propuesto]` — [por qué]

### Diseño propuesto
[Si el análisis es de diseño nuevo o requiere reestructuración significativa:
aggregate roots, value objects, domain events, y sus relaciones]

[Código de ejemplo para los casos más críticos: constructor con guard clauses,
método de dominio que enforce una invariante, value object con validación]

### Eventos de dominio identificados
[Hechos de negocio que deberían modelarse como eventos — si aplica]
| Evento | Cuándo se dispara | Efectos esperados |
|---|---|---|
| [NombreEvento] | [condición] | [lista de side effects] |

### Resumen de cambios recomendados
| Acción | Elemento | Prioridad |
|---|---|---|
| Crear Value Object | `Email` desde `string` en `User` | Alta |
| Mover invariante | validación de stock de `OrderService` a `Order.AddItem()` | Alta |
| ... | ... | ... |
```

---

## Output rules

- Show working code for every recommended Value Object or entity method — not just the concept
- Be precise about aggregate boundaries: "this should be a separate aggregate because X invariant is independent of Y"
- Do not push DDD patterns where a simple entity is enough — only recommend where the complexity justifies it
- If the project does not currently use DDD, frame recommendations as incremental steps, not a full rewrite
