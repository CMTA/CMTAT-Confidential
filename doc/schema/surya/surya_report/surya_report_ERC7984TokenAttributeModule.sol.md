## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./modules/ERC7984TokenAttributeModule.sol | 7f00f53a62985fc662663602d0622e57854fad0f |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ERC7984TokenAttributeModule** | Implementation | ERC7984, IERC7984TokenAttributeModule |||
| └ | _initTokenAttributes | Internal 🔒 | 🛑  | |
| └ | name | Public ❗️ |   |NO❗️ |
| └ | symbol | Public ❗️ |   |NO❗️ |
| └ | setName | Public ❗️ | 🛑  | onlyTokenAttributeManager |
| └ | setSymbol | Public ❗️ | 🛑  | onlyTokenAttributeManager |
| └ | _authorizeTokenAttributeManagement | Internal 🔒 | 🛑  | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
