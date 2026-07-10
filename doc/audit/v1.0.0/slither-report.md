<!-- ============================================================= -->
<!-- SUMMARY (maintainer-added header — raw Slither output follows) -->
<!-- ============================================================= -->

# Slither Report — v1.0.0 (summary)

- **Tool:** Slither 0.11.5 · compiled via Foundry (solc 0.8.34, prague)
- **Command:** `slither . --checklist --filter-paths "node_modules,lib,test,forge-std,mocks"` (**mocks excluded**)
- **Scope:** production `contracts/` (112 contracts incl. dependencies analyzed; findings below are in project code)
- **Severity tally:** **0 High · 8 Medium · 3 Low · 7 Info**

| Detector | Severity | Instances | Assessment |
|----------|----------|-----------|------------|
| unused-return | Medium | 8 | Not applicable — `FHE.allow` / `FHE.makePubliclyDecryptable` fluent API; the "ignored" return is the same handle, not an error code |
| reentrancy-events | Low | 3 | False positive — the external call is `FHE.allow`/`makePubliclyDecryptable` to the FHE coprocessor (not attacker-controllable); only an event is emitted afterwards, no state at risk |
| dead-code | Informational | 5 | False positive — `_validateMint`/`_validateBurn`/`_afterBurn`/`_validateForcedTransfer`/`_validateForcedBurn` are virtual hooks dispatched through the inheritance chain; Slither does not resolve the override |
| naming-convention | Informational | 1 | Cosmetic — `_TOKEN_DECIMALS` is an `immutable` intentionally styled like a constant |
| unindexed-event-address | Informational | 1 | Cosmetic — `MaxSupplyObserversUpdated` address param is not indexed (optional) |

**Nothing to fix: 0 High/real findings. All Medium/Low are the FHE fluent-API pattern (same root cause as Aderyn L-7); the Info items are false positives or cosmetic.**

Triage & rationale: [`slither-report-feedback.md`](./slither-report-feedback.md) · Overview: [`doc/audit/AUDIT_OVERVIEW.md`](../AUDIT_OVERVIEW.md)

---

**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [unused-return](#unused-return) (8 results) (Medium)
 - [reentrancy-events](#reentrancy-events) (3 results) (Low)
 - [dead-code](#dead-code) (5 results) (Informational)
 - [naming-convention](#naming-convention) (1 results) (Informational)
 - [unindexed-event-address](#unindexed-event-address) (1 results) (Informational)
## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-0
[ERC7984BalanceViewModule.setRoleObserver(address,address)](contracts/modules/ERC7984BalanceViewModule.sol#L48-L74) ignores return value by [FHE.allow(balanceHandle,newObserver)](contracts/modules/ERC7984BalanceViewModule.sol#L70)

contracts/modules/ERC7984BalanceViewModule.sol#L48-L74


 - [ ] ID-1
[ERC7984BalanceViewModule._update(address,address,euint64)](contracts/modules/ERC7984BalanceViewModule.sol#L123-L150) ignores return value by [FHE.allow(confidentialBalanceOf(from),fromRoleObs)](contracts/modules/ERC7984BalanceViewModule.sol#L141)

contracts/modules/ERC7984BalanceViewModule.sol#L123-L150


 - [ ] ID-2
[ERC7984BalanceViewModule._update(address,address,euint64)](contracts/modules/ERC7984BalanceViewModule.sol#L123-L150) ignores return value by [FHE.allow(confidentialBalanceOf(to),toRoleObs)](contracts/modules/ERC7984BalanceViewModule.sol#L145)

contracts/modules/ERC7984BalanceViewModule.sol#L123-L150


 - [ ] ID-3
[ERC7984TotalSupplyViewModule.addTotalSupplyObserver(address)](contracts/modules/ERC7984TotalSupplyViewModule.sol#L78-L99) ignores return value by [FHE.allow(ts,observer)](contracts/modules/ERC7984TotalSupplyViewModule.sol#L95)

contracts/modules/ERC7984TotalSupplyViewModule.sol#L78-L99


 - [ ] ID-4
[ERC7984BalanceViewModule._update(address,address,euint64)](contracts/modules/ERC7984BalanceViewModule.sol#L123-L150) ignores return value by [FHE.allow(transferred,toRoleObs)](contracts/modules/ERC7984BalanceViewModule.sol#L147)

contracts/modules/ERC7984BalanceViewModule.sol#L123-L150


 - [ ] ID-5
[ERC7984BalanceViewModule._update(address,address,euint64)](contracts/modules/ERC7984BalanceViewModule.sol#L123-L150) ignores return value by [FHE.allow(transferred,fromRoleObs)](contracts/modules/ERC7984BalanceViewModule.sol#L142)

contracts/modules/ERC7984BalanceViewModule.sol#L123-L150


 - [ ] ID-6
[ERC7984PublishTotalSupplyModule.publishTotalSupply()](contracts/modules/ERC7984PublishTotalSupplyModule.sol#L47-L54) ignores return value by [FHE.makePubliclyDecryptable(ts)](contracts/modules/ERC7984PublishTotalSupplyModule.sol#L52)

contracts/modules/ERC7984PublishTotalSupplyModule.sol#L47-L54


 - [ ] ID-7
[ERC7984TotalSupplyViewModule._updateTotalSupplyObserversAcl()](contracts/modules/ERC7984TotalSupplyViewModule.sol#L148-L154) ignores return value by [FHE.allow(ts,_supplyObservers[i])](contracts/modules/ERC7984TotalSupplyViewModule.sol#L152)

contracts/modules/ERC7984TotalSupplyViewModule.sol#L148-L154


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-8
Reentrancy in [ERC7984BalanceViewModule.setRoleObserver(address,address)](contracts/modules/ERC7984BalanceViewModule.sol#L48-L74):
	External calls:
	- [FHE.allow(balanceHandle,newObserver)](contracts/modules/ERC7984BalanceViewModule.sol#L70)
	Event emitted after the call(s):
	- [RoleObserverSet(account,oldObserver,newObserver,msg.sender)](contracts/modules/ERC7984BalanceViewModule.sol#L73)

contracts/modules/ERC7984BalanceViewModule.sol#L48-L74


 - [ ] ID-9
Reentrancy in [ERC7984TotalSupplyViewModule.addTotalSupplyObserver(address)](contracts/modules/ERC7984TotalSupplyViewModule.sol#L78-L99):
	External calls:
	- [FHE.allow(ts,observer)](contracts/modules/ERC7984TotalSupplyViewModule.sol#L95)
	Event emitted after the call(s):
	- [TotalSupplyObserverAdded(observer,msg.sender)](contracts/modules/ERC7984TotalSupplyViewModule.sol#L98)

contracts/modules/ERC7984TotalSupplyViewModule.sol#L78-L99


 - [ ] ID-10
Reentrancy in [ERC7984PublishTotalSupplyModule.publishTotalSupply()](contracts/modules/ERC7984PublishTotalSupplyModule.sol#L47-L54):
	External calls:
	- [FHE.makePubliclyDecryptable(ts)](contracts/modules/ERC7984PublishTotalSupplyModule.sol#L52)
	Event emitted after the call(s):
	- [TotalSupplyPublished(msg.sender)](contracts/modules/ERC7984PublishTotalSupplyModule.sol#L53)

contracts/modules/ERC7984PublishTotalSupplyModule.sol#L47-L54


## dead-code
Impact: Informational
Confidence: Medium
 - [ ] ID-11
[ERC7984EnforcementModule._afterBurn(address,euint64)](contracts/modules/ERC7984EnforcementModule.sol#L166) is never used and should be removed

contracts/modules/ERC7984EnforcementModule.sol#L166


 - [ ] ID-12
[ERC7984EnforcementModule._validateForcedBurn(address)](contracts/modules/ERC7984EnforcementModule.sol#L148-L151) is never used and should be removed

contracts/modules/ERC7984EnforcementModule.sol#L148-L151


 - [ ] ID-13
[ERC7984BurnModule._validateBurn(address)](contracts/modules/ERC7984BurnModule.sol#L70-L73) is never used and should be removed

contracts/modules/ERC7984BurnModule.sol#L70-L73


 - [ ] ID-14
[ERC7984EnforcementModule._validateForcedTransfer(address,address)](contracts/modules/ERC7984EnforcementModule.sol#L136-L142) is never used and should be removed

contracts/modules/ERC7984EnforcementModule.sol#L136-L142


 - [ ] ID-15
[ERC7984MintModule._validateMint(address)](contracts/modules/ERC7984MintModule.sol#L67-L70) is never used and should be removed

contracts/modules/ERC7984MintModule.sol#L67-L70


## naming-convention
Impact: Informational
Confidence: High
 - [ ] ID-16
Variable [CMTATConfidentialBase._TOKEN_DECIMALS](contracts/CMTATConfidentialBase.sol#L60) is not in mixedCase

contracts/CMTATConfidentialBase.sol#L60


## unindexed-event-address
Impact: Informational
Confidence: High
 - [ ] ID-17
Event [IERC7984TotalSupplyViewModule.MaxSupplyObserversUpdated(uint256,uint256,address)](contracts/interfaces/IERC7984TotalSupplyViewModule.sol#L33-L37) has address parameters but no indexed parameters

contracts/interfaces/IERC7984TotalSupplyViewModule.sol#L33-L37


