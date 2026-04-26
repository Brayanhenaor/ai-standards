# Inicializar y adaptar estándares al proyecto

Ejecuta este análisis completo UNA SOLA VEZ. El objetivo es generar un CLAUDE.md que sea fiel tanto a los estándares base de la empresa como a la realidad de este proyecto específico.

---

## Fase 1 — Análisis de la solución

Explora el proyecto con profundidad antes de escribir nada.

### Estructura general
- Lee el `.sln` y todos los `.csproj` para entender los proyectos y sus dependencias
- Mapea la estructura de carpetas completa (ignora bin/, obj/, .git/, .vs/, node_modules/)
- Identifica cuántos proyectos hay y cuál es el rol de cada uno

### Stack y dependencias
- Extrae todos los `PackageReference` de cada `.csproj`
- Identifica las librerías clave: ORM, mensajería, logging, autenticación, mapeo, etc.
- Detecta la versión de .NET y C# de cada proyecto

### Arquitectura real
- Lee `Program.cs` / `Startup.cs` para entender el setup de DI y middlewares
- Analiza los namespaces para entender las capas reales del proyecto
- Lee 2-3 archivos representativos de cada capa (controllers, services, repositories, entities)
- Detecta los patrones usados: ¿hay CQRS? ¿Repository pattern? ¿Clean Architecture? ¿Capas simples?
- Identifica si hay `ApiResponse<T>` u otra clase base de respuesta
- Detecta cómo se manejan los errores: ¿middleware global? ¿try/catch por controller?

### Convenciones reales del código
- Analiza el naming real de archivos y clases (¿usan Request/Response? ¿Dto? ¿ViewModel?)
- Detecta cómo se nombran los métodos async (¿tienen sufijo Async?)
- Identifica si usan `var` o tipo explícito
- Detecta el estilo de inyección: ¿constructor? ¿`inject()`?
- Revisa si hay constantes organizadas en clases estáticas o strings literales sueltos

### Deuda técnica y desviaciones
- Identifica qué partes del proyecto NO siguen la arquitectura ideal
- Detecta antipatrones comunes: lógica de negocio en controllers, DBContext expuesto, etc.
- Nota qué está bien implementado y qué necesita refactoring eventual

---

## Fase 2 — Descargar el template base y adaptarlo

**Primero descarga el template completo — nunca generes el CLAUDE.md desde cero.**

```bash
curl -fsSL "https://raw.githubusercontent.com/Brayanhenaor/ai-standards/master/templates/dotnet/CLAUDE.md" -o CLAUDE.md
```

El proyecto solo tendrá este archivo. Las reglas detalladas (`docker.md`, `resilience.md`, `ef-advanced.md`, `testing.md`, `security.md`) ya están instaladas globalmente en `~/.claude/rules/` por el `npx` setup — no se necesitan en el proyecto.

Luego lee el archivo descargado y aplica las siguientes adaptaciones sobre él:

### Secciones que DEBES modificar
- **Título** (`# [NombreProyecto]`) → nombre real del proyecto
- **Stack** → versiones y paquetes reales detectados en los `.csproj`
- **Arquitectura** → describe LO QUE HAY realmente: capas reales, carpetas reales, patrones reales
- **Convenciones C#** → ajusta solo lo que el proyecto ya hace distinto (naming, var vs tipo explícito, etc.)

### Secciones que NO debes tocar
Todo lo demás se mantiene exactamente como está en el template:
- Manejo de errores, logging, seguridad, performance, resiliencia
- EF Core, Mapster, DTOs, testing, calidad de código
- Docker, documentación, lo que NO hacer

### Balance reglas base vs adaptación

| Sección | Qué hacer |
|---|---|
| Calidad, seguridad, performance | Mantener sin cambios — son no negociables |
| Arquitectura ideal | Adaptar: describir la arquitectura real + indicar hacia dónde evolucionar |
| Naming y convenciones | Adaptar al estilo real del proyecto para no generar inconsistencias |
| Patrones (CQRS, Repository, etc.) | Solo incluir los que el proyecto ya usa o tiene intención clara de adoptar |
| Deuda técnica detectada | Agregar sección `## Estado actual del proyecto` con hallazgos reales |

### Sección adicional obligatoria si hay deuda

Si detectas desviaciones significativas de los estándares, agrega esta sección al CLAUDE.md:

```markdown
## Estado actual del proyecto

### Lo que está bien
- [lista de buenas prácticas ya implementadas]

### Deuda técnica detectada
- [CRÍTICO] descripción — afecta correctitud o seguridad
- [MEJORA] descripción — violación de estándares, prioridad media
- [TÉCNICO] descripción — limpieza menor

### Dirección de evolución
- [qué refactors graduales se recomiendan y en qué orden]
```

---

## Fase 3 — Escribir y confirmar

1. Escribe el CLAUDE.md adaptado sobre el archivo descargado
2. Si hay deuda técnica significativa, agrega la sección `## Estado actual del proyecto` antes de `## Comandos disponibles`
3. Presenta al dev el siguiente resumen:

```
✅ Proyecto inicializado: [NombreProyecto]

Stack detectado:
  • .NET X / C# X
  • [tipo de proyecto]
  • [DB y ORM]
  • [paquetes clave]

Arquitectura detectada:
  • [descripción en 1-2 líneas de lo que encontraste]

[Si hay deuda]: ⚠️ Se detectaron N items de deuda técnica — ver sección "Estado actual" en CLAUDE.md

Comandos disponibles:
  /user:init-dotnet   — este comando (ya ejecutado)
  /user:plan-dotnet   — planea un requerimiento antes de implementar
  /user:review-dotnet — revisión completa de cambios antes de PR
  /user:commit-dotnet — genera mensaje de commit en Conventional Commits
  /user:test-dotnet   — genera unit tests de cambios pendientes o de un commit
  /user:docker-dotnet — revisa o genera configuración Docker/Compose
```
