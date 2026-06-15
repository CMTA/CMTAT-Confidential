// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC7984PublishTotalSupplyModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the current total supply handle is marked publicly
     * decryptable via `FHE.makePubliclyDecryptable()`.
     * @param publishedBy The address that called `publishTotalSupply`.
     */
    event TotalSupplyPublished(address indexed publishedBy);

    /* ============ Errors ============ */

    /**
     * @notice Reverted when `publishTotalSupply` is called before any mint or burn
     * has occurred (total supply handle not yet initialized).
     */
    error ERC7984PublishTotalSupplyModule_TotalSupplyNotInitialized();

    /* ============ Functions ============ */

    /**
     * @notice Marks the current encrypted total supply handle as publicly
     * decryptable. Any off-chain party can then request decryption via the
     * Zama Relayer SDK without ACL access. This action is irrevocable for the
     * current handle — after the next mint or burn the new handle will not be
     * publicly decryptable and this function must be called again if needed.
     */
    function publishTotalSupply() external;
}
