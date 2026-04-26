# Estándares globales — [Empresa]

## Contexto
Soy desarrollador de [Empresa]. Stack principal: .NET 8+, C#.
Cada repo tiene su propio CLAUDE.md con reglas específicas del proyecto.

## Reglas universales de trabajo
- Conventional Commits siempre: feat/fix/chore/refactor/docs/test
- Nunca force push a main/master — pedir confirmación explícita
- Nunca commitear archivos .env, secrets ni connection strings
- Pedir confirmación antes de eliminar archivos o hacer cambios destructivos
- Proponer antes de implementar cuando el cambio afecte arquitectura

## Estilo de respuesta
- Conciso: no explicar lo que el código ya dice
- Sin resúmenes al final de cada respuesta
- Sin comentarios obvios en el código
- Preferir editar archivos existentes sobre crear nuevos

## Seguridad .NET
- Connection strings siempre desde IConfiguration / User Secrets / env vars
- Nunca loguear tokens, passwords, PII ni datos sensibles
- Usar ILogger<T>, nunca Console.WriteLine en producción
- Validar inputs en el borde del sistema (controllers/endpoints), no en servicios internos
