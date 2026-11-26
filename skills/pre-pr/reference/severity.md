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

**Calibration examples** (impact, not category):

- **Critical** — money, points, or stock moved without the matching debit/credit or moved twice; an
  endpoint that writes data or returns another tenant's data without valid authentication; account
  takeover; data loss or corruption on a normal path; insecure default that activates when a config key
  is missing.
- **High** — the same classes of defect behind a realistic precondition (concurrent requests, a
  specific config, a second replica); side effects (notifications, events) emitted for operations that
  rolled back; a background job that one bad record can block.
- **Medium** — a partial update that clears an optional field; a missing index on a query that is
  slow but correct; tests that run on an in-memory provider for transactional behavior; a new
  150-line service method that validates, calls out, and audits in one body; an endpoint with eleven
  query parameters and hand-written input checks; three DTOs declared inside a service file.

## Verdict — deterministic mapping

Look at the **highest** severity present:

- Any **Critical** → **❌ Not ready for the PR.**
- No Critical, any **High** → **⚠️ Ready for the PR, with risks** (the risks must be acknowledged).
- Only **Medium / Low / Suggestion** → **✅ Ready for the PR.**

State the reason in one or two lines, tied to the specific blockers.

## Finding format — a structured block, never a paragraph

A finding is evidence someone else reads on the PR. It must be a **scannable block with a fixed
shape**, not running prose. Show the actual code, explain in **plain language** (gloss any term in
one line — never assume jargon), and give a **concrete** fix. Render the headings and labels in the
developer's language (the skeleton below is English only because plugin content is; `**What:**` →
`**Qué:**`, etc.).

**Critical / High / Medium — the full block (Markdown, exactly this structure):**

    ### [<Severity>] <category> · path:line
    **What:** <one plain sentence — what is wrong and to whom it matters>

    ```<lang>
    <the actual offending lines, quoted from the diff>
    ```

    **Why it matters:** <the concrete consequence — the bug it causes, the attack it enables, the cost
    it incurs — not just the name of the rule>
    **Fix:** <the concrete change; show before → after when it makes it unambiguous>
    **Confidence:** <high | needs confirmation: what to check>   ·   **Effort:** <quick-fix | needs-design> *(optional)*

Never merge these into one paragraph. Every field on its own line, the code always in its own fenced
block. A Medium may omit the code fence only when the location alone is self-evident.

**Low / Suggestion — one line each**, under a single bulleted list. Show at most **5**; collapse the
rest into `+N minor items (naming/local structure) — not shown`. PR evidence, not a lint dump.

There is **no separate "priority" field** — severity implies it. The only optional extra axis is
**Effort** (`quick-fix` / `needs-design`), and only on Critical/High where it helps planning. The
severity label itself (`Critical`, `Alto`, …) is rendered in the developer's language.

## Confidence & context — how false positives are prevented

The reviewer **reads enough to judge, but reports only on the diff.** Pull the changed symbol's
direct callers/definitions (via the graph's call-chain capability when connected and fresh —
see SKILL.md §0 and `rules.md` § Context tool), touched config, and the context the developer gave in
step 1 — this is not "out of scope," only *findings* are scoped to the diff. Judging a line blind is
how false positives are born. This gathering is a single shared pass reused across every dispatched
engine (SKILL.md §3), not repeated per engine.

Before any finding is reported, all must hold — otherwise drop it or demote it:

1. It is **in the PR diff** (not untouched/legacy code).
2. It is **justified against a named rule** — not a personal style preference.
3. Its judgment is **grounded in context actually read** — not inferred from a line in isolation. If
   the verdict depends on code/config/runtime the reviewer could not see, it **reads it first**.
4. For **Critical/High**: reachability/impact is **confirmed**, not assumed — for a breaking-change
   claim on a public API/contract, confirm via the graph's cross-cutting query capability (SKILL.md §0)
   rather than guessing from the diff alone.

This confidence gate is applied by **the orchestrator in one pass** over the consolidated findings —
it is not a second fan-out of verifier agents. Reserve the reachability check above for Critical/High
breaking-change claims specifically; Medium/Low findings don't need independent re-verification.

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
