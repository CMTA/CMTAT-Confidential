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
     * @dev Extends the base freeze/pause validation with RuleEngine screening of the
     * mint leg (`from = address(0)`). Standard CMTAT screens every balance change —
     * including issuance — at the `ruleEngine.transferred` chokepoint; the base variant
     * only wires the engine into confidential transfers, so without this override a mint
     * to a non-whitelisted or sanctioned address would succeed even though a
     * `confidentialTransfer` to the same address reverts (audit finding M-01).
     *
     * The recipient is checked with `_canTransferByRuleEngine(address(0), to)` and, on
     * success, `ruleEngine.transferred(address(0), to, 0)` is fired *before* the FHE
     * mint, matching CMTAT's pre-transfer enforcement order. The `address(0)` sender leg
     * is passed to the engine exactly as standard CMTAT does for mint; the configured
     * engine is responsible for treating that leg as issuance (e.g. exempting it from
     * whitelist/spender checks). Forced operations are unaffected — they run through
     * `_validateForcedTransfer` / `_validateForcedBurn` and intentionally bypass the engine.
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
     * @dev Extends the base freeze/pause validation with RuleEngine screening of the
     * burn leg (`to = address(0)`). See {_validateMint} for the rationale (audit finding
     * M-01). The sender is checked with `_canTransferByRuleEngine(from, address(0))` and,
     * on success, `ruleEngine.transferred(from, address(0), 0)` is fired before the FHE
     * burn. Forced burns run through `_validateForcedBurn` and intentionally bypass the engine.
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
