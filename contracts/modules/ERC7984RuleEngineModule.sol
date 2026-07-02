// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IRuleEngine} from "../../lib/CMTAT/contracts/interfaces/engine/IRuleEngine.sol";
import {ValidationModuleRuleEngineInternal} from "../../lib/CMTAT/contracts/modules/internal/ValidationModuleRuleEngineInternal.sol";

/**
 * @title ERC7984RuleEngineModule
 * @dev RuleEngine integration for confidential transfers.
 *
 * ERC-7984 transfer amounts are encrypted, so every RuleEngine call receives
 * `value = 0`. Rules can still enforce public restrictions based on spender,
 * sender, recipient, timestamps, bound token state, allowlists, blacklists, etc.
 */
abstract contract ERC7984RuleEngineModule is ValidationModuleRuleEngineInternal {
    /// @notice Role allowed to set or update the RuleEngine.
    bytes32 public constant RULE_ENGINE_ROLE = keccak256("RULE_ENGINE_ROLE");

    error ERC7984RuleEngineModule_SameRuleEngine();

    modifier onlyRuleEngineManager() {
        _authorizeRuleEngineManagement();
        _;
    }

    /**
     * @dev Pass `address(0)` to disable RuleEngine checks entirely.
     * Note: calling `setRuleEngine(address(0))` when no engine has been set yet
     * (i.e. `ruleEngine() == address(0)`) reverts with `ERC7984RuleEngineModule_SameRuleEngine`.
     * The constructor uses `_setRuleEngine` directly to bypass this check, so
     * this edge case only arises if the caller explicitly tries to set zero after
     * deployment without first setting a non-zero engine.
     * @param newRuleEngine The RuleEngine to set (`address(0)` disables RuleEngine checks).
     */
    function setRuleEngine(
        IRuleEngine newRuleEngine
    ) public virtual onlyRuleEngineManager {
        if (address(newRuleEngine) == address(ruleEngine())) {
            revert ERC7984RuleEngineModule_SameRuleEngine();
        }
        _setRuleEngine(newRuleEngine);
    }

    function _canTransferByRuleEngine(
        address from,
        address to
    ) internal view virtual returns (bool) {
        IRuleEngine ruleEngine_ = ruleEngine();
        if (address(ruleEngine_) == address(0)) {
            return true;
        }
        return ruleEngine_.canTransfer(from, to, 0);
    }

    function _canTransferFromByRuleEngine(
        address spender,
        address from,
        address to
    ) internal view virtual returns (bool) {
        IRuleEngine ruleEngine_ = ruleEngine();
        if (address(ruleEngine_) == address(0)) {
            return true;
        }
        return ruleEngine_.canTransferFrom(spender, from, to, 0);
    }

    /**
     * @dev Fires `ruleEngine.transferred()` before FHE arithmetic, matching CMTAT's
     * pre-transfer enforcement order. If the rule engine reverts, no FHE gas is wasted.
     * Intended to be wired in as the `_beforeTransfer` hook from `CMTATConfidentialBase`
     * via an explicit override in the deployment contract.
     */
    function _applyRuleEngine(address spender, address from, address to) internal virtual {
        IRuleEngine ruleEngine_ = ruleEngine();
        if (address(ruleEngine_) != address(0)) {
            if (spender != address(0)) {
                ruleEngine_.transferred(spender, from, to, 0);
            } else {
                ruleEngine_.transferred(from, to, 0);
            }
        }
    }

    function _authorizeRuleEngineManagement() internal virtual;
}
