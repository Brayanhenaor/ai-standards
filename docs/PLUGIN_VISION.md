# Visión del plugin — ai-standards

> Documento de especificación. Fuente de verdad de la reestructuración del repo `ai-standards`
> hacia un plugin profesional de Claude Code. Desde aquí se ejecutan las fases.

---

## Objetivo

Reestructurar el repo `ai-standards` y convertirlo en un **plugin profesional de Claude Code
instalable vía `/plugin`** (repo = plugin + su propio marketplace, como Superpowers o Ponytail),
usando la arquitectura nativa y actual de plugins:

- `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`
- `skills/<n>/SKILL.md`, `agents/*.md`, `commands/*.md`, `hooks/hooks.json`

Debe aprovechar **todo el arsenal de capacidades que un plugin de Claude Code puede ofrecer** para
alcanzar el mejor resultado —skills, comandos, subagentes, hooks, manifest, marketplace,
configuración de usuario y demás piezas del ecosistema de plugins— usando en cada caso las que
aporten valor real, sin incluir ninguna por el solo hecho de que exista.

## Posicionamiento

Aunque nació para la empresa, en el fondo son **reglas de código limpio que sirven a cualquiera**.
Se diseña como herramienta **universal de clean code** que cualquiera pueda instalar, no atada a una
empresa. Lo específico de empresa (idioma de respuestas, plantillas oficiales de documentación,
convenciones internas) se modela como **capa de configuración opcional** (`userConfig` del manifest
/ overlay activable), nunca hardcodeado en el núcleo. Por defecto el plugin es genérico; la empresa
es un perfil más.

## Misión

Lograr que cualquier dev escriba **el código más limpio y con las mejores prácticas posibles**, en
cualquier lenguaje, de forma inteligente: cuestionando al dev, cuestionándose a sí mismo y
verificando, sin caer en sobreingeniería ni añadir código que no aporta valor.

---

## Jerarquía de principios

El corazón del plugin. Resuelve los conflictos entre reglas. Se aplica en este orden cuando entran
en tensión:

1. **Correctness y seguridad** — innegociables. Seguridad, accesibilidad y prevención de pérdida de
   datos nunca se sacrifican por simplicidad.

2. **Código limpio prima sobre la brevedad superficial.** "Simple" **no** es "menos líneas/clases".
   *Ejemplo ilustrativo, no la definición:* el god-method es lo más fácil de escribir pero no es
   limpio; el código limpio separa responsabilidades, nombra bien, inyecta dependencias y baja
   acoplamiento. Pero eso es **solo una muestra** de un cuerpo mucho más amplio (ver
   "Universo del clean code"). Esto es el estándar, no opcional.

3. **Evitar la sobreingeniería** — el error del lado opuesto. No añadir estructura, indirección,
   abstracción ni código que no aporte **valor presente y real**: nada de generalidad especulativa,
   abstracción prematura, ni DRY sobre similitudes casuales (rule of three). YAGNI.

4. **Criterio que decide siempre:** ¿esta estructura/abstracción se gana su lugar con valor real
   *hoy*? Sí → es clean code, va. "Por si algún día" → es sobreingeniería, fuera. El plugin debe
   evitar **ambos** fallos: el poco-estructurado (god-method/god-class) y el sobre-estructurado
   (framework especulativo).

---

## Universo del clean code

El plugin debe encarnar el **cuerpo completo del conocimiento de código limpio** y aplicarlo según
lenguaje y contexto, siempre bajo la jerarquía (limpio sí; sobreingeniería no). Dominios
principales — **mapa ilustrativo, no exhaustivo; guía, no dogma de números rígidos**:

- **SOLID completo** (no solo SRP/DI)
- **Diseño de funciones/métodos** — tamaño, nº de parámetros, un solo nivel de abstracción, efectos colaterales
- **Naming** en todos los niveles (variables, funciones, tipos, módulos, archivos)
- **Cohesión y acoplamiento** — alta cohesión, bajo acoplamiento, ley de Demeter
- **Niveles de abstracción consistentes** — no mezclar alto y bajo nivel
- **Code smells** — duplicación, primitive obsession, feature envy, long parameter list, large class, shotgun surgery…
- **Manejo de errores limpio** — sin control de flujo por excepciones, fronteras claras, resultados explícitos
- **Estado e inmutabilidad** — minimizar estado mutable y compartido
- **Encapsulamiento y fronteras** — ocultar detalles, contratos claros entre capas
- **Patrones de diseño con criterio** — solo cuando aportan valor real, nunca por convención
- **Testabilidad** — diseño que permite probar sin acrobacias
- **Comentarios/documentación en código** — explican el *porqué*, no el *qué*
- **+ específicos por lenguaje/framework** encima de lo anterior (.NET hoy; otros como packs)

Aplicar como criterio experto, no como checklist mecánico; toda decisión sigue sujeta a
"¿se gana su lugar con valor real hoy?".

---

## Principios transversales (toda skill/agente)

- **Inteligencia, no complacencia:** cuestionar al dev — desafiar supuestos, exponer trade-offs,
  señalar riesgos y pedir contexto cuando falte, en vez de ejecutar a ciegas.
- **Auto-cuestionamiento:** cada skill/agente revisa críticamente su propia salida (auto-review
  adversarial) antes de entregarla.
- **Verificación con dientes:** antes de declarar "listo", probar que funciona — correr build/tests,
  verificar comportamiento real. No basta con opinar.
- **DRY / reutilización:** priorizar reutilizar lo existente y evitar duplicación; detectar y señalar
  duplicación antes de crear algo nuevo (sujeto a la jerarquía: no aplicar DRY sobre similitudes casuales).
- **Adaptarse al proyecto, no imponer:** detectar las convenciones reales del repo y respetarlas;
  aplicar el estándar al código que se toca, señalar (no romper) lo que ya funciona.

---

## Estilo de salida (comunicación)

Cómo debe comunicar el plugin, en cualquier skill o agente:

- **Claro, conciso y preciso** — información exacta, no genérica. Cero "labia", relleno ni rodeos.
- **No deja espacio a dudas** — si menciona un concepto poco común o técnico, lo explica en una
  línea ahí mismo, sin asumir que el dev lo conoce.
- **Pregunta antes de asumir** — hace todas las preguntas necesarias para no asumir información ni
  alucinar. Si falta contexto, lo pide en lugar de inventar.
- **Sin resúmenes de relleno** — no cierra cada respuesta repitiendo lo ya dicho.

---

## Clean code agnóstico + profundidad por stack

Los principios son transversales a cualquier lenguaje. Mantener **backend .NET con la profundidad de
hoy** (concurrency, performance, EF, messaging, security…), activando la guía correcta según el
lenguaje/contexto como "packs" condicionales, con fallback genérico. Incluir **frontend**:
componentes reutilizables, prevención de duplicación de UI/lógica, composición sobre repetición.

## Descubrimiento de skills

Con 30+ skills, incluir un mecanismo de índice/dispatch (meta-skill estilo Superpowers) para que el
modelo encuentre y active la skill correcta sin ruido.

## Workflows inteligentes (estilo Superpowers)

brainstorm → plan → implement → verify, con subagentes y revisión contra el plan antes de dar algo
por terminado.

## Comportamiento dual

Automático (auto-invocación por `description`) **y** manual (el dev pide explícitamente plan, ADR,
etc.). Acciones sensibles/destructivas → `disable-model-invocation` (solo manual).

## Capacidad: auditoría / review

Capacidad de primer nivel (hereda del comando `review` actual, reconstruida). Audita el código
contra **todo el ruleset del plugin** — núcleo universal de clean code + anti-sobreingeniería + el
pack de stack activo (.NET hoy):

- **Dos alcances:** `--diff` (cambios actuales / staged) y `--full` (proyecto completo).
- **Entrada:** skill manual `/supercode:review`; también auto-invocable al detectar intención de auditar.
- **Motor:** subagente `code-reviewer` (trabajo profundo y aislado).
- **Salida:** hallazgos reales (no nitpicks) por severidad `[CRITICAL] / [IMPROVEMENT] / [TECHNICAL]`,
  con `archivo:línea`, el porqué y la corrección sugerida. Cuestiona, no complace; se auto-revisa
  antes de entregar.
- **Dependencia:** consume `clean-code-core`; se construye en F2, justo después del núcleo.

## Documentación congelada (no negociable)

Las skills de **ADR, changelog, documentación técnica/manual** preservan **exactamente** la
estructura/plantilla actual (formato oficial de la empresa). Migrar literal; no rediseñar. En el
plugin universal viven como perfil/plantilla configurable.

## Estándares base

Conventional Commits; código/identificadores/commits/contenido del plugin **en inglés**; nunca
commitear secretos; confirmar antes de borrar o cambios destructivos; proponer antes de tocar
arquitectura o contratos compartidos. **Idioma adaptativo:** la IA responde en el idioma en que le
escribe el dev (ver decisión 6).

## Calidad de producto (es un plugin público)

README/CONTRIBUTING/LICENSE, semver, `claude plugin validate` en CI, **progressive disclosure** en
skills (SKILL.md corto + `reference.md` bajo demanda para ahorrar tokens) y **ruta de migración**
para los usuarios actuales del `npx`.

## Dogfooding

El plugin ejemplifica lo que predica: sin sobreingeniería, sin dependencias ni duplicación
innecesarias, estructura mínima y profesional.

## Fuera de alcance por ahora (resistir hasta tener uso real)

Benchmarks tipo Ponytail, MCP servers propios, soporte profundo de muchos lenguajes desde el día 1,
themes/output-styles. Arrancar con **.NET profundo + núcleo universal + fallback genérico** y crecer
según demanda.

---

## Decisiones tomadas

1. **Solo Claude Code** — se elimina el soporte Cursor.
2. **Versionado semver explícito** en `plugin.json`.
3. **Nombre del plugin: `supercode`** → namespace `/supercode:<skill>`.
4. **Repo único** = plugin + su propio marketplace (`.claude-plugin/plugin.json` + `marketplace.json`).
5. **Rama nueva + migración por fases con aprobación** (F0 → F1 → … una a una).
6. **Idioma adaptativo:** todo el contenido producido (código, identificadores, commits, el propio
   plugin) se escribe **en inglés**; la IA **detecta el idioma del dev y responde en ese idioma**.
   No hay perfil de idioma fijo. Los documentos generados (ADR, changelog) por defecto siguen el
   idioma del dev (configurable a inglés fijo).

## Filosofía de migración: reconstruir, no portar

Lo actual (12 reglas + 30 comandos) es **base e inspiración, no camisa de fuerza**. Cada pieza se
**rehace al mejor estándar posible**, no se copia 1:1. Lo que no esté bien hecho se descarta o se
rediseña. La auditoría de reglas alimenta esta reconstrucción.

## Entregable de la primera fase (no implementar aún)

1. **Auditoría** de las 12 reglas base (`global/rules/`) vs mejores estándares vigentes, con propuestas.
2. **Árbol de archivos objetivo** del plugin con el rol de cada pieza.
3. **Inventario de migración** de los 30 comandos actuales → skills/agents/commands (qué se fusiona,
   elimina, crea), separando **núcleo universal / packs por stack / perfil de empresa**.
4. **Plan de migración por fases.**

Tras aprobación, ejecutar sobre una rama nueva.

---

## Estado de implementación

Construido en `feat/supercode-plugin` (F0–F5 completas), 25 skills + 2 agentes + 1 hook, validado con
`claude plugin validate` en cada paso.

**Ajustes de implementación (vs el plan original):**
- **Mecanismo de packs:** en vez de carpetas `packs/`/`profiles/` con rutas cableadas en el manifest,
  todo vive bajo `skills/` (que se escanea solo) — el pack `.NET` es el skill `dotnet` con su
  `reference/`; el perfil de empresa son los skills `adr`/`changelog`/`tech-doc`. Más simple, sin
  configuración extra (anti-sobreingeniería aplicada al propio plugin).
- **Dispatcher:** diferido — con descriptions claras la auto-invocación nativa alcanza.
- **`start`:** cubierto por `plan` + `scaffold`, no se creó skill aparte.
- **Diferidos a futuro perfil de empresa / pack frontend (vendor-specific):** `grafana`, `infisical`,
  `ui-ux-promax`. Se añadirán cuando haya demanda real.
- **Hooks:** solo `secret-scan` (universal). build/test/format los cubre `verify` por contexto, no un
  hook global que correría `dotnet`/`npm` a ciegas.

**Pendiente de confirmación:** baja de la estructura vieja (`global/`, `bin/`, `templates/`,
`package.json`) que el plugin reemplaza.

## Referencias de arquitectura

- Plugins: https://code.claude.com/docs/en/plugins
- Plugins reference: https://code.claude.com/docs/en/plugins-reference
- Marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Skills: https://code.claude.com/docs/en/skills
- Subagents: https://code.claude.com/docs/en/sub-agents
- Hooks: https://code.claude.com/docs/en/hooks
- Superpowers (workflow + skill dispatch): https://claude.com/plugins/superpowers
- Ponytail (anti-sobreingeniería): https://github.com/DietrichGebert/ponytail
