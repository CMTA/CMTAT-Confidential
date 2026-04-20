// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984ObserverAccess} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/extensions/ERC7984ObserverAccess.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984BalanceViewModule
 * @dev Module that implements a dual-observer pattern on ERC7984 tokens:
 *
 * 1. **Holder observer** (inherited from `ERC7984ObserverAccess`):
 *    Each account holder assigns their own observer via `setObserver`.
 *    The existing observer can abdicate by calling `setObserver(account, address(0))`.
 *
 * 2. **Role observer** (added by this module):
 *    An authorized role (gated by `_authorizeObserverManagement`) assigns an observer
 *    to any account for regulatory purposes via `setRoleObserver` / `removeRoleObserver`.
 *
 * Both observers independently receive ACL access to the account's encrypted balance
 * handle and the transferred amount on every balance update.
 *
 * Neither role can touch the other's slot. The two observer slots are fully independent.
 *
 * The authorization function `_authorizeObserverManagement()` must be overridden
 * in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984BalanceViewModule is ERC7984ObserverAccess {
    /* ============ State Variables ============ */
    bytes32 public constant OBSERVER_ROLE = keccak256("OBSERVER_ROLE");

    mapping(address account => address observer) private _roleObservers;

    /* ============ Events ============ */
    event RoleObserverSet(
        address indexed account,
        address indexed oldObserver,
        address indexed newObserver,
        address setBy
    );

    /* ============ Errors ============ */
    error ERC7984BalanceViewModule_SameRoleObserver(address account, address observer);
    error ERC7984BalanceViewModule_NoRoleObserver(address account);
    error ERC7984BalanceViewModule_ZeroAccount();
    error ERC7984BalanceViewModule_ZeroObserver();

    /* ============ Modifier ============ */
    /**
     * @dev Modifier to restrict access to role observer management functions.
     * Calls the virtual `_authorizeObserverManagement()` function for access control.
     */
    modifier onlyObserverManager() {
        _authorizeObserverManagement();
        _;
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Sets a role observer for a given account. The observer will be
     * granted ACL access to the account's encrypted balance, allowing
     * off-chain decryption.
     *
     * If the account already has a balance (i.e., the balance handle is
     * initialized), ACL access is granted immediately. For future balance
     * changes, `_update` re-grants access automatically.
     *
     * To remove a role observer use `removeRoleObserver` — passing `address(0)`
     * here is rejected to avoid ambiguity between the two operations.
     *
     * @param account The account whose balance the observer can view
     * @param newObserver The address that will have ACL access to the balance
     */
    function setRoleObserver(
        address account,
        address newObserver
    ) public virtual onlyObserverManager {
        if (account == address(0)) {
            revert ERC7984BalanceViewModule_ZeroAccount();
        }
        if (newObserver == address(0)) {
            revert ERC7984BalanceViewModule_ZeroObserver();
        }
        address oldObserver = _roleObservers[account];
        if (oldObserver == newObserver) {
            revert ERC7984BalanceViewModule_SameRoleObserver(account, newObserver);
        }

        _roleObservers[account] = newObserver;

        euint64 balanceHandle = confidentialBalanceOf(account);
        if (FHE.isInitialized(balanceHandle)) {
            FHE.allow(balanceHandle, newObserver);
        }

        emit RoleObserverSet(account, oldObserver, newObserver, msg.sender);
    }

    /**
     * @dev Removes the role observer for a given account.
     * Note: This does not revoke existing ACL access on the current handle
     * (FHE ACL does not support revocation), but the observer will not
     * receive access to future balance handles after updates.
     * @param account The account to remove the role observer from
     */
    function removeRoleObserver(address account) public virtual onlyObserverManager {
        if (account == address(0)) {
            revert ERC7984BalanceViewModule_ZeroAccount();
        }
        address oldObserver = _roleObservers[account];
        if (oldObserver == address(0)) {
            revert ERC7984BalanceViewModule_NoRoleObserver(account);
        }

        _roleObservers[account] = address(0);

        emit RoleObserverSet(account, oldObserver, address(0), msg.sender);
    }

    /**
     * @dev Returns the role observer for a given account.
     * @param account The account to query
     * @return The role observer address, or address(0) if none is set
     */
    function roleObserver(address account) public view virtual returns (address) {
        return _roleObservers[account];
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Overrides `_update` to re-grant ACL access to role observers after
     * each balance change, in addition to the holder observers handled by
     * `ERC7984ObserverAccess`. Since FHE creates new ciphertext handles on every
     * arithmetic operation, observers lose access unless re-granted.
     *
     * **Observer ACL scope — intentional design:**
     * Both the holder observer and the role observer receive ACL access to two
     * handles per `_update` call:
     *   1. The account's new **balance** handle (`confidentialBalanceOf(account)`)
     *   2. The **transferred amount** handle (`transferred`)
     *
     * Granting access to the transferred amount is deliberate: for regulatory
     * purposes a compliance observer needs to be able to reconstruct individual
     * transaction amounts, not just the resulting balance. An observer set via
     * `setRoleObserver` should therefore be considered to have transfer-level
     * granularity, not just balance-snapshot visibility.
     *
     * Note: ACL grants are permanent (FHE ACL cannot be revoked). Removing an
     * observer stops future grants but does not revoke access to already-granted handles.
     */
    function _update(
        address from,
        address to,
        euint64 amount
    ) internal virtual override returns (euint64 transferred) {
        // Handles holder observer ACL grants via ERC7984ObserverAccess
        transferred = super._update(from, to, amount);

        address fromRoleObs = address(0);
        address toRoleObs = address(0);
        if (from != address(0)) {
            fromRoleObs = _roleObservers[from];
        }
        if (to != address(0)) {
            toRoleObs = _roleObservers[to];
        }

        if (fromRoleObs != address(0)) {
            FHE.allow(confidentialBalanceOf(from), fromRoleObs);
            FHE.allow(transferred, fromRoleObs);
        }
        if (toRoleObs != address(0)) {
            FHE.allow(confidentialBalanceOf(to), toRoleObs);
            if (toRoleObs != fromRoleObs) {
                FHE.allow(transferred, toRoleObs);
            }
        }
    }

    /* ============ Access Control ============ */

    /**
     * @dev Authorization function for role observer management operations.
     * Must be overridden to implement access control.
     */
    function _authorizeObserverManagement() internal virtual;
}
