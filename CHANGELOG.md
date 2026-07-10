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

## 1.0.0 - 2026/07/10

First stable release, incorporating the remediation of the **OpenZeppelin security audit** (v0.3.0 report, June 24 2026): 0 Critical / 0 High, 1 Medium, 2 Low, 5 Notes. Per-finding PR/commit/comment table in `doc/audit/v0.3.0/OpenZeppelin.md`.

**Final audit report:** [`doc/audit/v1.0.0/OpenZeppelin_Audit_Reportv1.0.0.pdf`](./doc/audit/v1.0.0/OpenZeppelin_Audit_Reportv1.0.0.pdf) (OpenZeppelin, July 9 2026) — audit performed on **v0.3.0** (commit `463087c`, 2026-06-12 → 2026-06-24), sponsored by [Zama](https://www.zama.ai/); fixes made and reviewed for **v1.0.0**. Scope was limited to this repository's contracts; the underlying CMTAT, RuleEngine, OpenZeppelin Confidential Contracts, and Zama FHEVM libraries were **not** audited (see the [Security section of the README](./README.md#security)).

### Security

- **M-01 — RuleEngine now screens mint and burn** (`4e559b1`): `CMTATConfidentialRuleEngine` applies RuleEngine validation and notification to issuance and redemption via `_validateMint` / `_validateBurn`, closing the gap where a mint to (or burn from) a non-whitelisted / sanctioned address succeeded while an equivalent `confidentialTransfer` reverted. Following CMTAT v3.3.0, the operator (`_msgSender()`) is forwarded as the `spender` and `address(0)` as the mint/burn leg, exactly as CMTAT's `_mintOverride` / `_burnOverride` do (4-arg `ruleEngine.transferred`); rules must exempt the spender on those legs, as production `RuleWhitelist` does. Forced operations (`forcedTransfer` / `forcedBurn`) intentionally continue to bypass the engine.
- **L-02 — TokenAttribute seeding hardened** (`8eb95f2`): `ERC7984TokenAttributeModule` seeds `name` / `symbol` through a constructor instead of a skippable internal initializer, and `CMTATConfidentialBase` invokes it via the constructor inheritance list — a variant that omits the seed now fails to compile instead of deploying with empty attributes. **Breaking change** for downstream contracts that inherit `ERC7984TokenAttributeModule` directly: they must now pass `(name_, symbol_)` to its constructor.

### Fixed

- **N-04 — Pre-increment in loop** (`28090a8`): `ERC7984TotalSupplyViewModule._updateTotalSupplyObserversAcl` uses `++i` instead of `i++` (marginal gas saving).

### Changed

- **`CMTATConfidentialVersionModule`**: `version()` string updated to `1.0.0`.

### Dependencies

- **`lib/openzeppelin-confidential-contracts` submodule bumped `v0.4.1` → `v0.5.1`** (commit `d237bd9` → `afa97a6`). This is a **backward-compatible** upgrade for this project: no proxy **storage** change and no external API break, so it does **not** trigger a MAJOR bump — the contract version stays **`1.0.0`**. Verified by a clean `hardhat compile` and the full test suite (**440 passing**). Precise impact on our code:
  - **Behaviour change (inherited from `ERC7984._update`, upstream PR #357):** a transfer from an **uninitialized** sender balance (an account that never received tokens) no longer reverts — it now silently transfers `0`, matching the existing insufficient-balance semantics. Previously it reverted with `ERC7984ZeroBalance`.
  - **Removed upstream errors:** `ERC7984ZeroBalance` and `ERC7984InvalidGatewayRequest`. Neither is referenced by this project (verified), so nothing to migrate.
  - **Upstream refactor (no behavioural impact on us):** several `confidentialTransfer*` functions moved from named to explicit returns and relocated `FHE.allowTransient` into `_transferAndCall`. Our overrides delegate via explicit `ERC7984.confidential…` calls and are unaffected.
  - **`ERC7984ObserverAccess`** (the only extension we inherit directly) is unchanged between the two versions.
  - New upstream features shipped in `v0.5.0`/`v0.5.1` (hook-module system, holder/balance cap modules, RWA account recovery, `FHESafeMath.saturatingAdd/Sub`) are **not** integrated.

### Documentation

- **OZ-L-01 — Total-supply delta-inference disclosure** (`de3f439`): documented the cross-publication leak (`|V2 − V1|` recovers a single mint/burn amount) in the `publishTotalSupply` NatSpec, the module docstring, and README operator guidance; also captured in the threat model as FHE-5. Accepted as residual risk — it cannot be *fully* closed in code (a `counter ≥ k` gate would give k-anonymity against outside observers but trade away the transparent, on-demand total supply, since the exact figure could not be published right after a single operation), so the mitigation is operational (aggregate many operations per disclosure; restrict `SUPPLY_PUBLISHER_ROLE` to a multisig/timelock).
- **N-01 — Missing docstrings** (`8d283f6`): NatSpec added to the eight role constants, `version()` (referencing ERC-8303), `supportsInterface`, and the `CMTATConfidential` `confidentialTransfer*` / `decimals` / `name` / `symbol` overrides. Added the ERC-8303 draft specification under `doc/ERCSpecification/`.
- **N-02 — Incomplete docstrings** (`20a87db`): completed `@param` / `@return` documentation on `canTransfer`, `canTransferFrom`, and `setRuleEngine`.
- **N-05 — Misleading documentation** (`104218a`): added the silent-refund-failure warning to both `confidentialTransferFromAndCall` overloads; corrected the `_afterBurn` comment (direct call, empty base hooks) and the `CMTATConfidential` inheritance comments (explicit parent calls, not `super`).
- **N-03 — Floating pragma** (won't fix, by design): retained `^0.8.27` so library consumers keep compiler-version choice; rationale recorded in the remediation response.
- Added `doc/audit/v0.3.0/OpenZeppelin.md` — OpenZeppelin audit remediation response (per-finding PR / commit / comment table).
- Added `doc/audit/v0.3.0/claude-audit/CLAUDE_AUDIT.md` (+ `CLAUDE_AUDIT-feedback.md`) — complementary security audit of the **v0.3.0** contracts (commit `463087c`, same scope as the OpenZeppelin engagement) by Claude (Anthropic) with a set of custom smart-contract security-audit skills: 0 High / 0 Medium, 2 Low (F-1 observer disclosure is an inherent FHEVM ACL trust assumption; F-7 irrevocable ACL), 5 Info, 4 threat areas verified safe; new PoC suite `test/ThreatModel.test.ts` (25 passing).
- **FHE Gotchas (`CLAUDE.md` / `AGENTS.md`)**: extended the "Insufficient / uninitialized balance" row to record that, as of OZ Confidential `v0.5.0` (PR #357), an uninitialized sender balance also transfers `0` silently (previously reverted with the now-removed `ERC7984ZeroBalance`).

### Testing

- Added a regression test `transfer from an uninitialized balance transfers 0 without reverting` in `test/helpers/core-tests.ts` (runs across all four deployment variants) locking in the OZ Confidential `v0.5.0` behaviour so a future library bump cannot silently reintroduce the removed `ERC7984ZeroBalance` revert.
- Added the M-01 regression suite in `test/CMTATConfidentialRuleEngine.test.ts` and the `ScreeningRuleEngineMock` test helper (follows the CMTAT v3.3.0 convention: forwards the operator as spender, exempts the spender on the mint/burn legs like `RuleWhitelist`): blocked/allowed mint and burn, operator-as-spender forwarding, forced-ops bypass, engine-disabled behaviour, and the base freeze layer on top of engine screening. The RuleEngine-variant tests were migrated from the CMTA reference `RuleEngineMock` (whose `RuleSpenderAuthorized` rule does not exempt mint/burn) to this convention-compliant mock.

## 0.3.0

Commit: `463087cf99052235f56818617ac9548295be2f65`

### Added

- **Module interfaces** (`contracts/interfaces/`): Six new NatSpec-documented interfaces — `IERC7984MintModule`, `IERC7984BurnModule`, `IERC7984EnforcementModule`, `IERC7984BalanceViewModule`, `IERC7984PublishTotalSupplyModule`, `IERC7984TotalSupplyViewModule`. Each module contract now inherits its corresponding interface; all events and errors are defined exclusively in the interface (no duplication in the implementation).
- **`foundry.toml`**: Foundry configuration file matching the Hardhat optimizer settings (`optimizer = true`, `optimizer_runs = 200`, `evm_version = "prague"`, `solc = "0.8.34"`). Enables `forge build` as a fast compile check.

### Changed

- **`contracts/deployment/` directory**: The four concrete deployment variants (`CMTATConfidential`, `CMTATConfidentialLite`, `CMTATConfidentialRuleEngine`, `CMTATConfidentialWhitelist`) have been moved from `contracts/` to `contracts/deployment/`. `CMTATConfidentialBase` remains in `contracts/`. Import paths within the moved files have been updated accordingly.
- **ERC-7943 standard errors**: Transfer/mint/burn validation now uses the standard `ERC7943CannotReceive(address)`, `ERC7943CannotSend(address)`, and `ERC7943CannotTransfer(address, address, uint256)` errors instead of the project-local `CMTAT_InvalidTransfer`. `ERC7943CannotSend`/`CannotReceive` are in scope via CMTAT's `ValidationModule`; `IERC7943FungibleTransferError` is explicitly imported in `CMTATConfidentialBase` for `ERC7943CannotTransfer`. **Breaking change** for callers that caught `CMTAT_InvalidTransfer`.
- **Forced-operation error alignment**: `CMTAT_AddressZeroNotAllowed` replaced by `CMTAT_Enforcement_ZeroAddressNotAllowed` (inherited from CMTAT's `EnforcementModuleInternal`, no-arg). A local `CMTAT_AddressNotFrozen(address from)` is kept because CMTAT's `CMTAT_BurnEnforcement_AddressIsNotFrozen()` (no-arg, burn-only, defined in `CMTATBaseCore`) is outside the inheritance chain and lacks an address parameter.

### Documentation

- **`/// @inheritdoc` NatSpec tags**: All public functions in the six FHE module contracts now carry `/// @inheritdoc IERC7984XxxModule`, delegating full NatSpec to the interface.
- **`/** */` comment style in interfaces**: All NatSpec in interface files uses `/** */` blocks (not `///`).

### Added

- **`CMTATConfidentialRuleEngine`** (`0ab6137`): New deployment variant that gates all confidential transfers through a CMTA `IRuleEngine`. Because transfer amounts are encrypted, the RuleEngine always receives `value = 0`; rules can still enforce public restrictions (allowlists, blacklists, spender authorization, timestamps, etc.). Includes `canTransfer` / `canTransferFrom` view functions for ERC-7943 pre-flight checks.
- **`ERC7984RuleEngineModule`** (`0ab6137`): Abstract module encapsulating RuleEngine integration — `setRuleEngine`, `_canTransferByRuleEngine`, `_canTransferFromByRuleEngine`, `_transferredByRuleEngine`, `_transferredFromByRuleEngine`. Gated by `RULE_ENGINE_ROLE`.
- **`CMTATConfidentialWhitelist`** (`e237fea`, `f40068f`, `b08c62d`): New deployment variant enforcing an on-chain allowlist for confidential transfers. When `isAllowlistEnabled()` is true, both sender and recipient must be allowlisted. Overrides `canSend` / `canReceive` to compose CMTAT freeze/pause checks with allowlist policy. Exposes `canTransfer`. Gated by `ALLOWLIST_ROLE`.
- **`lib/RuleEngine`** (`0ab6137`): Added CMTA RuleEngine submodule under `lib/`.
- **ERC-7943 specification** (`e237fea`): Added `doc/ERCSpecification/erc-7943-uRWA.md`.

### Fixed

- **`CMTATConfidentialWhitelist` ERC-165 false claim removed**: An earlier version of this variant returned `true` for `0x3edbb4c4` (`IERC7943Fungible`). This was incorrect: full compliance requires `forcedTransfer(address, address, uint256)`, `setFrozenTokens`, `getFrozenTokens`, and plaintext-amount events — all incompatible with FHE encrypted balances. The contract now delegates `supportsInterface` to `CMTATConfidential` without claiming `0x3edbb4c4`. The view functions `canSend`, `canReceive`, `canTransfer` (with `amount` ignored) and the standard `ERC7943Cannot*` errors remain available as partial ERC-7943 support across all four variants.

### Changed

- **CMTAT submodule relocated** (`0ab6137`): Moved from `CMTAT/` to `lib/CMTAT/` to align all submodules under `lib/`.
- **CMTAT updated to v3.3.0-rc1** (`b08c62d`): Picks up native `canSend` / `canReceive` hooks used by `CMTATConfidentialWhitelist`.
- **`CMTATConfidentialVersionModule`**: version string updated to `"0.3.0"`.

### Documentation

- Added explicit inheritance delegation guideline to `CLAUDE.md` / `AGENTS.md` (`0ab6137`): prefer explicit parent calls (`CMTATConfidential.supportsInterface(...)`) over `super` in multi-inheritance contexts.
- **ERC-7943 partial compliance**: `doc/technical/CMTATConfidentialWhitelist.md` documents which parts of `IERC7943Fungible` are implemented and why full compliance is architecturally impossible with FHE encrypted amounts.
- **Aderyn v0.3.0 static analysis**: 21 contracts (1 276 nSLOC), 0 high, 7 low findings. Full disposition table added to `README.md` and `doc/audit/v0.3.0/aderyn-report-feedback.md`. No production code changes required.

### Added

- **`ERC7984TokenAttributeModule`**: New abstract module enabling post-deployment updates to the token name and symbol via `setName(string)` / `setSymbol(string)`, aligned with the ERC-3643 T-REX standard. Emits `Name(string indexed, string)` and `Symbol(string indexed, string)` — same event signatures as CMTAT's `ERC20BaseModule`. Gated by `TOKEN_ATTRIBUTE_ROLE`. Inherited by all four deployment variants through `CMTATConfidentialBase`.
- **`IERC7984TokenAttributeModule`** (`contracts/interfaces/`): Interface for the new module, extending `IERC3643ERC20Base` for ERC-3643 compatibility.
- **`TOKEN_ATTRIBUTE_ROLE`**: New role (`keccak256("TOKEN_ATTRIBUTE_ROLE")`) controlling `setName` / `setSymbol`. Finer-grained than `DEFAULT_ADMIN_ROLE`, which CMTAT uses for the equivalent functions.

### Documentation

- **`doc/technical/ERC7984TokenAttributeModule.md`**: Technical reference for the new module — storage shadowing design, ERC-3643 alignment table, diamond resolution explanation, security notes.
- **README `Module Reference` table**: New table listing all FHE and CMTAT modules with their role, source file, availability, and purpose — answers "which modules are used and what do they do?"
- **README roles table**: Added `TOKEN_ATTRIBUTE_ROLE`, `EXTRA_INFORMATION_ROLE`, and `DOCUMENT_ROLE` entries.
- **README Contract Functions**: Added `setName`/`setSymbol`, `setTokenId`/`setTerms`/`setInformation`, and document management (`setDocument`/`removeDocument`) subsections.

### Testing

- Added `test/CMTATConfidentialRuleEngine.test.ts` (`0ab6137`): covers rule engine allow/block paths, `setRuleEngine`, `canTransfer` / `canTransferFrom` semantics, and full `runCoreTests()` suite.
- Added `test/CMTATConfidentialWhitelist.test.ts` (`f40068f`): covers allowlist enable/disable, per-address allowlisting, operator path, partial ERC-7943 view functions, negative ERC-165 assertion for `0x3edbb4c4`, and full `runCoreTests()` suite.
- Added `test/CMTATBaseFeatures.test.ts`: 22 tests covering `setTerms`, `setTokenId`, `setInformation`, and full ERC-1643 document management (`setDocument`, `getDocument`, `getAllDocuments`, `removeDocument`, `DocumentUpdated`/`DocumentRemoved` events, access control, role delegation).
- Added `test/ERC7984TokenAttributeModule.test.ts`: 32 tests covering `setName`/`setSymbol` across all four deployment variants (`CMTATConfidential`, `CMTATConfidentialLite`, `CMTATConfidentialRuleEngine`, `CMTATConfidentialWhitelist`).

### Dependencies

- Updated OpenZeppelin Confidential Contracts submodule from `v0.4.0` to `v0.4.1`. The release contains a single bugfix in `BatcherConfidential` (not used by this project); no code changes required.

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
