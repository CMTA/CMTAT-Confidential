// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";

/**
 * @title ERC7984PublishTotalSupplyModule
 * @dev Module that allows authorized parties to make the encrypted total supply
 * publicly decryptable via `FHE.makePubliclyDecryptable()`.
 *
 * Once published, any off-chain party can request decryption through the Zama
 * Relayer SDK without requiring ACL access. The action is irrevocable for the
 * current ciphertext handle. After the next mint or burn a new handle is produced
 * and is not publicly decryptable — call `publishTotalSupply()` again if needed.
 *
 * This module is intentionally minimal. For automatic ACL re-grant to a registered
 * list of authorized addresses, combine with ERC7984TotalSupplyViewModule.
 *
 * The authorization function `_authorizePublishTotalSupply()` must be overridden
 * in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984PublishTotalSupplyModule is ERC7984 {
    /* ============ Constants ============ */
    bytes32 public constant SUPPLY_PUBLISHER_ROLE = keccak256("SUPPLY_PUBLISHER_ROLE");

    /* ============ Events ============ */
    event TotalSupplyPublished(address indexed publishedBy);

    /* ============ Errors ============ */
    error ERC7984PublishTotalSupplyModule_TotalSupplyNotInitialized();

    /* ============ Modifier ============ */
    modifier onlySupplyPublisher() {
        _authorizePublishTotalSupply();
        _;
    }

    /* ============ Public Functions ============ */

    /**
     * @dev Marks the current total supply handle as publicly decryptable.
     * Any off-chain party can then request decryption via the Zama Relayer SDK
     * without ACL access. This action is irrevocable for the current handle.
     * After the next mint or burn the new handle will not be publicly decryptable
     * — call this function again if needed.
     */
    function publishTotalSupply() public virtual onlySupplyPublisher {
        euint64 ts = confidentialTotalSupply();
        if (!FHE.isInitialized(ts)) {
            revert ERC7984PublishTotalSupplyModule_TotalSupplyNotInitialized();
        }
        FHE.makePubliclyDecryptable(ts);
        emit TotalSupplyPublished(msg.sender);
    }

    /* ============ Access Control ============ */

    /**
     * @dev Authorization function for public total supply disclosure.
     * Must be overridden to implement access control.
     */
    function _authorizePublishTotalSupply() internal virtual;
}
