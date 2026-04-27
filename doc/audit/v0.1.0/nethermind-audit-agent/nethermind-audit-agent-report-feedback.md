# Nethermind AuditAgent Report — Maintainer Feedback

**Source:** AuditAgent automated scan by Nethermind Security  
**Scan ID:** 2 — Date: March 18, 2026  
**Commit:** `51f9d7aa...8fbf4849` (branch `main`)  
**Contracts scanned:** 10 (1 239 lines of code)  
**Total findings:** 8 — Medium (3), Low (2), Info (2), Best Practices (1)

> **Important:** This report was generated entirely by AI and has **not** been manually
> reviewed by Nethermind's security team. It does not constitute a full security audit.
> All findings must be independently verified before being acted upon.

---

## Summary Table

| # | Title | Severity | Disposition |
|---|-------|----------|-------------|
| 1 | Receiver reentrancy can bypass the `transferAndCall` rollback path | Medium | Disputed — upstream design decision; document limitation, report to OZ Confidential team |
| 2 | Receiver reentrancy can steal tokens via `confidentialTransferAndCall` | Medium | Duplicate of #1 — resolved together |
| 3 | Freezing `address(0)` gives `ENFORCER_ROLE` a global block over holder transfers | Medium | Accepted — documented: `address(0)` is intentional synthetic spender; upstream CMTAT fix proposed; operator warning added |
| 4 | Unbounded supply-observer ACL refresh can cause OOG on mint/burn | Low | Fixed — admin-controlled cap (`setMaxSupplyObservers`, default 10) |
| 5 | `forcedBurn` does not invoke `_afterBurn`, causing observer ACL staleness | Low | Fixed — `_afterBurn` hook added to `ERC7984EnforcementModule`, diamond resolved in `CMTATConfidentialBase` |
| 6 | `forcedBurn` does not refresh total-supply observer ACLs (full variant) | Info | Fixed — duplicate of #5, resolved together |
| 7 | Unbounded observer list can cause DoS on `mint` and `burn` | Info | Duplicate of #4 — resolved together |
| 8 | Duplicate observer removal via `setRoleObserver(account, address(0))` | Best Practices | Accepted — add explicit guard or NatSpec clarification |

---

## Finding 1 — Receiver reentrancy can bypass the `transferAndCall` rollback path

**Severity:** Medium  
**File:** `contracts/CMTATConfidentialBase.sol`

### Description

`confidentialTransferAndCall(...)` in `CMTATConfidentialBase` performs the CMTAT policy
check then delegates to `ERC7984.confidentialTransferAndCall(...)`. Inside
`ERC7984._transferAndCall`, the execution has three distinct steps:

```
Step 1:  euint64 sent   = _transfer(from, to, amount)
            → Alice -100, Bob +100. State is committed immediately.

Step 2:  ebool success  = checkOnTransferReceived(operator, from, to, sent, data)
            → Bob's callback fires. Bob's balance already holds the tokens.

Step 3:  euint64 refund = _update(to, from, FHE.select(success, 0, sent))
            → If success==false: attempts a new transfer Bob→Alice of `sent`.
              If Bob's balance is insufficient: FHESafeMath.tryDecrease silently
              returns (false, 0) — no revert, refund=0.
         transferred = FHE.sub(sent, refund)
```

**Why the refund is non-atomic:** In a normal EVM transfer, a failed callback causes a
full `revert`, which unwinds the entire state including Step 1 — as if nothing happened.
Here there is no revert. Step 3 is an independent, best-effort reverse transfer. It only
succeeds if Bob still holds the tokens when Step 3 executes. The two state writes (Step 1
and Step 3) are not coupled: they can disagree. This is fundamentally a consequence of
FHE arithmetic — `FHESafeMath.tryDecrease` cannot revert on an encrypted condition; it
can only produce an encrypted 0. A true atomic rollback of an encrypted balance is
impossible without knowing the plaintext value.

**The reentrancy attack:** A malicious receiver calls `confidentialTransfer(attacker,
sent)` from inside `onConfidentialTransferReceived` (Step 2), draining its own balance
to zero before returning `false`. When Step 3 runs, `tryDecrease(balance=0, sent)`
silently produces `refund=0`. Alice loses 100 tokens permanently.

### Root cause analysis of the upstream library

Reading `ERC7984.sol` and `FHESafeMath.sol` directly:

- `_transferAndCall` is `internal` with no `virtual` keyword — it cannot be overridden.
- `_transfer` is likewise `internal` non-virtual.
- `FHESafeMath.tryDecrease` never reverts — it returns `(false, oldValue)` on underflow.
  This is a fundamental and intentional property of FHE arithmetic.
- The upstream library deliberately includes no reentrancy guard on `_transferAndCall`.

All public `confidentialTransfer*` functions are `public virtual` and are already
overridden in `CMTATConfidentialBase`, so a reentrancy lock could technically be added
at our level without forking. However, doing so would contradict the upstream design.

### Assessment

The upstream ERC-7984 library made a **conscious design choice** not to add a reentrancy
guard. The `onConfidentialTransferReceived` callback is explicitly designed to let
receivers perform operations — including token transfers — before deciding to accept or
reject. Adding a lock only in our wrapper would silently break any legitimate receiver
that calls `confidentialTransfer` as part of its callback logic, while other ERC-7984
implementations without our lock would remain vulnerable. This creates an inconsistent
and misleading security surface.

The right precedent here is ERC-777, which also introduced a callback-with-refund
pattern. It was eventually deprecated precisely because the callback-based safety
guarantee was unenforceable. ERC-7984 inherits this structural limitation, compounded
by the FHE constraint that makes the refund non-atomic by construction.

**Disposition:** Disputed — this is an upstream design decision, not a bug in our
contracts. `CMTATConfidentialBase` correctly delegates to the ERC-7984 implementation
without altering its semantics. We will:

1. Add NatSpec on both `confidentialTransferAndCall` overrides documenting that the
   refund is non-atomic, that the callback fires while the receiver already holds the
   tokens, and that the function must only be used with trusted receiver contracts.
2. Report the issue to the OpenZeppelin Confidential team so they can decide whether
   to add a guard or formally document this as an accepted trade-off at the standard level.

**No code change in our contracts.** Documentation update required.

---

## Finding 2 — Receiver reentrancy can steal tokens via `confidentialTransferAndCall`

**Severity:** Medium  
**Files:** `contracts/CMTATConfidential.sol`, `contracts/CMTATConfidentialBase.sol`

### Description

Same reentrancy and non-atomic refund vector as Finding 1, described from the
`CMTATConfidential` full-variant perspective.

### Assessment

Duplicate of Finding 1. Same root cause, same disposition.

**Disposition:** Resolved together with Finding 1 (NatSpec documentation + upstream
report). No code change required.

---

## Finding 3 — Freezing `address(0)` gives `ENFORCER_ROLE` a global block over holder transfers

**Severity:** Medium  
**Files:** `contracts/CMTATConfidential.sol`, `contracts/CMTATConfidentialBase.sol`

### Description

`_canTransferGenericByModule(address(0), from, to)` is used as the synthetic spender
for all holder-initiated `confidentialTransfer` and `confidentialTransferAndCall` calls.
This helper routes into `_canTransferStandardByModule`, which checks
`_canTransferisFrozen(spender, from, to)`. Since `EnforcementModule.setAddressFrozen`
accepts **any** address without a zero-address guard, an account with `ENFORCER_ROLE`
can freeze `address(0)`. Once `address(0)` is frozen, every direct holder transfer
reverts with `CMTAT_InvalidTransfer`, effectively pausing all holder transfers without
holding `PAUSER_ROLE` and bypassing the intended separation of freeze and pause powers.

### Assessment

This is a valid finding. The `ENFORCER_ROLE` is intended to freeze individual accounts,
not to impose a global transfer suspension.

**Disposition:** Accepted — documented. No code change in `CMTATConfidentialBase`.

**Root cause (precise):** `confidentialTransfer` and `confidentialTransferAndCall` in
`CMTATConfidentialBase` pass `address(0)` as the synthetic spender to
`_canTransferGenericByModule`. `address(0)` is semantically correct here — for direct
holder transfers there is no separate spender, and `address(0)` represents that absence.
That value flows into CMTAT's `_canTransferisFrozen(spender, from, to)`, which checks:

```solidity
if (EnforcementModule.isFrozen(spender) || EnforcementModule.isFrozen(from) || EnforcementModule.isFrozen(to))
    return false;
```

Because `setAddressFrozen` in CMTAT upstream has no zero-address guard, an
`ENFORCER_ROLE` holder can freeze `address(0)`, making that check always return `false`
for every direct holder transfer — effectively a global pause without `PAUSER_ROLE`.

**Why we do not change the synthetic spender:** replacing `address(0)` with `from` would
be semantically wrong (the holder is not acting as a "spender" of their own tokens) and
would make the frozen check on `from` redundant since it is already covered by the second
argument. The correct fix is at the source: the upstream CMTAT `EnforcementModule` should
reject `address(0)` in `setAddressFrozen`.

**Actions taken:**
1. An issue has been opened on the upstream CMTAT repository:
   [CMTA/CMTAT#372](https://github.com/CMTA/CMTAT/issues/372), proposing a zero-address
   guard in `EnforcementModuleInternal._addAddressToTheList`. A detailed analysis is also
   available in [`FREEZE_ISSUE.md`](../../../FREEZE_ISSUE.md).
2. An operator warning has been added to `README.md` (Freeze / Unfreeze section and Roles
   table) instructing `ENFORCER_ROLE` holders never to freeze `address(0)`.

---

## Finding 4 — Unbounded supply-observer ACL refresh can cause OOG on mint/burn

**Severity:** Low  
**Files:** `contracts/CMTATConfidential.sol`, `contracts/modules/ERC7984TotalSupplyViewModule.sol`

### Description

`_afterMint` and `_afterBurn` in `CMTATConfidential` call
`_updateTotalSupplyObserversAcl()`, which iterates over the entire `_supplyObservers`
array and calls `FHE.allow(ts, observer)` per entry. Each `FHE.allow` is an external
call to the ACL contract. There is no on-chain cap on the observer array length.
`addTotalSupplyObserver` is gated by `SUPPLY_OBSERVER_ROLE` but there is no maximum
count enforced. If the list grows large enough (hundreds of entries), cumulative gas can
approach or exceed the block gas limit, causing every `mint` and `burn` to revert.

### Assessment

The finding is valid. While `SUPPLY_OBSERVER_ROLE` is tightly controlled, the absence
of an on-chain cap creates an operational risk — even without malicious intent, a long
observer list could emerge over time and brick core supply operations.

**Disposition:** Accepted. **Fixed.**

The cap is implemented as an admin-controlled state variable (not a constant) so it can
be adjusted without redeployment:

- `_maxSupplyObservers` defaults to **10** at deployment.
- `maxSupplyObservers()` — public getter.
- `setMaxSupplyObservers(uint256 newMax)` — gated by `DEFAULT_ADMIN_ROLE` (via
  `_authorizeSetMaxSupplyObservers()` overridden in `CMTATConfidential`). Reverts with
  `ERC7984TotalSupplyViewModule_MaxBelowCurrentCount` if `newMax` is below the current
  observer count, preventing accidental lockout.
- `addTotalSupplyObserver` reverts with `ERC7984TotalSupplyViewModule_ObserverCapReached`
  when the list is at capacity.

---

## Finding 5 — `forcedBurn` does not invoke `_afterBurn`, causing observer ACL staleness

**Severity:** Low  
**Files:** `contracts/modules/ERC7984EnforcementModule.sol`, `contracts/CMTATConfidential.sol`

### Description

In `ERC7984EnforcementModule`, both overloads of `forcedBurn` call `_burn(from, amount)`
but do **not** call `_afterBurn` afterwards. The regular `burn` in `ERC7984BurnModule`
always calls `_afterBurn`. In `CMTATConfidential`, `_afterBurn` is overridden to call
`_updateTotalSupplyObserversAcl()`, which re-grants ACL access to all registered supply
observers on the new total-supply handle. Because `forcedBurn` skips this hook, every
FHE arithmetic operation inside `_burn` produces a new ciphertext handle, and the old
ACL grants on the pre-burn total supply handle are not refreshed. Registered supply
observers cannot decrypt the current total supply after a `forcedBurn` until a
subsequent regular `mint`, `burn`, or manual `publishTotalSupply()` is called.

### Assessment

This is a valid finding with real operational impact: compliance/off-chain reporting
systems relying on automatic observer tracking will see stale (or undecryptable) supply
data after any forced burn.

**Disposition:** Accepted. **Fixed.**

- `ERC7984EnforcementModule`: virtual `_afterBurn(address, euint64)` stub added (empty
  by default); called in both `forcedBurn` overloads after `_burn`.
- `CMTATConfidentialBase`: explicit `override(ERC7984BurnModule, ERC7984EnforcementModule)`
  added to resolve the diamond — both modules now declare the same hook.
- `CMTATConfidential`: no change needed — its existing `_afterBurn` override already
  calls `super._afterBurn` then `_updateTotalSupplyObserversAcl()`, which now runs for
  forced burns as well.

---

## Finding 6 — `forcedBurn` does not refresh total-supply observer ACLs (full variant)

**Severity:** Info  
**Files:** `contracts/CMTATConfidential.sol`, `contracts/modules/ERC7984EnforcementModule.sol`

### Description

The auditor describes the same staleness effect as Finding 5 from the perspective of
the full deployment variant (`CMTATConfidential`), emphasising that the full variant
explicitly advertises automatic ACL refresh after every supply-changing operation, but
`forcedBurn` undermines this contract.

### Assessment

This is a duplicate of Finding 5 with additional context about the full-variant
invariant violation. No separate fix is required beyond the fix described for Finding 5.

**Disposition:** Resolved by the fix for Finding 5.

---

## Finding 7 — Unbounded observer list can cause DoS on `mint` and `burn`

**Severity:** Info  
**Files:** `contracts/modules/ERC7984TotalSupplyViewModule.sol`, `contracts/CMTATConfidential.sol`

### Description

The auditor notes that `addTotalSupplyObserver` imposes no on-chain cap, that
`FHE.allow` is gas-expensive, and that hundreds/thousands of observers can push
`_updateTotalSupplyObserversAcl` past the block gas limit.

### Assessment

This is a duplicate of Finding 4 with an emphasis on the DoS angle rather than the
liveness-risk framing. Same root cause, same fix.

**Disposition:** Resolved by the fix for Finding 4 (observer cap constant).

---

## Finding 8 — Duplicate observer removal via `setRoleObserver(account, address(0))` and `removeRoleObserver`

**Severity:** Best Practices  
**File:** `contracts/modules/ERC7984BalanceViewModule.sol`

### Description

`setRoleObserver(account, address(0))` and `removeRoleObserver(account)` produce the
same end state (role observer cleared to `address(0)`) and emit the same
`RoleObserverSet` event. However, they differ in one edge case: if no observer is
currently set, `setRoleObserver(account, address(0))` reverts with
`ERC7984BalanceViewModule_SameRoleObserver` (because `oldObserver == newObserver ==
address(0)`), whereas `removeRoleObserver` reverts with
`ERC7984BalanceViewModule_NoRoleObserver`. This inconsistency can confuse integrators
who treat `setRoleObserver(account, address(0))` as a combined set/remove operation.

### Assessment

The finding is valid as a UX / API clarity issue. The dual path is not a security
vulnerability but it does create inconsistent error surfaces. The cleanest resolution
is to explicitly document the distinction in NatSpec and, optionally, guard
`setRoleObserver` from accepting `address(0)` as `newObserver` to force integrators
towards the dedicated `removeRoleObserver` function.

**Disposition:** Accepted. Add NatSpec clarification. Optionally add an explicit guard:

```solidity
function setRoleObserver(address account, address newObserver) public virtual onlyObserverManager {
    require(newObserver != address(0), "ERC7984BalanceViewModule: use removeRoleObserver to clear");
    // ... existing logic
}
```

This removes the ambiguity entirely and makes `removeRoleObserver` the single path for
clearing an observer.

---

## Action Items

| Priority | Finding | Action | Commit |
|----------|---------|--------|--------|
| Low | #1 / #2 | Done — NatSpec warning added to both `confidentialTransferAndCall` overrides in `CMTATConfidentialBase`; upstream issue to be reported to OZ Confidential team | `36dbd3f` |
| Medium | #3 | No code change — `address(0)` as synthetic spender is semantically correct; upstream fix proposed in CMTAT issue [#372](https://github.com/CMTA/CMTAT/issues/372); operator warning added to README | `1abe564` |
| High | #5 / #6 | Fixed — `_afterBurn` called in both `forcedBurn` overloads; diamond resolution added in `CMTATConfidentialBase` | `681ebde` |
| Medium | #4 / #7 | Fixed — admin-controlled `_maxSupplyObservers` (default 10) with `setMaxSupplyObservers` gated by `DEFAULT_ADMIN_ROLE` | `12249c1` |
| Low | #8 | Fixed — `setRoleObserver` now rejects `address(0)` with `ERC7984BalanceViewModule_ZeroObserver`; use `removeRoleObserver` to clear | `a74314e` |
