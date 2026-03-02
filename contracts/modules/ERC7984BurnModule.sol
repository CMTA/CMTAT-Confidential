// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984BurnModule
 * @dev Module for burning confidential tokens (ERC7984).
 *
 * This module provides:
 * - Burn functions for encrypted amounts
 * - Flexible access control via virtual authorization function
 *
 * The authorization function `_authorizeBurn()` must be overridden
 * in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984BurnModule is ERC7984 {
    /* ============ State Variables ============ */
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /* ============ Events ============ */
    event Burn(address indexed burner, address indexed from, euint64 encryptedAmount);

    /* ============ Errors ============ */
    error ERC7984BurnModule_UnauthorizedHandle();

    /* ============ Modifier ============ */
    /**
     * @dev Modifier to restrict access to burn functions.
     * Calls the virtual `_authorizeBurn()` function for access control.
     */
    modifier onlyBurner() {
        _authorizeBurn();
        _;
    }

    /* ============ Public Functions ============ */
    /**
     * @dev Burns tokens from an address using an encrypted amount with input proof.
     * @param from Address to burn from
     * @param encryptedAmount Encrypted amount to burn
     * @param inputProof Zero-knowledge proof for the encrypted input
     * @return transferred The encrypted amount actually burned
     */
    function burn(
        address from,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual onlyBurner returns (euint64 transferred) {
        _validateBurn(from);
        transferred = _burn(from, FHE.fromExternal(encryptedAmount, inputProof));
        _afterBurn(from, transferred);
        emit Burn(msg.sender, from, transferred);
    }

    /**
     * @dev Burns tokens from an address using an already-encrypted amount.
     * @param from Address to burn from
     * @param amount Encrypted amount to burn (caller must have ACL access)
     * @return transferred The encrypted amount actually burned
     */
    function burn(
        address from,
        euint64 amount
    ) public virtual onlyBurner returns (euint64 transferred) {
        _validateBurn(from);
        if (!FHE.isAllowed(amount, msg.sender)) {
            revert ERC7984BurnModule_UnauthorizedHandle();
        }
        transferred = _burn(from, amount);
        _afterBurn(from, transferred);
        emit Burn(msg.sender, from, transferred);
    }

    /* ============ Internal Functions ============ */
    /**
     * @dev Validates the burn operation. Override to add custom validation logic.
     * @param from Address to burn from
     */
    function _validateBurn(address from) internal virtual {
        // Default: no additional validation
        // Override to add pause/freeze checks
    }

    /**
     * @dev Hook called after every successful burn, with the source address and
     * the resulting encrypted amount handle. Override to add post-burn logic
     * (e.g., updating total supply observer ACL).
     * @param from Source address
     * @param burned The encrypted amount actually burned
     */
    function _afterBurn(address from, euint64 burned) internal virtual {}

    /* ============ Access Control ============ */
    /**
     * @dev Authorization function for burn operations.
     * Must be overridden to implement access control.
     */
    function _authorizeBurn() internal virtual;
}
