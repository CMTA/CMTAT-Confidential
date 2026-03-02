// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ERC7984} from "../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";

import {CMTATFHEBase} from "./CMTATFHEBase.sol";
import {ERC7984TotalSupplyViewModule} from "./modules/ERC7984TotalSupplyViewModule.sol";

/**
 * @title CMTATFHE
 * @dev Full deployment variant of CMTAT FHE.
 *
 * Extends CMTATFHEBase with ERC7984TotalSupplyViewModule, adding:
 *   - addTotalSupplyObserver / removeTotalSupplyObserver — authorized addresses
 *     automatically receive ACL access after every mint or burn (SUPPLY_OBSERVER_ROLE)
 *
 * publishTotalSupply (publicly decryptable total supply) is inherited from
 * CMTATFHEBase via ERC7984PublishTotalSupplyModule and is also available in
 * CMTATFHELite.
 *
 * The thin overrides below exist solely to resolve Solidity's diamond-inheritance
 * requirement: CMTATFHEBase overrides every ERC7984 transfer function and
 * supportsInterface, while ERC7984TotalSupplyViewModule inherits the originals
 * from ERC7984, creating a conflict the compiler requires to be explicitly resolved.
 * Each body delegates to super, which follows the MRO and runs CMTATFHEBase's
 * CMTAT checks (pause/freeze) before the ERC7984 implementation.
 *
 * For the lighter version without total supply observer registration, use CMTATFHELite.
 */
contract CMTATFHE is CMTATFHEBase, ERC7984TotalSupplyViewModule {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) CMTATFHEBase(name_, symbol_, contractURI_, admin, extraInformationAttributes_) {}

    /* ============ Authorization ============ */

    function _authorizeTotalSupplyObserverManagement() internal virtual override onlyRole(SUPPLY_OBSERVER_ROLE) {}

    /* ============ Total supply observer hooks ============ */

    /**
     * @dev After every mint, re-grant ACL access to all registered total supply
     * observers on the new total supply handle.
     */
    function _afterMint(address to, euint64 minted) internal virtual override {
        super._afterMint(to, minted);
        _updateTotalSupplyObserversACL();
    }

    /**
     * @dev After every burn, re-grant ACL access to all registered total supply
     * observers on the new total supply handle.
     */
    function _afterBurn(address from, euint64 burned) internal virtual override {
        super._afterBurn(from, burned);
        _updateTotalSupplyObserversACL();
    }

    /* ============ _update ============ */

    function _update(address from, address to, euint64 amount)
        internal virtual override(CMTATFHEBase, ERC7984)
        returns (euint64 transferred)
    {
        return super._update(from, to, amount);
    }

    /* ============ Diamond-resolution overrides (delegate to super) ============ */
    // CMTATFHEBase overrides each function; ERC7984TotalSupplyViewModule inherits
    // the originals from ERC7984. The override spec lists both defining bases.

    function confidentialTransfer(address to, externalEuint64 encryptedAmount, bytes calldata inputProof)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransfer(to, encryptedAmount, inputProof); }

    function confidentialTransfer(address to, euint64 amount)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransfer(to, amount); }

    function confidentialTransferFrom(address from, address to, externalEuint64 encryptedAmount, bytes calldata inputProof)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferFrom(from, to, encryptedAmount, inputProof); }

    function confidentialTransferFrom(address from, address to, euint64 amount)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferFrom(from, to, amount); }

    function confidentialTransferAndCall(address to, externalEuint64 encryptedAmount, bytes calldata inputProof, bytes calldata data)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferAndCall(to, encryptedAmount, inputProof, data); }

    function confidentialTransferAndCall(address to, euint64 amount, bytes calldata data)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferAndCall(to, amount, data); }

    function confidentialTransferFromAndCall(address from, address to, externalEuint64 encryptedAmount, bytes calldata inputProof, bytes calldata data)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferFromAndCall(from, to, encryptedAmount, inputProof, data); }

    function confidentialTransferFromAndCall(address from, address to, euint64 amount, bytes calldata data)
        public virtual override(CMTATFHEBase, ERC7984)
        returns (euint64)
    { return super.confidentialTransferFromAndCall(from, to, amount, data); }

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(CMTATFHEBase, ERC7984)
        returns (bool)
    { return super.supportsInterface(interfaceId); }
}
