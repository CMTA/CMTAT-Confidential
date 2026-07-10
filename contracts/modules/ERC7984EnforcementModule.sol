// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../lib/openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {IERC7984EnforcementModule} from "../interfaces/IERC7984EnforcementModule.sol";

/**
 * @title ERC7984EnforcementModule
 * @dev Module for enforcement operations on confidential tokens (ERC7984).
 *
 * This module provides:
 * - Forced transfer functions for regulatory compliance
 * - Forced burn functions for regulatory compliance
 * - Flexible access control via virtual authorization functions
 *
 * Forced transfers and burns are designed to operate on frozen addresses.
 * They can be performed even when the contract is deactivated (unless an
 * inheriting contract adds additional checks in `_validateForcedTransfer`
 * or `_validateForcedBurn`).
 * Use cases include: court orders, sanctions compliance, error correction.
 *
 * Role separation:
 * - `FORCED_OPS_ROLE` (defined here) — execute forced transfers and forced burns
 * - `ENFORCER_ROLE` (CMTAT's EnforcementModule) — freeze / unfreeze addresses
 *
 * The two roles are intentionally distinct: freezing an address and moving
 * its funds are separate regulatory powers that may be held by different actors.
 *
 * The authorization functions must be overridden in the inheriting contract
 * to implement the desired access control.
 * The validation functions should be overridden to enforce that the
 * source address is frozen.
 */
abstract contract ERC7984EnforcementModule is ERC7984, IERC7984EnforcementModule {
    /* ============ Roles ============ */
    /// @notice Role allowed to perform forced transfers and forced burns.
    bytes32 public constant FORCED_OPS_ROLE = keccak256("FORCED_OPS_ROLE");

    /* ============ Modifier ============ */
    /**
     * @dev Modifier to restrict access to forced transfer functions.
     * Calls the virtual `_authorizeForcedTransfer()` function for access control.
     * Note: Named differently from CMTAT's onlyEnforcer to avoid conflicts.
     */
    modifier onlyForcedTransferAuthorized() {
        _authorizeForcedTransfer();
        _;
    }

    /**
     * @dev Modifier to restrict access to forced burn functions.
     * Calls the virtual `_authorizeForcedBurn()` function for access control.
     */
    modifier onlyForcedBurnAuthorized() {
        _authorizeForcedBurn();
        _;
    }

    /* ============ Public Functions - Forced Transfer ============ */
    /// @inheritdoc IERC7984EnforcementModule
    function forcedTransfer(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    )
        public
        virtual
        onlyForcedTransferAuthorized
        returns (euint64 transferred)
    {
        _validateForcedTransfer(from, to);
        transferred = _transfer(
            from,
            to,
            FHE.fromExternal(encryptedAmount, inputProof)
        );
        emit ForcedTransfer(msg.sender, from, to, transferred);
    }

    /// @inheritdoc IERC7984EnforcementModule
    function forcedTransfer(
        address from,
        address to,
        euint64 amount
    )
        public
        virtual
        onlyForcedTransferAuthorized
        returns (euint64 transferred)
    {
        _validateForcedTransfer(from, to);
        require(
            FHE.isAllowed(amount, msg.sender),
            ERC7984EnforcementModule_UnauthorizedHandle()
        );
        transferred = _transfer(from, to, amount);
        emit ForcedTransfer(msg.sender, from, to, transferred);
    }

    /* ============ Public Functions - Forced Burn ============ */
    /// @inheritdoc IERC7984EnforcementModule
    function forcedBurn(
        address from,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual onlyForcedBurnAuthorized returns (euint64 burned) {
        _validateForcedBurn(from);
        burned = _burn(from, FHE.fromExternal(encryptedAmount, inputProof));
        _afterBurn(from, burned);
        emit ForcedBurn(msg.sender, from, burned);
    }

    /// @inheritdoc IERC7984EnforcementModule
    function forcedBurn(
        address from,
        euint64 amount
    ) public virtual onlyForcedBurnAuthorized returns (euint64 burned) {
        _validateForcedBurn(from);
        require(
            FHE.isAllowed(amount, msg.sender),
            ERC7984EnforcementModule_UnauthorizedHandle()
        );
        burned = _burn(from, amount);
        _afterBurn(from, burned);
        emit ForcedBurn(msg.sender, from, burned);
    }

    /* ============ Internal Functions ============ */
    /**
     * @dev Validates the forced transfer operation. Override to add custom validation logic.
     * @param from Source address
     * @param to Destination address
     */
    function _validateForcedTransfer(
        address from,
        address to
    ) internal virtual {
        // Default: no additional validation
        // Override to enforce frozen address requirement
    }

    /**
     * @dev Validates the forced burn operation. Override to add custom validation logic.
     * @param from Address to burn from
     */
    function _validateForcedBurn(address from) internal virtual {
        // Default: no additional validation
        // Override to enforce frozen address requirement
    }

    /* ============ Access Control ============ */
    /**
     * @dev Authorization function for forced transfer operations.
     * Must be overridden to implement access control.
     */
    function _authorizeForcedTransfer() internal virtual;

    /**
     * @dev Hook called after every successful forced burn. Empty by default.
     * Override to add post-burn logic (e.g., updating total supply observer ACL).
     * Mirrors the `_afterBurn` hook in ERC7984BurnModule so both regular and
     * forced burns trigger the same post-burn logic in inheriting contracts.
     */
    function _afterBurn(address from, euint64 burned) internal virtual {}

    /**
     * @dev Authorization function for forced burn operations.
     * Must be overridden to implement access control.
     */
    function _authorizeForcedBurn() internal virtual;
}
