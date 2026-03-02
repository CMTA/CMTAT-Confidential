// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ==== CMTAT Modules === */
import {CMTATBaseGeneric} from "../CMTAT/contracts/modules/0_CMTATBaseGeneric.sol";
import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";

/* ==== OpenZeppelin === */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* ==== OpenZeppelin Confidential Contracts === */
import {ERC7984} from "../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

/* ==== FHE Modules === */
import {ERC7984MintModule} from "./modules/ERC7984MintModule.sol";
import {ERC7984BurnModule} from "./modules/ERC7984BurnModule.sol";
import {ERC7984EnforcementModule} from "./modules/ERC7984EnforcementModule.sol";
import {ERC7984BalanceViewModule} from "./modules/ERC7984BalanceViewModule.sol";
import {ERC7984PublishTotalSupplyModule} from "./modules/ERC7984PublishTotalSupplyModule.sol";
import {CMTATFHEVersionModule} from "./modules/CMTATFHEVersionModule.sol";
import {VersionModule} from "../CMTAT/contracts/modules/wrapper/core/VersionModule.sol";

/**
 * @title CMTATFHEBase
 * @dev Abstract base contract shared by all CMTAT FHE deployment variants.
 *
 * Contains all shared logic: constructor, role authorization hooks, transfer
 * validation, confidential transfer overrides, and ERC-165 support.
 * Not intended for direct deployment — use CMTATFHE or CMTATFHELite instead.
 *
 * Inheritance chain:
 *   CMTATFHEBase
 *   ├── ERC7984                          (encrypted balances, transfers, operators)
 *   ├── CMTATBaseGeneric                 (pause, freeze, access control, documents)
 *   ├── ZamaEthereumConfig               (Zama coprocessor addresses)
 *   ├── ERC7984MintModule                (mint with hook)
 *   ├── ERC7984BurnModule                (burn with hook)
 *   ├── ERC7984EnforcementModule         (forcedTransfer, forcedBurn with hooks)
 *   ├── ERC7984BalanceViewModule         (dual-observer: holder slot + role slot)
 *   └── ERC7984PublishTotalSupplyModule  (publishTotalSupply — SUPPLY_PUBLISHER_ROLE)
 */
abstract contract CMTATFHEBase is
    ERC7984,
    CMTATBaseGeneric,
    ZamaEthereumConfig,
    ERC7984MintModule,
    ERC7984BurnModule,
    ERC7984EnforcementModule,
    ERC7984BalanceViewModule,
    ERC7984PublishTotalSupplyModule,
    CMTATFHEVersionModule
{
    /* ============ Errors ============ */
    /// @dev Since the amount is encrypted, we use a string reason instead of amount
    error CMTAT_InvalidTransfer(address from, address to, string reason);
    error CMTAT_AddressZeroNotAllowed();

    /* ============ Constructor ============ */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) ERC7984(name_, symbol_, contractURI_) {
        initialize(admin, extraInformationAttributes_);
    }

    function initialize(
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) internal initializer {
        __CMTAT_init(admin, extraInformationAttributes_);
    }

    /* ============ Module Authorization Overrides ============ */

    function _authorizeMint() internal virtual override onlyRole(MINTER_ROLE) {}

    function _authorizeBurn() internal virtual override onlyRole(BURNER_ROLE) {}

    function _authorizeForcedTransfer() internal virtual override onlyRole(FORCED_OPS_ROLE) {}

    function _authorizeForcedBurn() internal virtual override onlyRole(FORCED_OPS_ROLE) {}

    function _authorizePause() internal virtual override onlyRole(PAUSER_ROLE) {}

    function _authorizeDeactivate() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function _authorizeFreeze() internal virtual override onlyRole(ENFORCER_ROLE) {}

    function _authorizeObserverManagement() internal virtual override onlyRole(OBSERVER_ROLE) {}

    function _authorizePublishTotalSupply() internal virtual override onlyRole(SUPPLY_PUBLISHER_ROLE) {}

    /* ============ _update Override ============ */
    /**
     * @dev Explicit override resolving the diamond between ERC7984 and ERC7984BalanceViewModule.
     * Delegates entirely to the module chain (holder + role observer ACL grants).
     *
     * ⚠ **GAS WARNING — deep `_update` call chain**
     * A single transfer triggers up to five `_update` overrides in series:
     *   CMTATFHEBase → ERC7984BalanceViewModule → ERC7984ObserverAccess → ERC7984
     * In CMTATFHE (full variant) the total supply view module further extends this
     * via its `_afterMint`/`_afterBurn` hooks, iterating over all registered supply
     * observers. Each FHE.allow() call adds gas. Keep observer lists small.
     */
    function _update(address from, address to, euint64 amount)
        internal virtual override(ERC7984, ERC7984BalanceViewModule)
        returns (euint64 transferred)
    {
        return super._update(from, to, amount);
    }

    /* ============ Module Validation Overrides ============ */

    function _validateMint(address to) internal virtual override {
        if (!_canMintBurnByModule(to)) {
            revert CMTAT_InvalidTransfer(address(0), to, "Mint blocked");
        }
    }

    function _validateBurn(address from) internal virtual override {
        if (!_canMintBurnByModule(from)) {
            revert CMTAT_InvalidTransfer(from, address(0), "Burn blocked");
        }
    }

    function _validateForcedTransfer(address from, address to) internal virtual override {
        if (to == address(0)) {
            revert CMTAT_AddressZeroNotAllowed();
        }
        if (!isFrozen(from)) {
            revert CMTAT_InvalidTransfer(from, to, "Address not frozen");
        }
    }

    function _validateForcedBurn(address from) internal virtual override {
        if (!isFrozen(from)) {
            revert CMTAT_InvalidTransfer(from, address(0), "Address not frozen");
        }
    }

    /* ============ Transfer Overrides ============ */

    /// @inheritdoc ERC7984
    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ERC7984
    function confidentialTransfer(address to, euint64 amount) public virtual override returns (euint64) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransfer(to, amount);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        if (!_canTransferGenericByModule(_msgSender(), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferFrom(from, to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override returns (euint64 transferred) {
        if (!_canTransferGenericByModule(_msgSender(), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferFrom(from, to, amount);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferAndCall(to, encryptedAmount, inputProof, data);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferAndCall(to, amount, data);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        if (!_canTransferGenericByModule(_msgSender(), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferFromAndCall(from, to, encryptedAmount, inputProof, data);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        if (!_canTransferGenericByModule(_msgSender(), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferFromAndCall(from, to, amount, data);
    }

    /* ============ ERC165 Support ============ */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC7984, AccessControlUpgradeable)
        returns (bool)
    {
        return ERC7984.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /* ============ Version Override ============ */

    function version()
        public
        view
        virtual
        override(VersionModule, CMTATFHEVersionModule)
        returns (string memory version_)
    {
        return CMTATFHEVersionModule.version();
    }
}
