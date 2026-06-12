// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {CMTATConfidential} from "./CMTATConfidential.sol";
import {AllowlistModule} from "../CMTAT/contracts/modules/wrapper/options/AllowlistModule.sol";

/**
 * @title CMTATConfidentialWhitelist
 * @dev Deployment variant using CMTAT allowlist-only policy.
 *
 * Rules:
 * - If `isAllowlistEnabled() == false`, allowlist restrictions are bypassed.
 * - If `isAllowlistEnabled() == true`, both sender and recipient must be allowlisted.
 *
 * Forced operations (forced transfer / forced burn) are unchanged.
 */
contract CMTATConfidentialWhitelist is CMTATConfidential, AllowlistModule {
    error ERC7943CannotSend(address account);
    error ERC7943CannotReceive(address account);
    error ERC7943CannotTransfer(address from, address to, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractUri_,
        uint8 decimals_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    )
        CMTATConfidential(
            name_,
            symbol_,
            contractUri_,
            decimals_,
            admin,
            extraInformationAttributes_
        )
    {}

    function canSend(address account) public view returns (bool allowed) {
        return canTransact(account);
    }

    function canReceive(address account) public view returns (bool allowed) {
        return canTransact(account);
    }

    function canTransact(
        address account
    ) public view virtual override returns (bool allowed) {
        if (!super.canTransact(account)) {
            return false;
        }
        if (!isAllowlistEnabled()) {
            return true;
        }
        return isAllowlisted(account);
    }

    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view returns (bool allowed) {
        return
            canSend(from) &&
            canReceive(to) &&
            _canTransferByWhitelistPolicy(from, to);
    }

    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return super.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    function confidentialTransfer(
        address to,
        euint64 amount
    ) public virtual override returns (euint64) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return super.confidentialTransfer(to, amount);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(from, to);
        return
            super.confidentialTransferFrom(from, to, encryptedAmount, inputProof);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(from, to);
        return super.confidentialTransferFrom(from, to, amount);
    }

    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return
            super.confidentialTransferAndCall(
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
        _enforceWhitelistAndRevert(_msgSender(), to);
        return super.confidentialTransferAndCall(to, amount, data);
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(from, to);
        return
            super.confidentialTransferFromAndCall(
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
        _enforceWhitelistAndRevert(from, to);
        return super.confidentialTransferFromAndCall(from, to, amount, data);
    }

    function _canTransferByWhitelistPolicy(
        address from,
        address to
    ) internal view returns (bool) {
        if (!isAllowlistEnabled()) {
            return true;
        }
        return isAllowlisted(from) && isAllowlisted(to);
    }

    function _enforceWhitelistAndRevert(address from, address to) internal view {
        if (!_canTransferByWhitelistPolicy(from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
    }

    function _authorizeAllowlistManagement()
        internal
        virtual
        override
        onlyRole(ALLOWLIST_ROLE)
    {}
}
