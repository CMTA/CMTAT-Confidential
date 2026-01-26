// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984EnforcementModule
 * @dev Module for enforcement operations on confidential tokens (ERC7984).
 *
 * This module provides:
 * - Forced transfer functions for regulatory compliance
 * - Flexible access control via virtual authorization function
 *
 * Forced transfers are designed to transfer tokens FROM frozen addresses.
 * They can be performed even when the contract is deactivated.
 * Use cases include: court orders, sanctions compliance, error correction.
 *
 * The authorization function `_authorizeForcedTransfer()` must be overridden
 * in the inheriting contract to implement the desired access control.
 * The validation function `_validateForcedTransfer()` should be overridden
 * to enforce that the source address is frozen.
 */
abstract contract ERC7984EnforcementModule is ERC7984 {
    /* ============ Events ============ */
    event ForcedTransfer(
        address indexed enforcer,
        address indexed from,
        address indexed to,
        euint64 encryptedAmount
    );

    /* ============ Errors ============ */
    error ERC7984EnforcementModule_TransferBlocked(address from, address to, string reason);

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

    /* ============ Public Functions ============ */
    /**
     * @dev Forces a transfer from one address to another using encrypted amount with input proof.
     * Bypasses freeze checks but respects contract deactivation.
     * @param from Source address
     * @param to Destination address
     * @param encryptedAmount Encrypted amount to transfer
     * @param inputProof Zero-knowledge proof for the encrypted input
     * @return transferred The encrypted amount actually transferred
     */
    function forcedTransfer(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual onlyForcedTransferAuthorized returns (euint64 transferred) {
        _validateForcedTransfer(from, to);
        transferred = _transfer(from, to, FHE.fromExternal(encryptedAmount, inputProof));
        emit ForcedTransfer(msg.sender, from, to, transferred);
    }

    /**
     * @dev Forces a transfer from one address to another using an already-encrypted amount.
     * Bypasses freeze checks but respects contract deactivation.
     * @param from Source address
     * @param to Destination address
     * @param amount Encrypted amount to transfer (caller must have ACL access)
     * @return transferred The encrypted amount actually transferred
     */
    function forcedTransfer(
        address from,
        address to,
        euint64 amount
    ) public virtual onlyForcedTransferAuthorized returns (euint64 transferred) {
        _validateForcedTransfer(from, to);
        require(FHE.isAllowed(amount, msg.sender), "ERC7984EnforcementModule: Unauthorized use of encrypted amount");
        transferred = _transfer(from, to, amount);
        emit ForcedTransfer(msg.sender, from, to, transferred);
    }

    /* ============ Internal Functions ============ */
    /**
     * @dev Validates the forced transfer operation. Override to add custom validation logic.
     * @param from Source address
     * @param to Destination address
     */
    function _validateForcedTransfer(address from, address to) internal virtual {
        // Default: no additional validation
        // Override to add deactivation checks
    }

    /* ============ Access Control ============ */
    /**
     * @dev Authorization function for forced transfer operations.
     * Must be overridden to implement access control.
     */
    function _authorizeForcedTransfer() internal virtual;
}
