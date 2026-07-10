# CLAUDE_AUDIT.md (v0.3.0) — Maintainer Feedback

Review of [`CLAUDE_AUDIT.md`](./CLAUDE_AUDIT.md) — complementary security audit of the v0.3.0 contracts (commit
`463087c`) by Claude (Anthropic) with a set of custom smart-contract security-audit skills. Severity uses
Code4rena.

**Outcome:** 10 findings — **2 Low** (F-1, F-7), **5 Info** (F-3, F-4, F-5, F-9, + TX-2/POL-1 notes), **4
NOT-A-FINDING / verified safe** (F-2, F-6, F-8, F-10). No High/Medium; no exploitable issue. Both Low items are
inherent FHEVM/observer trust properties with **no in-code fix** — mitigated by documentation and governance. The
Info items are by-design or documented platform limitations; two carry optional hardening recommendations (F-5
docs, F-9 ABI parity). Each finding is assessed below with verdict, disposition and rationale.

**Branch:** `audit-fix`. The Claude-audit deliverable and its supporting documentation are, at time of writing,
**pending (uncommitted)** on this branch — see [Open / pending items](#open--pending-items).

---

## Triage summary

| ID | Severity | Verdict | Resolution / status |
|----|----------|---------|---------------------|
| F-1 | Low | Accepted — inherent FHEVM ACL trust assumption | No code fix (token-layer gate is ineffective); documented + governance. **Pending** (docs uncommitted) |
| F-7 | Low | Accepted — FHE-platform limitation | No code fix possible; documented in module NatSpec + README |
| F-3 | Info | Accepted — documented FHE limitation | No code change; documented (generic + forced-op decrypt-to-confirm note in README) |
| F-4 | Info | Accepted, by-design | No code change (role-gated, irreversible-per-handle is intentional) |
| F-5 | Info | Accepted, by-design (CMTAT) | No code change; already documented (README "Mint/Burn while paused" rows) |
| F-9 | Info | Accepted | No code change; NatSpec caveats present, `canTransferFrom` ABI parity **open (optional)** |
| F-2 | — | NOT-A-FINDING (verified safe) | No code change (PoC AC-2) |
| F-6 | — | NOT-A-FINDING (+Info POL-1) | No code change (PoC POL-2) |
| F-8 | — | NOT-A-FINDING (verified safe) | No code change (PoC AC-1, POL-2) |
| F-10 | — | NOT-A-FINDING (verified safe) | No code change (PoC TX-5) |

**Counts:** 2 accepted-Low (no code fix) · 4 accepted-Info · 4 verified-safe. Zero fixes required by code; the
actionable output is documentation + operational governance, plus two optional hardening items.

---

## F-1 — Observer can escalate scoped read into global public disclosure — **Low — Accepted (trust assumption)**

**Verdict:** Accepted. Severity re-rated Medium → Low during the audit's own adversarial review (observer already
holds cleartext read by design; residual harm is the non-consensual, irreversible *public* leak by a semi-trusted
role — real but privilege-gated).

**Key correction vs. the report's original recommendation:** the report first recommended overriding
`requestDiscloseEncryptedAmount` at the token layer. On review this was found **ineffective**:
`FHE.makePubliclyDecryptable` merely wraps the ACL system contract's `allowForDecryption`
(`@fhevm/host-contracts/contracts/ACL.sol:209-228`), whose only precondition is `isAllowed(handle, msg.sender)`.
An observer holding ACL can call the ACL contract **directly**, bypassing any token override. There is no
read-only ACL in FHEVM: an ACL grant confers, indivisibly, private read (`userDecrypt`), re-grant to a third
party (`allow`), and public disclosure (`allowForDecryption`). F-1 is therefore an **inherent trust assumption of
the observer model**, not a code-fixable escalation.

**Resolution (no code change):**
- Documented as a trust assumption in [`../F-1.md`](../F-1.md) (Resolution + revised
  Recommendation) and in the README "Balance observers hold indivisible read + disclosure power" limitation.
- Mitigation is governance: restrict `OBSERVER_ROLE` to a multisig/timelock, assign observers sparingly, and
  treat "make an observer" as "grant full disclosure power."
- **PoC:** `test/ThreatModel.test.ts` → "FHE-1" (confirms the escalation).

**Status:** documentation **pending** (uncommitted). Shares its irrevocable-ACL root cause with F-7.

---

## F-7 — Observer removal is not retroactive (irrevocable ACL) — **Low — Accepted (platform limitation)**

**Verdict:** Accepted. Removing an observer stops only *future* `FHE.allow` grants; access to already-granted
handles cannot be revoked. This is an FHE-platform property, not a contract defect.

**Resolution (no code fix possible):** documented in the module NatSpec (`ERC7984BalanceViewModule`,
`ERC7984TotalSupplyViewModule`) and README — observer removal is not retroactive; a compromised observer requires
rotating the underlying ciphertexts, which only happens on the next state change. No regression test applies (no
behaviour to assert beyond the documented limitation). Shares root cause with F-1.

---

## F-3 — Silent zero-transfer / zero-burn on insufficient balance — **Info — Accepted (documented FHE limitation)**

**Verdict:** Accepted. Severity re-rated Low → Info (inherent encrypted-underflow behaviour; no funds at risk; the
`ForcedTransfer`/`ForcedBurn` events emit the actual encrypted handle, so an enforcer must decrypt to learn the
result regardless).

**Resolution:** documented. The silent-zero semantics are covered generically (README "Transfers 0 silently" row
and the FHE-gotchas table in `CLAUDE.md`/`AGENTS.md`), and a **forced-operation-specific** warning was added to
the README "Forced Burn" section: enforcement tooling must decrypt the emitted `transferred`/`burned` handle to
confirm a non-zero amount actually moved, because a successful `ForcedTransfer`/`ForcedBurn` tx can silently move
`0`. **PoC:** `test/ThreatModel.test.ts` → "TX-1".

---

## F-4 — Public disclosure irreversible per handle — **Info — Accepted, by-design**

**Verdict:** Accepted as intended behaviour. `publishTotalSupply` (SUPPLY_PUBLISHER_ROLE) and
`requestDiscloseEncryptedAmount` make a handle world-decryptable permanently; the next mint/burn produces a fresh
non-public handle. Role-gated and intentional. No code change. (Related: the delta-inference channel from
*repeated* total-supply publication is tracked separately as OpenZeppelin L-01 / threat FHE-5.)

---

## F-5 — Mint/burn permitted while paused — **Info — Accepted, by-design (CMTAT)**

**Verdict:** Accepted as standard CMTAT semantics: pause halts *transfers*; supply changes are governed by
*deactivation* (`_canMintBurnByModule` checks `deactivated()` / `isFrozen`, not `paused()`). Gated to trusted
MINTER/BURNER. Severity re-rated Low → Info (spec-conformant, privileged-only, no attacker).

**Resolution:** Already documented — the README "Extended Features" table has explicit **"Mint while paused"** and
**"Burn while paused"** rows, each stating the behaviour is allowed and "(same as CMTAT)". This is the intended
design, not an oversight; no code change and no further documentation required. (Adding `_requireNotPaused()` to
`_validateMint`/`_validateBurn` would make pause halt supply changes, but that is explicitly *not* the intended
CMTAT-parity behaviour.) **PoC:** `test/ThreatModel.test.ts` → "TX-3".

---

## F-9 — Standardized eligibility views can mislead integrators — **Info — Accepted**

**Verdict:** Accepted. The views are non-reverting (good) but carry caveats: `canTransfer` ignores the encrypted
`amount` and assumes a non-delegated spender; `canSend`/`canReceive` reflect freeze/allowlist but **not** pause;
`canTransferFrom` exists only on the RuleEngine variant. All are NatSpec-documented.

**Resolution:** caveats documented. **Open (optional):** the report suggests adding `canTransferFrom` to all
variants for ABI parity and keeping the view caveats prominent. Cosmetic/ergonomic, not a security fix. **PoC:**
`test/ThreatModel.test.ts` → "canSend may return true while canTransfer returns false under pause".

---

## F-2 / F-6 / F-8 / F-10 — NOT-A-FINDING (verified safe)

Reviewed and confirmed safe with executable PoCs; no code change.

- **F-2 — Authorization-hook coverage.** Every `_authorizeX` hook is bound to a concrete role in each deployment
  variant; no abstract hook left unbound. PoC AC-2 (5 privileged functions revert for unauthorized callers).
- **F-6 — RuleEngine selector/policy wiring.** All 8 `confidentialTransfer*` overloads route through the policy
  hook; the RuleEngine variant's `_beforeTransfer` → `ruleEngine.transferred(...)` must revert on invalid
  transfer. PoC POL-2. *Info note POL-1:* enforcement uses `transferred()` while the views use
  `canTransfer`/`canTransferFrom`; integrators must keep a rule's two surfaces consistent (inherent to CMTAT).
- **F-8 — Transfer-gate completeness.** Exactly 8 token-moving externals, all overridden and gated in
  `CMTATConfidentialBase`; only the intentional FORCED_OPS enforcement paths bypass validation. PoC AC-1, POL-2.
- **F-10 — Observer-ACL re-grant invariants.** The `_update` chain and `_afterMint`/`_afterBurn` hooks re-grant
  ACL to holder/role/supply observers after every balance/supply change (incl. the forced-burn diamond path);
  observer count bounded by `maxSupplyObservers`. PoC TX-5.

---

## Open / pending items

**Pending (implemented but uncommitted on `audit-fix`):**

- F-1 trust-assumption documentation — `doc/audit/v0.3.0/F-1.md`, the README observer-disclosure warning, the
  audit overview row + summary, and this feedback file are all in the working tree, **not yet committed**.
- `CLAUDE_AUDIT.md` itself and the CHANGELOG / `AUDIT_OVERVIEW.md` references to it are pending.

**Open optional hardening (cosmetic / ergonomic):**

- **F-9:** provide `canTransferFrom` on all variants for ABI parity.

**No fixes are missing in the "unaddressed vulnerability" sense:** every Low is an inherent FHEVM/observer trust
property with no in-code remedy, and every Info is by-design or a documented platform limitation. The residual
work is (1) committing the pending documentation and (2) the one optional ABI-parity item above.
