# FAQ

## 1. As an issuer, can I burn tokens from a token holder without their consent? How does this work?

**Answer:** Yes, as an issuer with the `ENFORCER_ROLE`, you can burn tokens from any holder without their consent using the forced transfer mechanism.

**How it works:**

1. Use the `forcedTransfer()` function to move tokens from the holder's address to a burn address or another designated address
2. This function bypasses the freeze checks but still respects contract deactivation status
3. Only accounts with `ENFORCER_ROLE` can execute forced transfers

**Use cases for regulatory compliance:**
- Court orders requiring asset seizure
- Sanctions compliance
- Error correction (e.g., tokens sent to wrong address)

**Code example:**
```solidity
// As enforcer, force transfer tokens from frozen/non-frozen address
await token.connect(enforcer).forcedTransfer(
    holderAddress,      // from
    burnAddress,        // to (or address(0) for burn)
    encryptedAmount,
    inputProof
);
```

**Note:** The regular `burn()` function requires `BURNER_ROLE` and will fail if the target address is frozen. For frozen addresses, use `forcedTransfer()` instead.

---

## 2. As a token holder, how do I transfer my tokens to another address? What are the steps?

**Answer:** Transfers in CMTAT FHE use encrypted inputs to preserve confidentiality. Here's the complete process:

### Step 1: Create an encrypted input

Encrypted inputs are data values submitted in ciphertext form, accompanied by **Zero-Knowledge Proofs of Knowledge (ZKPoKs)** to ensure validity without revealing the plaintext.

```javascript
const encryptedInput = await fhevm
    .createEncryptedInput(tokenContractAddress, yourAddress)
    .add64(amount)  // Amount to transfer (will be encrypted)
    .encrypt();
```

### Step 2: Call the transfer function

```javascript
await token.confidentialTransfer(
    recipientAddress,
    encryptedInput.handles[0],  // externalEuint64 handle
    encryptedInput.inputProof   // ZKPoK proof
);
```

### How validation works on-chain

1. **Input verification**: The `FHE.fromExternal()` function validates the ciphertext and ZKPoK
2. **Type conversion**: Converts `externalEuint64` into `euint64` for contract operations
3. **Balance check**: If balance is insufficient, transfer executes but transfers 0 (FHE doesn't reveal balance)

### Alternative: Using an operator

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

### Transfer requirements
- Your address must not be frozen
- The recipient address must not be frozen
- The contract must not be paused or deactivated

---

## 3. Can I deploy CMTAT FHE contracts directly on Ethereum mainnet? What are the requirements?

**Answer:** Currently, **no** - you cannot deploy functional CMTAT FHE contracts on Ethereum mainnet.

### Why not?

Ethereum mainnet does not natively support Fully Homomorphic Encryption (FHE) operations. FHE requires a specialized **coprocessor infrastructure** that includes:

- **ACL (Access Control List)**: Manages permissions for encrypted data
- **FHEVMExecutor (Coprocessor)**: Performs encrypted computations
- **KMSVerifier**: Verifies decryption proofs from the Key Management System
- **InputVerifier**: Validates encrypted inputs and ZKPoKs

### Where can you deploy?

| Network | Chain ID | Status |
|---------|----------|--------|
| Local development | 31337 | Supported (mock coprocessor via hardhat plugin) |
| Ethereum Sepolia | 11155111 | Supported (Zama testnet infrastructure) |
| Ethereum Mainnet | 1 | Not yet available |

### Requirements for deployment

1. **Inherit from `ZamaEthereumConfig`**: This automatically configures coprocessor addresses:
   ```solidity
   import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

   contract MyToken is ERC7984, ZamaEthereumConfig {
       // Constructor automatically calls FHE.setCoprocessor()
   }
   ```

2. **Target network must have Zama infrastructure**: The coprocessor contracts must be deployed and operational

3. **Users need compatible tools**: Client applications must use fhevm-js to create encrypted inputs

### Contract addresses (Sepolia testnet)

```
ACL:           0xf0Ffdc93b7E186bC2f8CB3dAA75D86d1930A433D
Coprocessor:   0x92C920834Ec8941d2C77D188936E1f7A6f49c127
KMSVerifier:   0xbE0E383937d564D7FF0BC3b46c51f0bF8d5C311A
```

---

## 4. CMTAT FHE currently hides only the transfer amounts. Is it possible to also provide privacy for addresses? How?

**Answer:** Yes, it is technically possible using **encrypted addresses** (`eaddress` type in fhEVM).

### How it works

The fhEVM library provides the `eaddress` type which encrypts Ethereum addresses. This enables:
- Hiding sender and recipient addresses in transfers
- Omnibus account patterns where multiple users share a single on-chain address

### Implementation: Omnibus pattern

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

### Trade-offs

| Benefit | Cost |
|---------|------|
| Address privacy | Higher gas costs for encrypted address operations |
| Regulatory compliance (omnibus accounts) | More complex user experience |
| Institutional custody patterns | Requires trusted omnibus operators |

### Regulatory considerations

Hiding participant identities may conflict with AML/KYC requirements in some jurisdictions. Consider your compliance obligations before implementing address privacy.

---

## 5. Is the total supply public or private information?

**Answer:** The total supply is **private** (encrypted) by default in ERC7984.

### Technical details

- The `_totalSupply` variable is stored as `euint64` (encrypted unsigned 64-bit integer)
- The `confidentialTotalSupply()` function returns an encrypted handle, not a plaintext value
- Access is controlled by the ACL (Access Control List)

```solidity
// Returns an encrypted handle (euint64), not the actual value
function confidentialTotalSupply() public view returns (euint64);
```

### How to decrypt the total supply

Decryption is an **asynchronous three-step process**:

**Step 1: On-chain - Mark as publicly decryptable**
```solidity
FHE.makePubliclyDecryptable(confidentialTotalSupply());
```

**Step 2: Off-chain - Request decryption from KMS**
```javascript
const result = await fhevmInstance.publicDecrypt([totalSupplyHandle]);
// Returns: clearValues, abiEncodedClearValues, decryptionProof
```

**Step 3: On-chain - Verify and use the decrypted value**
```solidity
FHE.checkSignatures(handlesList, abiEncodedCleartexts, decryptionProof);
// Now you can use the verified cleartext value
```

### ACL permissions

To access encrypted values, accounts need proper ACL permissions:

| Function | Purpose |
|----------|---------|
| `FHE.allow(handle, address)` | Permanent access for specific address |
| `FHE.allowTransient(handle, address)` | Temporary access (current transaction only) |
| `FHE.makePubliclyDecryptable(handle)` | Allow anyone to decrypt off-chain |

### Why keep total supply private?

- Prevents market manipulation based on supply information
- Protects issuer's business information
- Consistent with the privacy-first design of confidential tokens

**Note:** If you need public total supply, implement a function that goes through the full decryption process and emits the result as an event. Consider the privacy implications carefully.

---

## Additional Resources

- [Zama Protocol Documentation](https://docs.zama.org/protocol)
- [OpenZeppelin Confidential Contracts](https://docs.openzeppelin.com/confidential-contracts)
- [fhEVM Solidity Library](https://github.com/zama-ai/fhevm-solidity)
- [CMTAT Documentation](https://github.com/CMTA/CMTAT)
