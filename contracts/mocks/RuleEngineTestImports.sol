// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {RuleEngineMock} from "../../lib/CMTAT/contracts/mocks/RuleEngine/RuleEngineMock.sol";

abstract contract RuleEngineTestImports {
    function _ruleEngineMockCreationCodeLength() internal pure returns (uint256) {
        return type(RuleEngineMock).creationCode.length;
    }
}
