## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ./modules/ERC7984TotalSupplyViewModule.sol | 874e1db76caf7e74ead77f0351f9b676158f6e22 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ERC7984TotalSupplyViewModule** | Implementation | ERC7984, IERC7984TotalSupplyViewModule |||
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
