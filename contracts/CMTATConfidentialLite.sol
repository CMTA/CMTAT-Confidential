// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {CMTATConfidentialBase} from "./CMTATConfidentialBase.sol";

/**
 * @title CMTATConfidentialLite
 * @dev Lightweight deployment variant of CMTAT Confidential.
 *
 * Identical to CMTATConfidential but without ERC7984TotalSupplyViewModule, reducing
 * gas costs and contract size when total supply visibility is not required.
 *
 * Includes:
 *   - Confidential balances (euint64)
 *   - Confidential transfers with ZKPoK inputs
 *   - Mint / Burn (MINTER_ROLE / BURNER_ROLE)
 *   - Forced transfer / Forced burn (FORCED_OPS_ROLE)
 *   - Pause / Unpause (PAUSER_ROLE)
 *   - Freeze / Unfreeze (ENFORCER_ROLE)
 *   - Per-account balance observers (OBSERVER_ROLE)
 *   - Public total supply disclosure via publishTotalSupply (SUPPLY_PUBLISHER_ROLE)
 *   - Document management and token metadata (CMTAT)
 *
 * For automatic per-observer ACL re-grant on every mint/burn, use CMTATConfidential instead.
 */
contract CMTATConfidentialLite is CMTATConfidentialBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        uint8 decimals_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) CMTATConfidentialBase(name_, symbol_, contractURI_, decimals_, admin, extraInformationAttributes_) {}
}
