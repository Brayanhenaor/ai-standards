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

## Fase 2 — Generar el CLAUDE.md adaptado

Con todo el análisis completo, genera un CLAUDE.md que:

1. **Mantiene las reglas base** — los estándares de calidad, seguridad, testing y patrones del template base no se negocian
2. **Refleja la realidad del proyecto** — la sección de arquitectura describe LO QUE HAY, no lo ideal
3. **Es honesto sobre las desviaciones** — si el proyecto no usa Clean Architecture, dice qué arquitectura usa y cómo trabajar dentro de ella
4. **Adapta las convenciones** — usa el naming y los patrones que el proyecto ya tiene (no introduce inconsistencias)
5. **Incluye el contexto específico** — stack real, nombre real, tipo de proyecto real

### Estructura del CLAUDE.md generado

El archivo debe tener estas secciones adaptadas al proyecto:

- **Stack** — versiones y paquetes reales detectados
- **Arquitectura** — descripción de la arquitectura REAL con sus capas/carpetas reales
- **Cómo aplicar estas reglas** — adaptado: qué partes del proyecto están bien, cuáles tienen deuda
- **Convenciones C#** — ajustadas a lo que el proyecto ya usa
- **[Resto de secciones del template]** — mantenidas con ajustes menores si aplica

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

1. Escribe el CLAUDE.md completo y adaptado en la raíz del proyecto
2. Elimina el bloque `<!--INIT ... ENDINIT-->` del archivo
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
  /user:init-btw             — este comando (ya ejecutado)
  /user:plan-implementation  — planea un requerimiento antes de implementar
  /user:review               — revisión completa de cambios antes de PR
  /user:commit-message       — genera mensaje de commit en Conventional Commits
```
