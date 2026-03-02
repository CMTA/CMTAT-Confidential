# CMTAT FHE - Confidential Security Token

A confidential security token implementation combining [CMTAT](https://github.com/CMTA/CMTAT) compliance features with the [Zama Confidential Blockchain Protocol](https://docs.zama.org/protocol) for private balances.

## Overview

CMTAT FHE implements the [ERC-7984](https://docs.openzeppelin.com/confidential-contracts/erc7984) standard (Confidential Fungible Token) with CMTAT regulatory compliance modules. All token balances and transfer amounts are encrypted using Fully Homomorphic Encryption (FHE), ensuring transfer amount and balance privacy while maintaining regulatory compliance capabilities.

CMTAT is a security token framework by [Capital Markets and Technology Association](https://www.cmta.ch/) that includes various compliance features such as conditional transfer, account freeze, and token pause. The specification are blockchain agnostic with implementation available for several different blockchain ecosystem such as [Ethereum](https://github.com/CMTA/CMTAT), [Solana](https://github.com/CMTA/CMTAT-Solana/) and [Tezos](https://github.com/CMTA/CMTAT-Tezos-FA2). CMTAT FHE is built on the Ethereum version written in Solidity.

### What is FHE?

Fully Homomorphic Encryption (FHE) enables computing directly on encrypted data without ever decrypting it. The Zama Protocol uses FHE combined with Multi-Party Computation (MPC) for threshold decryption and Zero-Knowledge Proofs (ZKPoKs) for input validation, providing:

- **End-to-end encryption**: Transaction inputs and state remain encrypted - no one can see the data, not even node operators
- **Composability**: Confidential contracts can interact with other contracts and dApps
- **Programmable confidentiality**: Smart contracts define who can decrypt what through the Access Control List (ACL)

### Key Features

- **Confidential Balances**: All balances are stored as `euint64` (encrypted unsigned 64-bit integers) - only authorized parties can decrypt
- **Confidential Transfers**: Transfer amounts are submitted as encrypted inputs with Zero-Knowledge Proofs of Knowledge (ZKPoKs)
- **Regulatory Compliance**: Pause, freeze, and forced transfer capabilities for compliance
- **Role-Based Access Control**: Granular permissions for minting, burning, pausing, and enforcement
- **Document Management**: Attach terms, documents, and metadata to tokens
- **ERC-7984 Standard**: Based on OpenZeppelin's confidential token implementation

## Architecture

```
CMTAT-FHE
├── ERC7984 (OpenZeppelin Confidential Contracts)
│   ├── Encrypted balances (euint64)
│   ├── Confidential transfers
│   ├── Operator system
│   └── Disclosure mechanism
│
├── CMTATBaseGeneric (CMTAT Modules)
│   ├── PauseModule - Pause/unpause transfers
│   ├── EnforcementModule - Freeze/unfreeze addresses
│   ├── AccessControlModule - Role-based permissions
│   ├── DocumentEngineModule - ERC-1643 document management
│   └── ExtraInformationModule - Token metadata (tokenId, terms, info)
│
├── FHE Modules (custom extensions)
│   ├── ERC7984MintModule - Modular mint with authorization hook
│   ├── ERC7984BurnModule - Modular burn with authorization hook
│   ├── ERC7984EnforcementModule - Forced transfer and forced burn
│   ├── ERC7984BalanceViewModule - Per-account balance observers (holder + role slots)
│   ├── ERC7984PublishTotalSupplyModule - Public total supply disclosure (in CMTATFHEBase)
│   └── ERC7984TotalSupplyViewModule - Total supply observer list with auto ACL re-grant (CMTATFHE only)
│
└── Zama Protocol Infrastructure (configured via ZamaEthereumConfig)
    ├── ACL - Access Control List for encrypted data permissions
    ├── FHEVMExecutor (Coprocessor) - Performs FHE computations
    ├── KMSVerifier - Verifies decryption proofs from Key Management System
    └── InputVerifier - Validates encrypted inputs and ZKPoKs
```

### How It Works

1. **Symbolic Execution**: When a contract calls an FHE operation, the host chain produces a pointer to the result and emits an event to notify the coprocessor network
2. **Coprocessor Computation**: The coprocessors perform the actual FHE computation off-chain
3. **Threshold Decryption**: Decryption requests go through the Key Management Service (KMS), which uses MPC to ensure no single party can access the private key

## Summary

This section maps the CMTAT framework features to the CMTAT FHE implementation, showing how standard functionalities are adapted for Fully Homomorphic Encryption.

### CMTAT Framework Mapping

| **CMTAT Framework Mandatory Functionalities** | **CMTATFHE Corresponding Features** |
| --------------------------------------------- | ----------------------------------- |
| Know total supply | `confidentialTotalSupply()` returns `euint64` (encrypted) |
| Know balance | `confidentialBalanceOf()` returns `euint64` (encrypted) |
| Transfer tokens | `confidentialTransfer()` with encrypted amount + ZKPoK |
| Create tokens (mint) | `mint()` with encrypted amount + ZKPoK |
| Cancel tokens (burn) | `burn()` with encrypted amount + ZKPoK |
| Pause tokens | `pause()` - inherited from CMTAT |
| Unpause tokens | `unpause()` - inherited from CMTAT |
| Deactivate contract | `deactivateContract()` - inherited from CMTAT |
| Freeze | `setAddressFrozen(address, true)` - inherited from CMTAT |
| Unfreeze | `setAddressFrozen(address, false)` - inherited from CMTAT |
| Name attribute | ERC20 `name()` - public |
| Ticker symbol attribute | ERC20 `symbol()` - public |
| Token ID attribute | `tokenId()` - inherited from CMTAT |
| Reference to legally required documentation | `terms()` - inherited from CMTAT |

### Extended Features

| **Functionalities** | **CMTAT FHE Features** | **Available** |
| ------------------- | --------------------- | ------------- |
| Forced Transfer | `forcedTransfer()` with encrypted amount | ✓ |
| Forced Burn | `forcedBurn()` with encrypted amount | ✓ |
| Operator System | `setOperator()` / `confidentialTransferFrom()` | ✓ |
| Public Disclosure | `requestDiscloseEncryptedAmount()` / `discloseEncryptedAmount()` | ✓ |
| On-chain snapshot | Not implemented | ✗ |
| Freeze partial tokens | Not implemented (all balances are encrypted) | ✗ |
| Integrated allowlisting | Not implemented | ✗ |
| RuleEngine / transfer hook | Not implemented | ✗ |
| Upgradability | Not implemented (standalone only) | ✗ |

### Implementation Details

| **Functionalities** | **CMTAT FHE** | **Note** |
| ------------------- | ------------ | -------- |
| Mint while paused | ✓ | Minting is allowed when contract is paused (same as CMTAT) |
| Burn while paused | ✓ | Burning is allowed when contract is paused (same as CMTAT) |
| Self burn | ✗ | Only `BURNER_ROLE` can burn tokens |
| Standard burn on frozen address | ✗ | Use `forcedBurn()` |
| Forced burn from frozen address | ✓ | `forcedBurn()` with `FORCED_OPS_ROLE` |
| Burn via `forcedTransfer` | ✗ | `forcedTransfer` reverts if `to` is `address(0)` -- use `forcedBurn()` |
| Balance overflow protection | ✓ | Uses FHESafeMath: transfers 0 on overflow/underflow (privacy-preserving) |

### Key Differences from Standard CMTAT

| **Aspect** | **CMTAT (Standard)** | **CMTAT FHE (Confidential)** |
| ---------- | -------------------- | --------------------------- |
| Balance type | `uint256` (public) | `euint64` (encrypted) |
| Value range | Up to ~1.15 × 10⁷⁷ (`uint256`) | Up to ~1.84 × 10¹⁹ (`uint64` max = 18,446,744,073,709,551,615) |
| Transfer amount | `uint256` (public) | `externalEuint64` + ZKPoK |
| Total supply | `uint256` (public) | `euint64` (encrypted) |
| Balance visibility | Anyone can read | Only ACL-authorized parties can decrypt |
| Transfer validation | Reverts on insufficient balance | Transfers 0 silently (privacy-preserving) |
| Allowance system | ERC20 `approve`/`allowance` | Operator system with time-limited access |
| Forced Burn | Through `forcedTransfer`or `forcedBurn` if implemented | Through `forcedBurn` since the function is implemented |

> **Important:** The `euint64` type has a significantly smaller range than `uint256`. For tokens with 18 decimals, `euint64` supports a maximum of ~18.44 tokens. Consider using fewer decimals (e.g., 6 or 8) to accommodate larger supplies.

### Decryption Requirements

To decrypt encrypted values (balances, amounts, total supply), the requesting party must:

1. Have ACL permission granted via `FHE.allow()` or `FHE.allowTransient()` (verifiable with `FHE.isAllowed()` or `FHE.isSenderAllowed()`)
2. Or the value must be marked publicly decryptable via `FHE.makePubliclyDecryptable()`
3. Request decryption through the Zama Relayer SDK (`@zama-fhe/relayer-sdk`)
4. Submit the decryption proof on-chain via `FHE.checkSignatures()` (reverts if the proof is invalid)

## Deployment Variants

Two deployment-ready contracts are provided. Both share the same abstract base (`CMTATFHEBase`) and are functionally identical except for total supply visibility.

| | `CMTATFHE` | `CMTATFHELite` |
|---|---|---|
| Confidential balances & transfers | ✓ | ✓ |
| Mint / Burn / Forced ops | ✓ | ✓ |
| Pause / Freeze | ✓ | ✓ |
| Per-account balance observers | ✓ | ✓ |
| `publishTotalSupply` (public disclosure) | ✓ | ✓ |
| Total supply observer list (auto ACL) | ✓ | ✗ |
| `SUPPLY_OBSERVER_ROLE` | ✓ | ✓ |
| Contract size | ~20.5 KB | ~19.2 KB |

Choose `CMTATFHELite` when automatic per-observer ACL re-grant on every mint/burn is not required and you want to minimize deployment cost. `publishTotalSupply` (one-shot public disclosure) is available in both variants.

## Installation

```bash
# Clone the repository
git clone --recursive https://github.com/your-repo/CMTAT-FHE.git
cd CMTAT-FHE

# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test
```

## Roles

| Role | Description |
|------|-------------|
| `DEFAULT_ADMIN_ROLE` | Can grant/revoke all roles, deactivate contract |
| `MINTER_ROLE` | Can mint new tokens |
| `BURNER_ROLE` | Can burn tokens |
| `PAUSER_ROLE` | Can pause/unpause all transfers |
| `ENFORCER_ROLE` | Can freeze and unfreeze addresses |
| `FORCED_OPS_ROLE` | Can execute forced transfers and forced burns on frozen addresses |
| `OBSERVER_ROLE` | Can assign per-account balance observers via `setRoleObserver` |
| `SUPPLY_OBSERVER_ROLE` | Can manage total supply observers and call `publishTotalSupply` |

## Contract Functions

### Minting

Mint tokens to an address (requires `MINTER_ROLE`):

```solidity
// With encrypted input and proof
function mint(
    address to,
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(MINTER_ROLE) returns (euint64 transferred);

// With existing encrypted handle (caller must have ACL access)
function mint(
    address to,
    euint64 amount
) public onlyRole(MINTER_ROLE) returns (euint64 transferred);
```

### Burning

Burn tokens from an address (requires `BURNER_ROLE`):

```solidity
function burn(
    address from,
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(BURNER_ROLE) returns (euint64 transferred);
```

### Transfers

ERC-7984 exposes eight transfer function variants:

| Function | Description |
|----------|-------------|
| `confidentialTransfer(to, amount)` | Transfer using existing handle |
| `confidentialTransfer(to, amount, proof)` | Transfer with encrypted input |
| `confidentialTransferFrom(from, to, amount)` | Operator transfer using handle |
| `confidentialTransferFrom(from, to, amount, proof)` | Operator transfer with proof |
| `confidentialTransferAndCall(...)` | Transfer with ERC-1363 callback |
| `confidentialTransferFromAndCall(...)` | Operator transfer with callback |

Example transfer:

```typescript
import { fhevm } from 'hardhat';

// Create encrypted input
const encryptedInput = await fhevm
  .createEncryptedInput(tokenAddress, senderAddress)
  .add64(1000) // Amount to transfer
  .encrypt();

// Execute transfer
await token.connect(sender)['confidentialTransfer(address,bytes32,bytes)'](
  recipientAddress,
  encryptedInput.handles[0],
  encryptedInput.inputProof
);
```

### Forced Transfer

Enforcers can move tokens from frozen addresses for regulatory compliance. Forced transfers can be performed even when the contract is deactivated.

```solidity
function forcedTransfer(
    address from,        // Must be frozen
    address to,          // Must not be address(0)
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(FORCED_OPS_ROLE) returns (euint64 transferred);
```

**Requirements:**
- The `from` address must be frozen
- The `to` address must not be `address(0)` -- use `forcedBurn()` for burning
- Can be performed even when the contract is deactivated

> **Note:** This is intentionally stricter than standard CMTAT, which allows `forcedTransfer` on any address (frozen or not). CMTAT FHE requires the address to be frozen first, creating an explicit audit trail (freeze event followed by forced transfer).

### Forced Burn

Enforcers can burn tokens directly from frozen addresses without the holder's consent. This is the dedicated burn equivalent of `forcedTransfer`. Forced burns can be performed even when the contract is deactivated.

```solidity
function forcedBurn(
    address from,        // Must be frozen
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(FORCED_OPS_ROLE) returns (euint64 burned);
```

**Requirements:**
- The `from` address must be frozen
- Can be performed even when the contract is deactivated

> **Note:** Same freeze requirement as `forcedTransfer` for consistency. The enforcer creates the encrypted input specifying how many tokens to burn.

### Total Supply Visibility

By default the total supply is encrypted and inaccessible to third parties. Two mechanisms are available to open read access, both gated by `SUPPLY_OBSERVER_ROLE`.

#### Option 1 — Authorized observers (automatic, stays current) — `CMTATFHE` only

Register addresses that will automatically receive ACL access to the total supply handle after every mint or burn:

```solidity
// Grant SUPPLY_OBSERVER_ROLE to the compliance manager
await token.grantRole(SUPPLY_OBSERVER_ROLE, complianceManager.address);

// Register a regulator as a total supply observer
await token.connect(complianceManager).addTotalSupplyObserver(regulatorAddress);

// Remove an observer (stops future grants; past ACL grants are irrevocable)
await token.connect(complianceManager).removeTotalSupplyObserver(regulatorAddress);

// Inspect the current observer list
const observers = await token.totalSupplyObservers();
```

Once registered, the observer can decrypt off-chain using the standard user-decryption flow:

```typescript
const handle = await token.confidentialTotalSupply();
const supply = await fhevm.userDecryptEuint(FhevmType.euint64, handle, tokenAddress, observer);
```

#### Option 2 — Public disclosure (anyone, irrevocable per handle) — `CMTATFHE` and `CMTATFHELite`

Mark the current total supply handle as publicly decryptable. Any off-chain party can then request decryption via the Zama Relayer SDK without ACL access. After the next mint or burn, the new handle will not be publicly decryptable — call again if needed.

```solidity
await token.connect(complianceManager).publishTotalSupply();
```

| Mechanism | Availability | Access scope | Stays current after mint/burn |
|-----------|-------------|-------------|-------------------------------|
| `addTotalSupplyObserver` | `CMTATFHE` only | Specific registered addresses | Yes — re-granted automatically via `_afterMint`/`_afterBurn` hooks |
| `publishTotalSupply` | `CMTATFHE` and `CMTATFHELite` | Anyone (no ACL needed) | No — must be called again after each mint/burn |

> **Gas note:** In `CMTATFHE`, every mint or burn triggers `_updateTotalSupplyObserversACL()`, which iterates over all registered total supply observers and calls `FHE.allow()` for each one. Additionally, `_update` runs a chain of balance observer ACL grants. Keep both observer lists small to control gas costs per operation.

### Pause / Unpause

Pause all transfers (requires `PAUSER_ROLE`):

```solidity
function pause() public onlyRole(PAUSER_ROLE);
function unpause() public onlyRole(PAUSER_ROLE);
```

### Freeze / Unfreeze

Freeze specific addresses (requires `ENFORCER_ROLE`):

```solidity
function setAddressFrozen(address account, bool freeze) public onlyRole(ENFORCER_ROLE);
function isFrozen(address account) public view returns (bool);
```

### Deactivate Contract

Permanently deactivate the contract (requires `DEFAULT_ADMIN_ROLE`, contract must be paused):

```solidity
function deactivateContract() public onlyRole(DEFAULT_ADMIN_ROLE);
```

## Operator System

Operators can transfer tokens on behalf of holders using `confidentialTransferFrom`. Unlike ERC-20 allowances, operators have time-limited unlimited access.

```typescript
// Set operator for 24 hours
const expirationTimestamp = Math.floor(Date.now() / 1000) + 86400;
await token.connect(holder).setOperator(operatorAddress, expirationTimestamp);

// Check operator status
const isOp = await token.isOperator(holderAddress, operatorAddress);
```

**Warning**: Setting an operator grants them access to transfer ALL your tokens during the approval period.

## Decrypting Balances

Only the balance holder can decrypt their balance:

```typescript
import { FhevmType } from '@fhevm/hardhat-plugin';

// Get encrypted balance handle
const balanceHandle = await token.confidentialBalanceOf(holderAddress);

// Decrypt (only works for the holder)
const balance = await fhevm.userDecryptEuint(
  FhevmType.euint64,
  balanceHandle,
  tokenAddress,
  holder // Signer must be the balance owner
);
```

### Public Disclosure

Holders can publicly disclose amounts:

```solidity
// Request disclosure (makes handle publicly decryptable)
function requestDiscloseEncryptedAmount(euint64 encryptedAmount) public;

// Finalize with decryption proof
function discloseEncryptedAmount(
    euint64 encryptedAmount,
    uint64 cleartextAmount,
    bytes calldata decryptionProof
) public;
```

## Deployment

```typescript
import { ethers } from 'hardhat';

const extraInfoAttributes = {
  tokenId: 'TOKEN-001',
  terms: 'https://example.com/terms',
  information: 'Security token for XYZ',
};

const token = await ethers.deployContract('CMTATFHE', [
  'My Token',           // name
  'MTK',                // symbol
  'https://example.com/metadata', // contractURI
  adminAddress,         // admin with DEFAULT_ADMIN_ROLE
  extraInfoAttributes,  // token metadata
]);

// Grant roles
await token.grantRole(MINTER_ROLE, minterAddress);
await token.grantRole(BURNER_ROLE, burnerAddress);
await token.grantRole(PAUSER_ROLE, pauserAddress);
await token.grantRole(ENFORCER_ROLE, enforcerAddress);     // freeze/unfreeze addresses
await token.grantRole(FORCED_OPS_ROLE, enforcerAddress);   // forced transfer / forced burn
```

## Dependencies

| Package | Version |
|---------|---------|
| `@fhevm/solidity` | 0.9.1 |
| `@fhevm/hardhat-plugin` | 0.3.0-1 |
| `@openzeppelin/contracts` | 5.5.0 |
| `@openzeppelin/contracts-upgradeable` | 5.5.0 |
| **Submodule** |  |
| [OpenZeppelin Confidential Contracts](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts) | v0.3.1 |

## Project Structure

```
CMTAT-FHE/
├── contracts/
│   ├── CMTATFHEBase.sol                      # Abstract base (all shared logic)
│   ├── CMTATFHE.sol                          # Full variant (+ total supply visibility)
│   ├── CMTATFHELite.sol                      # Lite variant (smaller, no total supply module)
│   └── modules/
│       ├── ERC7984MintModule.sol                  # Mint with authorization hook
│       ├── ERC7984BurnModule.sol                  # Burn with authorization hook
│       ├── ERC7984EnforcementModule.sol           # Forced transfer and forced burn
│       ├── ERC7984BalanceViewModule.sol           # Per-account balance observers
│       ├── ERC7984PublishTotalSupplyModule.sol    # Public total supply disclosure
│       └── ERC7984TotalSupplyViewModule.sol       # Total supply observer list (auto ACL)
├── CMTAT/                                    # CMTAT submodule (compliance modules)
├── openzeppelin-confidential-contracts/      # OZ submodule (ERC7984)
├── docs/
│   ├── fhe/                                  # Zama FHE documentation
│   └── openzeppelin-confidential/            # OZ confidential docs
├── test/
│   ├── CMTATFHE.test.ts                           # Full variant core tests
│   ├── CMTATFHELite.test.ts                       # Lite variant core tests (shared suite)
│   ├── ERC7984BalanceViewModule.test.ts           # Balance observer module tests
│   ├── ERC7984PublishTotalSupplyModule.test.ts    # Public disclosure module tests
│   ├── ERC7984TotalSupplyViewModule.test.ts       # Total supply observer module tests
│   └── helpers/
│       ├── deploy.ts                         # Shared deploy helper + role constants
│       ├── core-tests.ts                     # Shared Mocha test suite
│       └── accounts.ts                       # Account impersonation utilities
└── hardhat.config.js
```

## FAQ

### 1. As an issuer, can I burn tokens from a token holder without their consent?

**Answer:** Yes, as an issuer with the `FORCED_OPS_ROLE`, you can burn tokens from any holder without their consent using the `forcedBurn()` function.

**How it works:**

1. First freeze the holder's address using `setAddressFrozen(holderAddress, true)` (requires `ENFORCER_ROLE`)
2. Use the `forcedBurn()` function to burn tokens directly from the frozen address (requires `FORCED_OPS_ROLE`)
3. This function can be performed even when the contract is deactivated
4. Only accounts with `FORCED_OPS_ROLE` can execute forced burns

**Use cases for regulatory compliance:**
- Court orders requiring asset seizure
- Sanctions compliance
- Error correction (e.g., tokens sent to wrong address)

**Code example:**
```javascript
// Step 1: Freeze the holder's address
await token.connect(enforcer).setAddressFrozen(holderAddress, true);

// Step 2: Create encrypted input for the amount to burn
const encryptedInput = await fhevm
    .createEncryptedInput(tokenAddress, enforcerAddress)
    .add64(amountToBurn)
    .encrypt();

// Step 3: Force burn tokens from the frozen address
await token.connect(enforcer)['forcedBurn(address,bytes32,bytes)'](
    holderAddress,                  // from (must be frozen)
    encryptedInput.handles[0],      // encrypted amount
    encryptedInput.inputProof       // ZKPoK proof
);
```

**Note:** The regular `burn()` function requires `BURNER_ROLE` and will fail if the target address is frozen. For frozen addresses, use `forcedBurn()` instead (requires `FORCED_OPS_ROLE`). The `from` address must be frozen before calling `forcedBurn()`. Note that `forcedTransfer()` reverts if `to` is `address(0)` -- use `forcedBurn()` for burning.

> **Design choice:** Standard CMTAT allows `forcedTransfer` and `forcedBurn` on any address (frozen or not). CMTAT FHE intentionally requires the address to be frozen first, creating an explicit audit trail (freeze event followed by forced burn/transfer).

### 2. As a token holder, how do I transfer my tokens to another address?

**Answer:** Transfers in CMTAT FHE use encrypted inputs to preserve confidentiality. Here's the complete process:

#### Step 1: Create an encrypted input

Encrypted inputs are data values submitted in ciphertext form, accompanied by **Zero-Knowledge Proofs of Knowledge (ZKPoKs)** to ensure validity without revealing the plaintext.

```javascript
const encryptedInput = await fhevm
    .createEncryptedInput(tokenContractAddress, yourAddress)
    .add64(amount)  // Amount to transfer (will be encrypted)
    .encrypt();
```

#### Step 2: Call the transfer function

```javascript
await token.confidentialTransfer(
    recipientAddress,
    encryptedInput.handles[0],  // externalEuint64 handle
    encryptedInput.inputProof   // ZKPoK proof
);
```

#### How validation works on-chain

1. **Input verification**: The `FHE.fromExternal()` function validates the ciphertext and ZKPoK
2. **Type conversion**: Converts `externalEuint64` into `euint64` for contract operations
3. **Balance check**: If balance is insufficient, transfer executes but transfers 0 (FHE doesn't reveal balance)

#### Alternative: Using an operator

You can authorize an operator to transfer on your behalf using time-limited approval:

```javascript
const expirationTimestamp = Math.round(Date.now() / 1000) + 60 * 60 * 24; // 24 hours
await token.connect(holder).setOperator(operatorAddress, expirationTimestamp);

// Operator can now call confidentialTransferFrom
await token.connect(operator).confidentialTransferFrom(
    holderAddress,
    recipientAddress,
    encryptedAmount,
    inputProof
);
```

**Important:** Setting an operator allows them to transfer **all your tokens**. Carefully vet operators before approval.

#### Transfer requirements
- Your address must not be frozen
- The recipient address must not be frozen
- The contract must not be paused or deactivated

---

### 3. Can I deploy CMTAT FHE contracts on Ethereum mainnet?

**Answer:** **Yes** - the Zama Protocol mainnet on Ethereum is now live.

#### How does it work?

Ethereum mainnet does not natively support FHE operations. The Zama Protocol uses a **coprocessor architecture** where the host chain (Ethereum) performs symbolic execution, and the actual FHE computations are performed off-chain by coprocessors. The infrastructure includes:

- **ACL (Access Control List)**: Manages permissions for encrypted data
- **FHEVMExecutor (Coprocessor)**: Performs encrypted computations off-chain
- **KMSVerifier**: Verifies decryption proofs from the Key Management System
- **InputVerifier**: Validates encrypted inputs and ZKPoKs

#### Where can you deploy?

| Network | Chain ID | Status |
|---------|----------|--------|
| Local development | 31337 | Supported (mock coprocessor via hardhat plugin) |
| Ethereum Sepolia | 11155111 | Supported (Zama testnet infrastructure) |
| Ethereum Mainnet | 1 | **Live** |

#### Requirements for deployment

1. **Inherit from `ZamaEthereumConfig`**: This automatically configures coprocessor addresses:
   ```solidity
   import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
   
   contract MyToken is ERC7984, ZamaEthereumConfig {
       // Constructor automatically calls FHE.setCoprocessor()
   }
   ```

2. **Target network must have Zama infrastructure**: The coprocessor contracts must be deployed and operational

3. **Users need compatible tools**: Client applications must use the Relayer SDK to create encrypted inputs and request decryptions

---

### 4. Is it possible to also provide privacy for addresses?

**Answer:** Yes, it is technically possible using **encrypted addresses** (`eaddress` type in fhEVM).

#### How it works

The fhEVM library provides the `eaddress` type which encrypts Ethereum addresses. This enables:
- Hiding sender and recipient addresses in transfers
- Omnibus account patterns where multiple users share a single on-chain address

#### Implementation: Omnibus pattern

The OpenZeppelin Confidential Contracts library includes `ERC7984Omnibus` extension:

1. Uses a single omnibus address visible on-chain
2. Maintains encrypted mappings of actual user addresses to balances
3. Transfers happen between encrypted addresses within the omnibus

```solidity
function confidentialTransferFromOmnibus(
    address omnibusFrom,
    address omnibusTo,
    externalEaddress externalSender,      // encrypted sender
    externalEaddress externalRecipient,   // encrypted recipient
    externalEuint64 externalAmount,
    bytes calldata inputProof
) public virtual returns (euint64);
```

#### Trade-offs

| Benefit | Cost |
|---------|------|
| Address privacy | Higher gas costs for encrypted address operations |
| Regulatory compliance (omnibus accounts) | More complex user experience |
| Institutional custody patterns | Requires trusted omnibus operators |

#### Regulatory considerations

Hiding participant identities may conflict with AML/KYC requirements in some jurisdictions. Consider your compliance obligations before implementing address privacy.

---

### 5. Is the total supply public or private information?

**Answer:** The total supply is **private** (encrypted) by default in ERC7984.

#### Technical details

- The `_totalSupply` variable is stored as `euint64` (encrypted unsigned 64-bit integer)
- The `confidentialTotalSupply()` function returns an encrypted handle, not a plaintext value
- Access is controlled by the ACL (Access Control List)

```solidity
// Returns an encrypted handle (euint64), not the actual value
function confidentialTotalSupply() public view returns (euint64);
```

#### How to grant access to the total supply

CMTAT FHE provides two built-in mechanisms (both require `SUPPLY_OBSERVER_ROLE`):

**Option A — Authorized observers (stays current automatically) — `ERC7984TotalSupplyViewModule`, `CMTATFHE` only**

Register specific addresses that automatically receive ACL access after every mint or burn:

```solidity
token.addTotalSupplyObserver(regulatorAddress);  // re-granted on every mint/burn
token.removeTotalSupplyObserver(regulatorAddress); // stops future grants
```

Once registered, the observer decrypts using standard user-decryption — see [Decrypting Balances](#decrypting-balances).

**Option B — Public disclosure — `ERC7984PublishTotalSupplyModule`, available on both `CMTATFHE` and `CMTATFHELite`**

Call `publishTotalSupply()` to mark the current handle as publicly decryptable. Must be called again after each mint or burn since the handle changes.

```solidity
token.publishTotalSupply();
```

Internally this calls `FHE.makePubliclyDecryptable()`, which triggers the following **asynchronous three-step process**:

#### Public decryption — step by step

Public decryption splits work between on-chain and off-chain:

**Step 1: On-chain - Mark as publicly decryptable**

The contract sets the ciphertext handle's status as publicly decryptable, **globally and permanently** authorizing any entity to request its off-chain cleartext value.

```solidity
FHE.makePubliclyDecryptable(confidentialTotalSupply());
```

**Step 2: Off-chain - Request decryption from KMS**

Any off-chain client can submit the ciphertext handle to the Zama Relayer's Key Management System (KMS) using the Relayer SDK (`@zama-fhe/relayer-sdk`).

```javascript
const result = await fhevmInstance.publicDecrypt([totalSupplyHandle]);
// Returns:
// - clearValues: mapping of handles to decrypted values
// - abiEncodedClearValues: ABI-encoded byte string of all cleartext values
// - decryptionProof: cryptographic proof from the KMS
```

**Step 3: On-chain - Verify and use the decrypted value**

The caller submits the cleartext and decryption proof back to a contract function. The contract calls `FHE.checkSignatures`, which reverts if the proof is invalid.

```solidity
FHE.checkSignatures(handlesList, abiEncodedCleartexts, decryptionProof);
// Now you can use the verified cleartext value
```

**Important**: The decryption proof is cryptographically bound to the specific order of handles passed in the input array.

#### ACL permissions

To access encrypted values, accounts need proper ACL permissions:

| Function | Purpose |
|----------|---------|
| `FHE.allow(handle, address)` | Permanent access for specific address |
| `FHE.allowThis(handle)` | Shorthand for `FHE.allow(handle, address(this))` - allow current contract |
| `FHE.allowTransient(handle, address)` | Temporary access (current transaction only) |
| `FHE.makePubliclyDecryptable(handle)` | Allow anyone to decrypt off-chain |
| `FHE.isAllowed(handle, address)` | Check if an address has access to a ciphertext |
| `FHE.isSenderAllowed(handle)` | Check if `msg.sender` has access to a ciphertext |

#### Why keep total supply private?

- Prevents market manipulation based on supply information
- Protects issuer's business information
- Consistent with the privacy-first design of confidential tokens

**Note:** If you need public total supply, implement a function that goes through the full decryption process and emits the result as an event. Consider the privacy implications carefully.

---

### 6. As an issuer, can I get the non-encrypted balance of a token holder?

**Answer:** Yes, but only through the asynchronous decryption process -- there is no direct way to "read" a plaintext balance.

#### How to decrypt a holder's balance

The issuer must have ACL permission on the holder's balance ciphertext. By default, only the balance holder and the contract itself have access. To allow the issuer to decrypt:

**Option 1: Grant the issuer ACL access (on-chain)**

The contract can grant ACL permission to the issuer's address on the holder's balance handle. This would need to be built into the contract logic (e.g., a function that grants the issuer access to a specific balance):

```solidity
// Inside the contract, an admin function could grant access
function grantBalanceAccess(address holder, address viewer) public onlyRole(DEFAULT_ADMIN_ROLE) {
    FHE.allow(confidentialBalanceOf(holder), viewer);
}
```

Once the issuer has ACL access, they can decrypt the balance off-chain:

```javascript
const balanceHandle = await token.confidentialBalanceOf(holderAddress);
const balance = await fhevm.userDecryptEuint(
    FhevmType.euint64,
    balanceHandle,
    tokenAddress,
    issuer // Signer with ACL access
);
```

**Option 2: Public decryption**

The holder (or a contract function) can mark their balance as publicly decryptable, then anyone can request decryption through the three-step process (see FAQ #5).

#### Do I need a viewing key?

Zama's FHEVM does **not** use a "viewing key" model like some other privacy systems (e.g., Zcash). Instead, access is controlled through the **ACL (Access Control List)**:

| Concept | Zama FHE Approach |
|---------|-------------------|
| Viewing key | Not applicable -- uses ACL permissions instead |
| Grant read access | `FHE.allow(handle, address)` grants permanent access to a specific ciphertext |
| Temporary access | `FHE.allowTransient(handle, address)` grants access for the current transaction only |
| Public access | `FHE.makePubliclyDecryptable(handle)` allows anyone to decrypt |

The ACL model is more flexible than viewing keys: you can grant access per-ciphertext, per-address, and with different durations (permanent, transient, or public).

#### Can third-parties read balances?

Yes, if they are granted ACL permission. The contract logic decides who gets access.

**The handle staleness problem**

Every FHE arithmetic operation (mint, transfer, burn) produces a *new* ciphertext handle for the affected balance. A third party who was granted ACL access to an old handle loses the ability to read the balance the moment that handle is replaced. Access must therefore be re-granted after every update — it cannot be set once and forgotten.

CMTAT FHE solves this with the `ERC7984ObserverAccess` extension. After every `_update`, the contract automatically calls `FHE.allow()` on the new balance handle for each registered observer, keeping their ACL access current without any manual intervention.

**Two observer slots per holder**

`ERC7984BalanceViewModule` (built on `ERC7984ObserverAccess`) provides two independent observer slots per address:

| Slot | Set by | Typical use |
|------|--------|-------------|
| **Holder observer** (`setObserver`) | The holder themselves | Personal wallet app, portfolio dashboard |
| **Role observer** (`setRoleObserver`, requires `OBSERVER_ROLE`) | The issuer / compliance team | Regulator, auditor, compliance tool |

Both slots receive `FHE.allow()` on every balance update automatically.

**Observer ACL scope: balance *and* transfer amount**

On every `_update`, observers are granted ACL access to **two** ciphertext handles:
1. The account's new **balance** handle — so the observer can read the current balance at any time
2. The **transferred amount** handle — so the observer can reconstruct individual transaction amounts

This is intentional design for regulatory compliance: a compliance observer needs transfer-level granularity, not just balance snapshots. An observer set via `setRoleObserver` should therefore be treated as having access to individual transaction amounts for the account they are observing.

**Decrypting as an observer**

Once access is granted the observer can decrypt off-chain through the standard user-decryption flow:

```typescript
// Read the current handle
const handle = await token.confidentialBalanceOf(holderAddress);

// Decrypt — observer must have ACL access on that handle
const balance = await fhevm.userDecryptEuint(
    FhevmType.euint64,
    handle,
    tokenAddress,
    observer // signer with ACL access
);
```

**ACL access is permanent and cannot be revoked**

`FHE.allow()` is a one-way operation — once an observer is granted access to a handle, that access cannot be removed. Removing an observer with `setObserver` / `setRoleObserver` only stops *future* grants: the observer retains read access to all handles they were allowed on before removal.

**Common patterns**

| Party | How access is granted |
|-------|-----------------------|
| The holder themselves | Automatically by the contract on every transfer/mint |
| Regulatory observer | Issuer calls `setRoleObserver(holder, regulatorAddress)` |
| Personal observer | Holder calls `setObserver(holderAddress, walletAppAddress)` |
| Auditor (temporary) | Admin calls `FHE.allowTransient()` during the audit transaction |

---

### 7. Can the issuer compute the inputProof for operations if the issuer is not the token holder?

**Answer:** Yes. The `inputProof` (Zero-Knowledge Proof of Knowledge) is generated by whoever **creates the encrypted input**, not by the token holder.

#### How encrypted inputs work

When any party calls a function that requires an encrypted amount (mint, burn, forcedBurn, forcedTransfer), they:

1. **Choose the plaintext amount** they want to encrypt
2. **Generate the encrypted input** using the FHEVM client library
3. **The library produces** a ciphertext handle + a ZKPoK proof

The ZKPoK proves that the caller **knows** the plaintext value inside the ciphertext, without revealing it. It does not prove anything about token ownership or balances.

#### Example: Issuer burns tokens from a holder

```javascript
// The enforcer (issuer) creates the encrypted input themselves
const encryptedInput = await fhevm
    .createEncryptedInput(tokenAddress, enforcerAddress) // enforcer's address, NOT holder's
    .add64(amountToBurn)
    .encrypt();

// The enforcer calls forcedBurn with their own proof
await token.connect(enforcer)['forcedBurn(address,bytes32,bytes)'](
    holderAddress,                  // target to burn from
    encryptedInput.handles[0],      // enforcer's encrypted amount
    encryptedInput.inputProof       // enforcer's proof
);
```

#### Key points

| Question | Answer |
|----------|--------|
| Who generates the inputProof? | The caller of the function (e.g., the enforcer/issuer) |
| Does the holder need to participate? | No -- forced operations don't require holder involvement |
| Is the proof tied to the holder's balance? | No -- it proves knowledge of the encrypted input value, not the balance |
| Can the issuer specify any amount? | Yes, but if the amount exceeds the holder's balance, FHE transfers/burns 0 silently |

The `inputProof` is tied to the **caller's address** and the **contract address** (passed to `createEncryptedInput`), not to the token holder. This is what enables administrative operations like `forcedBurn` and `forcedTransfer` without the holder's participation.

## Glossary

| **Term** | **Definition** |
| -------- | -------------- |
| **FHE (Fully Homomorphic Encryption)** | Cryptographic scheme that enables arbitrary computations directly on ciphertext without ever decrypting it. The result, once decrypted, is identical to what would have been produced on the plaintext. It is the core primitive behind confidential balances and transfers in CMTAT FHE. |
| **euint64** | Encrypted unsigned 64-bit integer — the on-chain type used to store confidential balances and transfer amounts. It is a pointer to a ciphertext managed by the Zama coprocessor network, not a raw encrypted value. Maximum representable value is ~18.4 × 10¹⁸. |
| **externalEuint64** | The user-facing form of an encrypted 64-bit integer: a ciphertext handle produced by the client library and submitted alongside a ZKPoK. Converted to `euint64` on-chain via `FHE.fromExternal()` after the proof is verified. |
| **ZKPoK (Zero-Knowledge Proof of Knowledge)** | A cryptographic proof that the submitter knows the plaintext inside an encrypted input, without revealing that plaintext. Required for every encrypted input to prevent malleability and replay attacks. Verified on-chain by the InputVerifier contract. |
| **Ciphertext Handle** | A 32-byte pointer returned by every FHE operation (e.g., `euint64`). It references the actual ciphertext stored and computed by the coprocessor network, not the ciphertext itself. Arithmetic on handles triggers off-chain coprocessor computation and produces new handles. |
| **ACL (Access Control List)** | On-chain permission registry that tracks which addresses may decrypt a given ciphertext handle. Access is granted with `FHE.allow()` (permanent) or `FHE.allowTransient()` (current transaction only). Without ACL access, a party cannot request decryption of a handle. |
| **Coprocessor (FHEVMExecutor)** | Off-chain network of nodes that performs the actual FHE computations. When a Solidity contract calls an FHE operation, the host chain emits an event; coprocessors pick it up, compute the result, and make the new ciphertext available. |
| **KMS (Key Management System)** | Zama's key management infrastructure that holds the FHE private key in a distributed manner using MPC. Decryption requests are sent to the KMS, which returns a decrypted value together with a cryptographic proof that can be verified on-chain. |
| **MPC (Multi-Party Computation)** | Threshold cryptography protocol used by the KMS so that no single node ever holds the complete FHE private key. Decryption only succeeds when a quorum of KMS nodes cooperates, preventing any single point of compromise. |
| **Symbolic Execution** | The on-chain execution model for FHE operations: the EVM does not perform the actual FHE computation — it only records an intent (emits an event with a new handle). The coprocessor network executes the computation off-chain asynchronously. |
| **ERC-7984** | The Confidential Fungible Token standard (drafted by OpenZeppelin). It defines the interface for tokens with encrypted balances and transfer amounts, including the operator system, disclosure mechanism, and ACL-based access patterns used by CMTAT FHE. |
| **Operator** | An address authorized by a token holder to call `confidentialTransferFrom` on their behalf. Unlike ERC-20 allowances, operators are granted time-limited *unlimited* access — they may transfer any amount until the approval timestamp expires. |
| **Observer** | An ACL-authorized third party (e.g., a regulator or auditor) granted read access to one or more encrypted balance handles. Implemented via `ERC7984ObserverAccess`: the contract grants `FHE.allow()` on balances affected by each transfer, giving the observer a continuously updated view. |

---

## References

- [CMTAT - Capital Markets and Technology Association Token Standard](https://github.com/CMTA/CMTAT)
- Openzeppelin
  - [OpenZeppelin Confidential Contracts](https://docs.openzeppelin.com/confidential-contracts)
  - [ERC-7984 Specification](https://docs.openzeppelin.com/confidential-contracts/erc7984)

- Zama
  - [Zama Protocol Litepaper](https://docs.zama.org/protocol/zama-protocol-litepaper)
  - [Zama FHEVM Documentation](https://docs.zama.org/protocol/solidity-guides/getting-started/overview)
  - [Zama FHE Types](https://docs.zama.org/protocol/solidity-guides/smart-contract/types)
  - [Encrypted Inputs](https://docs.zama.org/protocol/solidity-guides/smart-contract/inputs)
  - [Access Control List (ACL)](https://docs.zama.org/protocol/solidity-guides/smart-contract/acl)
  - [Decryption](https://docs.zama.org/protocol/solidity-guides/smart-contract/oracle)

- Part of this project was carried out with the help of [Claude Code](https://claude.com/product/claude-code)



## License

This project is licensed under the MPL-2.0 License.
