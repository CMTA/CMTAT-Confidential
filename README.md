# CMTAT Zama FHE

This repository contains the CMTAT version for [Zama FHE](https://www.zama.ai).

- [CMTAT](https://github.com/CMTA/CMTAT?tab=readme-ov-file) is a framework for the tokenization of securities in compliance with local regulations. 

- Zama technology allows to keep token holders balance private by encrypted their value with FHE.

The projet uses the [CMTAT Solidity](https://github.com/CMTA/CMTAT) implementation for non-ERC20 related functions, such as:

- Manage tokenization terms and documents (CMTAT ExtraInformationModule & DocumentEngineModule)
- Compliance check such as address freeze (CMTAT EnforcementModule)
- Possibility to pause all transfers and "deactivate" the smart contract (CMTAT PauseModule)

Then it uses the FHE version to handle everything related to transfers



## OpenZeppelin

CMTAT FHE is mainly based on the [Confidential Fungible Token](https://docs.openzeppelin.com/confidential-contracts/0.1.0/token) produced by OpenZeppelin

### Transfer

The token standard exposes eight different transfer functions. They are all permutations of the following options:

- `transfer` and `transferFrom`: `transfer` moves tokens from the sender while `transferFrom` moves tokens from a specified `from` address. See [operator](https://docs.openzeppelin.com/confidential-contracts/0.1.0/token#operator).
- With and without `inputProof`: An `inputProof` can be provided to prove that the sender knows the value of the cypher-text `amount` provided.
- With and without an `ERC1363` style callback: The standard implements callbacks, see the [callback](https://docs.openzeppelin.com/confidential-contracts/0.1.0/token#callback) section for more details.

Select the appropriate transfer function and generate a cypher-text using [fhevm-js](https://github.com/zama-ai/fhevm-js). If the cypher-text is a new value, or the sender does not have permission to access the cypher text, an input-proof must be provided to show that the sender knows the value of the cypher-text.



### Operator

An operator is an address that has the ability to move tokens on behalf of another address by calling `transferFrom`. 

- If Bob is an operator for Alice, Bob can move any amount of Alice’s tokens at any point in time. 
- Operators are set using an expiration timestamp—this can be thought of as a limited duration infinite approval for an `ERC20`. 

Below is an example of setting Bob as an operator for Alice for 24 hours.

```typescript
const alice: Wallet;
const expirationTimestamp = Math.round(Date.now()) + 60 * 60 * 24; // Now + 24 hours

await tokenContract.connect(alice).setOperator(bob, expirationTimestamp);
```

Note:

- Operators do not have allowance to reencrypt/decrypt balance handles for other addresses. This means that operators cannot transfer full balances and can only know success after a transaction (by decrypting the transferred amount).
- Setting an operator for any amount of time allows the operator to ***take all of your tokens***. Carefully vet all potential operators before giving operator approval.



### Callback

The token standard exposes transfer functions with and without callbacks. It is up to the caller to decide if a callback is necessary for the transfer. For smart contracts that support it, callbacks allow the operator approval step to be skipped and directly invoke the receiver contract via a callback.

Smart contracts that are the target of a callback must implement [`IConfidentialFungibleTokenReceiver`](https://docs.openzeppelin.com/confidential-contracts/0.1.0/api/interfaces#IConfidentialFungibleTokenReceiver). 

After balances are updated for a transfer, the callback is triggered by calling the [`onConfidentialTransferReceived`](https://docs.openzeppelin.com/confidential-contracts/0.1.0/api/interfaces#IConfidentialFungibleTokenReceiver-onConfidentialTransferReceived-address-address-euint64-bytes-) function. 

The function must either revert or return an `ebool` indicating success. If the callback returns false, the token transfer is reversed.

## Zama concept

### FHE types

Zama FHE introduces several new types for variable and arguments

 See also [docs.zama.ai - smart-contract/types](https://docs.zama.ai/protocol/solidity-guides/smart-contract/types)

### Encrypted input

For example: 

- `externalEuint64 encryptedAmount`: Refers to the index of the encrypted parameter within the proof, representing a specific encrypted input handle.

- `bytes inputProof`: Contains the ciphertext and the associated zero-knowledge proof used for validation.

Example:

```solidity
function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
      ) public virtual override  returns (euint64 transferred)
```

In this example, `encryptedAmount` are encrypted inputs `euint64`  while `inputProof` contains the corresponding ZKPoK to validate their authenticity.

### fromExternal

The `FHE.fromExternal` function ensures that the input is a valid ciphertext with a corresponding ZKPoK.

The function `transfer`and `transferFrom`by OpenZeppelin uses this specific keyword

```solidity
function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual returns (euint64) {
        return _transfer(msg.sender, to, FHE.fromExternal(encryptedAmount, inputProof));
    }
```

See 

- [/OpenZeppelin/openzeppelin-confidential-contracts - ConfidentialFungibleToken.sol#L105C1-L111C6](https://github.com/OpenZeppelin/openzeppelin-confidential-contracts/blob/9c615ab72372c9a0cddbc23dd97f0feb6ca8067d/contracts/token/ConfidentialFungibleToken.sol#L105C1-L111C6)
- [docs.zama.ai -  Encrypted inputs]( https://docs.zama.ai/protocol/solidity-guides/smart-contract/inputs)
- [docs.zama.ai - How validation works](https://docs.zama.ai/protocol/solidity-guides/smart-contract/inputs#how-validation-works)

### Validating encrypted inputs

Smart contracts process encrypted inputs by verifying them against the associated zero-knowledge proof. This is done using the `FHE.asEuintXX`, `FHE.asEbool`, or `FHE.asEaddress` functions, which validate the input and convert it into the appropriate encrypted type.

##  Reference

- [CMTAT Solidity implementation](https://github.com/CMTA/CMTAT)
- [Confidential Fungible Token](https://docs.openzeppelin.com/confidential-contracts/0.1.0/token)
- [docs.zama.ai - overview](https://docs.zama.ai/protocol/solidity-guides/getting-started/overview)
