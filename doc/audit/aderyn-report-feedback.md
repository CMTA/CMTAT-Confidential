# Aderyn Report — Maintainer Feedback

Review of `aderyn-report.md` (8 low-severity findings, 0 high). Each finding is assessed
below with a disposition and rationale.

---

## L-1: Centralization Risk — **Accepted, by design**

All 10 instances are `_authorize*` hooks implementing role-based access control
(`MINTER_ROLE`, `BURNER_ROLE`, `PAUSER_ROLE`, `ENFORCER_ROLE`, `FORCED_OPS_ROLE`,
`DEFAULT_ADMIN_ROLE`, `OBSERVER_ROLE`, `SUPPLY_OBSERVER_ROLE`, `SUPPLY_PUBLISHER_ROLE`).

CMTAT Confidential is a **regulated security token**. Privileged roles for mint, burn,
pause, freeze, and forced transfer are mandatory compliance requirements defined by the
CMTAT specification. Roles are distributed across independent addresses; no single
account holds all roles by default.

No change required.

---

## L-2: Unspecific Solidity Pragma — **Accepted, intentional**

All contracts use `^0.8.27`. This lower bound is set to match the OpenZeppelin
Confidential Contracts submodule, which also requires `^0.8.27`. Pinning to a single
exact version would risk incompatibility when the submodule is updated.

In practice, Hardhat is configured to compile with `0.8.34` (see `hardhat.config.ts`),
so all deployed bytecode is always produced by a known, deterministic compiler version.

No change required.

---

## L-3: PUSH0 Opcode — **Not applicable**

The warning flags contracts compiled with Solidity ≥ 0.8.20 targeting chains that may
not support the `PUSH0` opcode (introduced in Shanghai). CMTAT Confidential targets
**Ethereum mainnet** via the Zama Protocol coprocessor architecture. The EVM version is
explicitly set to `prague` in `hardhat.config.ts`, which is a superset of Shanghai and
fully supports `PUSH0`.

No change required.

---

## L-4: Modifier Invoked Only Once — **Accepted, intentional**

The flagged modifier is `onlySupplyPublisher` in `ERC7984PublishTotalSupplyModule`, used
exclusively on `publishTotalSupply()`.

The modifier is intentional: it delegates authorization to the virtual hook
`_authorizePublishTotalSupply()`, following the same pattern used by every other module
(`onlyMinter` → `_authorizeMint`, etc.). Inlining the call would break pattern
consistency across the module architecture and make the authorization point less visible.

No change required.

---

## L-5: Empty Block — **Accepted, intentional**

16 instances across two categories:

**Authorization hooks (10 instances)** — `_authorizeMint() {} `, `_authorizeBurn() {}`,
etc. These are not truly empty: the access control logic lives in the modifier applied to
each function (`onlyRole(...)`). The empty brace body is the standard Solidity pattern
for modifier-only functions. The same approach is used by OpenZeppelin's `Ownable2Step`
and similar contracts.

**Virtual extension hooks (6 instances)** — `_validateMint`, `_validateBurn`,
`_validateForcedTransfer`, `_validateForcedBurn`, `_afterMint`, `_afterBurn`. These are
intentional no-op defaults that child contracts override to inject pause/freeze checks or
post-operation logic (e.g. ACL re-grant). Empty defaults are the correct implementation
for optional extension points.

No change required.

---

## L-6: Internal Function Used Only Once — **Accepted, required by OZ pattern**

The flagged function is `initialize()` in `CMTATConfidentialBase`:

```solidity
function initialize(...) internal initializer {
    __CMTAT_init(admin, extraInformationAttributes_);
}
```

The `initializer` modifier (from OpenZeppelin `Initializable`) cannot be applied inside
a constructor body inline. A named internal function is the required pattern to attach
`initializer` and ensure the init guard fires exactly once, even in the non-upgradeable
standalone deployment. Inlining the call without the modifier would silently remove the
guard.

No change required.

---

## L-7: State Change Without Event — **Not applicable (mock only)**

The flagged function `setAccept(bool)` is in `contracts/mocks/ConfidentialReceiverMock.sol`,
a test helper that is **never deployed in production**. Event emission in test mocks is
not required.

No change required.

---

## L-8: Unchecked Return — **Not applicable**

12 instances of unchecked return values from `FHE.allow()` and
`FHE.makePubliclyDecryptable()`.

Both functions use a **fluent interface** pattern — they return the same handle that was
passed in, allowing call chaining (e.g. `FHE.allow(FHE.allow(h, a), b)`). The return
value is not an error code; ignoring it when chaining is not needed is correct and
intentional. This pattern is used consistently throughout the OpenZeppelin Confidential
Contracts library itself.

4 of the 12 instances are in mock contracts (`ConfidentialReceiverMock`, `Euint64Factory`)
and are not production code.

No change required.

---

## Summary

| Finding | Disposition |
|---------|-------------|
| L-1 Centralization Risk | Accepted — mandatory for regulated security token |
| L-2 Unspecific Pragma | Accepted — lower bound set by submodule compatibility; Hardhat pins exact compiler |
| L-3 PUSH0 Opcode | Not applicable — target is Ethereum mainnet (`prague` EVM) |
| L-4 Modifier Once | Accepted — consistent with module authorization pattern |
| L-5 Empty Block | Accepted — modifier-only hooks and intentional no-op extension points |
| L-6 Internal Once | Accepted — required by OZ `initializer` modifier pattern |
| L-7 State Without Event | Not applicable — mock contract, not production code |
| L-8 Unchecked Return | Not applicable — fluent interface returns, not error codes |

No findings require a code change.
