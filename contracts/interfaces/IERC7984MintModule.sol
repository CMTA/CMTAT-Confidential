// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

interface IERC7984MintModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when tokens are minted.
     * @param minter The address that called `mint`.
     * @param to The recipient of the minted tokens.
     * @param encryptedAmount The encrypted amount handle produced by the mint.
     */
    event Mint(
        address indexed minter,
        address indexed to,
        euint64 encryptedAmount
    );

    /* ============ Errors ============ */

    /**
     * @notice Reverted when the caller does not have ACL access to the supplied
     * `euint64` handle (euint64 overload only).
     */
    error ERC7984MintModule_UnauthorizedHandle();

    /* ============ Functions ============ */

    /**
     * @notice Mints tokens to `to` using an encrypted amount submitted with a ZKPoK.
     * @param to Recipient address.
     * @param encryptedAmount Encrypted amount ciphertext.
     * @param inputProof Zero-knowledge proof for the encrypted input.
     * @return transferred The encrypted handle of the amount actually minted.
     */
    function mint(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 transferred);

    /**
     * @notice Mints tokens to `to` using an already-encrypted handle.
     * @dev The caller must hold ACL access to `amount`.
     * @param to Recipient address.
     * @param amount Encrypted amount handle (caller must have ACL access).
     * @return transferred The encrypted handle of the amount actually minted.
     */
    function mint(
        address to,
        euint64 amount
    ) external returns (euint64 transferred);
}
