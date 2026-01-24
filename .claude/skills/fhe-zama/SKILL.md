---
name: zama-fhe
description: how to use Zama FHEVM (Fully Homomorphic Encryption) for Solidity
---



## Purpose
This documentation covers Zama's FHEVM library for writing confidential smart contracts in Solidity using Fully Homomorphic Encryption (FHE). FHE allows computations on encrypted data without decrypting it on-chain.

---

## Core Concepts

### Encrypted Data Types
FHEVM introduces encrypted types compatible with Solidity:
- **`ebool`**: Encrypted boolean
- **`euint8`, `euint16`, `euint32`, `euint64`, `euint128`, `euint256`**: Encrypted unsigned integers
- **`eaddress`**: Encrypted address (internally `euint160`)
- **`externalEuint64`, `externalEbool`, etc.**: Types for encrypted inputs from users

**Important**: Encrypted integers are represented as ciphertext handles. Arithmetic operations are **unchecked** (wrap on overflow) to avoid leaking information.

### Operations on Encrypted Types
All operations use the `FHE` library prefix:

| Category | Functions |
|----------|-----------|
| **Arithmetic** | `FHE.add`, `FHE.sub`, `FHE.mul`, `FHE.div`*, `FHE.rem`*, `FHE.neg`, `FHE.min`, `FHE.max` |
| **Bitwise** | `FHE.and`, `FHE.or`, `FHE.xor`, `FHE.not`, `FHE.shl`, `FHE.shr`, `FHE.rotl`, `FHE.rotr` |
| **Comparison** | `FHE.eq`, `FHE.ne`, `FHE.lt`, `FHE.le`, `FHE.gt`, `FHE.ge` |
| **Conditional** | `FHE.select(condition, valueIfTrue, valueIfFalse)` |
| **Random** | `FHE.randEuint8()`, `FHE.randEuint64()`, etc. |

*`div` and `rem` only support **plaintext divisors**.

### Casting & Encryption
- `FHE.asEuint64(plainValue)` - Convert plaintext to encrypted type (trivial encryption)
- `FHE.fromExternal(externalEuint64, inputProof)` - Validate and convert user-encrypted input

---

## Configuration

### Contract Setup
Inherit from `ZamaEthereumConfig` to auto-configure FHEVM:

```solidity
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";

contract MyContract is ZamaEthereumConfig {
    euint64 private _encryptedBalance;
}
```

This automatically sets up:
- FHE library with encryption parameters
- ACL (Access Control List) contract
- KMS Verifier for decryption proofs
- Network-specific addresses (Sepolia, etc.)

---

## Access Control List (ACL)

The ACL governs who can access encrypted ciphertexts.

### Granting Access
```solidity
FHE.allow(ciphertext, address);      // Permanent access to address
FHE.allowThis(ciphertext);           // Allow current contract
FHE.allowTransient(ciphertext, address); // Temporary (current tx only)
FHE.makePubliclyDecryptable(ciphertext); // Anyone can decrypt off-chain
```

### Verifying Access
```solidity
FHE.isAllowed(ciphertext, address);
FHE.isSenderAllowed(ciphertext);
FHE.isPubliclyDecryptable(ciphertext);
```

---

## Encrypted Inputs

Users submit encrypted data with Zero-Knowledge Proofs (ZKPoK).

### Function Signature Pattern
```solidity
function transfer(
    address to,
    externalEuint64 encryptedAmount,
    bytes calldata inputProof
) public {
    euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
    // Use 'amount' for encrypted operations
}
```

---

## Decryption (Public Decryption Workflow - v0.9)

Decryption is a 3-step asynchronous process:

### Step 1: On-Chain - Mark as Decryptable
```solidity
FHE.makePubliclyDecryptable(encryptedResult);
```

### Step 2: Off-Chain - Get Cleartext + Proof
```typescript
const result = await fhevmInstance.publicDecrypt([handle]);
// Returns: { clearValues, abiEncodedClearValues, decryptionProof }
```

### Step 3: On-Chain - Verify & Use
```solidity
function finalize(uint64 clearValue, bytes calldata decryptionProof) public {
    bytes32[] memory handles = new bytes32[](1);
    handles[0] = euint64.unwrap(_encryptedValue);

    FHE.checkSignatures(handles, abi.encode(clearValue), decryptionProof);
    // Now safely use clearValue
}
```

---

## Best Practices for Confidential ERC-20

### Overflow Prevention
```solidity
function _mint(address to, euint64 amount) internal {
    euint64 newSupply = FHE.add(_totalSupply, amount);
    ebool noOverflow = FHE.le(newSupply, _totalSupply.add(amount));

    // Use select to conditionally update
    _totalSupply = FHE.select(noOverflow, newSupply, _totalSupply);
    _balances[to] = FHE.select(noOverflow, FHE.add(_balances[to], amount), _balances[to]);
}
```

### Use Scalar Operands for Gas Savings
```solidity
// Expensive: both encrypted
euint64 result = FHE.add(encryptedA, FHE.asEuint64(5));

// Cheaper: scalar operand
euint64 result = FHE.add(encryptedA, 5);
```

### Choose Appropriate Type Sizes
Use `euint64` for balances (sufficient for most tokens with 18 decimals up to reasonable supply).

---

## HCU (Homomorphic Complexity Units)

FHE operations are metered by HCU to prevent DoS attacks.

| Operation (euint64) | HCU (scalar) | HCU (encrypted) |
|---------------------|--------------|-----------------|
| `add` | 133,000 | 162,000 |
| `sub` | 133,000 | 162,000 |
| `mul` | 365,000 | 596,000 |
| `eq` | 83,000 | 120,000 |
| `select` | - | 55,000 |

**Limits**: 20,000,000 HCU per transaction, 5,000,000 depth limit.

---

## Development Setup

### Hardhat Template
```bash
# Clone Zama's FHEVM Hardhat template
git clone https://github.com/zama-ai/fhevm-hardhat-template
npm install

# Set Sepolia credentials
npx hardhat vars set MNEMONIC
npx hardhat vars set INFURA_API_KEY
```

### Key Dependencies
- `@fhevm/solidity` >= v0.9.1
- `@zama-fhe/relayer-sdk` >= v0.3.0
- `@fhevm/hardhat-plugin` >= v0.3.0

---

## Key Files Reference
- `welcome.md` - Introduction and navigation
- `what-is-fhevm-solidity.md` - Core features overview
- `supported-types.md` - Encrypted type specifications
- `operations-on-encrypted-types.md` - All FHE operations
- `access-control-list.md` - ACL system details
- `encrypted-inputs.md` - Handling user inputs with ZKPoK
- `decryption.md` - Public decryption workflow
- `configuration.md` - Contract setup with ZamaConfig
- `hcu.md` - Gas/computation costs for FHE operations
- `migrate-to-v0-9.md` - Migration guide for latest version
