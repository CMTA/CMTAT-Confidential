// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC3643ERC20Base} from "../../lib/CMTAT/contracts/interfaces/tokenization/IERC3643Partial.sol";

/**
 * @title IERC7984TokenAttributeModule
 * @notice Interface for post-deployment name and symbol management, aligned with ERC-3643.
 * @dev Mirrors CMTAT's `ERC20BaseModule` events and setters so that integrators
 * familiar with ERC-3643 tokens can use the same ABI. Extends `IERC3643ERC20Base`
 * for type compatibility.
 */
interface IERC7984TokenAttributeModule is IERC3643ERC20Base {
    /* ============ Events ============ */

    /**
     * @notice Emitted when the token name is updated.
     * @param newNameIndexed The new name (indexed for log filtering).
     * @param newName The new name (unindexed, full string for off-chain display).
     */
    event Name(string indexed newNameIndexed, string newName);

    /**
     * @notice Emitted when the token symbol is updated.
     * @param newSymbolIndexed The new symbol (indexed for log filtering).
     * @param newSymbol The new symbol (unindexed, full string for off-chain display).
     */
    event Symbol(string indexed newSymbolIndexed, string newSymbol);

    /* ============ Functions ============ */

    /**
     * @notice Updates the token name post-deployment.
     * @dev Emits {Name}. Caller must hold `TOKEN_ATTRIBUTE_ROLE`.
     * @param name The new token name.
     */
    function setName(string calldata name) external;

    /**
     * @notice Updates the token symbol post-deployment.
     * @dev Emits {Symbol}. Caller must hold `TOKEN_ATTRIBUTE_ROLE`.
     * @param symbol The new token symbol.
     */
    function setSymbol(string calldata symbol) external;
}
