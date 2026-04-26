# Generar descripción de PR

Genera la descripción del PR para los cambios actuales.

Ejecuta `git diff main...HEAD --stat` y `git log main...HEAD --oneline` para entender el alcance.

Usa este formato exacto:

---

## ¿Qué hace este PR?
[1-3 bullets concisos]

## ¿Por qué?
[Motivación, ticket relacionado, o decisión de diseño]

## Cambios principales
[Lista de archivos o componentes clave modificados con su propósito]

## Testing
- [ ] Tests unitarios pasan
- [ ] Probado localmente
- [ ] [Casos de prueba específicos al cambio]

## Notas para el reviewer
[Decisiones de diseño, trade-offs, o cosas que el reviewer debe saber]

---

No inventes información. Si algo no está claro en el diff, déjalo como [COMPLETAR].
