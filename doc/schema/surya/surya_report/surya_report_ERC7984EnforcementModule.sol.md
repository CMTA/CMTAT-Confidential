## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./modules/ERC7984EnforcementModule.sol | d28d5a867cd7d4b9ed73982df2710247e34e6f8e |


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
