# Aderyn Report v0.2.0 — Maintainer Feedback

Review of [`aderyn-report.md`](./aderyn-report.md) (0 high, 8 low).
Each finding is assessed below with disposition and rationale.

---

## L-1: Centralization Risk (11 instances) — Accepted, by design

The flagged instances are authorization hooks (`_authorize*`) protected by
`onlyRole(...)` in `CMTATConfidential` / `CMTATConfidentialBase`.

CMTAT Confidential is a regulated security token. Privileged roles for mint, burn,
pause, freeze, forced operations, observer management, and contract administration
are required by design and by compliance workflows.

No code change required.

---

## L-2: Unspecific Solidity Pragma (12 instances) — Accepted, intentional

Contracts use `pragma solidity ^0.8.27` to remain compatible with the
OpenZeppelin Confidential Contracts submodule.

Build output remains deterministic because Hardhat is pinned to compile with
`0.8.34` (`hardhat.config.ts`).

No code change required.

---

## L-3: PUSH0 Opcode (12 instances) — Not applicable

This warning applies when targeting chains that do not support `PUSH0`.
This project targets Ethereum mainnet and configures EVM `prague`, which supports
`PUSH0`.

No code change required.

---

## L-4: Modifier Invoked Only Once (2 instances) — Accepted, intentional

Flagged modifiers:
- `onlySupplyPublisher` (`ERC7984PublishTotalSupplyModule`)
- `onlyMaxObserversAdmin` (`ERC7984TotalSupplyViewModule`)

Both are intentionally kept as dedicated access-control entry points to preserve
module readability and pattern consistency (`modifier -> _authorize* hook`).

No code change required.

---

## L-5: Empty Block (18 instances) — Accepted, intentional

Two categories are flagged:
- Modifier-only authorization hooks with empty bodies
- Optional virtual extension hooks with no-op defaults

Both patterns are intentional in this modular architecture and are required for
clean inheritance overrides in `CMTATConfidential` / `CMTATConfidentialBase`.

No code change required.

---

## L-6: Internal Function Used Only Once (1 instance) — Accepted, required

The flagged function is `initialize(...)` in `CMTATConfidentialBase`.
It is intentionally separated so the OpenZeppelin `initializer` modifier can be
applied safely.

No code change required.

---

## L-7: State Change Without Event (1 instance) — Not applicable (mock only)

The flagged function is `setAccept(bool)` in `contracts/mocks/ConfidentialReceiverMock.sol`.
This is test-only mock code and is not part of production deployment.

No code change required.

---

## L-8: Unchecked Return (12 instances) — Not applicable

`FHE.allow(...)` and `FHE.makePubliclyDecryptable(...)` are used in a fluent style.
Their returned handle is not an error code; ignoring it when chaining is not needed
is intentional.

No code change required.

---

## Summary

| Finding | Instances | Disposition |
|---------|-----------|-------------|
| L-1 Centralization Risk | 11 | Accepted — required role model for regulated token |
| L-2 Unspecific Pragma | 12 | Accepted — compatibility with OZ Confidential submodule |
| L-3 PUSH0 Opcode | 12 | Not applicable — mainnet target, `prague` EVM |
| L-4 Modifier Invoked Only Once | 2 | Accepted — intentional module auth pattern |
| L-5 Empty Block | 18 | Accepted — intentional hooks and extension points |
| L-6 Internal Function Used Only Once | 1 | Accepted — required `initializer` pattern |
| L-7 State Change Without Event | 1 | Not applicable — mock contract only |
| L-8 Unchecked Return | 12 | Not applicable — fluent FHE API usage |

No findings require a production code change.
