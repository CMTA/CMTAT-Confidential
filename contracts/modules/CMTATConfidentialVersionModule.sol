// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {VersionModule} from "../../CMTAT/contracts/modules/wrapper/core/VersionModule.sol";

/**
 * @title CMTATConfidentialVersionModule
 * @dev Overrides CMTAT VersionModule to pin the exposed version string.
 */
abstract contract CMTATConfidentialVersionModule is VersionModule {
    string private constant CMTAT_CONFIDENTIAL_VERSION = "0.1.0";

    function version() public view virtual override returns (string memory version_) {
        return CMTAT_CONFIDENTIAL_VERSION;
    }
}
