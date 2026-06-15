// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {CMTATConfidential} from "./CMTATConfidential.sol";
import {AllowlistModule} from "../lib/CMTAT/contracts/modules/wrapper/options/AllowlistModule.sol";
import {ValidationModule} from "../lib/CMTAT/contracts/modules/wrapper/controllers/ValidationModule.sol";

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
    bytes4 private constant _INTERFACE_ID_ERC7943_FUNGIBLE = 0x3edbb4c4;

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

    function canSend(
        address account
    ) public view virtual override returns (bool allowed) {
        if (!ValidationModule.canSend(account)) {
            return false;
        }
        if (!isAllowlistEnabled()) {
            return true;
        }
        return isAllowlisted(account);
    }

    function canReceive(
        address account
    ) public view virtual override returns (bool allowed) {
        if (!ValidationModule.canReceive(account)) {
            return false;
        }
        if (!isAllowlistEnabled()) {
            return true;
        }
        return isAllowlisted(account);
    }

    /**
     * @notice Checks whether a confidential transfer is currently allowed by
     * account-level and allowlist policy checks.
     * @dev ERC-7943 includes `amount` for fungible tokens. In this confidential
     * variant the transfer amount is encrypted, so the public view cannot
     * evaluate amount-specific balance or frozen-amount rules. The public
     * `amount` parameter is therefore intentionally ignored and this function
     * only reflects permissioned transfer rules that are public in this model.
     */
    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view returns (bool allowed) {
        return canSend(from) && canReceive(to);
    }

    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return CMTATConfidential.confidentialTransfer(
            to,
            encryptedAmount,
            inputProof
        );
    }

    function confidentialTransfer(
        address to,
        euint64 amount
    ) public virtual override returns (euint64) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return CMTATConfidential.confidentialTransfer(to, amount);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(from, to);
        return
            CMTATConfidential.confidentialTransferFrom(
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
        _enforceWhitelistAndRevert(from, to);
        return CMTATConfidential.confidentialTransferFrom(from, to, amount);
    }

    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        _enforceWhitelistAndRevert(_msgSender(), to);
        return
            CMTATConfidential.confidentialTransferAndCall(
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
        return CMTATConfidential.confidentialTransferAndCall(to, amount, data);
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
            CMTATConfidential.confidentialTransferFromAndCall(
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
        return
            CMTATConfidential.confidentialTransferFromAndCall(
                from,
                to,
                amount,
                data
            );
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ERC7943_FUNGIBLE ||
            CMTATConfidential.supportsInterface(interfaceId);
    }

    function _authorizeAllowlistManagement()
        internal
        virtual
        override
        onlyRole(ALLOWLIST_ROLE)
    {}
}
