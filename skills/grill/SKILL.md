---
name: grill
description: Pressure-test a plan or design by interrogating the developer one question at a time. Use when the developer wants their thinking challenged, asks you to "grill me", "poke holes", or stress-test a decision before committing to it. Walks the decision tree branch by branch until understanding is solid.
---

# Grill

Interrogate the plan until it holds up — or reveals the gap it was hiding. This is the deliberate,
opt-in form of "question the developer." Be rigorous, not hostile: the goal is a decision that
survives scrutiny, not winning.

## How

- **One question at a time.** Ask, wait, listen, then ask the next. Never dump a questionnaire — a
  single sharp question the developer actually answers beats ten they skim.
- **Walk the decision tree.** Start at the riskiest or most load-bearing assumption. Resolve
  dependencies between decisions in order — don't jump around.
- **For each question, offer your own recommended answer** after they respond, so it's a dialogue,
  not an exam. They can accept, refine, or push back.
- **Follow the weak spots.** When an answer is vague, hand-wavy, or contradicts an earlier one, dig
  there — that's where the real risk lives.

## What to probe

- The assumptions the plan rests on — which are facts, which are hopes?
- Failure modes: what happens when this dependency is down, this input is hostile, this scales 100×?
- The trade-off actually being accepted, and whether the developer sees its cost.
- Edge cases, data integrity, rollback, and "what does done look like?"
- Whether a simpler approach was dismissed too fast — or a complex one adopted without need.

## When to stop

Stop when the plan's assumptions are explicit, its main risks are acknowledged and handled, and the
developer can state *why* this approach over the alternatives. If a question exposes a real flaw,
name it plainly and help reshape the plan rather than continuing to grill.

Reply in the developer's language.
