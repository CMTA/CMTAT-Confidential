## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./modules/ERC7984EnforcementModule.sol | 939dd70b57e7c10d2b437cc57dbd93cd6332e7e8 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ERC7984EnforcementModule** | Implementation | ERC7984, IERC7984EnforcementModule |||
| └ | forcedTransfer | Public ❗️ | 🛑  | onlyForcedTransferAuthorized |
| └ | forcedTransfer | Public ❗️ | 🛑  | onlyForcedTransferAuthorized |
| └ | forcedBurn | Public ❗️ | 🛑  | onlyForcedBurnAuthorized |
| └ | forcedBurn | Public ❗️ | 🛑  | onlyForcedBurnAuthorized |
| └ | _validateForcedTransfer | Internal 🔒 | 🛑  | |
| └ | _validateForcedBurn | Internal 🔒 | 🛑  | |
| └ | _authorizeForcedTransfer | Internal 🔒 | 🛑  | |
| └ | _afterBurn | Internal 🔒 | 🛑  | |
| └ | _authorizeForcedBurn | Internal 🔒 | 🛑  | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
