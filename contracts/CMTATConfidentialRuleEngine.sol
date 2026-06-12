// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {IRuleEngine} from "../lib/CMTAT/contracts/interfaces/engine/IRuleEngine.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {CMTATConfidential} from "./CMTATConfidential.sol";
import {ERC7984RuleEngineModule} from "./modules/ERC7984RuleEngineModule.sol";

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

    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view returns (bool allowed) {
        return
            _canTransferGenericByModule(address(0), from, to) &&
            _canTransferByRuleEngine(from, to);
    }

    function canTransferFrom(
        address spender,
        address from,
        address to,
        uint256 /*amount*/
    ) public view returns (bool allowed) {
        return
            _canTransferGenericByModule(spender, from, to) &&
            _canTransferFromByRuleEngine(spender, from, to);
    }

    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        _transferredByRuleEngine(from, to);
        transferred = CMTATConfidential.confidentialTransfer(
            to,
            encryptedAmount,
            inputProof
        );
    }

    function confidentialTransfer(
        address to,
        euint64 amount
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        _transferredByRuleEngine(from, to);
        transferred = CMTATConfidential.confidentialTransfer(to, amount);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        _transferredFromByRuleEngine(spender, from, to);
        transferred = CMTATConfidential.confidentialTransferFrom(
            from,
            to,
            encryptedAmount,
            inputProof
        );
    }

    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        _transferredFromByRuleEngine(spender, from, to);
        transferred = CMTATConfidential.confidentialTransferFrom(
            from,
            to,
            amount
        );
    }

    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        _transferredByRuleEngine(from, to);
        transferred = CMTATConfidential.confidentialTransferAndCall(
            to,
            encryptedAmount,
            inputProof,
            data
        );
    }

    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        _transferredByRuleEngine(from, to);
        transferred = CMTATConfidential.confidentialTransferAndCall(
            to,
            amount,
            data
        );
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        _transferredFromByRuleEngine(spender, from, to);
        transferred = CMTATConfidential.confidentialTransferFromAndCall(
            from,
            to,
            encryptedAmount,
            inputProof,
            data
        );
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        _transferredFromByRuleEngine(spender, from, to);
        transferred = CMTATConfidential.confidentialTransferFromAndCall(
            from,
            to,
            amount,
            data
        );
    }

    function _authorizeRuleEngineManagement()
        internal
        virtual
        override
        onlyRole(RULE_ENGINE_ROLE)
    {}
}
