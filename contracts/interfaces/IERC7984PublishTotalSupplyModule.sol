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
     *
     * @dev **Cross-publication disclosure warning (audit finding L-01).**
     * Each individual disclosure only reveals the *aggregate* total supply, never
     * per-account balances or per-transfer amounts. However, publishing the total
     * supply more than once opens a *delta-inference channel*: an observer who reads
     * two published values `V1` (before) and `V2` (after) a series of mints/burns can
     * compute the net change `|V2 - V1|`. If exactly one supply-changing operation
     * occurs between two publications, that operation's amount is fully revealed —
     * defeating the confidentiality of that single mint or burn.
     *
     * This channel is inherent to disclosing an aggregate that changes by discrete
     * confidential amounts; it cannot be closed in code (a holder of
     * `SUPPLY_PUBLISHER_ROLE` can always disclose). Treat each publication as a
     * deliberate, governed disclosure:
     * - aggregate many supply-changing operations between publications (never publish
     *   with a single mint/burn in between), or enforce a minimum time / operation
     *   window between calls;
     * - restrict `SUPPLY_PUBLISHER_ROLE` to a governance process (e.g. a multisig or
     *   timelock), not a high-frequency automated caller.
     */
    function publishTotalSupply() external;
}
