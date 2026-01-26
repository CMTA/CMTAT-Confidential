// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984MintModule
 * @dev Module for minting confidential tokens (ERC7984).
 *
 * This module provides:
 * - Mint functions for encrypted amounts
 * - Flexible access control via virtual authorization function
 *
 * The authorization function `_authorizeMint()` must be overridden
 * in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984MintModule is ERC7984 {
    /* ============ State Variables ============ */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /* ============ Events ============ */
    event Mint(address indexed minter, address indexed to, euint64 encryptedAmount);

    /* ============ Errors ============ */
    error ERC7984MintModule_MintBlocked(address to, string reason);

    /* ============ Modifier ============ */
    /**
     * @dev Modifier to restrict access to mint functions.
     * Calls the virtual `_authorizeMint()` function for access control.
     */
    modifier onlyMinter() {
        _authorizeMint();
        _;
    }

    /* ============ Public Functions ============ */
    /**
     * @dev Mints tokens to an address using an encrypted amount with input proof.
     * @param to Recipient address
     * @param encryptedAmount Encrypted amount to mint
     * @param inputProof Zero-knowledge proof for the encrypted input
     * @return transferred The encrypted amount actually minted
     */
    function mint(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual onlyMinter returns (euint64 transferred) {
        _validateMint(to);
        transferred = _mint(to, FHE.fromExternal(encryptedAmount, inputProof));
        emit Mint(msg.sender, to, transferred);
    }

    /**
     * @dev Mints tokens to an address using an already-encrypted amount.
     * @param to Recipient address
     * @param amount Encrypted amount to mint (caller must have ACL access)
     * @return transferred The encrypted amount actually minted
     */
    function mint(
        address to,
        euint64 amount
    ) public virtual onlyMinter returns (euint64 transferred) {
        _validateMint(to);
        require(FHE.isAllowed(amount, msg.sender), "ERC7984MintModule: Unauthorized use of encrypted amount");
        transferred = _mint(to, amount);
        emit Mint(msg.sender, to, transferred);
    }

    /* ============ Internal Functions ============ */
    /**
     * @dev Validates the mint operation. Override to add custom validation logic.
     * @param to Recipient address
     */
    function _validateMint(address to) internal virtual {
        // Default: no additional validation
        // Override to add pause/freeze checks
    }

    /* ============ Access Control ============ */
    /**
     * @dev Authorization function for mint operations.
     * Must be overridden to implement access control.
     */
    function _authorizeMint() internal virtual;
}
