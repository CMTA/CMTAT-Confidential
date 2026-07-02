// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {IRuleEngine} from "../../lib/CMTAT/contracts/interfaces/engine/IRuleEngine.sol";
import {CMTATConfidential} from "./CMTATConfidential.sol";
import {CMTATConfidentialBase} from "../CMTATConfidentialBase.sol";
import {ERC7984RuleEngineModule} from "../modules/ERC7984RuleEngineModule.sol";

/**
 * @title CMTATConfidentialRuleEngine
 * @dev Deployment variant that restricts confidential transfers through a CMTA
 * RuleEngine. Because transferred amounts are encrypted, RuleEngine validation
 * and transfer notifications always receive `value = 0`.
 */
contract CMTATConfidentialRuleEngine is
    CMTATConfidential,
    ERC7984RuleEngineModule
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractUri_,
        uint8 decimals_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes
            memory extraInformationAttributes_,
        IRuleEngine ruleEngine_
    )
        CMTATConfidential(
            name_,
            symbol_,
            contractUri_,
            decimals_,
            admin,
            extraInformationAttributes_
        )
    {
        if (address(ruleEngine_) != address(0)) {
            _setRuleEngine(ruleEngine_);
        }
    }

    /**
     * @notice Returns whether a transfer from `from` to `to` is currently permitted.
     * @dev `amount` is intentionally ignored. Transfer amounts are encrypted and
     * unavailable to public view functions, so amount-based rules in the RuleEngine
     * (e.g. minimum size, balance caps) are not evaluated here. Only sender/receiver
     * permissioning rules are reflected by this view.
     * @param from Token sender.
     * @param to Token recipient.
     * @return allowed True if the transfer passes module and RuleEngine checks.
     */
    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view virtual override(CMTATConfidentialBase) returns (bool allowed) {
        return
            _canTransferGenericByModule(address(0), from, to) &&
            _canTransferByRuleEngine(from, to);
    }

    /**
     * @notice Returns whether a delegated transfer by `spender` from `from` to `to` is permitted.
     * @dev `amount` is intentionally ignored for the same reason as `canTransfer`.
     * @param spender Address initiating the delegated transfer.
     * @param from Token sender.
     * @param to Token recipient.
     * @return allowed True if the delegated transfer passes module and RuleEngine checks.
     */
    function canTransferFrom(
        address spender,
        address from,
        address to,
        uint256 /*amount*/
    ) public view virtual returns (bool allowed) {
        return
            _canTransferGenericByModule(spender, from, to) &&
            _canTransferFromByRuleEngine(spender, from, to);
    }

    function _beforeTransfer(
        address spender,
        address from,
        address to
    ) internal virtual override(CMTATConfidentialBase) {
        ERC7984RuleEngineModule._applyRuleEngine(spender, from, to);
    }

    /**
     * @inheritdoc CMTATConfidentialBase
     * @dev Adds RuleEngine screening to the mint leg (`from = address(0)`) so issuance
     * is screened like standard CMTAT, not just confidential transfers (audit finding M-01).
     * The `address(0)` leg is passed as standard CMTAT does; the engine handles it as
     * issuance. Forced ops use `_validateForcedTransfer`/`_validateForcedBurn` and bypass this.
     */
    function _validateMint(address to) internal virtual override {
        CMTATConfidentialBase._validateMint(to);
        if (!_canTransferByRuleEngine(address(0), to)) {
            revert ERC7943CannotReceive(to);
        }
        _applyRuleEngine(address(0), address(0), to);
    }

    /**
     * @inheritdoc CMTATConfidentialBase
     * @dev Adds RuleEngine screening to the burn leg (`to = address(0)`). See {_validateMint}.
     */
    function _validateBurn(address from) internal virtual override {
        CMTATConfidentialBase._validateBurn(from);
        if (!_canTransferByRuleEngine(from, address(0))) {
            revert ERC7943CannotSend(from);
        }
        _applyRuleEngine(address(0), from, address(0));
    }

    function _authorizeRuleEngineManagement()
        internal
        virtual
        override
        onlyRole(RULE_ENGINE_ROLE)
    {}
}
