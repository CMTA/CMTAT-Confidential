// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {CMTATConfidential} from "./CMTATConfidential.sol";
import {AllowlistModule} from "../lib/CMTAT/contracts/modules/wrapper/options/AllowlistModule.sol";
import {ValidationModule} from "../lib/CMTAT/contracts/modules/wrapper/controllers/ValidationModule.sol";

/**
 * @title CMTATConfidentialWhitelist
 * @dev Deployment variant using CMTAT allowlist-only policy.
 *
 * Rules:
 * - If `isAllowlistEnabled() == false`, allowlist restrictions are bypassed.
 * - If `isAllowlistEnabled() == true`, sender, recipient, and (for `transferFrom`
 *   variants) spender must all be allowlisted.
 *
 * Forced operations (`forcedTransfer`, `forcedBurn`) intentionally bypass the allowlist.
 * They require only that the source address is frozen — the `FORCED_OPS_ROLE` holder has
 * authority to seize frozen funds regardless of whether the parties are allowlisted. This
 * mirrors CMTAT's design intent for regulatory enforcement actions (court orders, sanctions
 * compliance, error correction) where the allowlist is an operational restriction, not an
 * absolute override of regulatory power. The `_validateForcedTransfer` and
 * `_validateForcedBurn` hooks in `CMTATConfidentialBase` enforce only the frozen precondition.
 *
 * Implementation note: allowlist enforcement is wired through CMTAT's standard
 * validation hooks (`_canTransferStandardByModule`, `_canMintBurnByModule`,
 * `_canSend`, `_canReceive`) so the check happens once, in the shared validation
 * path, rather than being duplicated across every transfer variant.
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

    /**
     * @notice Returns whether a confidential transfer from `from` to `to` is
     * currently permitted.
     * @dev ERC-7943 includes `amount` for fungible tokens. In this confidential
     * variant the transfer amount is encrypted, so the public view cannot evaluate
     * amount-specific balance or frozen-amount rules. The public `amount` parameter
     * is therefore intentionally ignored and this function only reflects permissioned
     * transfer rules that are public in this model.
     *
     * Note: this view checks whether an unconditional (non-delegated) transfer is
     * permitted. It uses `address(0)` as the spender, so a delegated transfer by a
     * non-allowlisted spender could still be rejected at execution time.
     */
    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view returns (bool allowed) {
        return _canTransferGenericByModule(address(0), from, to);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == _INTERFACE_ID_ERC7943_FUNGIBLE ||
            CMTATConfidential.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                       INTERNAL VALIDATION HOOKS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Adds allowlist check to the standard transfer validation path.
     * Called by `_canTransferGenericByModule` for every non-mint, non-burn transfer,
     * including `confidentialTransferFrom` variants where `spender != address(0)`.
     */
    function _canTransferStandardByModule(
        address spender,
        address from,
        address to
    ) internal view virtual override(ValidationModule) returns (bool) {
        if (_isAllowlistEnabled()) {
            bool spenderBlocked = spender != address(0) && !isAllowlisted(spender);
            if (spenderBlocked || !isAllowlisted(from) || !isAllowlisted(to)) {
                return false;
            }
        }
        return ValidationModule._canTransferStandardByModule(spender, from, to);
    }

    /**
     * @dev Adds allowlist check for mint and burn operations.
     * Called by `_validateMint` and `_validateBurn` in `CMTATConfidentialBase`.
     */
    function _canMintBurnByModule(
        address account
    ) internal view virtual override(ValidationModule) returns (bool) {
        if (_isAllowlistEnabled() && !isAllowlisted(account)) {
            return false;
        }
        return ValidationModule._canMintBurnByModule(account);
    }

    /**
     * @dev Adds allowlist check to the `canSend` public view path.
     * Keeps the `canSend` / `canReceive` view functions consistent with
     * the actual transfer enforcement in `_canTransferStandardByModule`.
     */
    function _canSend(
        address account
    ) internal view virtual override(ValidationModule) returns (bool) {
        if (_isAllowlistEnabled() && !isAllowlisted(account)) {
            return false;
        }
        return ValidationModule._canSend(account);
    }

    /**
     * @dev Adds allowlist check to the `canReceive` public view path.
     */
    function _canReceive(
        address account
    ) internal view virtual override(ValidationModule) returns (bool) {
        if (_isAllowlistEnabled() && !isAllowlisted(account)) {
            return false;
        }
        return ValidationModule._canReceive(account);
    }

    function _authorizeAllowlistManagement()
        internal
        virtual
        override
        onlyRole(ALLOWLIST_ROLE)
    {}
}
