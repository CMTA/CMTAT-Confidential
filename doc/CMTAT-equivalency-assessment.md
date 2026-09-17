# CMTAT Equivalency Assessment Criteria

## Table of Contents

- [Document Version](#document-version)
- [Metadata](#metadata)
- [How to Use This Document](#how-to-use-this-document)
- [General Note](#general-note)
- [Warning](#warning)
- [Summary](#summary)
  - [Scope of the count](#scope-of-the-count)
  - [Answer values](#answer-values)
  - [Compliance table](#compliance-table)
- [CMTAT Function Equivalency Table](#cmtat-function-equivalency-table)
  - [Token Attributes](#token-attributes)
    - [Token module](#token-module)
  - [Pause module (mandatory)](#pause-module-mandatory)
    - [Enforcement](#enforcement)
    - [Transfer restriction (optional)](#transfer-restriction-optional)
    - [Access Control](#access-control)
    - [Snapshot (optional)](#snapshot-optional)
    - [Dividend (optional)](#dividend-optional)
    - [Credit Events (optional)](#credit-events-optional)
  - [Debt (optional)](#debt-optional)
- [Guideline for New Blockchain Implementations](#guideline-for-new-blockchain-implementations)
  - [Freeze](#freeze)
  - [Restriction (optional)](#restriction-optional)
  - [Version](#version)
  - [CMTAT Extended](#cmtat-extended)
  - [Forced Burn and Forced Transfer](#forced-burn-and-forced-transfer)
  - [Implementation Details](#implementation-details)
  - [Self-Burn](#self-burn)
  - [Cross-Chain Bridge Support](#cross-chain-bridge-support)
  - [Privacy and Confidentiality](#privacy-and-confidentiality)
- [Supplementary features](#supplementary-features)
- [Conclusion](#conclusion)
- [Reference](#reference)

## Document Version

Two distinct versions MUST be distinguished: the version of **this template**, as published by CMTA, and the version of the **filled assessment** produced for the implementation being approved.

| Version | Value |
|---|---|
| Template version — this document, as published by CMTA; pre-filled, MUST NOT be modified by the author of an assessment | `v0.3.0` |
| Assessment version — the filled document, set by its author | `v0.1.0` |

> Every assessment MUST fill this table, so that it records both the template it originates from and its own version. Only the second row is for the author to complete: the template version above is pre-filled and MUST be carried over unchanged, since an assessment is produced by filling a copy of this document and the value above **is** the version it was filled from.
>
> An assessment written as a separate report, which reproduces the criteria instead of filling this file, MUST reproduce this table with it.
>
>  The two numbers are independent: a filled assessment MAY be revised — for example after a new release of the implementation being approved — without any change to the template, and a new template version MAY be published without the existing assessments being refilled.
>
> Note:
>
> - versions with the `rc` suffix are draft versions.
> - version before `1.0` are also draft versions
> - both notes above apply to the template version and to the assessment version.
> - the template version MUST always be recorded next to the assessment version: criteria IDs are sequential over the whole document and MAY be renumbered from one template version to the next, so an answer given against an earlier template cannot be read against a later one without checking the [changelog](CHANGELOG.md).

## Metadata

This section identifies the implementation being assessed. It MUST be completed before the [CMTAT Function Equivalency Table](#cmtat-function-equivalency-table), together with the assessment version in [Document Version](#document-version).

| Field | Value |
|---|---|
| Implementation name | CMTAT Confidential — `CMTATConfidential` (reference variant) and its deployment variants `CMTATConfidentialLite`, `CMTATConfidentialRuleEngine`, `CMTATConfidentialWhitelist` |
| Target blockchain or distributed ledger | Ethereum and EVM chains supported by the Zama Confidential Blockchain Protocol (FHEVM coprocessor, `ZamaEthereumConfig`) |
| Implementation language | Solidity `^0.8.27` (compiled with `0.8.34`, EVM `prague`), built on OpenZeppelin Confidential Contracts (ERC-7984) and the CMTAT Solidity modules |
| Implementation version | `1.0.0` (returned by `version()`) |
| Source repository and commit | https://github.com/CMTA/CMTAT-Confidential — tag `v1.0.0`, commit `285ed93721dfbbc147932bd450aa057126e70e84` |
| Assessment date | 2026-09-17 |
| Assessed by | Ryan Sauge (Taurus SA), maintainer of the implementation |

The *Implementation version* is the version of the token implementation itself, as returned by criterion 6 when that criterion is supported. It is neither the assessment version nor the template version.

## How to Use This Document

- Fill the document in this order: **CMTAT Function Equivalency Table** first, then **Summary**, then **Conclusion**.
- Before starting, fill **[Metadata](#metadata)** — what is being assessed — and the assessment version in **[Document Version](#document-version)**, next to the template version the assessment is filled from.
- Use the **CMTAT Function Equivalency Table** as the fillable assessment checklist. Each criterion MUST be answered with `y`, `partial`, or `n` in the *Present in implementation being approved* column (see [Answer values](#answer-values)).
- Use the **Summary** to give the aggregated compliance result of the implementation being approved with the CMTAT standard.
- Use the **Conclusion** to describe, in broad terms, how the implementation being approved works and where it differs from CMTAT.
- Use **Guideline for New Blockchain Implementations** as reference guidance when designing or mapping non-Solidity implementations.

## General Note

- The listed functionalities are the **minimal set** required for each module.
- The key words "MUST", "MUST NOT", "REQUIRED", "SHOULD", and "MAY" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/info/rfc2119) and [RFC 8174](https://www.rfc-editor.org/info/rfc8174).

## Warning

An implementation MAY satisfy the CMTAT standard while still failing to meet the criteria required for tokenized shares under Swiss law at the underlying-ledger level. In particular, compliance with CMTAT does not, by itself, demonstrate that decentralization-related legal criteria are satisfied.

## Summary

> This section MUST be completed **after** the [CMTAT Function Equivalency Table](#cmtat-function-equivalency-table). It summarizes the compliance of the implementation being approved with the CMTAT standard.

### Scope of the count

The equivalency table contains **61 numbered criteria**:

| Category | Count | IDs |
|---|---:|---|
| Mandatory | 19 | 1–3, 7–11, 14–21, 29–31 |
| Optional | 42 | 4–6, 12–13, 22–28, 32–61 |

Each criterion MUST be counted exactly once. The non-numbered tables ([CMTAT Extended](#cmtat-extended), [Implementation Details](#implementation-details), [Cross-Chain Bridge Support](#cross-chain-bridge-support), [Restriction](#restriction-optional), [Privacy and Confidentiality](#privacy-and-confidentiality)) are **not** part of this count; they SHOULD be commented in the [Conclusion](#conclusion) instead.

### Answer values

Each criterion MUST be answered with exactly one of the following values in the *Present in implementation being approved* column:

| Value | Meaning |
|---|---|
| `y` | **Present** — an equivalent feature exists and covers the requirement, even if the name, the signature, or the chain-level mechanism differs from CMTAT Solidity. |
| `partial` | **Partial** — an equivalent feature exists but covers only a part of the requirement, or covers it with a restriction, a different access control model, or different semantics. |
| `n` | **Absent** — no equivalent feature is available in the implementation being approved. |

### Compliance table

| Answer         | Mandatory (19) | Optional (42) |
| -------------- | -------------: | ------------: |
| Present (`y`)  |             17 |             6 |
| Partial        |              2 |             1 |
| Absent (`n`)   |              0 |            35 |

Each column MUST sum to its total: 19 for mandatory criteria, 42 for optional criteria.

An implementation SHOULD be considered equivalent to CMTAT only if **no mandatory criterion is answered `n`**. Any mandatory criterion answered `partial` MUST be justified in the note below.

#### Note

> This subsection MUST explain the figures given in the compliance table, and in particular:
>
> - **every `partial` answer**: which part of the requirement is covered, which part is not, and why (chain-level limitation, legal or business choice, different access control model, feature planned for a later version);
> - **every mandatory `n` answer**: why the requirement cannot be met, and what compensating measure (if any) exists;
> - **optional modules left out by design**: when a whole optional module (for example Dividend, Debt, or Snapshot) is answered `n`, it SHOULD be stated once here rather than criterion by criterion.
>
> Example of an entry:
>
> > *Criterion 17 (Deactivate contract) — Partial: the implementation permanently blocks all transfers and mints, but the account itself cannot be deleted from the ledger, since the chain runtime does not allow it. The deactivated state is irreversible and publicly readable.*

<details><summary>Example of a filled compliance table</summary>

| Answer         | Mandatory (19) | Optional (42) |
| -------------- | -------------: | ------------: |
| Present (`y`)  |             16 |             7 |
| Partial        |              3 |             4 |
| Absent (`n`)   |              0 |            31 |

</details>

**Compliance result.** No mandatory criterion is answered `n`. Two mandatory criteria are `partial`, both for the same reason: the token state they read is encrypted.

- *Criterion 7 (Know total supply) — Partial:* `confidentialTotalSupply()` exists and is public, but it returns an FHE ciphertext handle. The plaintext is readable only by an address holding an FHE ACL grant on the current handle. The issuer obtains it by registering observers (`SUPPLY_OBSERVER_ROLE`, every variant except Lite), and can make it public at any time with `publishTotalSupply()` (`SUPPLY_PUBLISHER_ROLE`, all variants). The requirement is therefore covered with a read restriction that is the purpose of the implementation, not a chain limitation.
- *Criterion 8 (Know balance) — Partial:* `confidentialBalanceOf()` likewise returns a handle. The holder always has access; the issuer or a regulator obtains it per account through the role observer slot (`OBSERVER_ROLE`, `setRoleObserver`), which also carries the amount of every subsequent transfer. There is no way to read every balance at once without assigning an observer to every account.
- *Criterion 13 (Approve) — Partial:* ERC-7984 replaces the ERC-20 amount allowance with a time-bounded operator (`setOperator(operator, until)`), because an allowance amount cannot be compared with an encrypted transfer amount. Delegated transfer is available (`confidentialTransferFrom`), but not the "specific amount" part of the requirement.

**Optional modules left out by design:**

- *Snapshot (32–37), Dividend (38–43), Credit Events (44–47) and Debt (48–49, 51–61)* are not implemented. Snapshot and dividend would require computing on encrypted balances; Debt and Credit Events are plaintext metadata modules that were simply not included in v1.0.0. Criterion 50 is answered `y` because `tokenId()` and `terms().doc.documentHash` are provided by the always-present `ExtraInformationModule`.
- *Partial freeze (23–25)* cannot be offered on `euint64` balances without an encrypted comparison on every transfer.
- *Conditional transfer (26–27)* is not offered; the RuleEngine hook exists but passes `value = 0`, so an approval could not be tied to an amount.
- *User-approved cancellation (12)* is not offered: `burn` ignores the operator approval.

The non-numbered tables are commented in the [Conclusion](#conclusion).


## CMTAT Function Equivalency Table

### Token Attributes

#### Mandatory
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 1 | Name attribute | ERC20 `name` | Public (`view`) |  | y | Public (`view`) | `name()` — `ERC7984TokenAttributeModule` shadows the ERC-7984 name. Set at construction; updatable post-deployment with `setName(string)` by `TOKEN_ATTRIBUTE_ROLE` (ERC-3643 alignment), emits `Name`. |
| 2 | Reference to legally required documentation | `terms` | Public (`view`) |  | y | Read: public (`view`); write: `EXTRA_INFORMATION_ROLE` | `terms()` returns `CMTATTerms` (name, `uri`, `documentHash`, `lastModified`) from CMTAT `ExtraInformationModule`. Set at construction (`ExtraInformationAttributes.terms`) and updatable with `setTerms(DocumentInfo)`. Further documents through ERC-1643 `setDocument` / `getDocument` / `getAllDocuments` (`DOCUMENT_ROLE`). |
| 3 | Decimals (no fractions by default) | ERC20 `decimals` | Public (`view`) | - Decimals MUST be set to zero unless governing law permits fractions.<br />- The value MUST be readable, since a holder cannot interpret a balance without it.<br />- CMTAT Solidity allows configurable decimals at deployment | y | Public (`view`) | `decimals()` returns an `immutable` set by the constructor argument `decimals_`. `0` is allowed; values above 18 revert with `CMTAT_DecimalsTooHigh` because balances are `euint64` (max 18 446 744 073 709 551 615 raw units). `6` is the recommended default (max supply ≈ 18.4 × 10¹² tokens). |

For CMTAT reference implementations, decimals SHOULD be configurable rather than defaulting to zero, to support use cases beyond tokenized shares in Switzerland.

##### Note

> This subsection can be used to detail how mandatory token attributes are implemented and to document specific legal, business, or chain-specific cases.

`name()` and `symbol()` are served by `ERC7984TokenAttributeModule`, which shadows the immutable ERC-7984 fields so that they can be updated post-deployment by `TOKEN_ATTRIBUTE_ROLE` (ERC-3643 `setName` / `setSymbol` alignment). `terms()` is the CMTAT `CMTATTerms` structure, initialised from the constructor's `ExtraInformationAttributes` and updatable by `EXTRA_INFORMATION_ROLE`. `decimals()` is an `immutable`: the constructor rejects values above 18 (`CMTAT_DecimalsTooHigh`) because an `euint64` balance could not hold a single token. A deployment for Swiss tokenized shares SHOULD pass `0`; the project recommends `6` for other use cases (≈ 18.4 × 10¹² tokens of headroom).


#### Optional
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 4 | Ticker symbol attribute | ERC20 `symbol` | Public (`view`) | Optional in the CMTA framework, which lists the attribute as "Ticker symbol (optional)". | y | Public (`view`) | `symbol()`; updatable with `setSymbol(string)` by `TOKEN_ATTRIBUTE_ROLE`, emits `Symbol`. |
| 5 | Token ID attribute | `tokenId` | Public (`view`) | Optional parameter. | y | Read: public (`view`); write: `EXTRA_INFORMATION_ROLE` | `tokenId()` / `setTokenId(string)` from CMTAT `ExtraInformationModule`; set at construction. |
| 6 | Version attribute | `version()` (`IERC3643Version`, implemented by `VersionModule`) | Public (`view`) | Returns the version of the token implementation, for example `"3.2.0"`. In CMTAT Solidity the value is a constant of the contract code: it changes only through a new deployment or an upgrade, and it is not settable at runtime. | y | Public (`view`) | `version()` returns the compile-time constant `"1.0.0"` (`CMTATConfidentialVersionModule`, overriding CMTAT `VersionModule`); semantic versioning, ERC-8303 format. Non-upgradeable contracts, so the value can only change through a new deployment. |

An official CMTAT implementation SHOULD provide a ticker symbol (criterion 4): every CMTA reference implementation carries one, and a symbol SHOULD be set wherever the token is intended to be held in a wallet or admitted to trading.

For CMTAT reference implementations, `tokenId` and `version` SHOULD both be included.

##### Note

> This subsection can be used to detail optional token attributes implemented by the target system and to explain specific cases where an optional field is omitted or represented differently.

All three optional attributes are present. `tokenId()` follows the CMTAT `ExtraInformationModule` (`EXTRA_INFORMATION_ROLE`). `version()` is pinned to `"1.0.0"` by `CMTATConfidentialVersionModule` — see [Version](#version). `information()` (free-text metadata) and ERC-1643 documents (`setDocument`, `removeDocument`, `getDocument`, `getAllDocuments`, `DOCUMENT_ROLE`) are also available; `contractURI()` is inherited from ERC-7984.


#### Token module

##### Mandatory

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 7 | Know total supply | ERC20 `totalSupply` | Public (`view`) |  | partial | Handle: public (`view`). Plaintext: FHE-ACL holders — the contract, observers registered by `SUPPLY_OBSERVER_ROLE`, everyone after `SUPPLY_PUBLISHER_ROLE` publishes | `confidentialTotalSupply()` returns an `euint64` ciphertext handle, not a plaintext. Decryption (through the Zama KMS) requires an ACL grant: (a) observers registered with `addTotalSupplyObserver` (`ERC7984TotalSupplyViewModule`, every variant except Lite; ACL re-granted after each mint/burn, cap `maxSupplyObservers`); (b) anyone, once `publishTotalSupply()` (`ERC7984PublishTotalSupplyModule`, all variants) has marked the *current* handle publicly decryptable — irrevocable for that handle, must be repeated after the next mint/burn. |
| 8 | Know balance | ERC20 `balanceOf` | Public (`view`) |  | partial | Handle: public (`view`). Plaintext: the holder, the holder's observer (`setObserver`), the role observer set by `OBSERVER_ROLE` (`setRoleObserver`) | `confidentialBalanceOf(account)` returns an `euint64` handle. On every balance update ERC-7984 grants ACL to the holder; `ERC7984ObserverAccess` to the holder-designated observer; `ERC7984BalanceViewModule` to the role observer. `setRoleObserver` also grants access to the current handle immediately. ACL grants are permanent; removing an observer only stops future grants. |
| 9 | Transfer tokens | ERC20 `transfer` | Token holder (`msg.sender`) |  | y | Token holder (`msg.sender`) or an operator approved by the holder (`setOperator`) | `confidentialTransfer(to, externalEuint64, inputProof)` and `confidentialTransfer(to, euint64)`, plus `confidentialTransferFrom*` and `*AndCall` overloads (8 entry points). The amount is an encrypted input with a ZKPoK. Every overload is gated by `_canTransferGenericByModule` (pause; frozen sender, receiver and spender; allowlist or RuleEngine in the variants) and reverts with `ERC7943CannotTransfer(from, to, 0)`. An amount above the balance does not revert: `FHESafeMath` transfers 0 (privacy-preserving). `ConfidentialTransfer(from, to, encryptedAmount)` is emitted. |
| 10 | Create tokens | `mint` / `batchMint` | Role-restricted (issuer/minter authorized) |  | y | `MINTER_ROLE` | `mint(to, externalEuint64, inputProof)` / `mint(to, euint64)` (`ERC7984MintModule`). Reverts if `to` is frozen (`ERC7943CannotReceive`) or the contract is deactivated; allowed while paused. RuleEngine variant screens the mint leg (`canTransferFrom(minter, address(0), to, 0)`); Whitelist variant requires `to` allowlisted. No `batchMint`. Emits `Mint(minter, to, encryptedAmount)`. |
| 11 | Cancel tokens | `burn` / `batchBurn` / `burnFrom` | Role-restricted (issuer/burner authorized) | Implementations SHOULD use a dedicated issuer/authorized burn path for forced cancellation scenarios. | y | `BURNER_ROLE` | `burn(from, externalEuint64, inputProof)` / `burn(from, euint64)` (`ERC7984BurnModule`). Reverts if `from` is frozen (`ERC7943CannotSend`) or the contract is deactivated; allowed while paused. An amount above the balance burns 0 silently. Dedicated forced cancellation from a frozen address: `forcedBurn` (`FORCED_OPS_ROLE`, criterion 22 note). No `batchBurn`, no `burnFrom`. Emits `Burn(burner, from, encryptedAmount)`. |
#### Optional

| ID   | Requirement | CMTAT Solidity corresponding feature            | Access Control (CMTAT Solidity) | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 12   | User-approved cancellation | `burnFrom(address account, uint256 value)` | Role-restricted (`BURNER_FROM_ROLE`) **and** an ERC-20 allowance granted by the token holder | The token holder authorizes the cancellation with an `approve`, and the issuer, or an address it has authorized such as a bridge, performs it. It lets the issuer distinguish a cancellation made to manage supply from one made to carry out a court order. Cancellation by the issuer alone is criterion 11; cancellation by the holder alone is not offered by default — see [Self-Burn](#self-burn). | n | — | No `burnFrom` bound to a holder allowance. The ERC-7984 operator approval (`setOperator`) is not consulted by `burn`: cancellation is performed by `BURNER_ROLE` alone (criterion 11) or by `FORCED_OPS_ROLE` on a frozen address (`forcedBurn`). |
| 13   | Approve     | ERC20 `approve(address spender, uint256 value)` | Token holder                    | Grants a delegate permission to transfer a specific amount of tokens from the token account. This is optional, but implementations SHOULD include it since secondary market capability may depend on delegated approval to automate trading and settlement for regulated entities. Issuers SHOULD consult relevant trading and settlement venues if listing is contemplated. | partial | Token holder (`setOperator(operator, until)`) | ERC-7984 has no per-amount allowance because amounts are encrypted. The holder designates an operator with an expiry timestamp; until then the operator can move *any* amount with `confidentialTransferFrom` / `confidentialTransferFromAndCall`. `isOperator(holder, spender)` is public, `OperatorSet` is emitted. The operator is the `spender` in the transfer checks: a frozen or non-allowlisted operator blocks the transfer. |

##### Note

> This subsection can be used to detail how each mandatory function is implemented, including role model, execution flow, and specific chain-level behavior.

**Encrypted state.** The token primitive is ERC-7984 (OpenZeppelin Confidential Contracts v0.5.1): balances and total supply are `euint64` ciphertext handles stored on-chain, computed by the Zama FHEVM coprocessor. Amounts enter the contract as `externalEuint64` inputs with a zero-knowledge proof of knowledge (`inputProof`), or as an existing `euint64` handle the caller is allowed to use (`FHE.isAllowed`). Every arithmetic operation produces a new handle, so read access (FHE ACL) has to be re-granted on every update — this is what the observer modules do.

**Mint and burn.** `mint` and `burn` are provided by `ERC7984MintModule` / `ERC7984BurnModule`; each has an authorization hook (`_authorizeMint` → `MINTER_ROLE`, `_authorizeBurn` → `BURNER_ROLE`) and a validation hook overridden in `CMTATConfidentialBase` to apply the CMTAT checks (deactivated contract, frozen account, and allowlist or RuleEngine in the variants). Both are allowed while paused, as in CMTAT Solidity. A burn larger than the balance burns 0 rather than reverting: the comparison is encrypted and cannot trigger an EVM revert.

**Transfer.** The eight ERC-7984 transfer entry points are overridden in `CMTATConfidentialBase` to run `_canTransferGenericByModule(spender, from, to)` first (revert `ERC7943CannotTransfer(from, to, 0)`), then the `_beforeTransfer` hook (RuleEngine notification in the RuleEngine variant), then the ERC-7984 implementation. `confidentialTransferAndCall` variants credit the receiver before its callback and attempt a best-effort refund if the callback returns `false`; they SHOULD only be used with trusted receivers.

**Total supply.** Two complementary disclosure paths exist: `publishTotalSupply()` (`SUPPLY_PUBLISHER_ROLE`, all variants) makes the current supply handle publicly decryptable; `addTotalSupplyObserver` (`SUPPLY_OBSERVER_ROLE`, all variants except Lite) registers up to `maxSupplyObservers` addresses that are re-granted access after every mint or burn.


### Pause module (mandatory)

| ID   | Requirement         | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity)           | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 14   | Pause tokens        | `pause`                              | Role-restricted (pauser/admin authorized) | Pause must prevent all transfers until `unpause` is called.  | y | `PAUSER_ROLE` | `pause()` (CMTAT `PauseModule`). Blocks all 8 `confidentialTransfer*` overloads, including operator and `AndCall` variants (`_canTransferStandardByModule`). `mint`, `burn`, `forcedTransfer` and `forcedBurn` remain available (see [Implementation Details](#implementation-details)). |
| 15   | Unpause tokens      | `unpause`                            | Role-restricted (pauser/admin authorized) |                                                              | y | `PAUSER_ROLE` | `unpause()`; reverts with `CMTAT_PauseModule_ContractIsDeactivated` once the contract is deactivated. |
| 16   | Know pause status   | `paused()`                           | Public (`view`)                           | Any person MUST be able to determine whether the token is paused; a pause that cannot be read leaves a holder unable to tell why a transfer was refused. | y | Public (`view`) | `paused()`. |
| 17   | Deactivate contract | `deactivateContract`                 | Role-restricted (admin authorized)        | Must permanently disable the token (except in upgradeability patterns where deactivation behavior is explicitly defined). | y | `DEFAULT_ADMIN_ROLE` | `deactivateContract()`: requires the contract to be paused, sets an irreversible flag, emits `Deactivated`. The contracts are not upgradeable (constructor + `initializer`), so the state is permanent. Once deactivated: transfers stay blocked (cannot unpause), `mint` / `burn` revert (`_canMintBurnByModule`). `forcedTransfer` / `forcedBurn` from a frozen address remain available for enforcement, as in CMTAT Solidity. |
| 18   | Know deactivate status | `deactivated()`                   | Public (`view`)                           | Any person MUST be able to determine whether the token has been deactivated. In CMTAT Solidity the function is declared by the draft `IERC8343` interface. | y | Public (`view`) | `deactivated()`. |

##### Note

> This subsection can be used to detail how each mandatory function is implemented, including role model, execution flow, and specific chain-level behavior.

Pause, unpause, deactivation and their view functions are inherited unchanged from the CMTAT `PauseModule` (OpenZeppelin `PausableUpgradeable`). `pause()` blocks every `confidentialTransfer*` overload, including operator transfers and the `AndCall` variants; it does not block `mint`, `burn`, `forcedTransfer` or `forcedBurn`. `deactivateContract()` requires the paused state, is irreversible because the contracts are not upgradeable, and additionally blocks `mint` and `burn` through `_canMintBurnByModule`. Forced operations from a frozen address remain possible after deactivation so that court orders can still be executed.


#### Enforcement

#### Mandatory

| ID   | Requirement | CMTAT Solidity corresponding feature                         | Access Control (CMTAT Solidity)               | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 19   | Freeze      | `freeze` or `setAddressFrozen(true)` *(inferred from extracted PDF text)* | Role-restricted (compliance/admin authorized) | Must block transfers to and from a given address. Single-function implementations are acceptable if they set a frozen status. | y | `ENFORCER_ROLE` | `setAddressFrozen(account, true)`, `setAddressFrozen(account, true, data)` and `batchSetAddressFrozen(accounts, freezes)` (CMTAT `EnforcementModule`, ERC-3643 compatible). A frozen address can neither send, receive nor act as operator; mint to and burn from a frozen address revert. Emits `AddressFrozen`. `address(0)` MUST NOT be frozen (it would block every mint and burn). |
| 20   | Unfreeze    | `unfreeze` or `setAddressFrozen(false)` *(inferred from extracted PDF text)* | Role-restricted (compliance/admin authorized) | Single-function implementations are acceptable if they clear a frozen status. | y | `ENFORCER_ROLE` | Same functions with `freeze = false`. |
| 21   | Know frozen status | `isFrozen(address account)` | Public (`view`) | Any person MUST be able to determine whether a given address is frozen. On a ledger providing confidentiality the reading MAY be restricted to the issuer, the holder concerned and the third parties the issuer authorizes — see [Privacy and Confidentiality](#privacy-and-confidentiality). | y | Public (`view`) | `isFrozen(account)`. The frozen list is plaintext on-chain and freeze operations emit public events — only balances and amounts are encrypted. |


#### Optional

| ID   | Requirement        | CMTAT Solidity corresponding feature                         | Access Control (CMTAT Solidity)                  | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 22   | Enforce a transfer | `forcedTransfer(address from, address to, uint256 value)`    | Role-restricted (operator/compliance authorized) | Enforcement transfer is performed via `forcedTransfer`.      | y | `FORCED_OPS_ROLE` | `forcedTransfer(from, to, externalEuint64, inputProof)` / `forcedTransfer(from, to, euint64)` (`ERC7984EnforcementModule`). Stricter precondition than CMTAT Solidity: `from` MUST be frozen (`CMTAT_AddressNotFrozen`) and `to` MUST NOT be `address(0)` (`CMTAT_Enforcement_ZeroAddressNotAllowed`; use `forcedBurn`). Bypasses pause, deactivation, allowlist and RuleEngine. `FORCED_OPS_ROLE` is distinct from `ENFORCER_ROLE` (freeze). Emits `ForcedTransfer`. |
| 23   | Partial freeze     | `freezePartialTokens(address account, uint256 value)` / `unfreezePartialTokens(address account, uint256 value)` | Role-restricted (operator/compliance authorized) | Intended only to block a sold amount to avoid double-spend during settlement. | n | — | Not implemented. Balances are `euint64`; a partial freeze would need an encrypted comparison on every transfer. Whole-address freeze (criterion 19) is the only freeze granularity. |
| 24   | Know active balance | `getActiveBalanceOf(address account)` | Public (`view`) | The balance the holder can still transfer, that is the total balance less the partially frozen amount. Only meaningful where partial freeze (criterion 23) is offered. | n | — | No partial freeze; the active balance is the full `confidentialBalanceOf`. |
| 25   | Know frozen balance | `getFrozenTokens(address account)` | Public (`view`) | The partially frozen amount held on an address. Declared by the draft `IERC7943` interface in CMTAT Solidity. On a ledger providing confidentiality the reading MAY be restricted in the same way as the frozen status (criterion 21). | n | — | No partial freeze. |


##### Note

> This subsection can be used to detail how each mandatory function is implemented, including role model, execution flow, and specific chain-level behavior.

**Freeze.** CMTAT `EnforcementModule` is used unchanged: `setAddressFrozen(account, freeze[, data])` and `batchSetAddressFrozen` by `ENFORCER_ROLE`, `isFrozen` public. The frozen list is plaintext. A frozen address cannot send, receive or act as an operator, and cannot be minted to or burned from by the standard paths.

**Forced operations.** `forcedTransfer` and `forcedBurn` (`ERC7984EnforcementModule`, `FORCED_OPS_ROLE`) are the only operations allowed on a frozen address, and they are only allowed on a frozen address (`CMTAT_AddressNotFrozen`). They bypass pause, deactivation, the allowlist and the RuleEngine. Their amount is encrypted like any other; forcing an amount above the balance moves 0. `forcedTransfer` never burns (`to == address(0)` reverts) — see [Forced Burn and Forced Transfer](#forced-burn-and-forced-transfer).

**Partial freeze** is absent: the amount to freeze would have to be compared with the encrypted balance on every transfer.


#### Transfer restriction (optional)

| ID   | Requirement                   | CMTAT Solidity corresponding feature                         | Access Control (CMTAT Solidity)                         | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 26   | Conditional transfer request  | `RuleConditionalTransferLight.detectTransferRestriction(from, to, value)` / `detectTransferRestrictionFrom(spender, from, to, value)` and `approvedCount(from, to, value)` | Public (`view`)                                         | Request is represented by a transfer restricted until approval count is non-zero. | n | — | Not implemented. `CMTATConfidentialRuleEngine` can host external rules, but every RuleEngine call receives `value = 0`, so an approval cannot be bound to an amount; no conditional-transfer rule has been integrated or tested. |
| 27   | Conditional transfer approval | `RuleConditionalTransferLight.approveTransfer(from, to, value)` (or `approveAndTransferIfAllowed`) | Role-restricted (compliance/approver authorized)        | Approval is consumed on transfer via `transferred(...)`; cancellation via `cancelTransferApproval(...)`. | n | — | Same as criterion 26. |
| 28   | Assign to whitelist           | CMTAT Allowlist: `setAddressAllowlist(account, status)`, `batchSetAddressAllowlist(accounts, status)`, `isAllowlisted(account)`; Rules whitelist: `addAddress`, `removeAddress`, `addAddresses`, `removeAddresses`, `isAddressListed` | Role-restricted for setters; public (`view`) for checks | CMTAT Allowlist and Rules whitelist are alternative whitelist implementations. | y | `ALLOWLIST_ROLE` for setters; public (`view`) for checks | Integrated allowlist in `CMTATConfidentialWhitelist` (CMTAT `AllowlistModule`): `setAddressAllowlist(account, status[, data])`, `batchSetAddressAllowlist`, `enableAllowlist(bool)`, `isAllowlisted`, `isAllowlistEnabled`. When enabled, sender, receiver and spender (operator) MUST be allowlisted; mint and burn require the account to be allowlisted; forced operations bypass the allowlist. External whitelist rules can be used instead through `CMTATConfidentialRuleEngine`. |

##### Note

> This subsection can be used to detail the different transfer restrictions available.

Two deployment variants add a transfer restriction on top of pause and freeze; the reference `CMTATConfidential` and `CMTATConfidentialLite` apply none.

- `CMTATConfidentialWhitelist` embeds the CMTAT `AllowlistModule` (criterion 28). The check is wired into the shared validation hooks (`_canTransferStandardByModule`, `_canMintBurnByModule`, `_canSend`, `_canReceive`), so it applies once to every transfer overload, to mint and to burn. It is fail-open while `isAllowlistEnabled()` is `false`.
- `CMTATConfidentialRuleEngine` calls an external CMTA `IRuleEngine` (criteria 26–28 through rules, [Restriction](#restriction-optional)). Because the amount is encrypted, every call passes `value = 0`; only rules that decide on the spender, sender and recipient addresses are meaningful.

Conditional transfer (26–27) is not offered. Both variants expose `canTransfer(from, to, amount)` — `amount` is ignored — and the RuleEngine variant also `canTransferFrom(spender, from, to, amount)`; all variants expose `canSend(account)` and `canReceive(account)` (ERC-7943 style views, without the ERC-7943 interface id).


#### Access Control

| ID   | Requirement      | CMTAT Solidity corresponding feature                         | Access Control (CMTAT Solidity)                 | Notes                                                        | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 29   | Grant role       | `grantRole(bytes32 role, address account)` (OpenZeppelin AccessControl via CMTAT/Rules modules) | Role admin (`DEFAULT_ADMIN_ROLE` or role admin) | Used for roles such as `ALLOWLIST_ROLE`, `DEBT_ROLE`, `OPERATOR_ROLE`, `COMPLIANCE_MANAGER_ROLE`. | y | `DEFAULT_ADMIN_ROLE` (role admin of every role) | `grantRole(role, account)` — OpenZeppelin `AccessControlUpgradeable` through CMTAT `AccessControlModule`. Roles: `MINTER_ROLE`, `BURNER_ROLE`, `PAUSER_ROLE`, `ENFORCER_ROLE`, `FORCED_OPS_ROLE`, `OBSERVER_ROLE`, `SUPPLY_OBSERVER_ROLE` (not Lite), `SUPPLY_PUBLISHER_ROLE`, `TOKEN_ATTRIBUTE_ROLE`, `EXTRA_INFORMATION_ROLE`, `DOCUMENT_ROLE`, `RULE_ENGINE_ROLE` (RuleEngine variant), `ALLOWLIST_ROLE` (Whitelist variant). |
| 30   | Revoke role      | `revokeRole(bytes32 role, address account)`                  | Role admin (`DEFAULT_ADMIN_ROLE` or role admin) | AccessControl role removal.                                  | y | `DEFAULT_ADMIN_ROLE` | `revokeRole(role, account)`; `renounceRole` by the holder. Revoking `OBSERVER_ROLE` or `SUPPLY_OBSERVER_ROLE` does not revoke FHE ACL grants already given to observers (FHE ACL is permanent). |
| 31   | Role attribution | `hasRole(bytes32 role, address account)` / `getRoleAdmin(bytes32 role)` | Public (`view`)                                 | In CMTAT `AccessControlModule`, `DEFAULT_ADMIN_ROLE` is treated as having all roles in `hasRole`. | y | Public (`view`) | `hasRole(role, account)`, `getRoleAdmin(role)`. As in CMTAT, `DEFAULT_ADMIN_ROLE` is treated as holding every role in `hasRole`. |

##### Note

> This subsection can be used to detail the concrete authorization model (roles, admins, delegates, approvers) and implementation-specific exceptions. It MAY also be relevant to explain how access control works in the implementation being approved.

OpenZeppelin `AccessControlUpgradeable` through the CMTAT `AccessControlModule`. The `admin` constructor argument receives `DEFAULT_ADMIN_ROLE`, which is the admin of every other role and is treated by `hasRole` as holding all of them. There is no timelock or two-step admin transfer. Roles and the CMTAT role they correspond to:

| Role | Powers | CMTAT Solidity counterpart |
|---|---|---|
| `DEFAULT_ADMIN_ROLE` | grant / revoke roles, `deactivateContract`, `setMaxSupplyObservers` | `DEFAULT_ADMIN_ROLE` |
| `MINTER_ROLE` | `mint` | `MINTER_ROLE` |
| `BURNER_ROLE` | `burn` | `BURNER_ROLE` |
| `PAUSER_ROLE` | `pause`, `unpause` | `PAUSER_ROLE` |
| `ENFORCER_ROLE` | `setAddressFrozen`, `batchSetAddressFrozen` | `ENFORCER_ROLE` |
| `FORCED_OPS_ROLE` | `forcedTransfer`, `forcedBurn` | `DEFAULT_ADMIN_ROLE` (`forcedTransfer`; `forcedBurn` in CMTAT Light). `ERC20ENFORCER_ROLE` only covers partial freeze, which is absent here |
| `OBSERVER_ROLE` | `setRoleObserver`, `removeRoleObserver` | — (confidentiality-specific) |
| `SUPPLY_OBSERVER_ROLE` | `addTotalSupplyObserver`, `removeTotalSupplyObserver` (not Lite) | — |
| `SUPPLY_PUBLISHER_ROLE` | `publishTotalSupply` | — |
| `TOKEN_ATTRIBUTE_ROLE` | `setName`, `setSymbol` | `DEFAULT_ADMIN_ROLE` (`ERC20BaseModule`, ERC-3643 `setName` / `setSymbol`) |
| `EXTRA_INFORMATION_ROLE` | `setTokenId`, `setTerms`, `setInformation` | `EXTRA_INFORMATION_ROLE` |
| `DOCUMENT_ROLE` | `setDocument`, `removeDocument` | `DOCUMENT_ROLE` |
| `RULE_ENGINE_ROLE` | `setRuleEngine` (RuleEngine variant) | `DEFAULT_ADMIN_ROLE` |
| `ALLOWLIST_ROLE` | `setAddressAllowlist`, `batchSetAddressAllowlist`, `enableAllowlist` (Whitelist variant) | `ALLOWLIST_ROLE` |

Freezing (`ENFORCER_ROLE`) and seizing (`FORCED_OPS_ROLE`) are deliberately separate powers. Revoking an observer role stops future ACL grants but cannot revoke FHE ACL entries already written.


#### Snapshot (optional)
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 32 | Schedule a snapshot | `scheduleSnapshot(uint256 time)` | Role-restricted (snapshot scheduler/admin authorized) | SnapshotEngine `ISnapshotScheduler`. | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
| 33 | Reschedule a snapshot | `rescheduleSnapshot(uint256 oldTime, uint256 newTime)` | Role-restricted (snapshot scheduler/admin authorized) | `newTime` must stay between adjacent scheduled snapshots (not before previous / not after next). | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
| 34 | Unschedule a snapshot | `unscheduleLastSnapshot(uint256 time)` / `unscheduleSnapshotNotOptimized(uint256 time)` | Role-restricted (snapshot scheduler/admin authorized) | `unscheduleLastSnapshot` is restricted to the latest scheduled snapshot; `unscheduleSnapshotNotOptimized` supports generic unscheduling. | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
| 35 | Snapshot time | `getAllSnapshots()` / `getNextSnapshots()` | Public (`view`) | Returns created snapshot times and pending scheduled times. | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
| 36 | Snapshot total supply | `snapshotTotalSupply(uint256 time)` | Public (`view`) | `ISnapshotState`. | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
| 37 | Snapshot balance | `snapshotBalanceOf(uint256 time, address tokenHolder)` | Public (`view`) | `ISnapshotState` (see also `snapshotInfo`). | n | — | No snapshot module; `SnapshotEngine` is not integrated and balances are encrypted. |
##### Note

> This subsection can be used to detail snapshot scheduling and query behavior, including timing constraints and permission specifics.

Not implemented. A snapshot of encrypted balances would require the token to keep historical `euint64` handles per account and to grant ACL on them, and the total supply at a given time is itself encrypted.


#### Dividend (optional)

| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 38 | Distribution create parameters |  |  |  | n | — | Not implemented. |
| 39 | Distribution set eligibility |  |  |  | n | — | Not implemented. |
| 40 | Distribution set deposit |  |  |  | n | — | Not implemented. |
| 41 | Distribution claim deposit |  |  |  | n | — | Not implemented. |
| 42 | Distribution schedule |  |  |  | n | — | Not implemented. |
| 43 | Distribution unschedule |  |  |  | n | — | Not implemented. |
##### Note

> This subsection can be used to detail dividend/distribution workflow specifics and jurisdiction- or product-specific handling rules. No direct CMTAT Solidity equivalent is currently defined for these items; they are implementation-specific. However, a prototype is available on the CMTA GitHub organization: https://github.com/CMTA/IncomeVault

Not implemented.


#### Credit Events (optional)
| ID | Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 44 | Flag as default | `setCreditEvents(CreditEvents)` -> `creditEvents().flagDefault` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | — | Not implemented (no `CreditEvents` / `DebtModule`). |
| 45 | Remove default flag | `setCreditEvents(CreditEvents)` with `flagDefault = false` | Role-restricted (issuer/compliance/admin authorized) | Same function as ID 44 with a different value. | n | — | Not implemented (no `CreditEvents` / `DebtModule`). |
| 46 | Flag as redeemed | `setCreditEvents(CreditEvents)` -> `creditEvents().flagRedeemed` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | — | Not implemented (no `CreditEvents` / `DebtModule`). |
| 47 | Set rating | `setCreditEvents(CreditEvents)` -> `creditEvents().rating` | Role-restricted (issuer/compliance/admin authorized) | Managed in `ICMTATCreditEvents.CreditEvents`. | n | — | Not implemented (no `CreditEvents` / `DebtModule`). |
##### Note

> This subsection can be used to detail how credit event states are updated, governed, and audited in the implementation being approved.

Not implemented.


### Debt (optional)
| ID | Attribute | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|---|
| 48 | Guarantor identifier | `debt().debtIdentifier.guarantor` (set via `setDebt`) | Read: public (`view`); write: role-restricted (`setDebt`) | Debt module (`ICMTATDebt.DebtIdentifier`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 49 | Debtholder representative identifier | `debt().debtIdentifier.debtHolder` (set via `setDebt`) | Read: public (`view`); write: role-restricted (`setDebt`) | Debt module (`ICMTATDebt.DebtIdentifier`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 50 | Unique identifier / hash | `tokenId()` and `terms().doc.documentHash` | Public (`view`) | `tokenId` is optional (implementations MAY omit it); document hash is in `terms` metadata. | y | Public (`view`) | `tokenId()` and `terms().doc.documentHash` are available through CMTAT `ExtraInformationModule` (criteria 2 and 5), independently of the Debt module, which is not included. |
| 51 | Issuance date | `debt().debtInstrument.issuanceDate` (set via `setDebt` / `setDebtInstrument`) | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`ICMTATDebt.DebtInstrument`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 52 | Currency of payments | `debt().debtInstrument.currency` / `debt().debtInstrument.currencyContract` | Read: public (`view`); write: role-restricted (`setDebt*`) | Supports symbol-like string and token/asset contract address. | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 53 | Par value | `debt().debtInstrument.parValue` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 54 | Minimum denomination | `debt().debtInstrument.minimumDenomination` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 55 | Maturity date | `debt().debtInstrument.maturityDate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 56 | Interest rate | `debt().debtInstrument.interestRate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`uint256`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 57 | Coupon payment frequency | `debt().debtInstrument.couponPaymentFrequency` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 58 | Interest schedule format: A) start date/end date/period; B) start date/end date/day of period; C) date 1/date 2/date 3 | `debt().debtInstrument.interestScheduleFormat` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 59 | Interest payment date: A) period; B) specific date | `debt().debtInstrument.interestPaymentDate` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 60 | Day count convention | `debt().debtInstrument.dayCountConvention` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
| 61 | Business day convention | `debt().debtInstrument.businessDayConvention` | Read: public (`view`); write: role-restricted (`setDebt*`) | Debt module (`string`). | n | — | Debt module (`DebtModule` / `ICMTATDebt`) not included. |
##### Note

> This subsection can be used to detail supplementary attributes and to explain specific representation or governance choices made by the implementation being approved.

The Debt module is not included. Criterion 50 is nevertheless satisfied by `tokenId()` and `terms().doc.documentHash` from the `ExtraInformationModule`, which every variant carries.


## Guideline for New Blockchain Implementations

If you create a version for another blockchain, use this section to build a correspondence table between the CMTAT framework, the CMTAT Solidity version, and your implementation.

### Freeze

> To be compatible with [ERC-3643](https://eips.ethereum.org/EIPS/eip-3643), freeze in CMTAT Solidity is implemented with a single function: `setAddressFrozen(targetAddress, frozenStatus)`. For non-EVM blockchains, implementations MAY separate this into two distinct functions:

```solidity
freeze(address targetAddress)
unfreeze(address targetAddress)
```

##### Note

> This subsection can be used to detail the choice made by the implementation being approved.

The CMTAT Solidity `EnforcementModule` is inherited without modification: a single `setAddressFrozen(account, freeze)` function (ERC-3643), an overload with a `data` justification field, and `batchSetAddressFrozen`. The freeze is applied by the same `ValidationModule` hooks as in CMTAT Solidity, extended to the operator of an ERC-7984 delegated transfer (treated as the `spender`).


### Restriction (optional)

> Transfer restrictions are criteria 26–28 and are optional. The table below is a **reference catalogue** of the restrictions the CMTAT Solidity stack can apply, taken from the [Rules](https://github.com/CMTA/Rules) repository; it is not part of the equivalency count. An implementation MAY offer any subset of these restrictions, none of them, or restrictions that have no CMTAT Solidity equivalent.

In CMTAT Solidity a restriction is a **rule**: a contract that answers whether a movement of value is allowed.

- A rule is plugged directly into the token, or several rules are composed behind a **RuleEngine**, which returns the first non-zero restriction code — so the order of the rules decides which code a rejection reports.
- Each rule exposes a **read path** — `detectTransferRestriction` / `canTransfer` and their `…From` variants — which MUST NOT revert and returns an [ERC-1404](https://eips.ethereum.org/EIPS/eip-1404) restriction code, `0` meaning no restriction.
- Each rule also exposes a **write path** — `transferred`, `created`, `destroyed` — called by the token once it has decided to move the value. It reverts to block the operation and MAY update the rule state.

Mint and burn use the same path with one party missing — a mint is a movement from the zero address, a burn a movement to the zero address — so a rule does not necessarily apply to them. The table states, for each restriction, what it checks on a transfer, on a mint, and on a burn.

| Restriction | CMTAT Solidity rule | On transfer | On mint | On burn | Notes | Present in implementation being approved (`y/partial/n`) | Implementation details |
|---|---|---|---|---|---|---|---|
| Whitelist | `RuleWhitelist` | Sender and receiver MUST be listed; the spender of a `transferFrom` optionally | Not checked | Not checked |  | y | Integrated in `CMTATConfidentialWhitelist` (sender, receiver and operator/spender checked on transfer; the account is also checked on mint and burn, stricter than `RuleWhitelist`). `RuleWhitelist` can also be plugged behind a RuleEngine in `CMTATConfidentialRuleEngine`. |
| Aggregated whitelists | `RuleWhitelistWrapper` | Sender and receiver MUST be listed in at least one of the aggregated lists | Not checked | Not checked | An empty wrapper rejects every transfer (fail-closed). | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. |
| Receiver whitelist | `RuleReceiverWhitelist` | Receiver only | Receiver MUST be listed | Not checked | Reproduces ERC-3643 eligibility: screening only the receiver lets a de-listed holder still exit a position. | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. |
| Spender whitelist | `RuleSpenderWhitelist` | Spender of a `transferFrom` MUST be listed; sender and receiver are not checked | Not checked | Not checked |  | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. The operator is forwarded as `spender` (`canTransferFrom(spender, from, to, 0)` / `transferred(spender, from, to, 0)`). |
| Blacklist | `RuleBlacklist` | Blocks a listed sender, receiver or spender | Blocks a listed minter | Blocks a listed burner |  | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. Mint and burn legs forward the minter / burner as `spender` (audit finding OZ-M-01). |
| Sanctions list | `RuleSanctionsList` | Blocks a sanctioned sender, receiver or spender | Blocks a sanctioned minter | Blocks a sanctioned burner | Reads an external sanctions oracle. An unset oracle allows everything (fail-open). | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. |
| Whitelist and frozen list (ERC-2980) | `RuleERC2980` | Receiver MUST be whitelisted; sender, receiver and spender MUST NOT be frozen | Blocks a frozen minter | Blocks a frozen burner |  | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. |
| Identity registry | `RuleIdentityRegistry` | Receiver MUST be verified; sender and spender are opt-in checks | Not checked | Not checked | Calls `isVerified` on an ERC-3643 identity registry. An unset registry allows everything (fail-open). | y | Available through an external CMTA RuleEngine in `CMTATConfidentialRuleEngine`; address-based rule, unaffected by `value = 0`. Not bundled or tested in this repository. |
| Maximum total supply | `RuleMaxTotalSupply`, `RuleMaxTotalSupplyERC3643` | Not checked | Rejects a mint that would take the total supply over the cap | Not checked | The `…ERC3643` variant exists because an ERC-3643 token calls compliance after moving the value. | n | Amount-based rule: the token always passes `value = 0`, so the rule cannot evaluate the amount, the balance or the supply, which are encrypted. |
| Reserve-backed supply cap | `RuleChainlinkPoR`, `RuleChainlinkPoRERC3643` | Not checked | Rejects a mint that would take the total supply over the reserves reported by a proof-of-reserve feed | Not checked | A missing, broken or stale feed rejects every mint (fail-closed). | n | Amount-based rule: the token always passes `value = 0`, so the rule cannot evaluate the amount, the balance or the supply, which are encrypted. |
| Maximum balance per address | `RuleMaxBalance` | Receiver's balance after the transfer MUST stay under the cap | Receiver's balance after the mint MUST stay under the cap | Not checked | The cap counts tokens per address, so splitting a position across wallets defeats it unless one address per investor is enforced. | n | Amount-based rule: the token always passes `value = 0`, so the rule cannot evaluate the amount, the balance or the supply, which are encrypted. |
| Conditional transfer | `RuleConditionalTransferLight`, `RuleConditionalTransferLightMultiToken` | The exact transfer MUST have been approved beforehand; the approval is consumed | Not checked | Not checked | Criteria 20–21. | n | Amount-based rule: the token always passes `value = 0`, so the rule cannot evaluate the amount, the balance or the supply, which are encrypted. See criteria 26–27. |
| Per-minter quota | `RuleMintAllowance` | Not checked | Debits the minter's quota and rejects the mint once it is exhausted | Not checked | Needs the token to forward the spender on mint (CMTAT `v3.3` or later). | n | Amount-based rule: the token always passes `value = 0`, so the rule cannot evaluate the amount, the balance or the supply, which are encrypted. The minter is forwarded as `spender`, but the debited amount would always be 0. |

##### Note

> This subsection can be used to detail which restrictions the implementation being approved applies, where the logic lives (in the token, in an external module, or in the chain runtime), in which order the restrictions are evaluated, and what a rejected operation returns to the caller — a revert, an error code, or a status returned by a read-only entry point.
>
> Restrictions that have no CMTAT Solidity equivalent SHOULD be listed here as well, together with the behaviour of each restriction when its external data source (oracle, registry, list) is unset or unavailable: rejecting every operation (fail-closed) and allowing every operation (fail-open) are both defensible, but the choice MUST be explicit.

**Where the logic lives.** Pause and freeze are inside the token (`ValidationModule`). The allowlist is inside the token in `CMTATConfidentialWhitelist`. Rules are external contracts behind a CMTA `RuleEngine` in `CMTATConfidentialRuleEngine` (`setRuleEngine`, `RULE_ENGINE_ROLE`); the token only stores the engine address.

**Order of evaluation** (RuleEngine variant, execution path): `_canTransferGenericByModule` — pause, then frozen spender / sender / receiver — revert `ERC7943CannotTransfer(from, to, 0)`; then `_beforeTransfer` → `ruleEngine.transferred(spender, from, to, 0)` (or `transferred(from, to, 0)` when there is no operator), whose revert blocks the transfer before any FHE operation is issued; then the ERC-7984 transfer. On mint and burn the same order applies with `address(0)` as the missing leg and the minter / burner forwarded as `spender`. Forced operations skip the RuleEngine and the allowlist entirely.

**Read path.** `canTransfer(from, to, amount)` (all variants) and `canTransferFrom(spender, from, to, amount)` (RuleEngine variant) return a boolean, `amount` being ignored; they combine the module checks with `ruleEngine.canTransfer(from, to, 0)` / `canTransferFrom(spender, from, to, 0)`. No ERC-1404 restriction code is returned by the token itself.

**Fail-open / fail-closed.** `ruleEngine() == address(0)` disables the rule path (fail-open, configurable by `RULE_ENGINE_ROLE`). The allowlist is fail-open until `enableAllowlist(true)`. The behaviour of a rule whose oracle is unavailable is that of the CMTA Rules repository (see the *Notes* column above).

**Amount-based rules.** Every rule receives `value = 0`. Supply caps, balance caps, proof-of-reserve, mint quotas and conditional transfers therefore cannot be enforced and MUST NOT be configured with the expectation that they work. Only the mock screening engine used by the test-suite (`ScreeningRuleEngineMock`, address blocking) has been exercised; the CMTA `Rules` contracts are not part of this repository.


### Version

> CMTAT Solidity exposes the version of the implementation through the ERC-3643 function `version()`, provided by the `VersionModule`. The returned value is a compile-time constant (for example `"3.2.0"`) following [semantic versioning](https://semver.org/). It identifies the version of the token implementation; it is neither the version of the issued security nor the version of this assessment document.
>
> Versioning is an optional feature (criterion 6). Implementations on other blockchains MAY expose it differently:
>
> - as a constant returned by a read-only entry point, as in CMTAT Solidity;
> - through the chain-native contract or package metadata, when the target chain already versions the deployed code;
> - as a state variable restricted to an administrator role. In that case, the implementation MUST ensure that the value cannot be desynchronized from the deployed code, typically by writing it only in the initialization or upgrade path.
>
> For an upgradeable implementation, the version SHOULD be updated by the upgrade itself, so that an off-chain observer can always determine which code is live.

##### Note

> This subsection can be used to detail the choice made by the implementation being approved.

`version()` is a read-only entry point returning the compile-time constant `"1.0.0"` (`CMTATConfidentialVersionModule`), which overrides the CMTAT `VersionModule` value so that the CMTAT Confidential release is reported rather than the CMTAT library release. The format is `MAJOR.MINOR.PATCH` (ERC-8303). The contracts are not upgradeable, so the value can only change through a new deployment. The `package.json` version and the git tag carry the same number.


### CMTAT Extended

In the table below, the CMTAT framework extended features are mapped to Solidity features.

| CMTAT Functionalities | CMTAT Solidity corresponding features | CMTAT Allowlist | CMTAT Light | CMTAT Debt | CMTAT Standard | Present in implementation being approved (`y/partial/n`) | Implementation details |
|---|---|---|---|---|---|---|---|
| On-chain snapshot | `snapshotModule` and `snapshotEngine` | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | n | Not implemented; balances are encrypted. |
| Forced transfer | `forcedTransfer` | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | y | `forcedTransfer` (`FORCED_OPS_ROLE`), only from a frozen address, never to `address(0)`. |
| Forced burn | `forcedBurn` | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | y | `forcedBurn` (`FORCED_OPS_ROLE`), only from a frozen address. Both are implemented, unlike CMTAT Standard. |
| Freeze partial token | `freezePartialTokens` / `unfreezePartialTokens` | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | n | Not implementable on encrypted balances (criteria 23–25). |
| Integrated whitelisting/allowlisting | CMTAT Allowlist | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | y | `CMTATConfidentialWhitelist` variant (CMTAT `AllowlistModule`). |
| External whitelisting/allowlisting | CMTAT with rule whitelist | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | y | `CMTATConfidentialRuleEngine` variant with a CMTA `RuleEngine` and `RuleWhitelist`. |
| RuleEngine / transfer hook | CMTAT with RuleEngine | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | y | `CMTATConfidentialRuleEngine` variant (`ERC7984RuleEngineModule`, `RULE_ENGINE_ROLE`); `value = 0` on every call. |
| Upgradeability | CMTAT Upgradeable version | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | n | Standalone, immutable contracts (constructor calls `initialize` once). A new version requires a new deployment and a migration of encrypted balances. |
| Fee payer / gasless | CMTAT with ERC-2771 module | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #b00020;">&#x2718;</span></strong> | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | n | No ERC-2771 forwarder module. `_msgSender()` resolves to `msg.sender`. |

##### Note

> This section can be used to detail supplementary features implemented beyond the mandatory baseline and specific cases in the target chain. For non-EVM blockchains, it MAY be relevant to explain how gasless/gas sponsorship and upgradeability work in the particular blockchain targeted.

Forced transfer and forced burn are both present, both restricted to a frozen source address. The allowlist is integrated in one variant and externalised through the RuleEngine in another; neither is present in the reference and Lite variants. Snapshot, partial freeze, upgradeability and gasless transactions are absent. Upgradeability was left out on purpose: encrypted balances tie every handle to the contract's ACL, and the constructor-based deployment keeps the audited code immutable; migrating to a new version means deploying a new token and re-issuing balances.


### Forced Burn and Forced Transfer

> In the standard burn function, tokens from a frozen wallet MUST NOT be burnable. CMTAT offers `forcedTransfer` to force a transfer or a burn.
>
> If `forcedTransfer` is not available, implementations MAY implement only `forcedBurn` (as in CMTAT Light). Implementations MAY also implement both. In that case, only `forcedBurn` SHOULD burn tokens, and `forcedTransfer` SHOULD NOT burn tokens.
>
> With the CMTAT Solidity version, when `forcedTransfer` is available, `forcedBurn` is not implemented to reduce contract code size. This limitation MAY not apply to other blockchains.

##### Note

> This subsection can be used to detail the choice made by the implementation being approved.

Both functions are implemented (`ERC7984EnforcementModule`, `FORCED_OPS_ROLE`) and the recommended split is respected: `forcedBurn` is the only path that burns, and `forcedTransfer` reverts when `to == address(0)`. Both require the source address to be frozen (`CMTAT_AddressNotFrozen`) — a precondition CMTAT Solidity does not impose — so the operational sequence is `setAddressFrozen(from, true)` then `forcedTransfer` / `forcedBurn`. Both bypass pause, deactivation, allowlist and RuleEngine. The amount is encrypted; if it exceeds the balance, 0 is moved and no error is raised, so the enforcer SHOULD verify the balance through an observer grant before acting.


### Implementation Details

| Functionalities | CMTAT Solidity | Access Control (CMTAT Solidity) | Note | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|
| Mint while pause | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | Role-restricted (minter/issuer authorized) | Dedicated cross-chain mint (for example `crosschainMint`) cannot be performed while paused. | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | `MINTER_ROLE` | Allowed while paused; blocked once deactivated and when `to` is frozen. |
| Burn while pause | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | Role-restricted (burner/issuer authorized) | Dedicated cross-chain burn (for example `crosschainBurn`) cannot be performed while paused. | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | `BURNER_ROLE` | Allowed while paused; blocked once deactivated and when `from` is frozen. |
| Self-Burn for everyone | <strong><span style="color: #b00020;">&#x2718;</span></strong> | Not permitted | Token holders cannot burn their own tokens; only authorized addresses can burn. | <strong><span style="color: #b00020;">&#x2718;</span></strong> | Not permitted | Holders cannot burn their own tokens; `burn` requires `BURNER_ROLE`. |
| Self-Burn for authorized addresses | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | Role-restricted (authorized burner) |  | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | `BURNER_ROLE` | A `BURNER_ROLE` holder may call `burn` on its own address (no self-exclusion). |
| Standard burn on a frozen address | <strong><span style="color: #b00020;">&#x2718;</span></strong> | Not permitted in standard burn path | Requires `forcedTransfer` or `forcedBurn`. | <strong><span style="color: #b00020;">&#x2718;</span></strong> | Not permitted | `burn` reverts with `ERC7943CannotSend(from)`; use `forcedBurn`. |
| Burn tokens with `forcedTransfer` | <strong><span style="color: #1e7e34;">&#x2714;</span></strong> | Role-restricted (operator/compliance authorized) | See notes above. | <strong><span style="color: #b00020;">&#x2718;</span></strong> | Not permitted | `forcedTransfer` to `address(0)` reverts with `CMTAT_Enforcement_ZeroAddressNotAllowed`; `forcedBurn` is the only forced cancellation path. |

##### Note

> This subsection can be used to detail how the implementation being approved behaves in each case above, including the role model and the specific chain-level behavior while the token is paused or an address is frozen.

Mint and burn are allowed while paused because the pause check is carried only by the transfer path, as in CMTAT Solidity; both are blocked once the contract is deactivated and on a frozen address. There is no self-burn path for holders. A frozen address can only be debited through `forcedBurn` or `forcedTransfer`. `forcedTransfer` never burns. One FHE-specific behaviour applies to every debit: an amount above the balance results in a 0 movement instead of a revert (`FHESafeMath.tryDecrease`), which is a deliberate privacy property of ERC-7984.


### Self-Burn

> Only the issuer and authorized addresses (not the token holder) can burn a token in CMTAT Solidity, which reflects legal requirements in several jurisdictions.
>
> The CMTA framework permits it: functionality 41, *user-approved cancel*, states that the functionality "also allows token holders to cancel their own tokens". An implementation MAY therefore offer self-burn where its legal or business context allows. The holder-authorized cancellation that the issuer performs is criterion 12; what is described here is the cancellation the holder performs alone.
>
> An implementation that does offer self-burn SHOULD state so here, together with the legal basis on which it is offered, so that an assessment records which of the two arrangements was adopted rather than leaving it to be inferred.

CMTAT Confidential does not offer self-burn: `burn(from, ...)` requires `BURNER_ROLE` and ignores any operator approval, so a holder cannot cancel its own tokens. The arrangement adopted is therefore the CMTAT Solidity one — cancellation by the issuer only (criterion 11), with `forcedBurn` for frozen addresses. No holder-authorised cancellation (criterion 12) is provided either.


### Cross-Chain Bridge Support

> **This feature is NOT part of the CMTAT specification directly.** Cross-chain transferability is not a requirement of the CMTAT standard and is not part of the equivalency criteria above. It is an **optional module offered by the CMTAT Solidity implementation**, documented here only as a reference so that new implementations MAY map equivalent functionality if they choose to support bridging. An implementation MAY be fully CMTAT-equivalent without providing any cross-chain capability.

CMTAT Solidity supports cross-chain bridging through a **burn-and-mint** model rather than lock-and-mint: tokens are burned on the source chain by an authorized bridge and minted on the destination chain by an authorized bridge. Two complementary standards are implemented in the optional cross-chain module:

- **[ERC-7802](https://eips.ethereum.org/EIPS/eip-7802)** — a minimal, bridge-agnostic interface for cross-chain mint and burn. This is the primitive that any compliant token bridge can call.
- **[Chainlink CCIP](https://docs.chain.link/ccip) (Cross-Chain Token / CCT standard)** — administrative hooks (`CCIPModule`) that let the token register with the CCIP token admin registry.

A third arrangement sits **outside** the token rather than in it: **[CMTAT-LayerZero](https://github.com/CMTA/CMTAT-LayerZero)** is an adapter built on the LayerZero V2 OFT standard, which holds the bridge authorization itself and calls the token to burn on the source chain and mint on the destination chain. It ships in two forms:

- `LayerZeroAdapterERC7802` — calls the ERC-7802 entry points described above, and is the form CMTA recommends where the token implements ERC-7802;
- `LayerZeroAdapter` — calls the ERC-3643 `mint` and `burn` where the token does not, which is the reuse case described below.

Each adapter carries its own pause, controlled by the adapter owner and independent of the token's. An implementation MAY support several bridges at once; each one then holds its own authorization, so that one can be revoked without interrupting the others.

The cross-chain mint/burn entry points are **not** the standard `mint` / `burn` functions: they are dedicated functions restricted to the trusted bridge via a specific role, and they are blocked while the contract is paused (consistent with the *Mint while pause* / *Burn while pause* rows in [Implementation Details](#implementation-details)).

In CMTAT Solidity, the standard `mint` and `burn` remain available while the contract is paused: the pause check is carried by the authorization hook of each entry point (`_checkTokenBridge` is `whenNotPaused`, `_authorizeMint` is not), not by the shared mint/burn path.

An implementation that does **not** provide dedicated cross-chain entry points, and instead reuses the standard `mint` and `burn` functions for bridge operations:

- SHOULD apply the pause check to those functions on the bridge path, so that a cross-chain movement is subject to the same checks as a standard transfer;
- otherwise lets tokens keep moving across chains while transfers are frozen on each of them — a bridge burn on the source chain followed by a bridge mint on the destination chain is economically a transfer between two chains;
- SHOULD state which of the other transfer checks (freeze, partial freeze, allowlist, rule engine or transfer hook) the bridge path enforces, and why any of them is skipped.

| Requirement | CMTAT Solidity corresponding feature | Access Control (CMTAT Solidity) | Notes | Present in implementation being approved (`y/partial/n`) | Access Control (implementation being approved) | Implementation details |
|---|---|---|---|---|---|---|
| Cross-chain mint (ERC-7802) | `crosschainMint(address to, uint256 value)` | Role-restricted (`CROSS_CHAIN_ROLE`, trusted token bridge); blocked while paused | Authenticates the bridge with `msg.sender` (not `_msgSender()`) so a relayer/forwarder cannot impersonate the bridge. Emits `CrosschainMint`. | n | — | Not implemented. No ERC-7802, no CCIP module, no `burnFrom`. Cross-chain transferability is out of scope for v1.0.0 (see note below). |
| Cross-chain burn (ERC-7802) | `crosschainBurn(address from, uint256 value)` | Role-restricted (`CROSS_CHAIN_ROLE`, trusted token bridge); blocked while paused | Does **not** require an ERC-20 allowance from `from`, following the Optimism Superchain ERC-20 and OpenZeppelin `ERC20Bridgeable` design. Emits `CrosschainBurn`. | n | — | Not implemented. No ERC-7802, no CCIP module, no `burnFrom`. Cross-chain transferability is out of scope for v1.0.0 (see note below). |
| Advertise ERC-7802 support | `supportsInterface(type(IERC7802).interfaceId)` | Public (`view`) | ERC-165 discovery so bridges can detect ERC-7802 compatibility. | n | — | `supportsInterface` covers ERC-165, ERC-7984 and `AccessControl` only. |
| Set CCIP admin | `setCCIPAdmin(address newAdmin)` | Role-restricted (`DEFAULT_ADMIN_ROLE`) | Chainlink CCIP (CCT) integration. The CCIP admin only registers the token with the CCIP token admin registry and has no other powers; 1-step transfer, `address(0)` revokes. | n | — | Not implemented. |
| Get CCIP admin | `getCCIPAdmin()` | Public (`view`) | Returns the current CCIP admin. | n | — | Not implemented. |
| Bridge burn against an allowance | `burnFrom(address account, uint256 value)` | Role-restricted (`BURNER_FROM_ROLE`); blocked while paused; **and** an ERC-20 allowance granted by `account` | Declared by the same `ERC20CrossChainModule` as the ERC-7802 entry points, and usable by a Chainlink CCIP token pool — the interface notes it carries no `data` parameter for that reason. Spends the allowance and emits `Spend` alongside `BurnFrom`. Same function as criterion 12; see the note below on when to prefer it to `crosschainBurn`. | n | — | Not implemented (criterion 12). |

##### Note

> - The trusted bridge holds `CROSS_CHAIN_ROLE`. A bridge MAY `renounceRole` to drop its privileges; this only deprives it of cross-chain mint/burn and has no other effect, but such a bridge should then be considered compromised and not reused.
> - `burnFrom` and `crosschainBurn` bound the bridge's authority differently, and the choice between them is a trust decision rather than a matter of style. `crosschainBurn` deliberately requires no allowance, so a bridge holding `CROSS_CHAIN_ROLE` can cancel the tokens of **any** address; `burnFrom` spends an allowance, so the amount a bridge can cancel is capped per holder by what that holder has approved, and a compromised bridge cannot reach a holder who has approved nothing. The cost is that the holder MUST approve first, which adds a transaction to the bridge flow and does not suit a design in which the bridge burns without the holder acting.
> - CMTAT Solidity also exposes self-`burn` (guarded by `BURNER_SELF_ROLE`) alongside bridging, likewise role-restricted and blocked while paused.
> - This subsection can be used to detail whether and how the implementation being approved supports bridging, which standard(s) or bridge(s) it targets, and the trust/role model applied to the bridge on the target chain. For non-EVM blockchains, ERC-7802 and CCIP may not be directly applicable; an equivalent burn-and-mint bridge model MAY be documented instead.

CMTAT Confidential v1.0.0 does not support bridging. No ERC-7802 entry point, no CCIP admin and no `burnFrom` are implemented, and none is planned for this version. A bridge could only be arranged by granting it `MINTER_ROLE` and `BURNER_ROLE`; in that case the standard `mint` / `burn` would be used, which are *not* blocked while paused (they are blocked by freeze and deactivation, and by the allowlist or RuleEngine in the respective variants). Such a set-up would let tokens keep moving across chains while transfers are paused, and would also require the bridge to hold an FHE ACL grant on the amounts it moves; it is therefore not recommended without a dedicated module.


### Privacy and Confidentiality

> **This section is NOT part of the CMTAT specification and is NOT an equivalency criterion.** CMTAT Solidity targets public EVM chains, where all token state is readable by anyone. This section exists so that an implementation targeting a blockchain or a distributed ledger offering some level of privacy or confidentiality can document what stays public, what is hidden, and who is still able to read it.
>
> On a public EVM chain, every element of the table below is public: contract storage is readable by any node even when a variable is declared `private` in Solidity, and every transfer, mint, burn, freeze, and allowlist update is visible in the transaction data and in the emitted events. An implementation on a privacy-enabled ledger MAY hide part of this state. It MUST then document how the hidden state is protected, and who can still read it — in particular whether the issuer retains the visibility required by the CMTAT features it claims (snapshot, dividend, forced transfer, freeze).
>

#### Visibility values

| Value | Meaning |
|---|---|
| `public` | Readable by anyone with access to the ledger, as in CMTAT Solidity. |
| `private` | Not readable from the ledger; only the holder of a specific right (private key, view key, role, node, disclosure credential) can read it. |
| `partial` | Partly hidden — for example the amount is encrypted but the participants are public, the value is visible only to the parties of the transaction, or it is disclosed only in aggregated or delayed form. |

#### Privacy table

| Data | Visibility in CMTAT Solidity | Visibility in the implementation being approved (`public/private/partial`) | Available to the issuer (`y/n`) | Other readers (role or address) | Implementation details |
|---|---|---|---|---|---|
| Balance of an address | `public` — `balanceOf` is a public view function and the balance mapping is readable from storage | `private` | y | the account holder; the holder-designated observer (`setObserver`); the role observer assigned per account by `OBSERVER_ROLE` (`setRoleObserver`); the Zama KMS (threshold MPC, no single party holds the key) | `confidentialBalanceOf` returns an `euint64` handle; the plaintext is only obtainable by an FHE-ACL holder through KMS user decryption (relayer SDK). The issuer obtains it by having `OBSERVER_ROLE` assign itself or an agent as role observer of the account (immediate grant on the current handle, then automatic re-grant on every update). Grants are permanent. |
| Transfer amount | `public` — carried in the transaction calldata and in the `Transfer` event | `private` | y | sender; recipient; their holder and role observers; the operator (transient allowance on the transferred handle in `confidentialTransferFrom`); anyone after an ACL holder publishes it with `requestDiscloseEncryptedAmount` / `discloseEncryptedAmount` | The `ConfidentialTransfer`, `Mint`, `Burn`, `ForcedTransfer` and `ForcedBurn` events carry the *handle* of the transferred amount, not the value. Inputs are `externalEuint64` ciphertexts with a ZKPoK; calldata reveals nothing. An amount above the balance transfers 0 without revealing it. |
| Transfer participants (sender and recipient) | `public` — indexed `from` and `to` in the `Transfer` event | `public` | y | everyone | Indexed `from` / `to` in `ConfidentialTransfer`; `msg.sender` and the addresses in calldata are public, as is the operator relationship (`OperatorSet`, `isOperator`). |
| Total supply | `public` — `totalSupply` is a public view function; mint and burn are publicly traceable | `private` by default, `public` once published | y | observers registered by `SUPPLY_OBSERVER_ROLE` (`addTotalSupplyObserver`, not in Lite); everyone for a handle published by `SUPPLY_PUBLISHER_ROLE` (`publishTotalSupply`) | `confidentialTotalSupply` returns a handle. Mint and burn are publicly traceable as events (participants) but their amounts are encrypted. Publishing consecutive supply values lets anyone infer the net minted / burned amount between two publications (audit finding OZ-L-01); publication SHOULD aggregate many operations. |
| Token decimals | `public` — `decimals` is a public view function | `public` | y | everyone | `decimals()` is a public view; `name`, `symbol`, `tokenId`, `terms`, `information`, documents and `version` are public too. |
| Frozen / blacklisted addresses | `public` — `isFrozen` / `getFrozenTokens` are public view functions and freeze operations emit events | `public` | y | everyone | `isFrozen` is a public view; `AddressFrozen` events are public. RuleEngine lists (blacklist, sanctions) live in external public contracts. |
| Allowlisted / whitelisted addresses (if applicable) | `public` — `isAllowlisted` (CMTAT Allowlist) and `isAddressListed` (Rules whitelist) are public view functions | `public` | y | everyone | `isAllowlisted` / `isAllowlistEnabled` are public views in `CMTATConfidentialWhitelist`; allowlist updates emit events. |

#### Readers

> Typical readers to consider when filling the *Other readers* column. An implementation SHOULD list every case that applies, not only the most restrictive one:
>
> - **everyone** — the value is public on the ledger;
> - **the account holder** — an address can read its own balance and its own transfers, but not those of other holders;
> - **the counterparty of a transfer** — sender and recipient both see the amount, third parties do not;
> - **the issuer or an administrator role** — able to read all balances, typically because the corporate actions covered by this document (snapshot, dividend, forced transfer, freeze) require it;
> - **an auditor, a regulator, or a court-appointed third party** — granted a read credential (view key, decryption share, observer node) permanently or on request;
> - **the operator of the ledger or the validator nodes** — on a permissioned ledger the nodes hosting the data may see it even when the public cannot;
> - **nobody** — the value is recoverable only by the key holder, and is lost with the key.

##### Note

> This subsection is here to provide additional notes regarding privacy and confidentiality. It SHOULD describe **how privacy and confidentiality work on the particular blockchain targeted**, for example: encrypted balances under homomorphic encryption, a shielded pool with zero-knowledge proofs and view keys, confidential amounts with range proofs, per-participant data segregation on a permissioned ledger, or off-chain balances anchored on-chain by a commitment.
>
> It SHOULD also state the consequences for the CMTAT features: how the total supply can be audited when individual balances are hidden, how a snapshot or a dividend is computed on hidden balances, how the freeze and allowlist checks are enforced without revealing the lists, and what an issuer, an auditor, or a regulator has to do to obtain a disclosure.
>
> Privacy MUST NOT remove a mandatory capability: if the issuer cannot read a balance, the implementation MUST still explain how it performs the operations the mandatory criteria require on that balance.

**Mechanism.** Balances, total supply and transfer amounts are `euint64` ciphertexts of the Zama Confidential Blockchain Protocol. The chain stores handles; the FHE computation is performed by the coprocessor network; decryption requires a threshold decryption by the Key Management Service (MPC), which only serves addresses present in the on-chain ACL for that handle (`FHE.allow`) or handles marked publicly decryptable (`FHE.makePubliclyDecryptable`). Inputs are encrypted client-side and accompanied by a ZKPoK verified by the `InputVerifier`. Consequently no node operator, indexer or block explorer can read a balance or an amount; addresses, roles, freeze and allowlist status, documents and metadata are plaintext.

**Who can read.** Every balance update grants the new balance handle and the transferred-amount handle to: the holder, the holder's self-designated observer (`setObserver`, ERC-7984 `ObserverAccess`) and the role observer that `OBSERVER_ROLE` assigns per account (`setRoleObserver`). The total supply handle is granted to the observers registered by `SUPPLY_OBSERVER_ROLE` (not in Lite) after every mint or burn, and can be published to everyone by `SUPPLY_PUBLISHER_ROLE`. Any ACL holder can publish an individual amount with `requestDiscloseEncryptedAmount` / `discloseEncryptedAmount` (`AmountDisclosed` event). ACL grants are permanent: removing an observer stops future grants but does not revoke past ones.

**Consequences for the CMTAT features.**

- *Total supply audit:* an auditor is registered as supply observer, or the issuer publishes the supply. Repeated publications reveal the net minted / burned amount between two publications (OZ-L-01), so publication SHOULD be infrequent and aggregate many operations.
- *Snapshot and dividend:* not offered; the issuer can only reconstruct positions off-chain from the balances and amounts its role observers are allowed to decrypt.
- *Freeze, pause, allowlist, RuleEngine:* enforced on plaintext addresses; the lists are public. No encrypted data is needed for any compliance check.
- *Forced transfer and forced burn:* operate on encrypted amounts; the enforcer needs an observer grant on the target account to know the balance it is seizing, otherwise an over-sized amount silently moves 0.
- *Mandatory read criteria (7, 8):* the issuer obtains disclosure through the observer roles it controls (`OBSERVER_ROLE`, `SUPPLY_OBSERVER_ROLE`); a regulator or a court-appointed third party is given a grant by being set as role observer of the accounts concerned or as supply observer.

**Residual leakage.** Participants, timing and frequency of transfers, mints and burns are public. The balance of a fresh account after a single mint equals the minted amount, so an observer of one is an observer of the other. The Zama protocol's own security assumptions (coprocessor honesty for correctness, KMS threshold for confidentiality) apply.


## Supplementary features

> This section MAY be used to document supplementary features beyond the CMTAT standard that are present in the implementation being approved.

Features present in CMTAT Confidential v1.0.0 that have no CMTAT criterion:

- **Balance observers** (`ERC7984BalanceViewModule`, all variants): a holder slot (`setObserver`, ERC-7984 `ObserverAccess`) and a role slot (`setRoleObserver` / `removeRoleObserver` / `roleObserver`, `OBSERVER_ROLE`) per account; both receive the balance and the transferred amount on every update.
- **Total supply observers** (`ERC7984TotalSupplyViewModule`, all variants except Lite): `addTotalSupplyObserver`, `removeTotalSupplyObserver`, `totalSupplyObservers`, `maxSupplyObservers` / `setMaxSupplyObservers` (`SUPPLY_OBSERVER_ROLE`, cap by `DEFAULT_ADMIN_ROLE`, default 10).
- **Public total supply disclosure** (`ERC7984PublishTotalSupplyModule`, all variants): `publishTotalSupply` (`SUPPLY_PUBLISHER_ROLE`), one handle at a time, irrevocable.
- **Amount disclosure** (ERC-7984): `requestDiscloseEncryptedAmount` / `discloseEncryptedAmount` by any ACL holder of the handle.
- **Operators** (ERC-7984): `setOperator(operator, until)`, `isOperator`, `confidentialTransferFrom`, with pause / freeze / allowlist / RuleEngine applied to the operator as spender.
- **Transfer-and-call** (ERC-7984): `confidentialTransferAndCall` / `confidentialTransferFromAndCall` with `IERC7984Receiver` callback and best-effort refund; documented as safe only with trusted receivers.
- **Token attribute updates** (`ERC7984TokenAttributeModule`): `setName`, `setSymbol` (`TOKEN_ATTRIBUTE_ROLE`), ERC-3643 alignment.
- **Pre-flight views** (ERC-7943 style): `canTransfer(from, to, amount)`, `canTransferFrom(spender, from, to, amount)` (RuleEngine variant), `canSend`, `canReceive`; errors `ERC7943CannotTransfer`, `ERC7943CannotSend`, `ERC7943CannotReceive`. The ERC-7943 interface id is not advertised because the views ignore the amount.
- **Documents and metadata** (CMTAT): ERC-1643 documents (`DOCUMENT_ROLE`), `information()` (`EXTRA_INFORMATION_ROLE`), `contractURI()`.
- **Handle-based overloads**: every mint, burn, transfer and forced operation also accepts an existing `euint64` handle the caller is allowed to use, for composition with other confidential contracts.


## Conclusion

> This section MUST describe, in broad terms, **how the implementation being approved works technically**, so that a reader who has not gone through the tables can understand the design and its main differences with the CMTAT specification. It SHOULD cover at least the following points:
>
> - **Token model**: the underlying token primitive of the target blockchain (for example ERC-20, SPL token, Soroban token interface, UTXO-based asset), and how balances, total supply, and decimals are represented.
> - **Architecture**: single contract or several modules/programs, how they are linked (inheritance, composition, external calls, on-chain registry), and the upgradeability strategy (proxy, native chain upgrade, immutable with redeployment).
> - **Access control model**: which roles exist, who holds the administrator role, how roles are granted and revoked, and how these roles map to the CMTAT roles.
> - **Transfer control flow**: which checks are applied on a transfer (pause, freeze, partial freeze, allowlist, rule engine or transfer hook), in which order, and where this logic lives (inside the token, in an external module, or in the chain runtime).
> - **Issuance and cancellation**: the mint and burn paths, forced transfer and forced burn, and the behaviour on a frozen address or while the contract is paused.
> - **Data and metadata storage**: how terms, `tokenId`, debt attributes, and credit events are stored (on-chain state, hash with off-chain document, or chain-native metadata).
> - **Main differences with the CMTAT Solidity implementation**, and the reason for each one (chain constraints, legal context, performance, code size).
> - **Known limitations** and features that are planned but not yet implemented.
>
> The [Summary](#summary) gives the counts; this section gives the technical explanation behind them and MUST stay consistent with it.

**Token model.** CMTAT Confidential is an ERC-7984 confidential fungible token (OpenZeppelin Confidential Contracts v0.5.1) on EVM chains served by the Zama FHEVM coprocessor. Balances, total supply and amounts are `euint64` ciphertext handles; the plaintext is only obtainable through the Zama KMS by an address that the contract has put on the FHE access-control list for that handle. `decimals` is a public immutable (0 to 18). All other state — addresses, roles, pause, freeze, allowlist, RuleEngine address, terms, `tokenId`, documents, version — is plaintext, exactly as in CMTAT Solidity.

**Architecture.** A single abstract base, `CMTATConfidentialBase`, combines ERC-7984, the CMTAT `CMTATBaseGeneric` (pause, freeze, access control, ERC-1643 documents, extra information, validation hooks) and a set of FHE modules that follow one pattern: a role constant, a modifier calling a virtual `_authorizeXxx()` hook, and an optional virtual `_validateXxx()` hook overridden in the base to apply the CMTAT checks. Four immutable deployment contracts derive from it: `CMTATConfidential` (reference, with total supply observers), `CMTATConfidentialLite` (without them), `CMTATConfidentialRuleEngine` (adds a CMTA `RuleEngine` hook) and `CMTATConfidentialWhitelist` (adds the CMTAT `AllowlistModule`). There is no proxy: the constructor runs the initializer once, and a new version is a new deployment. Version 1.0.0 was audited by OpenZeppelin (report in `doc/audit/v1.0.0/`).

**Access control.** OpenZeppelin `AccessControl` through the CMTAT `AccessControlModule`; `DEFAULT_ADMIN_ROLE` administers every role and is treated as holding all of them. The CMTAT roles are kept (`MINTER`, `BURNER`, `PAUSER`, `ENFORCER`, `EXTRA_INFORMATION`, `DOCUMENT`, `ALLOWLIST`) and four confidentiality-specific roles are added (`FORCED_OPS`, `OBSERVER`, `SUPPLY_OBSERVER`, `SUPPLY_PUBLISHER`), plus `TOKEN_ATTRIBUTE` and `RULE_ENGINE`. The table under [Access Control](#access-control) gives the mapping.

**Transfer control flow.** All eight ERC-7984 transfer entry points are overridden to call the CMTAT `_canTransferGenericByModule(spender, from, to)` first: pause, then frozen spender / sender / receiver, then — in the variants — allowlist membership or `ruleEngine.canTransfer*` with `value = 0`. A rejection reverts with `ERC7943CannotTransfer(from, to, 0)`. The `_beforeTransfer` hook then notifies the RuleEngine (`transferred(...)`) before any FHE operation, and finally the ERC-7984 `_update` moves the encrypted amount and re-grants ACL to the holders and their observers. The logic is entirely inside the token except for the external rules of the RuleEngine variant. Because amounts are encrypted, no check can depend on the amount: an insufficient balance leads to a transfer of 0 rather than a revert, and amount-based rules cannot be enforced.

**Issuance and cancellation.** `mint` (`MINTER_ROLE`) and `burn` (`BURNER_ROLE`) take an encrypted amount with a ZKPoK; both are blocked on a frozen address and on a deactivated contract, and allowed while paused. `forcedTransfer` and `forcedBurn` (`FORCED_OPS_ROLE`) are both implemented, both restricted to a frozen source address and both exempt from pause, deactivation, allowlist and RuleEngine; `forcedTransfer` never burns. There is no self-burn, no `burnFrom`, no batch operation and no cross-chain entry point.

**Data and metadata storage.** `terms`, `tokenId` and `information` are stored on-chain by the CMTAT `ExtraInformationModule` (terms as name / URI / hash); documents follow ERC-1643 with an on-chain hash and off-chain URI. No debt attributes and no credit events are stored. `name` and `symbol` are updatable.

**Main differences with CMTAT Solidity, and why.**

1. *Encrypted balances, amounts and supply* (criteria 7, 8 `partial`): the purpose of the implementation. Disclosure is organised through observer roles and publication functions instead of public views.
2. *Operators instead of allowances* (criterion 13 `partial`): ERC-7984 design, since an allowance amount cannot be compared with an encrypted value.
3. *Silent zero on insufficient balance* instead of a revert: FHE comparison results cannot revert without leaking the outcome.
4. *`value = 0` towards the RuleEngine*: amount-based rules are unenforceable; only address-based rules apply.
5. *Forced operations require a frozen source* and `forcedBurn` is the only forced cancellation: a deliberate, stricter operational guard; both functions exist unlike CMTAT Standard.
6. *No partial freeze, snapshot, dividend, debt, credit events, ERC-2771, cross-chain, upgradeability*: the first three are incompatible with encrypted balances at reasonable cost; the others were left out of v1.0.0 for scope and code-size reasons (the variants are 19.7–22.2 KB).
7. *`uint64` value range* (max 18 446 744 073 709 551 615 raw units): `decimals` capped at 18, 6 recommended.

**Known limitations.** FHE ACL grants are permanent, so a removed observer keeps access to past handles. Publishing the total supply repeatedly leaks the net mint / burn between publications (OZ-L-01). `confidentialTransferAndCall` can lose the sender's tokens with a malicious receiver (best-effort refund). Every transfer costs one FHE operation per handle plus one ACL grant per observer, so observer lists SHOULD stay small (`maxSupplyObservers`, default 10). ERC-7943 views ignore the amount and the interface id is not advertised. The CMTAT library under `lib/CMTAT` (v3.3.0-rc1) and the RuleEngine (v3.0.0-rc4) are release candidates and were outside the OpenZeppelin audit scope.

These points are consistent with the figures in the [Summary](#summary): 17 mandatory `y`, 2 mandatory `partial`, no mandatory `n`; 6 optional `y`, 1 optional `partial`, 35 optional `n`.


## Reference

Submodules used in this project and current checked-out versions:

| Submodule | Repository | Version | Commit |
|---|---|---|---|
| CMTAT | https://github.com/CMTA/CMTAT | `v3.3.0-rc3` | `658672f190d56d3f61663a7d6d51962b8980df70` |
| SnapshotEngine | https://github.com/CMTA/SnapshotEngine | `v0.5.0` | `aa089353605cd1b0e555d22b62aa4fbeaae7df25` |
| RuleEngine | https://github.com/CMTA/RuleEngine | `v3.0.0-rc6` | `ca75429c581a2eb9043e4719561e941d0b2e1206` |
| Rules | https://github.com/CMTA/Rules | `v0.6.0` | `283efe723225c89729fd618852a9c2705a47180b` |
| CMTAT-Confidential | https://github.com/CMTA/CMTAT-Confidential | `v1.0.0` | `285ed93721dfbbc147932bd450aa057126e70e84` |
| CMTAT-LayerZero | https://github.com/CMTA/CMTAT-LayerZero | `v0.2.0` + 1 commit | `e57ca4f076e44ed5a08fdfce9379e2a82925d7cf` |
| private-CMTAT-aztec | https://github.com/taurushq-io/private-CMTAT-aztec | `0.1.1` + 25 commits | `61f4220d5565840fd4fcdd2b723c9f55eb824c60` |

The first four are the implementations the criteria are mapped against. The last three are referenced by the [Cross-Chain Bridge Support](#cross-chain-bridge-support) and [Privacy and Confidentiality](#privacy-and-confidentiality) sections, which are outside the equivalency count.


Dependencies of the implementation being approved (CMTAT Confidential `v1.0.0`, commit `285ed93`):

| Dependency | Repository | Version | Commit / package |
|---|---|---|---|
| CMTAT (submodule `lib/CMTAT`) | https://github.com/CMTA/CMTAT | `v3.3.0-rc1` | `580d4776e4cbb857b2da7d83fd79144ae7e47557` |
| RuleEngine (submodule `lib/RuleEngine`) | https://github.com/CMTA/RuleEngine | `v3.0.0-rc4` | `66fcf2aafebd1f9d9de8a81dec92b88da071c9b3` |
| OpenZeppelin Confidential Contracts (submodule) | https://github.com/OpenZeppelin/openzeppelin-confidential-contracts | `v0.5.1` | `afa97a6cbfa35961c1e2ce21abf5c2115bfb5c0f` |
| CMTAT-equivalency-assessment (submodule, this template) | https://github.com/CMTA/CMTAT-equivalency-assessment | `v0.3.0` | `e2ddb6ee05354311fcf2c00f421f5a4f0fb94944` |
| `@fhevm/solidity` | https://github.com/zama-ai/fhevm | `0.11.1` | npm |
| `@openzeppelin/contracts` / `contracts-upgradeable` | https://github.com/OpenZeppelin/openzeppelin-contracts | `5.6.1` | npm |
