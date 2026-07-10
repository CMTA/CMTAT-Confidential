# CLAUDE_AUDIT.md — CMTAT Confidential Security Audit (v0.3.0)

**Tool:** Claude (Anthropic), driven by a set of **custom smart-contract security-audit skills**.
**Codebase audited:** CMTAT Confidential contracts at **v0.3.0** (commit `463087c`) — `contracts/CMTATConfidentialBase.sol`,
`contracts/modules/*`, `contracts/deployment/*`, `contracts/interfaces/*`. This is the same scope as the
OpenZeppelin v0.3.0 engagement; it was run as a complementary review.
**Severity framework:** [Code4rena](https://docs.code4rena.com/awarding/judging-criteria/severity-categorization)
(High / Medium / Low / Info).
**Scope:** project Solidity only. Vendored submodules under `lib/` (OpenZeppelin Confidential, CMTAT, RuleEngine)
are treated as trusted dependencies; their **integration** into this project is in scope.

**Method:** threat model (`THREAT_MODEL.md`) → enumeration of the privileged/attack surface → targeted manual
review of each surface → executable Hardhat PoCs for every material claim (`test/ThreatModel.test.ts`) →
adversarial self-review of each finding's severity. The specific internal skills used are intentionally not
enumerated here.

> This is the published version of an internal Claude analysis. It credits the tool and method but not the
> individual skills. Severities and dispositions are unchanged from the internal deliverable.

---

## 1. Test Execution Summary

New suite: `test/ThreatModel.test.ts` — **25 passing**. Full project suite — **427 passing, 0 failing**
(no regressions). Run under Node 20 + `@fhevm/hardhat-plugin` mock coprocessor
(`DeactivateReportGas=true ./node_modules/.bin/hardhat test`).

| Test group | Threat | Result |
|------------|--------|--------|
| FHE-1: observer → public disclosure (role + holder observer) | F-1 | ✅ PoC confirms escalation |
| TX-3: mint/burn while paused; mint blocked when deactivated | F-5 | ✅ confirms by-design behaviour |
| TX-4: forcedTransfer while paused | (TX-4) | ✅ confirms bypass |
| TX-1: transfer/forcedTransfer > balance → 0 (no revert) | F-3 | ✅ confirms silent-zero |
| AC-1: 4 transfer overloads gated by freeze/pause | F-8 | ✅ gate holds |
| POL-2: allowlist on mint + transfer (Whitelist) | (POL-2) | ✅ enforced |
| TX-5: observer/supply-observer ACL across sequences | F-10 | ✅ invariant holds |
| AC-2: 5 privileged functions reject unauthorized callers | F-2 | ✅ all revert |
| math/view: decimals>18 reverts; canSend≠canTransfer under pause | F-9 | ✅ confirms asymmetry |

---

## 2. Findings

### Findings Summary Table

| ID | Short Description | Severity | Status | Component (`file:line`) | PoC |
|----|-------------------|----------|--------|--------------------------|-----|
| F-1 | Observer can globally disclose a balance | Low | Confirmed | `ERC7984BalanceViewModule.sol:67,140` + inherited `requestDiscloseEncryptedAmount` | `FHE-1` ✅ |
| F-2 | Authorization-hook coverage | — | NOT-A-FINDING | `CMTATConfidentialBase.sol:109-167` | `AC-2` ✅ |
| F-3 | Silent zero-transfer on insufficient balance | Info | Confirmed | `ERC7984._update`; `ERC7984EnforcementModule.sol:73,109` | `TX-1` ✅ |
| F-4 | Public disclosure irreversible per handle | Info | By-design | `ERC7984PublishTotalSupplyModule.sol:44` | ✗ |
| F-5 | Mint/burn permitted while paused | Info | By-design (CMTAT) | `ERC7984Mint/BurnModule`; CMTAT `ValidationModule:81` | `TX-3` ✅ |
| F-6 | RuleEngine selector/policy wiring | — | NOT-A-FINDING (+Info POL-1) | `CMTATConfidentialRuleEngine.sol:77-83` | `POL-2` ✅ |
| F-7 | Irrevocable ACL grants (observer removal not retroactive) | Low | Confirmed | `ERC7984BalanceViewModule.sol`; `ERC7984TotalSupplyViewModule.sol` | ✗ (FHE limit) |
| F-8 | Transfer-gate completeness (all 8 overloads) | — | NOT-A-FINDING | `CMTATConfidentialBase.sol:307-437` | `AC-1`,`POL-2` ✅ |
| F-9 | Standardized eligibility views can mislead | Info | Confirmed | `CMTATConfidentialBase.canTransfer`; CMTAT `canSend/canReceive` | view test ✅ |
| F-10 | Observer-ACL re-grant invariants | — | NOT-A-FINDING | `_update` chain; `_afterMint/_afterBurn` | `TX-5` ✅ |

**Severity tally:** 0 Critical, 0 High, 0 Medium, **2 Low** (F-1, F-7), **5 Info** (F-3, F-4, F-5, F-9, + TX-2/POL-1 notes); **4 threat areas verified safe** (F-2, F-6, F-8, F-10). All in-scope; no duplicates (no external analyser run provided).

### F-1 — Observer can escalate scoped read access to GLOBAL public disclosure — **Low**
> Severity adjusted Medium → Low after adversarial review: the escalation requires a trusted
> `OBSERVER_ROLE` grant (or the holder acting on their own account), and an observer already holds
> permanent cleartext access by design — so the marginal information gain is converting
> already-surrendered private knowledge into an on-chain-provable public value. The residual harm is
> the *non-consensual, irreversible* public leak of an unconsenting user's balance by a semi-trusted
> role; real, but privilege-gated. Shares its irrevocable-ACL root cause with F-7.

**Files:** `contracts/modules/ERC7984BalanceViewModule.sol:67,140-147`; inherited
`lib/openzeppelin-confidential-contracts/.../ERC7984.sol:requestDiscloseEncryptedAmount`
(not overridden by any variant).

Role observers (`setRoleObserver`, OBSERVER_ROLE) and holder observers (`setObserver`) receive a
**permanent** `FHE.allow` ACL on the observed account's balance handle and every transferred-amount
handle. The base contracts never override the inherited `requestDiscloseEncryptedAmount(euint64)`,
which makes *any* handle the caller has ACL on **publicly decryptable by the entire world**:

```solidity
function requestDiscloseEncryptedAmount(euint64 encryptedAmount) public virtual {
    require(FHE.isAllowed(encryptedAmount, msg.sender), ERC7984Unauthorized...);
    FHE.makePubliclyDecryptable(encryptedAmount);   // irrevocable, global
}
```

An observer is intended to *view* (decrypt for itself) the balances it oversees. This lets it
**publish** any observed balance to everyone, irreversibly. For a role observer (assigned by
OBSERVER_ROLE without the account's consent) this is a unilateral, non-consensual leak of a user's
confidential balance — defeating the token's core confidentiality guarantee for that account.

**Impact:** breach of confidentiality (the protocol's primary security property) by a
semi-trusted role, beyond its intended "view" scope. Irreversible.
**PoC:** `test/ThreatModel.test.ts` → "FHE-1" — an outsider cannot `userDecrypt` the holder
balance, but after the observer calls `requestDiscloseEncryptedAmount`, `fhevm.publicDecryptEuint`
returns the cleartext `5000` to a party with no ACL.
**Recommendation:** if observers should only *read* (not *publish*), override
`requestDiscloseEncryptedAmount` to restrict disclosure to the balance owner (or a dedicated
DISCLOSER role), e.g. require `msg.sender == owner-of-handle` or gate behind an explicit role.
At minimum, document that granting an observer is equivalent to granting public-disclosure power.

> **Read vs. publish — this fix does NOT remove observer read access.** FHE exposes two distinct
> "decrypt" mechanisms, and F-1 only concerns the second:
>
> 1. **Private read (observer reading a balance for itself).** Driven by the **ACL** (`FHE.allow`). An
>    observer is granted ACL on the balance/transferred handles by `setRoleObserver`
>    (`ERC7984BalanceViewModule.sol:69`) and `setObserver`, and the grant is re-applied on every balance
>    change in `_update` (`ERC7984BalanceViewModule.sol:140-147`; holder observers via
>    `ERC7984ObserverAccess._update`). With that ACL the observer calls `userDecrypt` off-chain — the KMS
>    re-encrypts the value **under the observer's own key only** (checked via `FHE.isAllowed`). This is the
>    intended regulatory read path.
> 2. **Public disclosure (publishing a balance to everyone).** Driven by
>    `requestDiscloseEncryptedAmount(handle)` → `FHE.makePubliclyDecryptable(handle)`
>    (`ERC7984.sol:208-214`), which makes the handle decryptable by the **entire world**, irreversibly. It
>    only requires the caller to already hold the ACL — which the observer does — so the observer can
>    escalate its private read into a global publish. **This escalation is the F-1 finding.**
>
> **Update (post-review — the token-layer override is not an effective mitigation).** Further review of the
> FHEVM ACL model showed that `makePubliclyDecryptable` merely wraps the ACL system contract's
> `allowForDecryption`, whose only precondition is that the caller already holds ACL on the handle. An
> observer can therefore call the ACL system contract **directly**, bypassing any override on
> `requestDiscloseEncryptedAmount`. There is no read-only ACL in FHEVM: an ACL grant confers, indivisibly,
> private read (`userDecrypt`), re-grant to a third party (`allow`), and public disclosure
> (`allowForDecryption`). F-1 is consequently an **inherent trust assumption of the observer model**, not a
> code-fixable escalation: mitigate by governing who may become an observer (restrict `OBSERVER_ROLE`,
> assign observers sparingly) and documenting that an observer grant equals full disclosure power.

---

### F-2 — Authorization-hook coverage — **NOT-A-FINDING (verified safe)**
Every privileged entrypoint binds its `_authorizeX` hook to a
concrete role in the deployment variants (`CMTATConfidentialBase` lines 109-167; `CMTATConfidential`
58-70; `CMTATConfidentialWhitelist` 142-147; `CMTATConfidentialRuleEngine` 85-90). No abstract hook
is left unbound. PoC AC-2 confirms 5 representative functions revert for unauthorized callers.
Disposition: safe.

---

### F-3 — Silent zero-transfer / zero-burn on insufficient balance — **Info**
> Severity adjusted Low → Info after adversarial review: inherent, documented FHE-platform limitation
> (encrypted underflow cannot revert); no funds at risk, and the forced-ops "looked successful" angle
> is structurally mitigated because the `ForcedTransfer`/`ForcedBurn` events emit the actual encrypted
> transferred handle, which an enforcer must decrypt to learn the result regardless.

**Files:** inherited `ERC7984._update` (FHESafeMath `tryDecrease` saturates); reached by all
transfer/burn paths incl. `forcedTransfer`/`forcedBurn` (`ERC7984EnforcementModule.sol:73,109`).

A transfer/burn/forced-op of `amount > balance` does not revert — it moves `0`. FHE underflow
conditions are encrypted and cannot trigger an EVM revert. For **enforcement** actions this is
material: a FORCED_OPS_ROLE holder executing a court-ordered seizure of a frozen account may believe
the seizure succeeded while `0` was moved. The emitted `ForcedTransfer`/`ForcedBurn` event carries
the encrypted *actual* amount, so success is verifiable only by decrypting the event.
**PoC:** `test/ThreatModel.test.ts` → "TX-1".
**Recommendation:** documented as an FHE gotcha; recommend off-chain enforcement tooling always
decrypts the emitted `transferred`/`burned` handle to confirm the moved amount, and that the docs
call this out specifically for forced operations (currently documented generically).

---

### F-4 — Public total-supply / amount disclosure is irreversible per handle — **Info**
`publishTotalSupply` (SUPPLY_PUBLISHER_ROLE) and any
`requestDiscloseEncryptedAmount` make a handle world-decryptable permanently. Intentional and
role-gated; the next mint/burn produces a fresh non-public handle. Recorded for completeness.
Disposition: by-design.

---

### F-5 — Mint and burn are permitted while the contract is paused — **Info**
> Severity adjusted Low → Info after adversarial review: this is standard, documented CMTAT semantics
> (pause halts *transfers*; supply changes are governed by *deactivation*), gated to trusted
> MINTER/BURNER roles. It diverges only from a naive intuition, not from the spec. No attacker, no loss.

**Files:** `ERC7984MintModule.sol:41/56`, `ERC7984BurnModule.sol:41/59` →
`CMTATConfidentialBase._validateMint/_validateBurn` → `ValidationModule._canMintBurnByModule`
(checks `deactivated()` and `isFrozen`, **not** `paused()`).

Confidential mint/burn bypass the `confidentialTransfer*` gate and are validated only by
`_canMintBurnByModule`, which does not check pause. So MINTER_ROLE/BURNER_ROLE can change supply
while the token is paused (only full deactivation blocks them). This matches upstream CMTAT
semantics, but contradicts the intuition that "pause halts all token movements," and pause is often
an incident-response control. Privileged-actor only.
**PoC:** `test/ThreatModel.test.ts` → "TX-3" (mint & burn succeed while paused; mint reverts once
deactivated).
**Recommendation:** confirm this is intended; if pause should also halt supply changes, add a
`_requireNotPaused()` to `_validateMint`/`_validateBurn`. Otherwise document explicitly that pause
does not stop mint/burn.

---

### F-6 — RuleEngine selector / policy wiring completeness — **NOT-A-FINDING (verified safe)** + **Info note**
All 8 `confidentialTransfer*` overloads route
through `CMTATConfidentialBase`, which calls `_canTransferGenericByModule` then `_beforeTransfer`.
In the RuleEngine variant `_beforeTransfer` → `_applyRuleEngine` → `ruleEngine.transferred(...)`,
which **must revert on invalid transfer** per `IRuleEngine` ("Must revert if the transfer is
invalid"). Direct vs delegated transfers correctly dispatch the 3-arg vs 4-arg `transferred`
overload. No overload omits the policy hook. Disposition: safe.

*Info note (POL-1):* enforcement uses `transferred()` while the `canTransfer`/`canTransferFrom`
**views** call the engine's `canTransfer`/`canTransferFrom`. If a rule implements these two surfaces
inconsistently, the pre-flight view can disagree with execution. Inherent to CMTAT; out of scope for
this repo's rule set, but integrators should keep rule `canTransfer`/`transferred` logic aligned.

---

### F-7 — Permanent ACL grants are irrevocable — **Low**
**Files:** `ERC7984BalanceViewModule.sol` (`removeRoleObserver`), `ERC7984TotalSupplyViewModule.sol`
(`removeTotalSupplyObserver`), inherited `setObserver(account, address(0))`.

Removing an observer only stops *future* `FHE.allow` grants; it cannot revoke access to handles
already granted. A removed observer retains decrypt access to every balance/amount/supply handle it
ever saw. This is an FHE-platform limitation, documented in the module NatSpec.
**Recommendation:** no code fix possible; ensure operational docs state that observer removal is not
retroactive and that compromised observers require rotating the underlying ciphertexts (which only
happens on the next state change).

---

### F-8 — Transfer-gate completeness across all entry points — **NOT-A-FINDING (verified safe)**
ERC-7984 exposes exactly 8 token-moving externals
(`confidentialTransfer`×2, `confidentialTransferFrom`×2, `…AndCall`×4); all are overridden in
`CMTATConfidentialBase` and routed through the freeze/pause(+policy) gate. `setOperator` only sets an
approval. `requestDiscloseEncryptedAmount`/`discloseEncryptedAmount` move no tokens (see F-1 for the
disclosure angle). The confidential `_update` chain deliberately omits CMTAT validation (validation
lives in the public overrides), and no public path reaches `_transfer`/`_mint`/`_burn` without a gate
except the intentional FORCED_OPS_ROLE enforcement functions. PoC AC-1 + POL-2 confirm. Disposition: safe.

---

### F-9 — Standardized eligibility views can mislead integrators — **Info**
**Files:** `CMTATConfidentialBase.canTransfer` (amount ignored, spender hardcoded `address(0)`);
`ValidationModule.canSend/canReceive` (ignore pause); `canTransferFrom` exists only on the RuleEngine
variant.

The standardized views are non-reverting (good) but carry caveats an ERC-3643/ERC-7943 integrator
might miss: `canTransfer(from,to,amount)` ignores `amount` (encrypted) and assumes a non-delegated
spender; `canSend`/`canReceive` reflect freeze/allowlist but **not** pause, so they can return `true`
while a transfer would revert; `canTransferFrom` is absent on the Lite/Whitelist/full variants. All
are thoroughly documented in NatSpec. Recorded as Info per the standardized-view-surface rule.
**PoC:** `test/ThreatModel.test.ts` → "canSend may return true while canTransfer returns false under
pause". **Recommendation:** consider providing `canTransferFrom` on all variants for ABI consistency,
and keep the NatSpec caveats prominent.

---

### F-10 — Observer-ACL re-grant invariants — **NOT-A-FINDING (verified safe)**
After every balance change the `_update` override chain
(`CMTATConfidentialBase → ERC7984BalanceViewModule → ERC7984ObserverAccess → ERC7984`) re-grants ACL
to both holder and role observers on the new balance and transferred-amount handles; after every
supply change `_afterMint`/`_afterBurn` re-grant supply observers (including the forced-burn path via
the `(ERC7984BurnModule, ERC7984EnforcementModule)` diamond resolution). The observer count is bounded
by `maxSupplyObservers`. PoC TX-5 confirms ACL survives multi-step sequences. Disposition: safe.

---

## 3. Invariant Verification

| # | Invariant | Result |
|---|-----------|--------|
| 1 | Every external token-moving path is gated, or is a FORCED_OPS enforcement on a frozen address | ✅ (F-8) |
| 2 | No `_authorizeX` hook unbound | ✅ (F-2) |
| 3 | Observers retain ACL on the latest balance/amount handle | ✅ (F-10/TX-5) |
| 4 | Supply observers retain ACL after mint/burn/forced-burn | ✅ (F-10/TX-5) |
| 5 | Supply-observer count ≤ `maxSupplyObservers` | ✅ (TX-5) |
| 6 | Frozen/non-allowlisted accounts cannot use the standard path | ✅ (AC-1, POL-2) |
| 7 | `decimals ≤ 18` | ✅ (constructor reverts at 19) |
| 8 | Balance ciphertext decryptable only by owner/observers/contract | ⚠ holds, but observers can *re-publish* (F-1) |

## 4. Access-Control Verification

| Function | Required role | Unauthorized caller | Result |
|----------|---------------|---------------------|--------|
| `mint` / `burn` | MINTER / BURNER | reverts | ✅ |
| `forcedTransfer` / `forcedBurn` | FORCED_OPS | reverts | ✅ (existing suite) |
| `setAddressFrozen` | ENFORCER | reverts | ✅ (existing suite) |
| `pause` | PAUSER | reverts | ✅ |
| `setRoleObserver` | OBSERVER | reverts | ✅ |
| `publishTotalSupply` | SUPPLY_PUBLISHER | reverts | ✅ |
| `add/removeTotalSupplyObserver` | SUPPLY_OBSERVER | reverts | ✅ (existing suite) |
| `setMaxSupplyObservers` | DEFAULT_ADMIN | reverts | ✅ |
| `setName` / `setSymbol` | TOKEN_ATTRIBUTE | reverts | ✅ (existing suite) |
| `setRuleEngine` | RULE_ENGINE | reverts | ✅ (existing suite) |
| allowlist mgmt | ALLOWLIST | reverts | ✅ (existing suite) |

## 5. Recommendations Summary (prioritized)

1. **F-1 (Low):** the disclosure power cannot be removed at the token layer (see the post-review update under
   F-1). Mitigate by governing who may become an observer — restrict `OBSERVER_ROLE` to a multisig/timelock,
   assign observers sparingly — and document that granting an observer confers public-disclosure power over the
   observed balance. *Highest priority — touches the confidentiality guarantee, even if privilege-gated.*
2. **F-7 (Low):** document that observer removal is not retroactive (shares root cause with F-1).
3. **F-5 (Info):** decide and document whether pause should halt mint/burn; add `_requireNotPaused()`
   to mint/burn validation if intended.
4. **F-3 (Info):** make the forced-op silent-zero behaviour explicit in enforcement docs; require
   off-chain tooling to decrypt the emitted amount to confirm seizures.
5. **F-9 (Info):** add `canTransferFrom` to all variants for ABI parity; keep view caveats prominent.

**Final severity tally:** 0 High, 0 Medium, **2 Low** (F-1, F-7), **5 Info** (F-3, F-4, F-5, F-9, and
the TX-2/POL-1 notes). 4 threat areas verified safe (F-2, F-6, F-8, F-10).

## 6. Scope & Duplicate Check

All findings are within the in-scope `contracts/` Solidity. F-1, F-3, F-4, F-7 stem from inherited
OZ-Confidential/FHE behaviour but are realized through this project's observer modules and variant
composition, so they are in scope as integration findings. No external Code4rena analyser run was
provided to deduplicate against; no findings are marked `duplicate`.

### Threat disposition (every THREAT_MODEL.md ID)

| Threat ID | Disposition |
|-----------|-------------|
| AC-1 | NOT-A-FINDING — gate complete (F-8), PoC AC-1 |
| AC-2 | NOT-A-FINDING — all hooks bound (F-2), PoC AC-2 |
| AC-3 | NOT-A-FINDING — ENFORCER/FORCED_OPS intentionally separated (by-design) |
| AC-4 | NOT-A-FINDING — `initializer` consumed in constructor; no public/reinit path |
| FHE-1 | **Finding F-1 (Low)** |
| FHE-2 | Finding F-7 (Low) |
| FHE-3 | Finding F-4-adjacent / Info (intentional transfer-granularity) |
| FHE-4 | Finding F-4 (Info) |
| TX-1 | Finding F-3 (Info) |
| TX-2 | Info — documented silent-refund/reentrancy; trusted-receiver only (by-design upstream) |
| TX-3 | Finding F-5 (Info) |
| TX-4 | Info — forced ops intentionally bypass pause/deactivation (by-design) |
| TX-5 | NOT-A-FINDING — invariants hold (F-10) |
| POL-1 | Info — view/enforcement surface divergence inherent to CMTAT (F-6 note) |
| POL-2 | NOT-A-FINDING — allowlist enforced on all paths, PoC POL-2 |
| POL-3 | Finding F-9 (Info) |
| VIEW-1 | Finding F-9 (Info) |
