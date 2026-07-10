# CMTAT Confidential — Audit & Security-Analysis Overview

> This is a security **overview** (audits + static analysis). For how to report a vulnerability, see the
> repository's [`SECURITY.md`](../../SECURITY.md).

**In scope:** the production contracts under `contracts/` (deployment variants, `CMTATConfidentialBase`, FHE
modules, interfaces). Mocks (`contracts/mocks/`), tests, and vendored submodules under `lib/` are out of scope for
the static-analysis runs below (run with mocks excluded).

## Audits & automated analyses

| Version | Type | Report | Feedback / disposition |
|---------|------|--------|------------------------|
| v1.0.0 | Static analysis — Aderyn 0.6.5 | [`v1.0.0/aderyn-report.md`](./v1.0.0/aderyn-report.md) | [`v1.0.0/aderyn-report-feedback.md`](./v1.0.0/aderyn-report-feedback.md) |
| v1.0.0 | Static analysis — Slither 0.11.5 | [`v1.0.0/slither-report.md`](./v1.0.0/slither-report.md) | [`v1.0.0/slither-report-feedback.md`](./v1.0.0/slither-report-feedback.md) |
| v0.3.0 | Manual audit — OpenZeppelin | [`v0.3.0/OpenZeppelin Audit Reportv0.3.0.pdf`](./v0.3.0/) | [`v0.3.0/OpenZeppelin.md`](./v0.3.0/OpenZeppelin.md), [`v0.3.0/feedback.md`](./v0.3.0/feedback.md) |
| v0.3.0 | Complementary audit — Claude (custom security-audit skills) | [`v0.3.0/claude-audit/CLAUDE_AUDIT.md`](./v0.3.0/claude-audit/CLAUDE_AUDIT.md) | [`v0.3.0/claude-audit/CLAUDE_AUDIT-feedback.md`](./v0.3.0/claude-audit/CLAUDE_AUDIT-feedback.md); findings summary below |
| v0.3.0 | Static analysis — Aderyn | [`v0.3.0/aderyn-report.md`](./v0.3.0/aderyn-report.md) | [`v0.3.0/aderyn-report-feedback.md`](./v0.3.0/aderyn-report-feedback.md) |
| v0.2.0 | Static analysis — Aderyn | [`v0.2.0/aderyn-report.md`](./v0.2.0/aderyn-report.md) | [`v0.2.0/aderyn-report-feedback.md`](./v0.2.0/aderyn-report-feedback.md) |
| v0.1.0 | Automated audit — Nethermind AuditAgent | [`v0.1.0/nethermind-audit-agent/`](./v0.1.0/nethermind-audit-agent/) | see report-feedback in that folder |

## Static-analysis results (latest: v1.0.0)

| Tool | High | Medium | Low | Info | Relevant to fix? |
|------|------|--------|-----|------|------------------|
| Aderyn 0.6.5 (`-x mocks`) | 0 | 0 | 7 | 0 | **No** — all by-design or not-applicable |
| Slither 0.11.5 (mocks excluded) | 0 | 8 | 3 | 7 | **No** — all FHE fluent-API pattern or false positive / cosmetic |

All 7 Aderyn Low findings (centralization, unspecific pragma, PUSH0, single-use modifier, empty block, single-use
internal function, unchecked fluent-return) are by-design or not applicable to the deployment target; unchanged in
count and disposition since v0.3.0.

Slither's 8 Medium + 3 Low results are the **same FHE fluent-interface pattern** Aderyn reports as L-7
(`FHE.allow` / `FHE.makePubliclyDecryptable` return the passed-in handle; the external call targets the Zama
coprocessor, not an attacker). The 7 Informational results are virtual-hook dead-code false positives or cosmetic
style notes. The two tools agree: **no exploitable finding.** See each tool's v1.0.0 feedback for the per-finding
rationale.

## Manual-audit findings fixed (OpenZeppelin v0.3.0 → remediated in v1.0.0)

| ID | Severity | Title | Disposition |
|----|----------|-------|-------------|
| M-01 | Medium | Rule Engine not applied to mint/burn | **Fixed** — RuleEngine screening added to `_validateMint`/`_validateBurn` in the RuleEngine variant |
| L-01 | Low | Sequential total-supply disclosures leak mint/burn amounts | **Documented** — accepted residual risk; operational mitigations + threat-model FHE-5 |
| L-02 | Low | TokenAttribute seeded via skippable internal initializer | **Fixed** — compiler-enforced constructor |
| N-01 | Note | Missing docstrings | **Fixed** |
| N-02 | Note | Incomplete docstrings | **Fixed** |
| N-03 | Note | Floating pragma | **Won't fix** — deliberate, so library consumers keep compiler-version choice |
| N-04 | Note | `++i` saves gas in loops | **Fixed** |
| N-05 | Note | Misleading documentation | **Fixed** |

Full remediation response: [`v0.3.0/OpenZeppelin.md`](./v0.3.0/OpenZeppelin.md).

## Complementary Claude audit (v0.3.0) — findings summary

Independent review of the v0.3.0 contracts (commit `463087c`, same scope as the OpenZeppelin engagement) by Claude
(Anthropic) driven by a set of custom smart-contract security-audit skills. Method: threat model →
privileged-surface enumeration → targeted manual review → executable Hardhat PoCs (`test/ThreatModel.test.ts`, 25
passing) → adversarial severity self-review. Severity uses Code4rena.
Full report: [`v0.3.0/claude-audit/CLAUDE_AUDIT.md`](./v0.3.0/claude-audit/CLAUDE_AUDIT.md).

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| F-1 | Low | Observer can escalate scoped read into global public balance disclosure | Confirmed — inherent FHEVM ACL trust assumption (not code-fixable); govern `OBSERVER_ROLE` + documented |
| F-7 | Low | Observer removal is not retroactive (ACL grants irrevocable) | Confirmed — FHE-platform limitation; documented |
| F-3 | Info | Silent zero-transfer/burn on insufficient balance | Confirmed — documented FHE limitation; decrypt emitted handle to verify |
| F-4 | Info | Public disclosure is irreversible per handle | By-design (role-gated) |
| F-5 | Info | Mint/burn permitted while paused | By-design (CMTAT: pause halts transfers, deactivation halts supply) |
| F-9 | Info | Standardized eligibility views can mislead integrators | Confirmed — NatSpec-documented caveats |
| F-2 | — | Authorization-hook coverage complete | NOT-A-FINDING (verified safe) |
| F-6 | — | RuleEngine selector/policy wiring complete | NOT-A-FINDING (+Info POL-1 note) |
| F-8 | — | Transfer-gate completeness across all 8 overloads | NOT-A-FINDING (verified safe) |
| F-10 | — | Observer-ACL re-grant invariants hold | NOT-A-FINDING (verified safe) |

**Tally:** 0 Critical / 0 High / 0 Medium, **2 Low**, **5 Info**, 4 threat areas verified safe. No exploitable
finding; the two Low items are inherent FHEVM/observer trust properties mitigated operationally.
