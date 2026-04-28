## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./modules/ERC7984TotalSupplyViewModule.sol | aecbcb94419a7bbc80ab79feb865c3480564b9d1 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ERC7984TotalSupplyViewModule** | Implementation | ERC7984 |||
| └ | maxSupplyObservers | Public ❗️ |   |NO❗️ |
| └ | setMaxSupplyObservers | Public ❗️ | 🛑  | onlyMaxObserversAdmin |
| └ | addTotalSupplyObserver | Public ❗️ | 🛑  | onlySupplyObserverManager |
| └ | removeTotalSupplyObserver | Public ❗️ | 🛑  | onlySupplyObserverManager |
| └ | totalSupplyObservers | Public ❗️ |   |NO❗️ |
| └ | _updateTotalSupplyObserversAcl | Internal 🔒 | 🛑  | |
| └ | _authorizeTotalSupplyObserverManagement | Internal 🔒 | 🛑  | |
| └ | _authorizeSetMaxSupplyObservers | Internal 🔒 | 🛑  | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
