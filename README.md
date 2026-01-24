# CMTAT FHE - Confidential Security Token

A confidential security token implementation combining [CMTAT](https://github.com/CMTA/CMTAT) compliance features with [Zama FHE](https://www.zama.ai) encryption for private balances.

## Overview

CMTATFHE implements the [ERC-7984](https://docs.openzeppelin.com/confidential-contracts/erc7984) standard (Confidential Fungible Token) with CMTAT regulatory compliance modules. All token balances and transfer amounts are encrypted using Fully Homomorphic Encryption (FHE), ensuring complete privacy while maintaining regulatory compliance capabilities.

### Key Features

- **Confidential Balances**: All balances are encrypted using FHE - only authorized parties can decrypt
- **Confidential Transfers**: Transfer amounts remain private on-chain
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
└── CMTATBaseGeneric (CMTAT Modules)
    ├── PauseModule - Pause/unpause transfers
    ├── EnforcementModule - Freeze/unfreeze addresses
    ├── AccessControlModule - Role-based permissions
    ├── DocumentEngineModule - ERC-1643 document management
    └── ExtraInformationModule - Token metadata (tokenId, terms, info)
```

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

Enforcers can move tokens between addresses for regulatory compliance (bypasses freeze):

```solidity
function forcedTransfer(
    address from,
    address to,
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public onlyRole(ENFORCER_ROLE) returns (euint64 transferred);
```

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

## References

- [CMTAT - Capital Markets Token Standard](https://github.com/CMTA/CMTAT)
- [OpenZeppelin Confidential Contracts](https://docs.openzeppelin.com/confidential-contracts)
- [ERC-7984 Specification](https://docs.openzeppelin.com/confidential-contracts/erc7984)
- [Zama FHEVM Documentation](https://docs.zama.ai/protocol/solidity-guides/getting-started/overview)
- [Zama FHE Types](https://docs.zama.ai/protocol/solidity-guides/smart-contract/types)
- [Encrypted Inputs](https://docs.zama.ai/protocol/solidity-guides/smart-contract/inputs)

## License

This project is licensed under the MIT License.
