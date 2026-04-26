# [NombreProyecto]

> Ejecuta `/user:init-dotnet` para adaptar este archivo al proyecto actual.

## Reglas de contexto

Reglas detalladas que se cargan automáticamente al trabajar en archivos específicos:

| Al tocar... | Se carga |
|---|---|
| `Dockerfile`, `docker-compose*.yml`, `.dockerignore` | `.claude/rules/docker.md` |
| `*Client.cs`, `*Gateway.cs`, `*Extensions.cs`, `Program.cs` | `.claude/rules/resilience.md` |
| `*Repository*.cs`, `*DbContext*.cs`, `Migrations/`, `*Configuration.cs` | `.claude/rules/ef-advanced.md` |

---

## Stack
- [.NET Version] / [C# Version]
- [ASP.NET Core Web API / Worker Service / Blazor] — [rol: principal / consumer / híbrido]
- Entity Framework Core + [SQL Server / PostgreSQL / SQLite / MongoDB]
- [Completar: MediatR, Serilog, etc.]
- Mapster (mapeo de objetos)

---

## Cómo aplicar estas reglas

Este documento define el estándar ideal. No todos los proyectos lo cumplen al 100% — muchos tienen deuda técnica, arquitectura inconsistente o patrones heredados.

**Regla general: no rompas lo que funciona para cumplir el estándar.**

### Al escribir código nuevo
Aplicar siempre los estándares de este documento, aunque el código existente alrededor no los siga.

### Al modificar código existente
- Aplicar los estándares en el código que tocas
- Si el contexto inmediato tiene problemas, incluir al final de tu respuesta una sección `⚠️ Sugerencias de refactor` con lo detectado
- No refactorizar fuera del alcance de la tarea — solo señalarlo

### Formato de advertencias
Cuando detectes algo que no cumple los estándares, reportarlo así al final de la respuesta:

```
⚠️ Sugerencias de refactor detectadas

[CRÍTICO] Descripción del problema — impacto en seguridad, correctitud o mantenibilidad
[MEJORA]  Descripción del problema — mejora recomendada pero no urgente
[TÉCNICO] Deuda técnica menor — para considerar en un sprint de refactor
```

- `[CRÍTICO]`: memory leak, captive dependency, lógica de negocio en controller, secrets hardcodeados
- `[MEJORA]`: violación de SOLID, código duplicado, método largo, falta de tests
- `[TÉCNICO]`: naming incorrecto, comentarios innecesarios, estructura de carpetas inconsistente

### Lo que nunca debes hacer
- No reescribir código funcional sin que el dev lo pida explícitamente
- No bloquear una tarea porque el proyecto no tiene la arquitectura ideal
- No aplicar el estándar de forma dogmática si rompe compatibilidad con el resto del proyecto

---

## Arquitectura

Clean Architecture. Proyectos de la solución:

| Proyecto | Responsabilidad |
|---|---|
| `Domain/` | Entidades, value objects, domain events, enums de dominio |
| `Application/` | Commands, queries, DTOs, interfaces de repositorios y servicios, validators |
| `Infrastructure/` | EF Core, repositorios, servicios externos, migraciones, integraciones |
| `API/` | Controllers, filtros, mapeos de request/response |
| `Host/` | Program.cs vía extension methods, middlewares, configuración de DI |
| `Shared/` | (Opcional) Constantes, helpers, extensiones transversales |

**Reglas de dependencia:**
- Dirección: `API` → `Application` → `Domain` ← `Infrastructure`
- Cualquier proyecto puede referenciar `Shared`
- `API` usa `Host` para configuración
- `Domain` no referencia ningún otro proyecto de la solución

**Reglas de diseño:**
- Lógica de negocio SOLO en `Domain` y `Application`, nunca en controllers ni infraestructura
- **CQRS con MediatR**: solo si el proyecto lo requiere explícitamente — no forzarlo
  - Si aplica: un command/query y su handler en el mismo archivo
  - Si no aplica: el controller llama directamente a un service de `Application/` mediante su interfaz
- Siempre aplicar principios SOLID; si viola uno, explicar el trade-off
- Siempre usar DI, nunca instanciar servicios con `new`
- Aplicar patrones de diseño cuando aporten valor real (Factory, Builder, Specification, etc.) — nunca por convención
- Responsabilidades claramente separadas; si un método hace más de una cosa, separarlo
- Todo el código en inglés
- Sin comentarios obvios; usar `/// <summary>` solo cuando el comportamiento no es inferible del nombre

**Antes de implementar cualquier cosa:**
- Evalúa el estado real del proyecto — si no sigue Clean Architecture, adapta la solución a lo que existe
- Haz las preguntas necesarias para tener contexto completo
- Propón al menos dos opciones con sus trade-offs (complejidad, mantenibilidad, performance, testabilidad)
- Toda decisión de arquitectura o diseño relevante → ADR en `/docs/adr/`
- Si la mejor solución implica refactorizar algo fuera del alcance, mencionarlo como `[MEJORA]` sin hacerlo

---

## Controllers

- Thin controllers: solo reciben request, llaman Application, retornan response
- Siempre retornan `ApiResponse<T>` (con campos: `Success`, `Result`, `Message`)
- Rutas en PascalCase iniciando con `/api` — ej: `/api/Users/{id}`
- Documentar todos los posibles códigos de respuesta para Swagger con `[ProducesResponseType]`
- Versioning de API cuando hay breaking changes — nunca modificar un endpoint existente sin versionar

---

## Manejo de errores

- Exception handler global en middleware — nunca `try/catch` en controllers
- Excepciones de dominio/aplicación heredan de una base y declaran explícitamente su código HTTP
- `Result<T>` para errores esperados y flujos alternativos — nunca usar exceptions para control de flujo
- Errores de validación → 400 con detalle de campos
- Errores de negocio → código HTTP explícito en la excepción personalizada
- Errores inesperados → 500 logueado con correlationId, sin exponer stack trace al cliente

---

## Convenciones C#

- `PascalCase`: clases, métodos, propiedades, eventos, constantes
- Constantes en clases estáticas agrupadas por dominio (`ErrorCodes`, `PolicyNames`, `RouteConstants`, etc.) — nunca strings literales dispersos en el código
- Única excepción permitida: mensajes de log (pueden ser strings literales inline)
- `camelCase`: parámetros, variables locales, campos privados
- `I` prefix: interfaces (`IUserRepository`)
- `Async` suffix: todo método async (`GetUserAsync`)
- Records para DTOs y value objects inmutables
- Preferir tipo explícito sobre `var`; usar `var` solo cuando el tipo es evidente por el lado derecho
- Siempre `async/await` para I/O — nunca `.Result`, `.Wait()` ni `.GetAwaiter().GetResult()`
- Usar `CancellationToken` en todos los métodos async que hagan I/O o llamen a servicios externos
- Preferir `IReadOnlyList<T>` / `IEnumerable<T>` sobre `List<T>` en firmas públicas
- Expresiones `switch` sobre `if/else if` encadenados para múltiples casos
- Usar `is null` / `is not null` en lugar de `== null` / `!= null`
- Habilitar `<Nullable>enable</Nullable>` en todos los proyectos
- No suprimir nullable warnings con `!` sin un comentario que explique por qué es seguro
- Nunca retornar `null` desde un servicio para indicar "no encontrado" — usar `Result<T>` o lanzar excepción
- Para colecciones: retornar siempre colección vacía, nunca `null`

---

## Mapeo de objetos (Mapster)

- Usar Mapster para todo mapeo entre capas — nunca mapeo manual salvo casos muy simples
- Configuraciones de mapeo en clases `XMappingConfig` que implementan `IRegister`, ubicadas en `Application/`
- Registrar todos los `IRegister` automáticamente al iniciar: `TypeAdapterConfig.GlobalSettings.Scan(assembly)`
- Inyectar `IMapper` via DI — no usar `TypeAdapter.Adapt<T>()` estático en servicios
- Mapeos permitidos: `Entity → XResponse`, `XRequest → Entity`, `XRequest → Command/Query`
- Nunca mapear directamente `Entity → Entity` para actualizaciones — asignar propiedades explícitamente para que la intención sea clara
- Si un mapeo requiere lógica (calcular campos, resolvers), documentarlo en el `IRegister` con un comentario técnico

---

## DTOs y Validaciones

- DTOs se nombran `XRequest` (entrada) y `XResponse` (salida) — sin sufijo genérico "Dto"
- Validaciones con DataAnnotations directamente en los `XRequest`
- Activar validación automática del modelo con el filtro de validación de ASP.NET Core — no validar manualmente en controllers ni services
- No duplicar validaciones: si EF tiene una constraint, no replicarla en DataAnnotations a menos que el error de DB sea inaceptable como respuesta al cliente

---

## Entity Framework Core

- Configuración de entidades con `IEntityTypeConfiguration<T>` en `Infrastructure/` — nunca data annotations en Domain
- Queries de lectura: siempre `.AsNoTracking()` salvo que se vaya a modificar
- Proyectar con `.Select()` en queries de lectura — nunca cargar entidad completa para leer 2 campos
- Evitar N+1: usar `.Include()` solo cuando sea necesario y con criterio; preferir joins explícitos en queries complejas
- Paginación obligatoria en endpoints que devuelven colecciones — no exponer endpoints sin límite
- Nunca exponer `DbContext` fuera de `Infrastructure/`
- Migrations con nombre descriptivo: `AddOrderAuditFields`, no `Migration20240101`
- No modificar migrations ya aplicadas en producción — siempre crear una nueva

---

## Logging

- Usar `ILogger<T>` en todos los servicios — nunca `Console.WriteLine`
- Logging estructurado con Serilog; siempre incluir propiedades relevantes como contexto
- Niveles:
  - `Debug`: flujo interno, valores intermedios (solo desarrollo)
  - `Information`: eventos de negocio relevantes (request recibido, proceso completado)
  - `Warning`: situación inesperada pero recuperable
  - `Error`: fallo que impacta al usuario, siempre con excepción si aplica
- Nunca loguear: passwords, tokens, tarjetas, PII, connection strings
- Incluir `correlationId` en todos los logs para trazabilidad
- Enriquecer con: environment, version, userId (cuando aplique)

---

## Configuración (Options pattern)

- Leer configuración en servicios con `IOptions<T>`, `IOptionsSnapshot<T>` o `IOptionsMonitor<T>` — nunca `IConfiguration` fuera de `Host/`
- Una clase de opciones por sección (`SmtpOptions`, `JwtOptions`, etc.) con `.ValidateDataAnnotations().ValidateOnStart()`

---

## Ciclo de vida de dependencias

Registrar cada servicio con el lifetime correcto — los bugs por lifetime incorrecto son silenciosos y difíciles de detectar:

| Lifetime | Cuándo usarlo |
|---|---|
| `Singleton` | Sin estado mutable, thread-safe, costoso de crear (`IHttpClientFactory`, caches, configuración) |
| `Scoped` | Una instancia por request HTTP (`DbContext`, repositorios, servicios de negocio) |
| `Transient` | Liviano, sin estado, barato de crear |

**Reglas críticas:**
- Nunca inyectar un servicio `Scoped` en un `Singleton` — captive dependency, causa bugs en concurrencia
- Nunca inyectar un `DbContext` directamente en un `Singleton` — usar `IServiceScopeFactory` para crear un scope explícito
- Los `IDisposable` registrados como `Transient` en un `Singleton` nunca se liberan — evitarlo
- Si un `Singleton` necesita un servicio `Scoped`, inyectar `IServiceScopeFactory` y crear el scope manualmente

---

## Seguridad

- Connection strings exclusivamente desde `IConfiguration` (User Secrets en dev, env vars / secrets manager en prod)
- Nunca hardcodear credenciales, tokens ni URLs de servicios internos
- Autorización con políticas (`[Authorize(Policy = "...")]`) — nunca lógica de roles en controllers
- Validar y sanitizar toda entrada en el borde del sistema (controllers/endpoints)
- No exponer IDs internos de base de datos en APIs públicas — usar GUIDs o IDs ofuscados
- HTTPS obligatorio; no aceptar HTTP en producción

---

## Performance y gestión de recursos

- Nunca `new HttpClient()` — siempre `IHttpClientFactory` para evitar socket exhaustion
- `IDisposable` / `IAsyncDisposable` en clases con recursos no administrados; siempre con `using` / `await using`
- `async void` solo en event handlers — en cualquier otro caso `async Task`
- No capturar `this` en closures de larga vida sin desuscribirse — memory leak clásico
- `StringBuilder` en loops — nunca `string +=` dentro de iteraciones
- `IAsyncEnumerable<T>` para streaming de grandes volúmenes — nunca `.ToList()` de miles de registros
- Operaciones bulk con `ExecuteUpdateAsync` / `ExecuteDeleteAsync` — nunca cargar entidades solo para modificarlas masivamente

---

## Resiliencia

Toda llamada a servicio externo (HTTP, colas, terceros) necesita timeout + retry con backoff + circuit breaker, configurados via `IHttpClientFactory` con `AddResilienceHandler` — nunca inline en cada llamada. No reintentar 4xx.

---

## Testing

- Librerías: xUnit + FluentAssertions + NSubstitute
- Proyectos: `[Nombre].Tests.Unit` y `[Nombre].Tests.Integration`
- Naming: `MethodName_Scenario_ExpectedResult`
- Patrón AAA obligatorio con secciones `// Arrange`, `// Act`, `// Assert` explícitas
- Testear comportamiento observable, no implementación interna
- Cada test independiente: sin estado compartido, sin dependencia de orden
- Integration tests: `WebApplicationFactory` para endpoints, Testcontainers o SQLite in-memory para repositorios

Usa `/user:test-dotnet` para generar tests de cambios pendientes o de un commit específico.

---

## Calidad de código y patrones

### Guard clauses

- Retornar o lanzar temprano para casos inválidos — nunca anidar la lógica principal dentro de `if`
- El happy path debe ser el flujo principal, sin indentación excesiva

```csharp
// MAL
if (user != null) {
    if (user.IsActive) {
        // lógica principal...
    }
}

// BIEN
if (user is null) throw new NotFoundException();
if (!user.IsActive) throw new BusinessException("User is inactive");
// lógica principal...
```

### Modelo de dominio rico

- Las entidades tienen comportamiento, no son solo bolsas de propiedades
- La lógica que pertenece a una entidad va como método en esa entidad, no en un service
- Usar Value Objects para conceptos del dominio con identidad por valor (`Email`, `Money`, `Address`)
- Evitar primitive obsession: un `string email` suelto es peor que un `Email` value object con su propia validación
- Domain events para efectos secundarios desacoplados — no llamar servicios directamente desde la entidad

### Composición sobre herencia

- Preferir interfaces + composición sobre jerarquías de herencia profundas
- Máximo 2 niveles de herencia; si necesitas más, replantear el diseño
- Decorators para comportamiento transversal (logging, caching, retry) — no heredar para agregar comportamiento

### Detección de code smells

Al revisar o escribir código, identificar y proponer solución para:
- **Método largo** (> 20 líneas): extraer métodos privados con nombre descriptivo
- **Lista larga de parámetros** (> 3): agrupar en un objeto de parámetros o usar Builder
- **Clase grande** (> 300 líneas): evaluar si tiene más de una responsabilidad (SRP)
- **Feature envy**: método que usa más datos de otra clase que de la propia → mover el método
- **Números mágicos**: cualquier número literal que no sea 0 o 1 → constante nombrada

---

## Lo que NO hacer

- No strings literales hardcodeados en el código — usar constantes; excepción: mensajes de log
- No `dynamic`, no `object` como tipo de retorno o parámetro
- No `.Result` / `.Wait()` / `.GetAwaiter().GetResult()` en código async
- No `catch (Exception)` genérico sin re-throw o logging estructurado
- No lógica de negocio en controllers, middlewares ni infrastructure
- No exponer `DbContext` fuera de `Infrastructure/`
- No retornar entidades de EF directamente desde la API — siempre DTOs/records
- No servicios estáticos con estado mutable
- No agregar paquetes NuGet sin discutir primero y evaluar mantenimiento y licencia
- No omitir `CancellationToken` en métodos async que hagan I/O
- No agregar un nuevo `case` a un `switch` existente sin evaluar si corresponde extraer un patrón

---

## Documentación técnica

### README.md
El README es la puerta de entrada al proyecto — debe estar siempre actualizado. Estructura mínima obligatoria:

```
# Nombre del proyecto
Descripción breve de qué hace y para qué existe.

## Arquitectura
Diagrama o descripción de los componentes principales y cómo se relacionan.

## Requisitos
Versiones de .NET, herramientas, servicios externos necesarios.

## Configuración
Tabla de todas las variables de entorno / secciones de appsettings con:
- Nombre de la variable
- Descripción
- Valor de ejemplo
- Si es obligatoria u opcional

## Cómo correr el proyecto
Pasos para levantar localmente (con y sin Docker si aplica).

## Cómo correr los tests
Comandos exactos para unit e integration tests.

## Despliegue
Proceso de despliegue por ambiente (dev / staging / prod).
```

**Regla**: si haces un cambio que afecta configuración, variables de entorno, endpoints o proceso de despliegue → actualizar el README en el mismo PR, no después.

### ADRs
- Ubicación: `/docs/adr/`
- Formato de nombre: `NNNN-titulo-en-kebab-case.md`
- Contenido: contexto, opciones consideradas, decisión tomada, consecuencias

### Código
- `/// <summary>` en métodos públicos no obvios, interfaces y value objects

---

## Comandos disponibles
- `/user:init-dotnet`    — configuración inicial del proyecto (ejecutar una sola vez)
- `/user:plan-dotnet`    — planea un requerimiento con trade-offs antes de implementar
- `/user:review-dotnet`  — revisión completa de todos los cambios del branch
- `/user:commit-dotnet`  — genera mensaje de commit en Conventional Commits
- `/user:test-dotnet`    — genera unit tests de cambios pendientes o de un commit
- `/user:docker-dotnet`  — revisa o genera configuración Docker/Compose
