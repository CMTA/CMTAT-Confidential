// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984TotalSupplyViewModule
 * @dev Module that grants registered observers automatic ACL access to the
 * encrypted total supply handle after every mint or burn.
 *
 * Since every FHE arithmetic operation (mint/burn) produces a new `euint64`
 * handle for `_totalSupply`, any previously granted ACL becomes stale. This
 * module re-grants `FHE.allow()` on the new handle to every registered observer
 * inside `_update`, keeping their view current without manual intervention.
 *
 * For one-off public disclosure (anyone can decrypt), combine with
 * ERC7984PublishTotalSupplyModule — already included in CMTATConfidentialBase.
 *
 * The authorization function `_authorizeTotalSupplyObserverManagement()` must be
 * overridden in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984TotalSupplyViewModule is ERC7984 {
    /* ============ State Variables ============ */
    bytes32 public constant SUPPLY_OBSERVER_ROLE = keccak256(
        "SUPPLY_OBSERVER_ROLE"
    );

    /// @dev Default cap applied at deployment. Kept low to bound gas cost of
    /// _updateTotalSupplyObserversAcl (one FHE.allow() per observer per mint/burn).
    uint256 private constant _DEFAULT_MAX_SUPPLY_OBSERVERS = 10;

    /// @dev Admin-configurable cap on the number of registered supply observers.
    uint256 private _maxSupplyObservers = _DEFAULT_MAX_SUPPLY_OBSERVERS;

    address[] private _supplyObservers;

    /// @dev 1-based index into _supplyObservers. 0 means not registered.
    mapping(address => uint256) private _supplyObserverIndex;

    /* ============ Events ============ */
    event TotalSupplyObserverAdded(
        address indexed observer,
        address indexed addedBy
    );
    event TotalSupplyObserverRemoved(
        address indexed observer,
        address indexed removedBy
    );
    event MaxSupplyObserversUpdated(
        uint256 oldMax,
        uint256 newMax,
        address updatedBy
    );

    /* ============ Errors ============ */
    error ERC7984TotalSupplyViewModule_AlreadyObserver(address observer);
    error ERC7984TotalSupplyViewModule_NotObserver(address observer);
    error ERC7984TotalSupplyViewModule_ZeroAddressObserver();
    error ERC7984TotalSupplyViewModule_ObserverCapReached();
    error ERC7984TotalSupplyViewModule_MaxBelowCurrentCount(
        uint256 newMax,
        uint256 currentCount
    );

    /* ============ Modifier ============ */
    modifier onlySupplyObserverManager() {
        _authorizeTotalSupplyObserverManagement();
        _;
    }

    modifier onlyMaxObserversAdmin() {
        _authorizeSetMaxSupplyObservers();
        _;
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Returns the current maximum number of supply observers allowed.
     */
    function maxSupplyObservers() public view virtual returns (uint256) {
        return _maxSupplyObservers;
    }

    /**
     * @dev Sets the maximum number of supply observers. Cannot be set below
     * the current observer count. Gated by `_authorizeSetMaxSupplyObservers`.
     * @param newMax New maximum value
     */
    function setMaxSupplyObservers(
        uint256 newMax
    ) public virtual onlyMaxObserversAdmin {
        uint256 currentCount = _supplyObservers.length;
        if (newMax < currentCount) {
            revert ERC7984TotalSupplyViewModule_MaxBelowCurrentCount(
                newMax,
                currentCount
            );
        }
        uint256 oldMax = _maxSupplyObservers;
        _maxSupplyObservers = newMax;
        emit MaxSupplyObserversUpdated(oldMax, newMax, msg.sender);
    }

    /**
     * @dev Registers an observer that will automatically receive ACL access to
     * the total supply handle after every mint or burn. If the total supply
     * handle is already initialized, ACL access is granted immediately.
     * @param observer The address to grant total supply read access to
     */
    function addTotalSupplyObserver(
        address observer
    ) public virtual onlySupplyObserverManager {
        if (observer == address(0)) {
            revert ERC7984TotalSupplyViewModule_ZeroAddressObserver();
        }
        if (_supplyObservers.length >= _maxSupplyObservers) {
            revert ERC7984TotalSupplyViewModule_ObserverCapReached();
        }
        if (_supplyObserverIndex[observer] != 0) {
            revert ERC7984TotalSupplyViewModule_AlreadyObserver(observer);
        }
        _supplyObservers.push(observer);
        _supplyObserverIndex[observer] = _supplyObservers.length; // 1-based

        euint64 ts = confidentialTotalSupply();
        if (FHE.isInitialized(ts)) {
            FHE.allow(ts, observer);
        }

        emit TotalSupplyObserverAdded(observer, msg.sender);
    }

    /**
     * @dev Removes a registered total supply observer. The observer will no longer
     * receive ACL access on future total supply handles. Existing ACL grants on
     * previous handles cannot be revoked (FHE ACL is irrevocable).
     * @param observer The address to remove
     */
    function removeTotalSupplyObserver(
        address observer
    ) public virtual onlySupplyObserverManager {
        uint256 index = _supplyObserverIndex[observer];
        if (index == 0) {
            revert ERC7984TotalSupplyViewModule_NotObserver(observer);
        }

        // Swap with last element and pop (O(1) removal)
        uint256 lastIndex = _supplyObservers.length - 1;
        if (index - 1 != lastIndex) {
            address last = _supplyObservers[lastIndex];
            _supplyObservers[index - 1] = last;
            _supplyObserverIndex[last] = index;
        }
        _supplyObservers.pop();
        delete _supplyObserverIndex[observer];

        emit TotalSupplyObserverRemoved(observer, msg.sender);
    }

    /**
     * @dev Returns the list of registered total supply observers.
     */
    function totalSupplyObservers()
        public
        view
        virtual
        returns (address[] memory)
    {
        return _supplyObservers;
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Re-grants ACL access to all registered total supply observers on
     * the current total supply handle. Call this after any operation that
     * changes the total supply (mint or burn) to keep observer ACL current.
     *
     * This function is intentionally NOT called from `_update`. Instead, it is
     * invoked via the `_afterMint` / `_afterBurn` hooks defined in
     * `ERC7984MintModule` and `ERC7984BurnModule`, which are overridden in
     * `CMTATConfidential`. This avoids the zero-address guard that would otherwise be
     * required inside a generic `_update` override.
     *
     * ⚠ Gas: iterates over all registered observers. Keep the list small.
     */
    function _updateTotalSupplyObserversAcl() internal {
        euint64 ts = confidentialTotalSupply();
        uint256 len = _supplyObservers.length;
        for (uint256 i = 0; i < len; i++) {
            FHE.allow(ts, _supplyObservers[i]);
        }
    }

    /* ============ Access Control ============ */

    /**
     * @dev Authorization function for total supply observer management.
     * Must be overridden to implement access control.
     */
    function _authorizeTotalSupplyObserverManagement() internal virtual;

    /**
     * @dev Authorization function for updating the observer cap.
     * Must be overridden to implement access control (typically DEFAULT_ADMIN_ROLE).
     */
    function _authorizeSetMaxSupplyObservers() internal virtual;
}
