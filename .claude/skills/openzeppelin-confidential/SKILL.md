---
name: openzeppelin-confidential
description: OpenZeppelin Confidential Contracts is a library for building confidential smart contracts using FHE ciphertext for amounts. It provides production-ready implementations for confidential tokens, compatible with Zama's FHEVM by implementing ERC-7984.
---

## Purpose
OpenZeppelin Confidential Contracts is a library for building confidential smart contracts using FHE ciphertext for amounts. It provides production-ready implementations for confidential tokens, compatible with Zama's FHEVM.

---

## ERC-7984: Confidential Fungible Token Standard

ERC-7984 is a **new confidential token standard** inspired by ERC-20 but built for privacy. All balances and transfer amounts are represented as **ciphertext handles**.

### Key Differences from ERC-20
| Feature | ERC-20 | ERC-7984 |
|---------|--------|----------|
| Balances | Public `uint256` | Encrypted `euint64` |
| Allowances | Amount-based approval | Operator-based (time-limited) |
| Transfers | Direct amounts | Encrypted amounts with optional proofs |
| Interface | Standard functions | 8 transfer function variants |

**Important**: ERC-7984 is **NOT** ERC-20 compliant. It's a new standard designed specifically for confidentiality.

---

## Contract Setup

All contracts must configure the FHE coprocessor during construction:

```solidity
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ERC7984} from "@openzeppelin/confidential-contracts/token/ERC7984/ERC7984.sol";

contract MyToken is ERC7984 {
    constructor() ERC7984("MyToken", "MTK", "https://example.com/metadata") {}
}
```

---

## Transfer Functions

ERC-7984 exposes **8 transfer function variants**:

### Transfer Types
1. **`transfer`** - Move tokens from sender
2. **`transferFrom`** - Move tokens from specified address (requires operator approval)

### Modifiers
- **With/without `inputProof`**: Proof required if sender doesn't have ACL access to the amount ciphertext
- **With/without callback**: ERC-1363 style callbacks for receiver contracts

### Example Transfer
```solidity
// Transfer with encrypted amount and proof
function transfer(
    address to,
    externalEuint64 amount,
    bytes calldata inputProof
) external returns (euint64 amountTransferred);

// TransferFrom for operators
function confidentialTransferFrom(
    address from,
    address to,
    euint64 amount
) external returns (euint64 amountTransferred);
```

---

## Operator System

Instead of ERC-20's allowance system, ERC-7984 uses **operators with expiration timestamps**.

### Setting an Operator
```solidity
// Grant operator access for 24 hours
uint256 expiration = block.timestamp + 86400;
token.setOperator(operatorAddress, expiration);
```

### Key Points
- Operators can move **any amount** of tokens during the approval period
- Operators **cannot** decrypt balance handles (they can't know exact amounts)
- Operators can only verify success after transaction completes

**Warning**: Setting an operator allows them to take all tokens during the approval period.

---

## Callbacks (IERC7984Receiver)

Contracts receiving tokens via callback must implement:

```solidity
interface IERC7984Receiver {
    function onConfidentialTransferReceived(
        address operator,
        address from,
        euint64 amount,
        bytes calldata data
    ) external returns (ebool success);
}
```

If callback returns `false`, the transfer is reversed.

---

## Practical Examples

### Mintable/Burnable Token
```solidity
import {FHE, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC7984} from "@openzeppelin/confidential-contracts/token/ERC7984/ERC7984.sol";

contract ERC7984MintableBurnable is ERC7984, Ownable {
    constructor(
        address owner,
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC7984(name, symbol, uri) Ownable(owner) {}

    function mint(address to, externalEuint64 amount, bytes memory inputProof) public onlyOwner {
        _mint(to, FHE.fromExternal(amount, inputProof));
    }

    function burn(address from, externalEuint64 amount, bytes memory inputProof) public onlyOwner {
        _burn(from, FHE.fromExternal(amount, inputProof));
    }
}
```

### Wrapping ERC-20 to ERC-7984
```solidity
function wrap(address to, uint256 amount) public virtual {
    // Take ownership of ERC-20 tokens
    SafeERC20.safeTransferFrom(underlying(), msg.sender, address(this), amount - (amount % rate()));

    // Mint confidential tokens
    _mint(to, (amount / rate()).toUint64().asEuint64());
}
```

### Unwrapping ERC-7984 to ERC-20 (Async)
Requires decryption workflow:

```solidity
function swapConfidentialToERC20(externalEuint64 encryptedInput, bytes memory inputProof) public {
    euint64 amount = FHE.fromExternal(encryptedInput, inputProof);
    FHE.allowTransient(amount, address(_fromToken));
    euint64 amountTransferred = _fromToken.confidentialTransferFrom(msg.sender, address(this), amount);

    FHE.makePubliclyDecryptable(amountTransferred);
    _receivers[amountTransferred] = msg.sender;
}

function finalizeSwap(euint64 amount, uint64 cleartextAmount, bytes calldata decryptionProof) public {
    bytes32[] memory handles = new bytes32[](1);
    handles[0] = euint64.unwrap(amount);

    FHE.checkSignatures(handles, abi.encode(cleartextAmount), decryptionProof);
    // ... transfer ERC-20
}
```

### Swap ERC-7984 to ERC-7984
```solidity
function swapConfidentialForConfidential(
    IERC7984 fromToken,
    IERC7984 toToken,
    externalEuint64 amountInput,
    bytes calldata inputProof
) public virtual {
    require(fromToken.isOperator(msg.sender, address(this)));

    euint64 amount = FHE.fromExternal(amountInput, inputProof);

    FHE.allowTransient(amount, address(fromToken));
    euint64 amountTransferred = fromToken.confidentialTransferFrom(msg.sender, address(this), amount);

    FHE.allowTransient(amountTransferred, address(toToken));
    toToken.confidentialTransfer(msg.sender, amountTransferred);
}
```

---

## Available Extensions (v0.3.0)

| Extension | Purpose |
|-----------|---------|
| **ERC7984ERC20Wrapper** | Wrap/unwrap ERC-20 tokens |
| **ERC7984Omnibus** | Confidential subaccounts for omnibus wallets |
| **ERC7984ObserverAccess** | Allow observers to view balances/transfers |
| **ERC7984Restricted** | User account transfer restrictions |
| **ERC7984Freezable** | Freeze/unfreeze account tokens |
| **ERC7984Rwa** | Real World Asset (RWA) support |
| **ERC7984Votes** | Governance voting with confidential delegation |

---

## Utility Libraries

### FHESafeMath
Safe math operations for encrypted types:
```solidity
import {FHESafeMath} from "@openzeppelin/confidential-contracts/utils/FHESafeMath.sol";

// Returns 0 on failure instead of reverting
euint64 result = FHESafeMath.tryAdd(a, b);
euint64 result = FHESafeMath.trySub(a, b);
```

### CheckpointsConfidential
Checkpoint library for confidential values (useful for governance/voting).

---

## Dependencies

```json
{
  "@openzeppelin/confidential-contracts": "^0.3.0",
  "@fhevm/solidity": "^0.9.1",
  "@openzeppelin/contracts": "^5.0.0"
}
```

---

## Security Notice

- Contracts are provided **as-is** with no formal audit
- **Not covered** by OpenZeppelin's bug bounty program
- No backward compatibility guarantees for v0.x releases
- Report issues to OpenZeppelin security contact

---

## Key Files Reference
- `confidential-contracts.md` - Library overview and security notes
- `erc7984.md` - ERC-7984 standard implementation guide
- `changelog.md` - Version history and breaking changes
