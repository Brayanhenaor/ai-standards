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

## Finding format — legible, tiered by severity

A finding is evidence someone else reads on the PR. It must stand on its own: show the actual code,
explain the problem in **plain language** (gloss any term in one line — never assume jargon), and
give a **concrete** fix. Spend words in proportion to severity — don't wrap a one-line nit in a
template, but never leave a real issue cryptic.

**Critical / High — the full, readable form:**

```
[CRITICAL] · <category> · path:line
  <One plain sentence: what is wrong and to whom it matters.>

  <lang>
  <the actual offending lines, quoted from the diff>

  Why it matters: <the concrete consequence — the bug it causes, the attack it enables, the cost it
                   incurs — not just the name of the rule>
  Fix: <the concrete change; show before → after when that makes it unambiguous>
       (Effort: quick-fix | needs-design)                                        ← optional
  Confidence: high | needs confirmation — <what must be checked, when not high>
```

**Medium** — problem · why · one-line fix, with a short code excerpt when the line alone is unclear.

**Low / Suggestion** — one line each. Show at most **5**; collapse the rest into
`+N minor items (naming/local structure) — not shown`. The report is PR evidence, not a lint dump.

There is **no separate "priority" field** — severity implies it. The only optional extra axis is
**Effort** (`quick-fix` / `needs-design`), and only on Critical/High where it helps planning.

## Confidence & context — how false positives are prevented

The reviewer **reads freely to judge, but reports only on the diff.** Reading the whole changed file,
the definitions and callers a changed line references, config, and the context the developer gave in
step 1 is not "out of scope" — only *findings* are scoped to the diff. Judging a line blind is how
false positives are born.

Before any finding is reported, all must hold — otherwise drop it or demote it:

1. It is **in the PR diff** (not untouched/legacy code).
2. It is **justified against a named rule** — not a personal style preference.
3. Its judgment is **grounded in context actually read** — not inferred from a line in isolation. If
   the verdict depends on code/config/runtime the reviewer could not see, it **reads it first**.
4. For **Critical/High**: reachability/impact is **confirmed**, not assumed.

**Ask the developer — throughout, not only at the start.** Questions are the primary tool against
false positives, and they don't stop after step 1. Whenever a potential finding hinges on context
only the developer holds — intent, a business rule, a constraint, whether validation happens
elsewhere — **ask before deciding** rather than guess. A short, targeted question resolves an
ambiguity that a blind assumption would turn into a wrong blocker. Batch these questions so the
developer answers a few at once, not a drip.

When context still can't be confirmed — the developer isn't available to ask (e.g. `--ci` mode) or
the deciding code genuinely isn't there — **do not emit a hard finding**. Move it to the report's
*Assumptions & things to verify* section, phrased as a question ("if X isn't validated upstream, this
is a gap — confirm"). A wrong blocker erodes trust in the whole report more than a missed nitpick.
When still unsure, cut it.

Use the developer's step-1 answers to **suppress** findings the context already explains (a value
that looks magic but is a documented constant, validation that happens at a boundary outside the
diff, an intentional design the ticket calls for).

## ADR recommendation — search, then ask, then conclude

Never assume no ADR exists. If the change makes an architectural decision with lasting, cross-cutting
impact — a new external integration, a new persistence/messaging pattern, a public-contract change,
swapping a core library/framework, a change to the security model — run these steps **before** the
verdict, so the recommendation reflects reality, not a guess:

1. **Search for an existing ADR** that covers this decision. Look in the repo's ADR location (defer to
   the `adr` skill for where/format) and common ones: `docs/adr/`, `docs/decisions/`, `adr/`, `ADR/`,
   `architecture/decisions/`. Match by topic, not just filename.
2. **If none is found, ask the developer** — *"this change looks like an architectural decision (…);
   is there an ADR for it, and where?"* Don't conclude "missing" from a failed search alone; the dev
   may know it lives elsewhere or is in review.
3. **Then emit exactly one:**
   - **✅ Covered** — an ADR already records this decision and the change stays consistent with it.
     Cite it (`ADR-XXXX`).
   - **⚠️ ADR should be updated** — an ADR exists but this change diverges from or supersedes it.
     Say which one and what changed.
   - **⚠️ ADR recommended** — a significant but reversible / borderline decision with no ADR.
   - **❗ ADR required before the PR** — a lasting, cross-cutting decision with **confirmed** no ADR.
   - **✅ No ADR needed** — a local change with no architectural decision.

Always justify the choice in one line, and cite the ADR when one is involved. Do not invent ADR
criteria — defer to the `adr` skill.
