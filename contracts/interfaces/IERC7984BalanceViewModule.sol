// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC7984BalanceViewModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a role observer is assigned or removed for an account.
     * @param account The account whose role observer changed.
     * @param oldObserver The previous role observer (address(0) if none was set).
     * @param newObserver The new role observer (address(0) if the observer was removed).
     * @param setBy The address that triggered the change.
     */
    event RoleObserverSet(
        address indexed account,
        address indexed oldObserver,
        address indexed newObserver,
        address setBy
    );

    /* ============ Errors ============ */

    /**
     * @notice Reverted when `setRoleObserver` is called with an observer already
     * set for that account.
     */
    error ERC7984BalanceViewModule_SameRoleObserver(
        address account,
        address observer
    );

    /**
     * @notice Reverted when `removeRoleObserver` is called for an account that
     * has no role observer set.
     */
    error ERC7984BalanceViewModule_NoRoleObserver(address account);

    /** @notice Reverted when `account` is address(0). */
    error ERC7984BalanceViewModule_ZeroAccount();

    /**
     * @notice Reverted when `newObserver` is address(0) in `setRoleObserver`.
     * Use `removeRoleObserver` to clear an observer.
     */
    error ERC7984BalanceViewModule_ZeroObserver();

    /* ============ Functions ============ */

    /**
     * @notice Assigns a role observer to `account`. The observer receives ACL
     * access to the account's encrypted balance handle immediately (if the
     * handle is initialized) and on every subsequent balance update.
     * @param account The account to observe.
     * @param newObserver The address to grant ACL access to.
     */
    function setRoleObserver(address account, address newObserver) external;

    /**
     * @notice Removes the role observer for `account`. The observer will no
     * longer receive ACL access on future balance handles. Existing ACL grants
     * on past handles are irrevocable.
     * @param account The account to remove the role observer from.
     */
    function removeRoleObserver(address account) external;

    /**
     * @notice Returns the role observer for `account`, or address(0) if none is set.
     * @param account The account to query.
     * @return The role observer address.
     */
    function roleObserver(address account) external view returns (address);
}
