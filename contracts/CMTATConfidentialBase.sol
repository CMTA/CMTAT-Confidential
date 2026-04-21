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
import {CMTATConfidentialVersionModule} from "./modules/CMTATConfidentialVersionModule.sol";
import {VersionModule} from "../CMTAT/contracts/modules/wrapper/core/VersionModule.sol";

/**
 * @title CMTATConfidentialBase
 * @dev Abstract base contract shared by all CMTAT Confidential deployment variants.
 *
 * Contains all shared logic: constructor, role authorization hooks, transfer
 * validation, confidential transfer overrides, and ERC-165 support.
 * Not intended for direct deployment — use CMTATConfidential or CMTATConfidentialLite instead.
 *
 * Inheritance chain:
 *   CMTATConfidentialBase
 *   ├── ERC7984                          (encrypted balances, transfers, operators)
 *   ├── CMTATBaseGeneric                 (pause, freeze, access control, documents)
 *   ├── ZamaEthereumConfig               (Zama coprocessor addresses)
 *   ├── ERC7984MintModule                (mint with hook)
 *   ├── ERC7984BurnModule                (burn with hook)
 *   ├── ERC7984EnforcementModule         (forcedTransfer, forcedBurn with hooks)
 *   ├── ERC7984BalanceViewModule         (dual-observer: holder slot + role slot)
 *   └── ERC7984PublishTotalSupplyModule  (publishTotalSupply — SUPPLY_PUBLISHER_ROLE)
 */
abstract contract CMTATConfidentialBase is
    ERC7984,
    CMTATBaseGeneric,
    ZamaEthereumConfig,
    ERC7984MintModule,
    ERC7984BurnModule,
    ERC7984EnforcementModule,
    ERC7984BalanceViewModule,
    ERC7984PublishTotalSupplyModule,
    CMTATConfidentialVersionModule
{
    uint8 private immutable _TOKEN_DECIMALS;

    /* ============ Errors ============ */
    /// @dev Since the amount is encrypted, we use a string reason instead of amount
    error CMTAT_InvalidTransfer(address from, address to, string reason);
    error CMTAT_AddressZeroNotAllowed();
    /// @dev Reverted when `decimals_` exceeds 18. ERC-7984 balances use `euint64`
    /// (max 18_446_744_073_709_551_615 raw units); above 18 decimals the type cannot
    /// represent even a single human-readable token.
    error CMTAT_DecimalsTooHigh(uint8 decimals);

    /* ============ Constructor ============ */
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @dev `ERC7984` stores balances and supply as `euint64` (max 18_446_744_073_709_551_615 raw units).
    /// The maximum human-readable supply equals `uint64 max / 10^decimals_`:
    ///   - 6 decimals  → ~18 trillion tokens  (recommended default)
    ///   - 8 decimals  → ~184 billion tokens
    ///   - 18 decimals → ~18 tokens
    /// Values above 18 are rejected because even 1 token (10^decimals raw units) would overflow `uint64`.
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractUri_,
        uint8 decimals_,
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) ERC7984(name_, symbol_, contractUri_) {
        require(decimals_ <= 18, CMTAT_DecimalsTooHigh(decimals_));
        _TOKEN_DECIMALS = decimals_;
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

    /// @inheritdoc ERC7984
    function decimals() public view virtual override returns (uint8) {
        return _TOKEN_DECIMALS;
    }

    /* ============ _afterBurn Diamond Resolution ============ */
    /**
     * @dev Explicit override resolving the diamond between ERC7984BurnModule and
     * ERC7984EnforcementModule, both of which declare a virtual `_afterBurn` hook.
     * Delegates to super so the full hook chain is preserved.
     * CMTATConfidential further overrides this to call _updateTotalSupplyObserversAcl.
     */
    function _afterBurn(address from, euint64 burned)
        internal virtual override(ERC7984BurnModule, ERC7984EnforcementModule)
    {
        super._afterBurn(from, burned);
    }

    /* ============ _update Override ============ */
    /**
     * @dev Explicit override resolving the diamond between ERC7984 and ERC7984BalanceViewModule.
     * Delegates entirely to the module chain (holder + role observer ACL grants).
     *
     * ⚠ **GAS WARNING — deep `_update` call chain**
     * A single transfer triggers up to five `_update` overrides in series:
     *   CMTATConfidentialBase → ERC7984BalanceViewModule → ERC7984ObserverAccess → ERC7984
     * In CMTATConfidential (full variant) the total supply view module further extends this
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

    /**
     * @inheritdoc ERC7984
     * @dev **Non-atomic refund warning.** The receiver's `onConfidentialTransferReceived`
     * callback fires while the receiver already holds the tokens (Step 1 credits the
     * receiver before Step 2 calls the hook). If the callback returns `false`, Step 3
     * attempts a best-effort reverse transfer — but this is NOT an EVM revert: it only
     * succeeds if the receiver still holds the tokens at that point. A malicious or
     * re-entrant receiver can drain its balance before returning `false`, causing the
     * refund to silently produce 0. This is a structural limitation of FHE arithmetic
     * (`FHESafeMath.tryDecrease` cannot revert on an encrypted condition) and an
     * intentional design choice in the upstream ERC-7984 library.
     * **Only call this function with trusted, audited receiver contracts.**
     */
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

    /**
     * @inheritdoc ERC7984
     * @dev **Non-atomic refund warning.** See the `externalEuint64` overload above for a
     * full description of the non-atomic refund risk. The same limitation applies here.
     * **Only call this function with trusted, audited receiver contracts.**
     */
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
        override(VersionModule, CMTATConfidentialVersionModule)
        returns (string memory version_)
    {
        return CMTATConfidentialVersionModule.version();
    }
}
