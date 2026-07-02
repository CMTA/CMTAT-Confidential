// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ERC7984} from "../../lib/openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {IERC7984PublishTotalSupplyModule} from "../interfaces/IERC7984PublishTotalSupplyModule.sol";

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
 * WARNING: Cross-publication delta-inference (audit finding L-01). A single disclosure
 * only reveals the aggregate supply, but publishing it repeatedly lets an observer
 * subtract consecutive values (`|V2 - V1|`) to recover the net minted/burned amount
 * between publications — fully revealing a mint/burn amount when only one occurs in
 * between. This cannot be prevented in code; treat publishing as a governed action
 * that aggregates many operations per disclosure. See {IERC7984PublishTotalSupplyModule-publishTotalSupply}.
 *
 * This module is intentionally minimal. For automatic ACL re-grant to a registered
 * list of authorized addresses, combine with ERC7984TotalSupplyViewModule.
 *
 * The authorization function `_authorizePublishTotalSupply()` must be overridden
 * in the inheriting contract to implement the desired access control.
 */
abstract contract ERC7984PublishTotalSupplyModule is ERC7984, IERC7984PublishTotalSupplyModule {
    /* ============ Constants ============ */
    /// @notice Role allowed to make the encrypted total supply publicly decryptable.
    bytes32 public constant SUPPLY_PUBLISHER_ROLE = keccak256(
        "SUPPLY_PUBLISHER_ROLE"
    );

    /* ============ Modifier ============ */
    modifier onlySupplyPublisher() {
        _authorizePublishTotalSupply();
        _;
    }

    /* ============ Public Functions ============ */

    /// @inheritdoc IERC7984PublishTotalSupplyModule
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
