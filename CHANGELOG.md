# Changelog

## Semantic Version 2.0.0

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when the new version makes:
   -  Incompatible proxy **storage** change internally or through the upgrade of an external library (OpenZeppelin)
   -  A significant change in external APIs (public/external functions) or in the internal architecture
2. MINOR version when the new version adds functionality in a backward compatible manner
3. PATCH version when the new version makes backward compatible bug fixes

See [https://semver.org](https://semver.org)

## Type of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

Reference: [keepachangelog.com/en/1.1.0/](https://keepachangelog.com/en/1.1.0/)

Custom changelog tag: `Dependencies`, `Documentation`, `Testing`

## Release checklist (mandatory)

Before each release:

1. Update the version string in `contracts/modules/CMTATConfidentialVersionModule.sol`.
2. Run Prettier on Solidity sources:

```bash
npx prettier --write --plugin=prettier-plugin-solidity 'contracts/**/*.sol'
```
3. Run Aderyn static analysis and update:
   - command: `aderyn --output aderyn-report.md`
   - `doc/audit/vX.Y.Z/aderyn-report.md`
   - `doc/audit/vX.Y.Z/aderyn-report-feedback.md`

## 0.2.0

Nethermind AuditAgent findings (March 18, 2026) — all addressed.

### Fixed

- **`setRoleObserver` zero-address guard** (`a74314e`): `setRoleObserver` now rejects `address(0)` as `newObserver` with `ERC7984BalanceViewModule_ZeroObserver`; use `removeRoleObserver` to clear an observer (finding #8).
- **Admin-controlled supply observer cap** (`12249c1`): `addTotalSupplyObserver` enforces an on-chain cap (`_maxSupplyObservers`, default 10) to prevent OOG on mint/burn. Cap is adjustable by `DEFAULT_ADMIN_ROLE` via `setMaxSupplyObservers` (findings #4, #7).
- **`forcedBurn` ACL staleness** (`681ebde`): Both `forcedBurn` overloads in `ERC7984EnforcementModule` now call the `_afterBurn` hook after `_burn`, ensuring total-supply observer ACLs are refreshed after a forced burn. Diamond resolution added in `CMTATConfidentialBase` (findings #5, #6).

### Documentation

- **Non-atomic refund warning** (`36dbd3f`): NatSpec added to both `confidentialTransferAndCall` overrides documenting that the refund is non-atomic, the callback fires while the receiver already holds the tokens, and the function must only be used with trusted receiver contracts (findings #1, #2).
- **`address(0)` freeze risk** (`1abe564`): `ENFORCER_ROLE` holders must not freeze `address(0)`; doing so blocks all direct holder transfers. Warning added to README. Upstream fix proposed in [CMTA/CMTAT#372](https://github.com/CMTA/CMTAT/issues/372) and detailed in `FREEZE_ISSUE.md` (finding #3).

### Dependencies

- Upgraded `@fhevm/solidity` to `0.11.1`.
- Upgraded `@openzeppelin/contracts` to `5.6.1`.
- Upgraded `@openzeppelin/contracts-upgradeable` to `5.6.1`.
- Upgraded `@fhevm/hardhat-plugin` to `0.4.2` (required compatibility with `@fhevm/solidity@0.11.1`).
- Upgraded `@zama-fhe/relayer-sdk` to `0.4.1`.
- Updated OpenZeppelin Confidential Contracts submodule to `v0.4.0`.

### Testing

- `npx hardhat compile` succeeds.
- `npm run test` passes (`177 passing`).

## 0.1.0 - 2026-03-16

Commit: `51f9d7aa2e7700784ad0755a75b8e1de8fbf4849`

- Initial CMTAT Confidential release with encrypted balances/transfers (ERC-7984) and CMTAT compliance modules.
- Confidential mint, burn, forced transfer/burn, pause, and freeze flows with FHE ACL enforcement.
- Observer support for balance visibility and total supply disclosure (observer list + public publish).
