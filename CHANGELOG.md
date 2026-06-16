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

## 0.3.0

### Added

- **Module interfaces** (`contracts/interfaces/`): Six new NatSpec-documented interfaces — `IERC7984MintModule`, `IERC7984BurnModule`, `IERC7984EnforcementModule`, `IERC7984BalanceViewModule`, `IERC7984PublishTotalSupplyModule`, `IERC7984TotalSupplyViewModule`. Each module contract now inherits its corresponding interface; all events and errors are defined exclusively in the interface (no duplication in the implementation).
- **`foundry.toml`**: Foundry configuration file matching the Hardhat optimizer settings (`optimizer = true`, `optimizer_runs = 200`, `evm_version = "prague"`, `solc = "0.8.34"`). Enables `forge build` as a fast compile check.

### Changed

- **ERC-7943 standard errors**: Transfer/mint/burn validation now uses the standard `ERC7943CannotReceive(address)`, `ERC7943CannotSend(address)`, and `ERC7943CannotTransfer(address, address, uint256)` errors instead of the project-local `CMTAT_InvalidTransfer`. `ERC7943CannotSend`/`CannotReceive` are in scope via CMTAT's `ValidationModule`; `IERC7943FungibleTransferError` is explicitly imported in `CMTATConfidentialBase` for `ERC7943CannotTransfer`. **Breaking change** for callers that caught `CMTAT_InvalidTransfer`.
- **Forced-operation error alignment**: `CMTAT_AddressZeroNotAllowed` replaced by `CMTAT_Enforcement_ZeroAddressNotAllowed` (inherited from CMTAT's `EnforcementModuleInternal`, no-arg). A local `CMTAT_AddressNotFrozen(address from)` is kept because CMTAT's `CMTAT_BurnEnforcement_AddressIsNotFrozen()` (no-arg, burn-only, defined in `CMTATBaseCore`) is outside the inheritance chain and lacks an address parameter.

### Documentation

- **`/// @inheritdoc` NatSpec tags**: All public functions in the six FHE module contracts now carry `/// @inheritdoc IERC7984XxxModule`, delegating full NatSpec to the interface.
- **`/** */` comment style in interfaces**: All NatSpec in interface files uses `/** */` blocks (not `///`).

### Added

- **`CMTATConfidentialRuleEngine`** (`0ab6137`): New deployment variant that gates all confidential transfers through a CMTA `IRuleEngine`. Because transfer amounts are encrypted, the RuleEngine always receives `value = 0`; rules can still enforce public restrictions (allowlists, blacklists, spender authorization, timestamps, etc.). Includes `canTransfer` / `canTransferFrom` view functions for ERC-7943 pre-flight checks.
- **`ERC7984RuleEngineModule`** (`0ab6137`): Abstract module encapsulating RuleEngine integration — `setRuleEngine`, `_canTransferByRuleEngine`, `_canTransferFromByRuleEngine`, `_transferredByRuleEngine`, `_transferredFromByRuleEngine`. Gated by `RULE_ENGINE_ROLE`.
- **`CMTATConfidentialWhitelist`** (`e237fea`, `f40068f`, `b08c62d`): New deployment variant enforcing an on-chain allowlist for confidential transfers. When `isAllowlistEnabled()` is true, both sender and recipient must be allowlisted. Overrides `canSend` / `canReceive` to compose CMTAT freeze/pause checks with allowlist policy. Exposes `canTransfer` and advertises `0x3edbb4c4` (ERC-7943 fungible) via ERC-165. Gated by `ALLOWLIST_ROLE`.
- **`lib/RuleEngine`** (`0ab6137`): Added CMTA RuleEngine submodule under `lib/`.
- **ERC-7943 specification** (`e237fea`): Added `doc/ERCSpecification/erc-7943-uRWA.md`.

### Changed

- **CMTAT submodule relocated** (`0ab6137`): Moved from `CMTAT/` to `lib/CMTAT/` to align all submodules under `lib/`.
- **CMTAT updated to v3.3.0-rc1** (`b08c62d`): Picks up native `canSend` / `canReceive` hooks used by `CMTATConfidentialWhitelist`.
- **`CMTATConfidentialVersionModule`**: version string updated to `"0.3.0"`.

### Documentation

- Added explicit inheritance delegation guideline to `CLAUDE.md` / `AGENTS.md` (`0ab6137`): prefer explicit parent calls (`CMTATConfidential.supportsInterface(...)`) over `super` in multi-inheritance contexts.

### Testing

- Added `test/CMTATConfidentialRuleEngine.test.ts` (`0ab6137`): covers rule engine allow/block paths, `setRuleEngine`, `canTransfer` / `canTransferFrom` semantics, and full `runCoreTests()` suite.
- Added `test/CMTATConfidentialWhitelist.test.ts` (`f40068f`): covers allowlist enable/disable, per-address allowlisting, operator path, ERC-7943 view functions, ERC-165 interface advertisement, and full `runCoreTests()` suite.

## 0.2.0

Commit: `99fb89bc1331edaeaf662546dcb81f3acfe7be2e`

Nethermind AuditAgent findings (March 18, 2026) — all addressed.

**Changed**

- Update `CMTAT_CONFIDENTIAL_VERSION` in `CMTATConfidentialVersionModule`to `0.2.0`

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
