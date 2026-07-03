# Pre-PR — severity rubric & verdict mapping

The verdict must be a **function of the findings**, not of mood. Same diff → same verdict. That
requires two things: severity assigned by **impact** (not by category), and a **deterministic**
map from the highest severity to the verdict.

## Severity — assigned by impact

| Severity | Meaning |
|---|---|
| **Critical** | Breaks correctness, security, or data safety; an uncontrolled breaking change; a red build or failing tests. Must fix before the PR. |
| **High** | A real defect with a realistic precondition; a serious risk that isn't certain to fire. Includes a missing regression test for a bugfix and new public behavior with no test. |
| **Medium** | Clear debt worth fixing: SOLID violation with real cost, duplication, over-long method, missing secondary coverage. |
| **Low** | Minor, local. |
| **Suggestion** | Optional; a justifiable improvement, not a defect. |

**"A High that will break production" does not exist as a category** — if it will break, it *is*
Critical. Keeping severity impact-based is what makes the mapping below a pure function.

## Verdict — deterministic mapping

Look at the **highest** severity present:

- Any **Critical** → **❌ Not ready for the PR.**
- No Critical, any **High** → **⚠️ Ready for the PR, with risks** (the risks must be acknowledged).
- Only **Medium / Low / Suggestion** → **✅ Ready for the PR.**

State the reason in one or two lines, tied to the specific blockers.

## Finding format — tiered verbosity

Spend words in proportion to severity. Don't wrap a one-line nit in a seven-field template.

```
[CRITICAL] · <category> · path:line
  What:  <the problem, concretely>
  Why it matters: <the rule it breaks + the real risk, in one idea>
  Fix:   <the concrete change>          (Effort: quick-fix | needs-design)   ← optional

[HIGH] — same shape as Critical.

[MEDIUM] path:line — <problem> · <why> · <fix in one line>

[LOW] path:line — <one line>
[SUGGESTION] path:line — <one line>
```

**Cap the noise.** Show at most **5** Low/Suggestion findings; collapse the rest into a single line:
`+N minor items (naming/local structure) — not shown`. The report is evidence for a PR, not a lint
dump.

There is **no separate "priority" field** — severity already implies it. The only optional extra axis
is **Effort** (`quick-fix` / `needs-design`), and only on Critical/High where it helps planning.

## Adversarial self-review — before anything is reported

Re-read each finding and drop it unless all hold:

1. It is **in the PR diff** (not untouched/legacy code).
2. It is **justified against a named rule** — not a personal style preference.
3. For **Critical/High**: its reachability/impact is **proven**, not assumed.

A false alarm erodes trust in the whole report. When unsure, cut it.

## ADR recommendation — reuse the `adr` skill's criteria

Emit exactly one:

- **❗ ADR required before the PR** — the change makes an architectural decision with lasting,
  cross-cutting impact and **no ADR records it**: a new external integration, a new
  persistence/messaging pattern, a public-contract change, swapping a core library/framework, or a
  change to the security model.
- **⚠️ ADR recommended** — a significant but reversible / borderline decision.
- **✅ No ADR needed** — a local change with no architectural decision.

Always justify the choice in one line. Do not invent ADR criteria — defer to the `adr` skill.
