// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../lib/openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {IERC7984TokenAttributeModule} from "../interfaces/IERC7984TokenAttributeModule.sol";
import {IERC3643ERC20Base} from "../../lib/CMTAT/contracts/interfaces/tokenization/IERC3643Partial.sol";

/**
 * @title ERC7984TokenAttributeModule
 * @notice Module for post-deployment update of the token name and symbol (ERC-3643 alignment).
 *
 * ERC7984 stores name and symbol as private fields set at construction.
 * This module shadows them with its own storage and overrides the `name()` and
 * `symbol()` view functions, enabling permissioned post-deployment updates.
 *
 * Call `_initTokenAttributes(name_, symbol_)` in the inheriting constructor
 * immediately after the `ERC7984(name_, symbol_, ...)` super call.
 *
 * Access control: override `_authorizeTokenAttributeManagement()`.
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

    /* ============ Initializer ============ */

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

    /// @inheritdoc IERC3643ERC20Base
    function setName(string calldata name_) public virtual override onlyTokenAttributeManager {
        _name = name_;
        emit Name(name_, name_);
    }

    /// @inheritdoc IERC3643ERC20Base
    function setSymbol(string calldata symbol_) public virtual override onlyTokenAttributeManager {
        _symbol = symbol_;
        emit Symbol(symbol_, symbol_);
    }

    /* ============ Access Control ============ */

    function _authorizeTokenAttributeManagement() internal virtual;
}
