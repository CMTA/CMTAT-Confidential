// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ERC7984} from "../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";

import {CMTATConfidentialBase} from "./CMTATConfidentialBase.sol";
import {ERC7984TotalSupplyViewModule} from "./modules/ERC7984TotalSupplyViewModule.sol";

/**
 * @title CMTATConfidential
 * @dev Full deployment variant of CMTAT Confidential.
 *
 * Extends CMTATConfidentialBase with ERC7984TotalSupplyViewModule, adding:
 *   - addTotalSupplyObserver / removeTotalSupplyObserver — authorized addresses
 *     automatically receive ACL access after every mint or burn (SUPPLY_OBSERVER_ROLE)
 *
 * publishTotalSupply (publicly decryptable total supply) is inherited from
 * CMTATConfidentialBase via ERC7984PublishTotalSupplyModule and is also available in
 * CMTATConfidentialLite. Access is controlled by SUPPLY_PUBLISHER_ROLE.
 *
 * The thin overrides below exist solely to resolve Solidity's diamond-inheritance
 * requirement: CMTATConfidentialBase overrides every ERC7984 transfer function and
 * supportsInterface, while ERC7984TotalSupplyViewModule inherits the originals
 * from ERC7984, creating a conflict the compiler requires to be explicitly resolved.
 * Each body delegates to super, which follows the MRO and runs CMTATConfidentialBase's
 * CMTAT checks (pause/freeze) before the ERC7984 implementation.
 *
 * For the lighter version without total supply observer registration, use CMTATConfidentialLite.
 */
contract CMTATConfidential is
    CMTATConfidentialBase,
    ERC7984TotalSupplyViewModule
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractUri_,
        uint8 decimals_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    )
        CMTATConfidentialBase(
            name_,
            symbol_,
            contractUri_,
            decimals_,
            admin,
            extraInformationAttributes_
        )
    {}

    /* ============ Authorization ============ */

    function _authorizeTotalSupplyObserverManagement()
        internal
        virtual
        override
        onlyRole(SUPPLY_OBSERVER_ROLE)
    {}

    function _authorizeSetMaxSupplyObservers()
        internal
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /* ============ Total supply observer hooks ============ */

    /**
     * @dev After every mint, re-grant ACL access to all registered total supply
     * observers on the new total supply handle.
     */
    function _afterMint(address to, euint64 minted) internal virtual override {
        super._afterMint(to, minted);
        _updateTotalSupplyObserversAcl();
    }

    /**
     * @dev After every burn, re-grant ACL access to all registered total supply
     * observers on the new total supply handle.
     */
    function _afterBurn(
        address from,
        euint64 burned
    ) internal virtual override {
        super._afterBurn(from, burned);
        _updateTotalSupplyObserversAcl();
    }

    /* ============ _update ============ */

    function _update(
        address from,
        address to,
        euint64 amount
    )
        internal
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64 transferred)
    {
        return super._update(from, to, amount);
    }

    /* ============ Diamond-resolution overrides (delegate to super) ============ */
    // CMTATConfidentialBase overrides each function; ERC7984TotalSupplyViewModule inherits
    // the originals from ERC7984. The override spec lists both defining bases.

    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return super.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    function confidentialTransfer(
        address to,
        euint64 amount
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return super.confidentialTransfer(to, amount);
    }

    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return
            super.confidentialTransferFrom(
                from,
                to,
                encryptedAmount,
                inputProof
            );
    }

    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return super.confidentialTransferFrom(from, to, amount);
    }

    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return
            super.confidentialTransferAndCall(
                to,
                encryptedAmount,
                inputProof,
                data
            );
    }

    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return super.confidentialTransferAndCall(to, amount, data);
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return
            super.confidentialTransferFromAndCall(
                from,
                to,
                encryptedAmount,
                inputProof,
                data
            );
    }

    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    )
        public
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (euint64)
    {
        return super.confidentialTransferFromAndCall(from, to, amount, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function decimals()
        public
        view
        virtual
        override(CMTATConfidentialBase, ERC7984)
        returns (uint8)
    {
        return super.decimals();
    }
}
