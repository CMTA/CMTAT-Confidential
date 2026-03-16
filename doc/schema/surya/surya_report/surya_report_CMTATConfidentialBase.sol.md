## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./CMTATConfidentialBase.sol | 0717e6dcdb1e3be76779718e7ffd67ab868f9341 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **CMTATConfidentialBase** | Implementation | ERC7984, CMTATBaseGeneric, ZamaEthereumConfig, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule, ERC7984BalanceViewModule, ERC7984PublishTotalSupplyModule, CMTATConfidentialVersionModule |||
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
| └ | decimals | Public ❗️ |   |NO❗️ |
| └ | _update | Internal 🔒 | 🛑  | |
| └ | _validateMint | Internal 🔒 | 🛑  | |
| └ | _validateBurn | Internal 🔒 | 🛑  | |
| └ | _validateForcedTransfer | Internal 🔒 | 🛑  | |
| └ | _validateForcedBurn | Internal 🔒 | 🛑  | |
| └ | confidentialTransfer | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransfer | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFromAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | confidentialTransferFromAndCall | Public ❗️ | 🛑  |NO❗️ |
| └ | supportsInterface | Public ❗️ |   |NO❗️ |
| └ | version | Public ❗️ |   |NO❗️ |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
