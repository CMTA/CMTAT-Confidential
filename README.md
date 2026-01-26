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
CMTATFHE
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

This section maps the CMTAT framework features to the CMTATFHE implementation, showing how standard functionalities are adapted for Fully Homomorphic Encryption.

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

| **Functionalities** | **CMTATFHE Features** | **Available** |
| ------------------- | --------------------- | ------------- |
| Forced Transfer | `forcedTransfer()` with encrypted amount | ✓ |
| Operator System | `setOperator()` / `confidentialTransferFrom()` | ✓ |
| Public Disclosure | `requestDiscloseEncryptedAmount()` / `discloseEncryptedAmount()` | ✓ |
| On-chain snapshot | Not implemented | ✗ |
| Freeze partial tokens | Not implemented (all balances are encrypted) | ✗ |
| Integrated allowlisting | Not implemented | ✗ |
| RuleEngine / transfer hook | Not implemented | ✗ |
| Upgradability | Not implemented (standalone only) | ✗ |

### Implementation Details

| **Functionalities** | **CMTATFHE** | **Note** |
| ------------------- | ------------ | -------- |
| Mint while paused | ✓ | Minting is allowed when contract is paused (same as CMTAT) |
| Burn while paused | ✓ | Burning is allowed when contract is paused (same as CMTAT) |
| Self burn | ✗ | Only `BURNER_ROLE` can burn tokens |
| Standard burn on frozen address | ✗ | Use `forcedTransfer()` instead |
| Burn via `forcedTransfer` | ✓ | Transfer to burn address with `ENFORCER_ROLE` |
| Balance overflow protection | ✓ | FHE arithmetic wraps on overflow silently |

### Key Differences from Standard CMTAT

| **Aspect** | **CMTAT (Standard)** | **CMTATFHE (Confidential)** |
| ---------- | -------------------- | --------------------------- |
| Balance type | `uint256` (public) | `euint64` (encrypted) |
| Transfer amount | `uint256` (public) | `externalEuint64` + ZKPoK |
| Total supply | `uint256` (public) | `euint64` (encrypted) |
| Balance visibility | Anyone can read | Only ACL-authorized parties can decrypt |
| Transfer validation | Reverts on insufficient balance | Transfers 0 silently (privacy-preserving) |
| Allowance system | ERC20 `approve`/`allowance` | Operator system with time-limited access |

### Decryption Requirements

To decrypt encrypted values (balances, amounts, total supply), the requesting party must:

1. Have ACL permission granted via `FHE.allow()` or `FHE.allowTransient()`
2. Or the value must be marked publicly decryptable via `FHE.makePubliclyDecryptable()`
3. Request decryption through the Zama Relayer SDK
4. Submit the decryption proof on-chain via `FHE.checkSignatures()`

## Installation

```bash
# Clone the repository
git clone --recursive https://github.com/your-repo/CMTATFHE.git
cd CMTATFHE

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
| `ENFORCER_ROLE` | Can freeze addresses and execute forced transfers |

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

Enforcers can move tokens from frozen addresses for regulatory compliance. The source address must be frozen. Forced transfers can be performed even when the contract is deactivated.

```solidity
function forcedTransfer(
    address from,        // Must be frozen
    address to,
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(ENFORCER_ROLE) returns (euint64 transferred);
```

**Requirements:**
- The `from` address must be frozen
- Can be performed even when the contract is deactivated

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
await token.grantRole(ENFORCER_ROLE, enforcerAddress);
```

## Dependencies

| Package | Version |
|---------|---------|
| `@fhevm/solidity` | 0.9.1 |
| `@fhevm/hardhat-plugin` | 0.3.0-1 |
| `@openzeppelin/contracts` | ^5.4.0 |
| `@openzeppelin/contracts-upgradeable` | ^5.4.0 |

## Project Structure

```
CMTATFHE/
├── contracts/
│   └── CMTATFHE.sol          # Main contract
├── CMTAT/                     # CMTAT submodule (compliance modules)
├── openzeppelin-confidential-contracts/  # OZ submodule (ERC7984)
├── docs/
│   ├── fhe/                   # Zama FHE documentation
│   └── openzeppelin-confidential/  # OZ confidential docs
├── test/
│   ├── CMTATFHE.test.ts       # Comprehensive tests
│   └── helpers/
└── hardhat.config.js
```

## FAQ

### 1. As an issuer, can I burn tokens from a token holder without their consent?

**Answer:** Yes, as an issuer with the `ENFORCER_ROLE`, you can burn tokens from any holder without their consent using the forced transfer mechanism.

**How it works:**

1. First freeze the holder's address using `setAddressFrozen(holderAddress, true)`
2. Use the `forcedTransfer()` function to move tokens from the frozen address to a burn address or another designated address
3. This function can be performed even when the contract is deactivated
4. Only accounts with `ENFORCER_ROLE` can execute forced transfers

**Use cases for regulatory compliance:**
- Court orders requiring asset seizure
- Sanctions compliance
- Error correction (e.g., tokens sent to wrong address)

**Code example:**
```solidity
// Step 1: Freeze the holder's address
await token.connect(enforcer).setAddressFrozen(holderAddress, true);

// Step 2: Force transfer tokens from the frozen address
await token.connect(enforcer).forcedTransfer(
    holderAddress,      // from (must be frozen)
    burnAddress,        // to (or address(0) for burn)
    encryptedAmount,
    inputProof
);
```

**Note:** The regular `burn()` function requires `BURNER_ROLE` and will fail if the target address is frozen. For frozen addresses, use `forcedTransfer()` instead. The `from` address must be frozen before calling `forcedTransfer()`.

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

#### Roadmap

- **Ethereum Mainnet**: Live
- **Other EVM chains**: H1 2026
- **Solana support**: H2 2026

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

#### How to decrypt the total supply

Public decryption is an **asynchronous three-step process** that splits work between on-chain and off-chain:

**Step 1: On-chain - Mark as publicly decryptable**

The contract sets the ciphertext handle's status as publicly decryptable, **globally and permanently** authorizing any entity to request its off-chain cleartext value.

```solidity
FHE.makePubliclyDecryptable(confidentialTotalSupply());
```

**Step 2: Off-chain - Request decryption from KMS**

Any off-chain client can submit the ciphertext handle to the Zama Relayer's Key Management System (KMS) using the Relayer SDK.

```javascript
const result = await relayerInstance.publicDecrypt([totalSupplyHandle]);
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
| `FHE.allowTransient(handle, address)` | Temporary access (current transaction only) |
| `FHE.makePubliclyDecryptable(handle)` | Allow anyone to decrypt off-chain |

#### Why keep total supply private?

- Prevents market manipulation based on supply information
- Protects issuer's business information
- Consistent with the privacy-first design of confidential tokens

**Note:** If you need public total supply, implement a function that goes through the full decryption process and emits the result as an event. Consider the privacy implications carefully.



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


## License

This project is licensed under the MIT License.
