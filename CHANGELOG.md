# Changelog

## 0.2.0 - 2026-04-21

Nethermind AuditAgent findings (March 18, 2026) — all addressed.

### Fixed

- **`setRoleObserver` zero-address guard** (`a74314e`): `setRoleObserver` now rejects `address(0)` as `newObserver` with `ERC7984BalanceViewModule_ZeroObserver`; use `removeRoleObserver` to clear an observer (finding #8).
- **Admin-controlled supply observer cap** (`12249c1`): `addTotalSupplyObserver` enforces an on-chain cap (`_maxSupplyObservers`, default 10) to prevent OOG on mint/burn. Cap is adjustable by `DEFAULT_ADMIN_ROLE` via `setMaxSupplyObservers` (findings #4, #7).
- **`forcedBurn` ACL staleness** (`681ebde`): Both `forcedBurn` overloads in `ERC7984EnforcementModule` now call the `_afterBurn` hook after `_burn`, ensuring total-supply observer ACLs are refreshed after a forced burn. Diamond resolution added in `CMTATConfidentialBase` (findings #5, #6).

### Documentation

- **Non-atomic refund warning** (`36dbd3f`): NatSpec added to both `confidentialTransferAndCall` overrides documenting that the refund is non-atomic, the callback fires while the receiver already holds the tokens, and the function must only be used with trusted receiver contracts (findings #1, #2).
- **`address(0)` freeze risk** (`1abe564`): `ENFORCER_ROLE` holders must not freeze `address(0)`; doing so blocks all direct holder transfers. Warning added to README. Upstream fix proposed in [CMTA/CMTAT#372](https://github.com/CMTA/CMTAT/issues/372) and detailed in `FREEZE_ISSUE.md` (finding #3).

## 0.1.0 - 2026-03-16

Commit: `51f9d7aa2e7700784ad0755a75b8e1de8fbf4849`

- Initial CMTAT Confidential release with encrypted balances/transfers (ERC-7984) and CMTAT compliance modules.
- Confidential mint, burn, forced transfer/burn, pause, and freeze flows with FHE ACL enforcement.
- Observer support for balance visibility and total supply disclosure (observer list + public publish).
