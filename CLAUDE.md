# CLAUDE.md — CMTAT FHE Project Guide

## Project Overview

CMTAT FHE is a confidential security token combining [CMTAT](https://github.com/CMTA/CMTAT) compliance modules with the [Zama FHEVM](https://docs.zama.ai/fhevm) for encrypted balances. All balances and transfer amounts are stored as `euint64` (FHE-encrypted 64-bit integers).

This file must always have the same content as AGENTS.md

**Main contract:** `contracts/CMTATFHE.sol`
**Test framework:** Hardhat + Mocha/Chai (`test/*.test.ts`)
**Compile (quick check):** `forge build`
**Compile (for tests):** `npx hardhat compile`
**Run tests:** `npm run test`

---

## Architecture

### Inheritance chain (simplified)

```
CMTATFHE
├── ERC7984                          (OZ Confidential — encrypted balances, transfers, operators)
│   └── ERC7984ObserverAccess        (via ERC7984BalanceViewModule)
├── CMTATBaseGeneric                 (CMTAT — pause, freeze, access control, documents)
├── ZamaEthereumConfig               (Zama coprocessor addresses)
├── ERC7984MintModule                (mint with hook)
├── ERC7984BurnModule                (burn with hook)
├── ERC7984EnforcementModule         (forcedTransfer, forcedBurn with hooks)
└── ERC7984BalanceViewModule         (dual-observer: holder slot + role slot)
```

### Key submodule paths

| Path | Contents |
|------|----------|
| `openzeppelin-confidential-contracts/contracts/token/ERC7984/` | `ERC7984.sol`, `ERC7984ObserverAccess.sol` |
| `CMTAT/contracts/modules/` | Pause, Enforcement, AccessControl, Document, ExtraInfo modules |

---

## Module Pattern

Every FHE module follows the same three-part pattern. **Never break this pattern.**

### 1. Module contract (`contracts/modules/ERC7984XxxModule.sol`)

```solidity
abstract contract ERC7984XxxModule is ERC7984 {
    // Role constant — always keccak256("XXX_ROLE")
    bytes32 public constant XXX_ROLE = keccak256("XXX_ROLE");

    // Events & errors here

    // Modifier calls the virtual hook
    modifier onlyXxx() {
        _authorizeXxx();
        _;
    }

    // Public function(s) gated by the modifier
    function doXxx(...) public virtual onlyXxx returns (...) { ... }

    // Optional: validation hook (called inside the function, not the modifier)
    // Override in CMTATFHE to apply pause/freeze logic
    function _validateXxx(...) internal virtual { }

    // Authorization hook — MUST be overridden in CMTATFHE
    function _authorizeXxx() internal virtual;
}
```

### 2. Wire into `CMTATFHE.sol`

```solidity
// 1. Add import
import {ERC7984XxxModule} from "./modules/ERC7984XxxModule.sol";

// 2. Add to inheritance list (append, do not insert before ERC7984)
contract CMTATFHE is ERC7984, ..., ERC7984XxxModule {

// 3. Override the authorization hook
function _authorizeXxx() internal virtual override onlyRole(XXX_ROLE) {}

// 4. Override the validation hook if needed (pause/freeze checks)
function _validateXxx(...) internal virtual override {
    if (!someCheck) revert CMTAT_InvalidTransfer(...);
}
```

---

## Adding a Feature — Checklist

- [ ] Create `contracts/modules/ERC7984XxxModule.sol` (see pattern above)
- [ ] Define role constant as `bytes32 public constant XXX_ROLE = keccak256("XXX_ROLE")`
- [ ] Define a modifier + virtual `_authorizeXxx()` hook
- [ ] Define optional virtual `_validateXxx()` hook for pause/freeze logic
- [ ] Add import + inheritance in `CMTATFHE.sol`
- [ ] Override `_authorizeXxx()` with `onlyRole(XXX_ROLE)` in `CMTATFHE.sol`
- [ ] Override `_validateXxx()` with CMTAT module checks if applicable
- [ ] If the module overrides `_update`: add explicit `_update` override in `CMTATFHE.sol`
- [ ] Update `README.md` (Architecture tree, Roles table, Extended Features table, Contract Functions section, Project Structure)
- [ ] Write tests in `test/ERC7984XxxModule.test.ts`

---

## Writing Tests

### File naming

| File | Purpose |
|------|---------|
| `test/CMTATFHE.test.ts` | Core contract behaviour (mint, burn, transfer, pause, freeze, forced ops) |
| `test/ERC7984XxxModule.test.ts` | One file per module feature |

### Imports & globals

```typescript
import { FhevmType } from '@fhevm/hardhat-plugin';
import { expect } from 'chai';
import { ethers, fhevm } from 'hardhat';

const SOME_ROLE = ethers.keccak256(ethers.toUtf8Bytes('SOME_ROLE'));
```

### Deploy in `beforeEach`

```typescript
beforeEach(async function () {
  const [admin, minter, holder, ...] = await ethers.getSigners();
  // assign to this.*

  this.token = await ethers.deployContract('CMTATFHE', [
    name, symbol, contractURI, admin.address, extraInfoAttributes,
  ]);

  await this.token.connect(admin).grantRole(MINTER_ROLE, minter.address);
  // grant other roles as needed
});
```

### Encrypt an input (FHE)

```typescript
const encInput = await fhevm
  .createEncryptedInput(this.token.target, signer.address)
  .add64(amount)
  .encrypt();
// encInput.handles[0] → externalEuint64 handle (bytes32)
// encInput.inputProof  → ZKPoK bytes
```

### Call functions with overloaded selectors

Always use the full selector string when there are multiple overloads:

```typescript
await token.connect(minter)['mint(address,bytes32,bytes)'](to, handle, proof);
await token.connect(holder)['confidentialTransfer(address,bytes32,bytes)'](to, handle, proof);
await token.connect(enforcer)['forcedTransfer(address,address,bytes32,bytes)'](from, to, handle, proof);
await token.connect(enforcer)['forcedBurn(address,bytes32,bytes)'](from, handle, proof);
```

### Decrypt and assert a value

```typescript
async function decrypt(token: any, handle: bigint, signer: any): Promise<bigint> {
  return fhevm.userDecryptEuint(FhevmType.euint64, handle, token.target, signer);
}

const handle = await token.confidentialBalanceOf(account.address);
const balance = await decrypt(token, handle, account); // signer must have ACL access
expect(balance).to.equal(1000n);                       // FHE values are bigint
```

### Testing ACL access (observer pattern)

After granting ACL via `setObserver` or `setRoleObserver`, decrypt using the observer as signer. If ACL was not granted, `userDecryptEuint` throws — use this as the positive-path assertion.

```typescript
// Positive: observer can decrypt after being set
await token.connect(holder).setObserver(holder.address, observer.address);
const handle = await token.confidentialBalanceOf(holder.address);
const value = await decrypt(token, handle, observer); // succeeds → ACL granted
expect(value).to.equal(expectedBalance);
```

### Asserting reverts

```typescript
// Custom error
await expect(token.connect(other).setRoleObserver(...))
  .to.be.revertedWithCustomError(token, 'ERC7984BalanceViewModule_SameRoleObserver');

// Access control (role missing) — no specific error needed
await expect(token.connect(unauthorized).someFunction()).to.be.reverted;
```

### Asserting events

```typescript
await expect(token.connect(manager).setRoleObserver(account.address, observer.address))
  .to.emit(token, 'RoleObserverSet')
  .withArgs(account.address, ethers.ZeroAddress, observer.address, manager.address);
```

### Test structure template

```typescript
describe('ERC7984XxxModule', function () {
  beforeEach(async function () { /* deploy + roles */ });

  // helpers defined at file scope (not inside describe)
  async function mint(token, minter, to, amount) { ... }
  async function decrypt(token, handle, signer): Promise<bigint> { ... }

  describe('access control', function () {
    it('authorized role can call function', ...);
    it('unauthorized caller is rejected', ...);
  });

  describe('state changes', function () {
    it('updates storage correctly', ...);
    it('emits event with correct args', ...);
    it('reverts with SameXxx on duplicate', ...);
  });

  describe('ACL / FHE effects', function () {
    it('grants ACL on existing handle immediately', ...);
    it('grants ACL via _update after transfer', ...);
  });

  describe('independence / invariants', function () {
    it('feature X does not affect feature Y', ...);
  });
});
```

---

## FHE Gotchas

| Gotcha | Notes |
|--------|-------|
| `uint64` range | Max ~18.4 × 10¹⁸. Use 6 decimals (not 18) to avoid overflow for realistic supplies |
| Insufficient balance | Transfers/burns with amount > balance execute but transfer/burn **0 silently** — no revert |
| Handle staleness | Every arithmetic operation creates a new handle. ACL must be re-granted after each `_update` |
| `super._update` chain | `ERC7984BalanceViewModule._update` → `ERC7984ObserverAccess._update` → `ERC7984._update` |
| `FHE.allow` is permanent | ACL cannot be revoked. Removing an observer only prevents future grants |
| `userDecryptEuint` signature | `(type, handle, contractAddress, signerWithAccess)` — contract address is the 3rd arg |
| `bigint` comparisons | FHE decrypted values are `bigint` — use `1000n`, not `1000` in assertions |

---

## Existing Roles & Modules Summary

| Role | Module | Authorization hook |
|------|--------|--------------------|
| `MINTER_ROLE` | `ERC7984MintModule` | `_authorizeMint()` |
| `BURNER_ROLE` | `ERC7984BurnModule` | `_authorizeBurn()` |
| `FORCED_OPS_ROLE` | `ERC7984EnforcementModule` | `_authorizeForcedTransfer()`, `_authorizeForcedBurn()` |
| `PAUSER_ROLE` | `PauseModule` (CMTAT) | `_authorizePause()` |
| `DEFAULT_ADMIN_ROLE` | `AccessControlModule` (CMTAT) | `_authorizeDeactivate()` |
| `ENFORCER_ROLE` | `EnforcementModule` (CMTAT) | `_authorizeFreeze()` |
| `OBSERVER_ROLE` | `ERC7984BalanceViewModule` | `_authorizeObserverManagement()` |
