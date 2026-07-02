// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {VersionModule} from "../../lib/CMTAT/contracts/modules/wrapper/core/VersionModule.sol";

/**
 * @title CMTATConfidentialVersionModule
 * @dev Overrides CMTAT VersionModule to pin the exposed version string.
 */
abstract contract CMTATConfidentialVersionModule is VersionModule {
    string private constant CMTAT_CONFIDENTIAL_VERSION = "0.3.0";

    /**
     * @notice Returns the contract implementation version string.
     * @dev Conforms to ERC-8303 (Contract Version, interface id `0x54fd4d50`) and
     * follows the recommended `MAJOR.MINOR.PATCH` Semantic Versioning format.
     * @return version_ The pinned CMTAT Confidential implementation version (e.g. "0.3.0").
     */
    function version()
        public
        view
        virtual
        override
        returns (string memory version_)
    {
        return CMTAT_CONFIDENTIAL_VERSION;
    }
}
