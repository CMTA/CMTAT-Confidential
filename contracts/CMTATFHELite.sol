// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {CMTATFHEBase} from "./CMTATFHEBase.sol";

/**
 * @title CMTATFHELite
 * @dev Lightweight deployment variant of CMTAT FHE.
 *
 * Identical to CMTATFHE but without ERC7984TotalSupplyViewModule, reducing
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
 *   - Public total supply disclosure via publishTotalSupply (SUPPLY_OBSERVER_ROLE)
 *   - Document management and token metadata (CMTAT)
 *
 * For automatic per-observer ACL re-grant on every mint/burn, use CMTATFHE instead.
 */
contract CMTATFHELite is CMTATFHEBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) CMTATFHEBase(name_, symbol_, contractURI_, admin, extraInformationAttributes_) {}
}
