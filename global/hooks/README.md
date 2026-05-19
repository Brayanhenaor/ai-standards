# Hooks — ai-standards

Cuatro hooks automatizan validaciones durante el ciclo de Claude. Se instalan en `~/.claude/hooks/` y se registran en `~/.claude/settings.json`.

---

## Mapa de hooks

| Hook | Evento | Matcher | Propósito |
|------|--------|---------|-----------|
| `cs-dirty-flag.sh` | `PostToolUse` | `Write`, `Edit` | Marca turno como "modificó .cs" |
| `build-check.sh` | `Stop` | — | Compila si hubo cambios .cs este turno |
| `format-check.sh` | `Stop` | — | Verifica dotnet format si hubo cambios .cs |
| `test-runner.sh` | `PostToolUse` | `Write` | Ejecuta tests al guardar archivo de test |
| `migration-guard.sh` | `PreToolUse` | `Bash` | Bloquea operaciones EF destructivas |
| `secret-scan.sh` | `PreToolUse` | `Bash` | Bloquea git commit con secretos detectados |

---

## Detalle por hook

### `cs-dirty-flag.sh`

**Evento:** `PostToolUse` → `Write` y `Edit`

Crea un archivo temporal (`/tmp/claude-build-dirty`) cuando Claude escribe o edita un `.cs`. Es el mecanismo de señal para `build-check.sh` — sin este flag el build no se dispara.

**No produce output visible.**

```
.cs editado → flag creado → (al Stop) → build-check.sh lo lee y compila
```

---

### `build-check.sh`

**Evento:** `Stop` (al finalizar cada turno de Claude)

Lee el flag de `cs-dirty-flag.sh`. Si existe:
1. Busca el `.sln` o `.csproj` más cercano caminando hacia arriba desde `$PWD`
2. Ejecuta `dotnet build --no-restore -v quiet`
3. Si hay errores o warnings CS, los muestra con contexto de código (3 líneas arriba/abajo)
4. Elimina el flag

**Silent on success** — solo imprime cuando hay errores.

```
--- build errors ---
Build FAILED

/src/Api/Controllers/UsersController.cs(42,17): error CS0246
  ┌─ /src/Api/Controllers/UsersController.cs
  │  39 │  var result = await _service.GetAsync(id);
  │  40 │
  │→ 42 │  return Ok(unknownType);
  └─
---
```

---

### `test-runner.sh`

**Evento:** `PostToolUse` → `Write`

Se activa solo cuando el archivo escrito termina en `Tests.cs`, `Test.cs` o `Specs.cs`. Busca el `.csproj` de tests más cercano (que contenga "Test" o "Spec" en el nombre) y ejecuta `dotnet test --no-build`.

**Solo imprime si hay fallos** — ignorado en verde.

```
--- tests: MyProject.Tests ---
Failed   CreateAsync_WhenEmailExists_ThrowsConflict
passed 14, failed 1
---
```

---

### `migration-guard.sh`

**Evento:** `PreToolUse` → `Bash`

Intercepta cualquier comando Bash que coincida con:
```
ef database update
ef database drop
ef migrations remove
ef migrations reset
```

Bloquea el comando con exit code 2 (Claude no puede continuar) y muestra el estado actual de migraciones:

```
⛔  Operación destructiva de EF bloqueada

Comando interceptado:
  dotnet ef database update

Migraciones actuales:
  20240101_InitialCreate
  20240215_AddUsersTable
  20240301_AddIndexes

Ejecuta el comando manualmente si es tu intención.
```

**Propósito:** Evitar que Claude aplique migraciones automáticamente sin revisión humana. Las migraciones en producción siempre deben ser revisadas y ejecutadas manualmente.

---

---

### `format-check.sh`

**Evento:** `Stop`

Usa el mismo flag de `cs-dirty-flag.sh`. Si hubo cambios en `.cs` este turno, ejecuta `dotnet format --verify-no-changes`. **No modifica archivos** — solo reporta cuáles tienen problemas de formato.

**Silent on success.**

```
--- dotnet format: archivos con problemas de formato ---

  Formatted: src/Api/Controllers/UsersController.cs

Corregir con: dotnet format MyProject.sln
---
```

---

### `secret-scan.sh`

**Evento:** `PreToolUse` → `Bash`

Intercepta `git commit` y `git add`. Escanea los archivos staged buscando patrones de secretos:

- JWTs (`eyJ...`)
- AWS access/secret keys (`AKIA...`)
- RSA/EC private key headers
- Connection strings con password embebida
- Variables con nombres de secreto asignadas a string literals
- Slack webhooks, GitHub tokens

Bloquea el commit con exit code 2 si encuentra coincidencias.

```
🔴  Posibles secretos detectados en archivos staged

Patrones encontrados:
  • Password in connection string
    → Password=Admin123...
  • JWT token
    → eyJhbGciOiJI...

Acciones recomendadas:
  1. Elimina el secreto del archivo
  2. Agrega a User Secrets o variable de entorno
  3. Si es falso positivo: git commit --no-verify (bajo tu responsabilidad)
```

---

## Configuración en settings.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/build-check.sh\"" },
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/format-check.sh\"" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/cs-dirty-flag.sh\"" },
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/test-runner.sh\"" }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/cs-dirty-flag.sh\"" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/migration-guard.sh\"" },
          { "type": "command", "command": "bash \"$HOME/.claude/hooks/secret-scan.sh\"" }
        ]
      }
    ]
  }
}
```

---

## Diagnóstico

**Build nunca se dispara:**
- Verifica que `cs-dirty-flag.sh` esté registrado en `PostToolUse` para `Write` y `Edit`
- Verifica permisos: `ls -la ~/.claude/hooks/` → todos deben ser `rwxr-xr-x`

**migration-guard no intercepta:**
- Verifica que el comando use exactamente `ef database update` (no `dotnet ef database update` con path completo)
- El hook parsea stdin como JSON — requiere que Claude Code pase `CLAUDE_TOOL_INPUT`

**test-runner ejecuta en archivos que no son tests:**
- El filtro es por nombre de archivo: `*Tests.cs`, `*Test.cs`, `*Specs.cs`
- Si el archivo de test tiene otro naming, el hook no lo detectará
