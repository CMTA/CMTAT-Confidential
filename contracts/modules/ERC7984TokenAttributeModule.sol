// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../lib/openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {IERC7984TokenAttributeModule} from "../interfaces/IERC7984TokenAttributeModule.sol";

/**
 * @title ERC7984TokenAttributeModule
 * @notice Allows the token name and symbol to be updated post-deployment (ERC-3643 alignment).
 *
 * @dev ERC7984 stores name and symbol as private fields set at construction.
 * This module shadows them with its own storage and overrides the `name()` and
 * `symbol()` view functions, enabling permissioned post-deployment updates.
 *
 * Call `_initTokenAttributes(name_, symbol_)` in the inheriting constructor
 * immediately after the `ERC7984(name_, symbol_, ...)` super call so that
 * `name()` and `symbol()` return the correct values from deployment.
 *
 * Access control: override `_authorizeTokenAttributeManagement()` in the
 * concrete contract to enforce the desired role or permission check.
 */
abstract contract ERC7984TokenAttributeModule is ERC7984, IERC7984TokenAttributeModule {
    /* ============ State Variables ============ */

    bytes32 public constant TOKEN_ATTRIBUTE_ROLE = keccak256("TOKEN_ATTRIBUTE_ROLE");

    string private _name;
    string private _symbol;

    /* ============ Modifier ============ */

    modifier onlyTokenAttributeManager() {
        _authorizeTokenAttributeManagement();
        _;
    }

    /* ============ Internal Helpers ============ */

    /**
     * @dev Seeds module storage with the constructor-supplied name and symbol.
     * Must be called from the inheriting constructor with the same values passed
     * to `ERC7984(name_, symbol_, contractUri_)`.
     */
    function _initTokenAttributes(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /* ============ View Functions ============ */

    /// @inheritdoc ERC7984
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @inheritdoc ERC7984
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /* ============ State-Changing Functions ============ */

    /// @inheritdoc IERC7984TokenAttributeModule
    function setName(string calldata name_) public virtual override onlyTokenAttributeManager {
        _name = name_;
        emit Name(name_, name_);
    }

    /// @inheritdoc IERC7984TokenAttributeModule
    function setSymbol(string calldata symbol_) public virtual override onlyTokenAttributeManager {
        _symbol = symbol_;
        emit Symbol(symbol_, symbol_);
    }

    /* ============ Access Control ============ */

    function _authorizeTokenAttributeManagement() internal virtual;
}
