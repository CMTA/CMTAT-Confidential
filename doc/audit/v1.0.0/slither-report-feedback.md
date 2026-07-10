# Slither Report v1.0.0 — Maintainer Feedback

Review of [`slither-report.md`](./slither-report.md) (0 high, 8 medium, 3 low, 7 info).
Command: `slither . --checklist --filter-paths "node_modules,lib,test,forge-std,mocks"` (Slither 0.11.5, Foundry/solc 0.8.34, **mocks excluded**).
Each detector is assessed below with disposition and rationale, verified against the cited `file:line`.

---

## unused-return (8 instances) — Not applicable

Every instance is an ignored return value of `FHE.allow(...)` or
`FHE.makePubliclyDecryptable(...)` in `ERC7984BalanceViewModule` (`setRoleObserver`,
`_grantHolderObserverAcl`), `ERC7984PublishTotalSupplyModule.publishTotalSupply`, and
`ERC7984TotalSupplyViewModule` (`addTotalSupplyObserver`, `_updateTotalSupplyObserversAcl`).

These functions expose a **fluent interface**: they return the same encrypted handle
that was passed in, to allow call chaining. The return is not a success/error code, so
ignoring it when chaining is not needed is intentional and matches usage throughout the
OpenZeppelin Confidential Contracts library. (This is the same root cause Aderyn reports
as **L-7**.)

No code change required.

---

## reentrancy-events (3 instances) — False positive

Flagged in `setRoleObserver`, `publishTotalSupply`, and `addTotalSupplyObserver`. In each,
the "external call" is `FHE.allow(...)` / `FHE.makePubliclyDecryptable(...)` — a call to
the Zama FHE coprocessor system contract, not an attacker-controllable address — after
which an event (`RoleObserverSet`, `TotalSupplyPublished`, observer-set events) is emitted.

`reentrancy-events` is Slither's lowest-severity reentrancy class: it only warns that an
event is emitted after an external call. There is no attacker-controllable callback and no
state mutation after the call that could be exploited; the ordering has no security impact.

No code change required.

---

## dead-code (5 instances) — False positive (virtual hooks)

Flagged: `ERC7984MintModule._validateMint`, `ERC7984BurnModule._validateBurn`,
`ERC7984EnforcementModule._afterBurn`, `._validateForcedTransfer`, `._validateForcedBurn`.

These are the **default (no-op / base) implementations of virtual hooks** that are called
from `mint`/`burn`/`forcedTransfer`/`forcedBurn` and overridden in `CMTATConfidentialBase`
(and, for `_validateMint`/`_validateBurn`, further in `CMTATConfidentialRuleEngine`). They
are reached through virtual dispatch, which Slither's `dead-code` detector does not resolve,
so it reports the base definitions as unused. They are required for the module pattern and
for variants that do not override a given hook.

No code change required.

---

## naming-convention (1 instance) — Cosmetic, intentional

`CMTATConfidentialBase._TOKEN_DECIMALS` is flagged as not mixedCase. It is an `immutable`
value intentionally styled like a constant (`UPPER_SNAKE_CASE`) to signal its
set-once-at-construction nature. Renaming brings no functional benefit.

No code change required.

---

## unindexed-event-address (1 instance) — Cosmetic

`IERC7984TotalSupplyViewModule.MaxSupplyObserversUpdated(uint256, uint256, address)` has an
address parameter (the caller/admin) that is not `indexed`. Indexing is optional; this event
is emitted only on an admin cap change (rare, not a high-volume filter target), so leaving it
unindexed is acceptable. Could be indexed in a future non-urgent change.

No code change required.

---

## Summary

| Detector | Severity | Instances | Disposition |
|----------|----------|-----------|-------------|
| unused-return | Medium | 8 | Not applicable — FHE fluent API (return is the same handle) |
| reentrancy-events | Low | 3 | False positive — FHE coprocessor call + event only, no exploitable state |
| dead-code | Info | 5 | False positive — virtual hooks resolved via inheritance override |
| naming-convention | Info | 1 | Cosmetic — `_TOKEN_DECIMALS` immutable styled as constant |
| unindexed-event-address | Info | 1 | Cosmetic — optional indexing on a rare admin event |

No findings require a production code change.

---

## Cross-check with Aderyn (v1.0.0)

Slither's Medium/Low output (`unused-return`, `reentrancy-events`) is the **same FHE
fluent-API pattern** that Aderyn reports as `L-7: Unchecked Return`. The two tools agree:
there is no exploitable finding. Slither adds only the virtual-hook dead-code false positives
and two cosmetic style notes.

## Executive triage

**Nothing to fix — 0 High, 0 real findings.** All 8 Medium and 3 Low results are the FHE
fluent-interface pattern (returns the passed-in handle; the external call targets the Zama
coprocessor, not an attacker). The 7 Informational results are virtual-dispatch false
positives or cosmetic style notes. No result is exploitable and none requires a production
code change.

> **Note:** earlier attempts to run Slither on this project were unsuccessful; with Slither
> 0.11.5 compiling via Foundry (solc 0.8.34), the run completes cleanly (112 contracts, 101
> detectors, 18 results).
