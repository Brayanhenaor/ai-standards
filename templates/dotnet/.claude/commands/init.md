# Inicializar proyecto

Este es el comando de configuración inicial. Ejecútalo una sola vez después de instalar ai-standards.

## Pasos

1. Lee el archivo `CLAUDE.md` en la raíz del proyecto
2. Lee todos los archivos `.csproj` del proyecto
3. Analiza la estructura de carpetas (ignora bin/, obj/, .git/, .vs/)
4. Lee `Program.cs` y `appsettings.json` si existen
5. Reemplaza TODOS los placeholders `[entre corchetes]` en `CLAUDE.md` con los valores reales detectados
6. Elimina el bloque `<!--INIT ... ENDINIT-->` del `CLAUDE.md`
7. Guarda el `CLAUDE.md` actualizado

Al terminar, presenta este resumen al dev:

```
✅ Proyecto configurado: [NombreProyecto]

Stack detectado:
  • [tecnología, versión, DB, etc.]

Comandos disponibles:
  /project:init               — este comando (solo primera vez)
  /project:plan-implementation — planea un requerimiento antes de implementar
  /project:review             — revisión completa de cambios antes de PR
  /project:commit-message     — genera mensaje de commit en Conventional Commits
  /project:pr                 — genera descripción de PR
  /project:task               — desglosa una tarea en pasos técnicos
  /project:fix                — debugging sistemático
```
