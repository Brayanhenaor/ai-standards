---
name: security-audit
description: Audit code for security vulnerabilities (OWASP Top 10 and common weaknesses) and report them by severity. Use when asked for a security review, before shipping sensitive features (auth, payments, file upload, PII), or to check for injection, broken auth, secret leakage, and access-control gaps. Scope is the current diff or the whole project.
---

# Security audit

A focused security pass, separate from general `review`. Finds exploitable weaknesses and reports
them by severity — with the attack scenario, not just the rule.

## Scope

```
/supercode:security-audit            # current diff (default)
/supercode:security-audit --full     # whole project, or a path
```

Resolve scope like `review` (diff = uncommitted changes; full = source tree, skipping
vendored/generated). Dispatch the **`security-auditor`** subagent over the file set.

## What's checked (OWASP-aligned)

- **Broken access control** — missing/incorrect authorization, IDOR (acting on another user's id),
  privilege escalation, missing ownership checks.
- **Injection** — SQL/NoSQL/command/LDAP; any unparameterized query or shelled-out user input.
- **Authentication & sessions** — weak token validation, missing expiry, tokens/secrets in logs,
  plaintext refresh tokens, missing rate limits on auth.
- **Cryptographic failures** — weak/again hashing for passwords, hardcoded keys, secrets in source or
  config committed to the repo.
- **Sensitive data exposure** — PII/secrets in logs or responses, stack traces leaked to clients,
  over-permissive serialization returning fields the caller shouldn't see.
- **SSRF / unvalidated input** — user-controlled URLs/paths, missing boundary validation.
- **Security misconfiguration** — `AllowAnyOrigin`, missing security headers, debug endpoints in prod.
- **Vulnerable dependencies** — flag known-risky or outdated packages where visible.

## Reporting

Findings by severity, highest first — each with **how it's exploited**, the impact, and the fix:

```
[CRITICAL]    Exploitable now (injection, auth bypass, leaked secret) — fix before merge
[HIGH]        Serious weakness needing a realistic precondition
[MEDIUM]      Defense-in-depth gap / hardening
[LOW]         Minor / informational
```

Report only real, justifiable findings — a false security alarm erodes trust. Confirm the path is
actually reachable with attacker-controlled input before calling it critical. This skill reports; it
does not fix. Reply in the developer's language; keep code in English.
