// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC7984TotalSupplyViewModule {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a new address is registered as a total supply observer.
     * @param observer The address added to the observer list.
     * @param addedBy The address that called `addTotalSupplyObserver`.
     */
    event TotalSupplyObserverAdded(
        address indexed observer,
        address indexed addedBy
    );

    /**
     * @notice Emitted when an address is removed from the total supply observer list.
     * @param observer The address removed from the observer list.
     * @param removedBy The address that called `removeTotalSupplyObserver`.
     */
    event TotalSupplyObserverRemoved(
        address indexed observer,
        address indexed removedBy
    );

    /**
     * @notice Emitted when the maximum number of supply observers is updated.
     * @param oldMax The previous cap.
     * @param newMax The new cap.
     * @param updatedBy The address that called `setMaxSupplyObservers`.
     */
    event MaxSupplyObserversUpdated(
        uint256 oldMax,
        uint256 newMax,
        address updatedBy
    );

    /* ============ Errors ============ */

    /**
     * @notice Reverted when `addTotalSupplyObserver` is called with an address
     * already in the observer list.
     */
    error ERC7984TotalSupplyViewModule_AlreadyObserver(address observer);

    /**
     * @notice Reverted when `removeTotalSupplyObserver` is called with an address
     * not in the observer list.
     */
    error ERC7984TotalSupplyViewModule_NotObserver(address observer);

    /** @notice Reverted when `addTotalSupplyObserver` is called with address(0). */
    error ERC7984TotalSupplyViewModule_ZeroAddressObserver();

    /**
     * @notice Reverted when `addTotalSupplyObserver` is called and the observer
     * list has already reached `maxSupplyObservers`.
     */
    error ERC7984TotalSupplyViewModule_ObserverCapReached();

    /**
     * @notice Reverted when `setMaxSupplyObservers` is called with a value below
     * the current number of registered observers.
     */
    error ERC7984TotalSupplyViewModule_MaxBelowCurrentCount(
        uint256 newMax,
        uint256 currentCount
    );

    /* ============ Functions ============ */

    /** @notice Returns the current maximum number of supply observers allowed. */
    function maxSupplyObservers() external view returns (uint256);

    /**
     * @notice Sets the maximum number of supply observers. Cannot be set below
     * the current observer count.
     * @param newMax New maximum value.
     */
    function setMaxSupplyObservers(uint256 newMax) external;

    /**
     * @notice Registers `observer` to automatically receive ACL access to the
     * encrypted total supply handle after every mint or burn. If the total
     * supply handle is already initialized, ACL access is granted immediately.
     * @param observer The address to grant total supply read access to.
     */
    function addTotalSupplyObserver(address observer) external;

    /**
     * @notice Removes `observer` from the total supply observer list. The observer
     * will no longer receive ACL access on future total supply handles. Existing
     * ACL grants on past handles are irrevocable.
     * @param observer The address to remove.
     */
    function removeTotalSupplyObserver(address observer) external;

    /** @notice Returns the list of registered total supply observers. */
    function totalSupplyObservers() external view returns (address[] memory);
}
