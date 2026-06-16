// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC3643ERC20Base} from "../../lib/CMTAT/contracts/interfaces/tokenization/IERC3643Partial.sol";

/**
 * @title IERC7984TokenAttributeModule
 * @notice Interface for post-deployment name and symbol management (ERC-3643 alignment).
 * @dev Mirrors CMTAT's ERC20BaseModule events and setters. The `amount` parameter is
 * irrelevant here — this module only manages metadata, not encrypted amounts.
 */
interface IERC7984TokenAttributeModule is IERC3643ERC20Base {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the token name is updated.
     * @param newNameIndexed The new name (indexed for log filtering).
     * @param newName The new name (unindexed, full string value).
     */
    event Name(string indexed newNameIndexed, string newName);

    /**
     * @notice Emitted when the token symbol is updated.
     * @param newSymbolIndexed The new symbol (indexed for log filtering).
     * @param newSymbol The new symbol (unindexed, full string value).
     */
    event Symbol(string indexed newSymbolIndexed, string newSymbol);
}
