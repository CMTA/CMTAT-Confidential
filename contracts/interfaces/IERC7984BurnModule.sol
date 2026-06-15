// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";

interface IERC7984BurnModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when tokens are burned.
     * @param burner The address that called `burn`.
     * @param from The address whose tokens were burned.
     * @param encryptedAmount The encrypted amount handle produced by the burn.
     */
    event Burn(
        address indexed burner,
        address indexed from,
        euint64 encryptedAmount
    );

    /* ============ Errors ============ */

    /**
     * @notice Reverted when the caller does not have ACL access to the supplied
     * `euint64` handle (euint64 overload only).
     */
    error ERC7984BurnModule_UnauthorizedHandle();

    /* ============ Functions ============ */

    /**
     * @notice Burns tokens from `from` using an encrypted amount submitted with a ZKPoK.
     * @param from Address to burn from.
     * @param encryptedAmount Encrypted amount ciphertext.
     * @param inputProof Zero-knowledge proof for the encrypted input.
     * @return transferred The encrypted handle of the amount actually burned.
     */
    function burn(
        address from,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint64 transferred);

    /**
     * @notice Burns tokens from `from` using an already-encrypted handle.
     * @dev The caller must hold ACL access to `amount`.
     * @param from Address to burn from.
     * @param amount Encrypted amount handle (caller must have ACL access).
     * @return transferred The encrypted handle of the amount actually burned.
     */
    function burn(
        address from,
        euint64 amount
    ) external returns (euint64 transferred);
}
