## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./CMTATConfidentialBase.sol | 30e22bed551548dcaf1cd61030a97f3bea92d5ec |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **CMTATConfidentialBase** | Implementation | ERC7984, CMTATBaseGeneric, IERC7943FungibleTransferError, ZamaEthereumConfig, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule, ERC7984BalanceViewModule, ERC7984PublishTotalSupplyModule, ERC7984TokenAttributeModule, CMTATConfidentialVersionModule |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC7984 |
| └ | initialize | Internal 🔒 | 🛑  | initializer |
| └ | _authorizeMint | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeBurn | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeForcedTransfer | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeForcedBurn | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizePause | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeDeactivate | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeFreeze | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeObserverManagement | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizePublishTotalSupply | Internal 🔒 | 🛑  | onlyRole |
| └ | _authorizeTokenAttributeManagement | Internal 🔒 | 🛑  | onlyRole |
| └ | name | Public ❗️ |   |NO❗️ |
| └ | symbol | Public ❗️ |   |NO❗️ |
| └ | decimals | Public ❗️ |   |NO❗️ |
| └ | _afterBurn | Internal 🔒 | 🛑  | |
| └ | _update | Internal 🔒 | 🛑  | |
| └ | _validateMint | Internal 🔒 | 🛑  | |
| └ | _validateBurn | Internal 🔒 | 🛑  | |
| └ | _validateForcedTransfer | Internal 🔒 | 🛑  | |
| └ | _validateForcedBurn | Internal 🔒 | 🛑  | |
| └ | canTransfer | Public ❗️ |   |NO❗️ |
| └ | confidentialTransfer | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransfer | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFromAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFromAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | _beforeTransfer | Internal 🔒 | 🛑  | |
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
| └ | version | Public ❗️ |   |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
