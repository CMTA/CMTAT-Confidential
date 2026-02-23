// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984TotalSupplyViewModule
 * @dev Module that provides controlled visibility of the encrypted total supply.
 *
 * Two mechanisms are provided:
 *
 * 1. **Total supply observers** (authorized addresses):
 *    Addresses registered via `addTotalSupplyObserver` automatically receive
 *    ACL access to the current total supply handle after every mint or burn,
 *    keeping their view current without manual intervention.
 *    Since every mint/burn produces a new `euint64` handle, ACL must be
 *    re-granted after each update — this module handles that automatically.
 *
 * 2. **Public disclosure** (`publishTotalSupply`):
 *    Marks the current total supply handle as publicly decryptable via
 *    `FHE.makePubliclyDecryptable()`. Any off-chain party can then request
 *    decryption through the Zama Relayer SDK without ACL access.
 *    Warning: This action is irrevocable for the current handle.
 *    After the next mint or burn the new handle will not be publicly
 *    decryptable — call this function again if needed.
 *
 * The authorization function `_authorizeTotalSupplyObserverManagement()` must be
 * overridden in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984TotalSupplyViewModule is ERC7984 {
    /* ============ Constants ============ */
    bytes32 public constant SUPPLY_OBSERVER_ROLE = keccak256("SUPPLY_OBSERVER_ROLE");

    /* ============ State Variables ============ */
    address[] private _supplyObservers;

    /// @dev 1-based index into _supplyObservers. 0 means not registered.
    mapping(address => uint256) private _supplyObserverIndex;

    /* ============ Events ============ */
    event TotalSupplyObserverAdded(address indexed observer, address indexed addedBy);
    event TotalSupplyObserverRemoved(address indexed observer, address indexed removedBy);
    event TotalSupplyPublished(address indexed publishedBy);

    /* ============ Errors ============ */
    error ERC7984TotalSupplyViewModule_AlreadyObserver(address observer);
    error ERC7984TotalSupplyViewModule_NotObserver(address observer);

    /* ============ Modifier ============ */
    modifier onlySupplyObserverManager() {
        _authorizeTotalSupplyObserverManagement();
        _;
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Registers an observer that will automatically receive ACL access to
     * the total supply handle after every mint or burn. If the total supply
     * handle is already initialized, ACL access is granted immediately.
     * @param observer The address to grant total supply read access to
     */
    function addTotalSupplyObserver(address observer) public virtual onlySupplyObserverManager {
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
    function removeTotalSupplyObserver(address observer) public virtual onlySupplyObserverManager {
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
     * @dev Marks the current total supply handle as publicly decryptable.
     * Any off-chain party can then request decryption via the Zama Relayer SDK
     * without ACL access. This action is irrevocable for the current handle.
     * After the next mint or burn the new handle will not be publicly decryptable
     * — call this function again if needed.
     */
    function publishTotalSupply() public virtual onlySupplyObserverManager {
        FHE.makePubliclyDecryptable(confidentialTotalSupply());
        emit TotalSupplyPublished(msg.sender);
    }

    /**
     * @dev Returns the list of registered total supply observers.
     */
    function totalSupplyObservers() public view virtual returns (address[] memory) {
        return _supplyObservers;
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev Overrides `_update` to re-grant ACL access to all registered total
     * supply observers after every mint or burn. The total supply handle changes
     * only on mint (from == address(0)) and burn (to == address(0)).
     */
    function _update(
        address from,
        address to,
        euint64 amount
    ) internal virtual override returns (euint64 transferred) {
        transferred = super._update(from, to, amount);

        if (from == address(0) || to == address(0)) {
            euint64 ts = confidentialTotalSupply();
            uint256 len = _supplyObservers.length;
            for (uint256 i = 0; i < len; i++) {
                FHE.allow(ts, _supplyObservers[i]);
            }
        }
    }

    /* ============ Access Control ============ */

    /**
     * @dev Authorization function for total supply observer management and
     * public disclosure. Must be overridden to implement access control.
     */
    function _authorizeTotalSupplyObserverManagement() internal virtual;
}
