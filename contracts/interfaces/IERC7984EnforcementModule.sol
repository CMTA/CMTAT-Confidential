// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

interface IERC7984EnforcementModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when tokens are forcibly transferred from a frozen address.
     * @param enforcer The address that called `forcedTransfer`.
     * @param from The frozen source address.
     * @param to The destination address.
     * @param encryptedAmount The encrypted amount handle of the transferred tokens.
     */
    event ForcedTransfer(
        address indexed enforcer,
        address indexed from,
        address indexed to,
        euint64 encryptedAmount
    );

    /**
     * @notice Emitted when tokens are forcibly burned from a frozen address.
     * @param enforcer The address that called `forcedBurn`.
     * @param from The frozen source address.
     * @param encryptedAmount The encrypted amount handle of the burned tokens.
     */
    event ForcedBurn(
        address indexed enforcer,
        address indexed from,
        euint64 encryptedAmount
    );

    /* ============ Errors ============ */

    /**
     * @notice Reverted when the caller does not have ACL access to the supplied
     * `euint64` handle (euint64 overloads only).
     */
    error ERC7984EnforcementModule_UnauthorizedHandle();

    /* ============ Functions ============ */

    /**
     * @notice Transfers tokens from a frozen address, bypassing the freeze
     * restriction that normally blocks `confidentialTransfer`.
     * @param from Source address (must be frozen).
     * @param to Destination address.
     * @param encryptedAmount Encrypted amount ciphertext.
     * @param inputProof Zero-knowledge proof for the encrypted input.
     * @return transferred The encrypted handle of the amount actually transferred.
     */
    function forcedTransfer(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 transferred);

    /**
     * @notice Transfers tokens from a frozen address using an already-encrypted handle.
     * @dev The caller must hold ACL access to `amount`.
     * @param from Source address (must be frozen).
     * @param to Destination address.
     * @param amount Encrypted amount handle (caller must have ACL access).
     * @return transferred The encrypted handle of the amount actually transferred.
     */
    function forcedTransfer(
        address from,
        address to,
        euint64 amount
    ) external returns (euint64 transferred);

    /**
     * @notice Burns tokens from a frozen address, bypassing the freeze restriction
     * that normally blocks regular burns from frozen addresses.
     * @param from Address to burn from (must be frozen).
     * @param encryptedAmount Encrypted amount ciphertext.
     * @param inputProof Zero-knowledge proof for the encrypted input.
     * @return burned The encrypted handle of the amount actually burned.
     */
    function forcedBurn(
        address from,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 burned);

    /**
     * @notice Burns tokens from a frozen address using an already-encrypted handle.
     * @dev The caller must hold ACL access to `amount`.
     * @param from Address to burn from (must be frozen).
     * @param amount Encrypted amount handle (caller must have ACL access).
     * @return burned The encrypted handle of the amount actually burned.
     */
    function forcedBurn(
        address from,
        euint64 amount
    ) external returns (euint64 burned);
}
