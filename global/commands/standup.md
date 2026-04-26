# Generar resumen de standup

Genera un resumen del trabajo del día para el standup del equipo.

## Pasos

1. Ejecuta `git log --oneline --since="yesterday" --author="$(git config user.name)"` para ver commits propios
2. Ejecuta `git diff --stat HEAD~5..HEAD` si no hay commits recientes
3. Revisa si hay algún archivo abierto o cambio sin commitear con `git status`

## Formato de respuesta

**Ayer hice:**
- [lista de tareas completadas basada en commits]

**Hoy voy a hacer:**
- [infiere del trabajo en progreso o pregunta si no es claro]

**Bloqueos:**
- [menciona solo si hay ramas desactualizadas, conflictos, o PRs esperando review]

Sé breve. Máximo 5 bullets en total.
