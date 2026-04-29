# Generate change control document

Generate a professional change control document based on specific commits or pending changes.

**Usage:**
- `/user:changelog-dotnet <commit1> <commit2> ...` — document for one or more specific commits
- `/user:changelog-dotnet` — document for all pending changes not yet pushed

---

## Step 1 — Collect the changes

If `$ARGUMENTS` contains commit SHAs:
```bash
# For each provided commit
git show <sha> --stat
git show <sha>

# Full diff across all provided commits
git diff <first-sha>^..<last-sha>
git diff <first-sha>^..<last-sha> --stat
```

If `$ARGUMENTS` is empty:
```bash
# All local commits not yet on remote
git log origin/HEAD..HEAD --oneline
git diff origin/HEAD..HEAD
git diff origin/HEAD..HEAD --stat

# Also include uncommitted staged changes if any
git diff --cached
git diff --cached --stat
```

Also run:
```bash
git log --format="%H %s %an %ad" --date=short <range>
```

---

## Step 2 — Analyze

Before writing the document, identify:

- **What changed**: which files, which functional areas, what behavior was added/modified/removed
- **Why it changed**: infer intent from commit messages, code context, and the nature of the changes
- **Technical scope**: which layers were touched (domain, application, infrastructure, API, config, tests, docs)
- **Risk surface**: what existing functionality could be affected
- **Validation approach**: how to verify the change works correctly

---

## Step 3 — Generate the document

Produce the document in the following exact structure. Write it in the same language the project uses (check commit messages and existing docs to determine language).

---

```
CHANGE CONTROL DOCUMENT
=======================
Project:    [project name from folder or solution file]
Date:       [current date, format: DD/MM/YYYY]
Version:    [infer from latest tag or write "N/A"]
Commits:    [SHA list, or "Pending changes" if no commits provided]
Author:     [from git config user.name]


1. CHANGE DESCRIPTION
---------------------
[2–4 sentences describing what was changed at a functional level.
Written for a non-technical reader. Explain what the system does
differently after this change.]


2. JUSTIFICATION
----------------
[2–3 sentences explaining why this change was necessary.
Infer from commit messages, issue references, or the nature of the change.
Focus on the business or technical motivation.]


3. TECHNICAL CHANGES
--------------------
[Detailed description of what was done technically. Organized by area
if the change spans multiple layers. Explain decisions made and why.
This section is for technical reviewers.]


4. MODIFIED FILES
-----------------
[List every modified file with a brief description of what changed in it.
Format:

  Path/To/File.cs
    - [what was changed and why]

  Path/To/Another.cs
    - [what was changed and why]
]


5. NEW FILES CREATED
--------------------
[List every new file with a description of its purpose.
Write "None" if no files were created.

  Path/To/NewFile.cs
    - [purpose and responsibility of this file]
]


6. PRESERVED FUNCTIONALITY
--------------------------
[List the key behaviors and flows that remain unchanged.
Reassure the reviewer that existing functionality was not broken.
Be specific — mention endpoint names, features, or integration points.]


7. IMPACT AND RISKS
-------------------
[Describe potential risks introduced by this change.
Consider: breaking changes, performance impact, dependency changes,
database schema changes, configuration changes, security implications.
Rate each risk as LOW / MEDIUM / HIGH and explain the mitigation.]


8. VALIDATION
-------------
[Step-by-step instructions to verify the change works correctly.
Include: unit tests to run, endpoints to call, scenarios to test,
expected results. Make it actionable for a QA or another developer.]


9. CHANGE STATISTICS
--------------------
  Files modified:   [N]
  Files created:    [N]
  Files deleted:    [N]
  Lines added:      [N]
  Lines removed:    [N]
  Commits included: [N]


10. TECHNICAL OBSERVATIONS
--------------------------
[Any additional technical notes relevant for future maintainers.
Include: known limitations, follow-up work needed, dependencies on
other changes, configuration required in each environment, etc.
Write "None" if there is nothing to add.]
```

---

## Output rules

- Professional tone — no emojis, no informal language
- Mix user-level explanations (sections 1, 2, 6) with technical detail (sections 3, 4, 5)
- Clean formatting suitable for copying into Word or a ticketing system
- If a section has nothing to report, write "None" — do not omit the section
- Infer missing context (justification, risks) from the code — do not leave placeholders
- Output the document as a plain text code block so it is easy to copy
