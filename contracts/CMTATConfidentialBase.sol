// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ==== CMTAT Modules === */
import {CMTATBaseGeneric} from "../lib/CMTAT/contracts/modules/0_CMTATBaseGeneric.sol";
import {ICMTATConstructor} from "../lib/CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";
import {IERC7943FungibleTransferError} from "../lib/CMTAT/contracts/interfaces/tokenization/draft-IERC7943.sol";

/* ==== OpenZeppelin === */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* ==== OpenZeppelin Confidential Contracts === */
import {ERC7984} from "../lib/openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {externalEuint64, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

/* ==== FHE Modules === */
import {ERC7984MintModule} from "./modules/ERC7984MintModule.sol";
import {ERC7984BurnModule} from "./modules/ERC7984BurnModule.sol";
import {ERC7984EnforcementModule} from "./modules/ERC7984EnforcementModule.sol";
import {ERC7984BalanceViewModule} from "./modules/ERC7984BalanceViewModule.sol";
import {ERC7984PublishTotalSupplyModule} from "./modules/ERC7984PublishTotalSupplyModule.sol";
import {ERC7984TokenAttributeModule} from "./modules/ERC7984TokenAttributeModule.sol";
import {CMTATConfidentialVersionModule} from "./modules/CMTATConfidentialVersionModule.sol";
import {VersionModule} from "../lib/CMTAT/contracts/modules/wrapper/core/VersionModule.sol";

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
 *   ├── ERC7984PublishTotalSupplyModule  (publishTotalSupply — SUPPLY_PUBLISHER_ROLE)
 *   └── ERC7984TokenAttributeModule      (setName / setSymbol — TOKEN_ATTRIBUTE_ROLE)
 */
abstract contract CMTATConfidentialBase is
    ERC7984,
    CMTATBaseGeneric,
    IERC7943FungibleTransferError,
    ZamaEthereumConfig,
    ERC7984MintModule,
    ERC7984BurnModule,
    ERC7984EnforcementModule,
    ERC7984BalanceViewModule,
    ERC7984PublishTotalSupplyModule,
    ERC7984TokenAttributeModule,
    CMTATConfidentialVersionModule
{
    uint8 private immutable _TOKEN_DECIMALS;

    /* ============ Errors ============ */
    /**
     * @dev CMTAT defines `CMTAT_BurnEnforcement_AddressIsNotFrozen()` (no args, burn-only) in
     * CMTATBaseCore, which is outside our inheritance chain. We define our own with the address
     * parameter so callers can identify which account failed the frozen precondition, and we reuse
     * it for both forcedTransfer and forcedBurn.
     */
    error CMTAT_AddressNotFrozen(address from);
    // CMTAT_Enforcement_ZeroAddressNotAllowed() (no-arg) is already in scope via EnforcementModuleInternal.
    /**
     * @dev Reverted when `decimals_` exceeds 18. ERC-7984 balances use `euint64`
     * (max 18_446_744_073_709_551_615 raw units); above 18 decimals the type cannot
     * represent even a single human-readable token.
     */
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
    )
        ERC7984(name_, symbol_, contractUri_)
        ERC7984TokenAttributeModule(name_, symbol_)
    {
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

    function _authorizeForcedTransfer()
        internal
        virtual
        override
        onlyRole(FORCED_OPS_ROLE)
    {}

    function _authorizeForcedBurn()
        internal
        virtual
        override
        onlyRole(FORCED_OPS_ROLE)
    {}

    function _authorizePause()
        internal
        virtual
        override
        onlyRole(PAUSER_ROLE)
    {}

    function _authorizeDeactivate()
        internal
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function _authorizeFreeze()
        internal
        virtual
        override
        onlyRole(ENFORCER_ROLE)
    {}

    function _authorizeObserverManagement()
        internal
        virtual
        override
        onlyRole(OBSERVER_ROLE)
    {}

    function _authorizePublishTotalSupply()
        internal
        virtual
        override
        onlyRole(SUPPLY_PUBLISHER_ROLE)
    {}

    function _authorizeTokenAttributeManagement()
        internal
        virtual
        override
        onlyRole(TOKEN_ATTRIBUTE_ROLE)
    {}

    /// @inheritdoc ERC7984
    function name()
        public
        view
        virtual
        override(ERC7984, ERC7984TokenAttributeModule)
        returns (string memory)
    {
        return ERC7984TokenAttributeModule.name();
    }

    /// @inheritdoc ERC7984
    function symbol()
        public
        view
        virtual
        override(ERC7984, ERC7984TokenAttributeModule)
        returns (string memory)
    {
        return ERC7984TokenAttributeModule.symbol();
    }

    /// @inheritdoc ERC7984
    function decimals() public view virtual override returns (uint8) {
        return _TOKEN_DECIMALS;
    }

    /* ============ _afterBurn Diamond Resolution ============ */
    /**
     * @dev Explicit override resolving the diamond between ERC7984BurnModule and
     * ERC7984EnforcementModule, both of which declare a virtual `_afterBurn` hook.
     * Calls `ERC7984BurnModule._afterBurn` directly; both base hooks are empty, so no
     * additional chain needs to be preserved.
     * CMTATConfidential further overrides this to call _updateTotalSupplyObserversAcl.
     */
    function _afterBurn(
        address from,
        euint64 burned
    ) internal virtual override(ERC7984BurnModule, ERC7984EnforcementModule) {
        ERC7984BurnModule._afterBurn(from, burned);
    }

    /* ============ _update Override ============ */
    /**
     * @dev Explicit override resolving the diamond between ERC7984 and ERC7984BalanceViewModule.
     * Delegates entirely to the module chain (holder + role observer ACL grants).
     *
     * GAS WARNING — deep `_update` call chain
     * A single transfer triggers up to five `_update` overrides in series:
     *   CMTATConfidentialBase → ERC7984BalanceViewModule → ERC7984ObserverAccess → ERC7984
     * In CMTATConfidential (full variant) the total supply view module further extends this
     * via its `_afterMint`/`_afterBurn` hooks, iterating over all registered supply
     * observers. Each FHE.allow() call adds gas. Keep observer lists small.
     */
    function _update(
        address from,
        address to,
        euint64 amount
    )
        internal
        virtual
        override(ERC7984, ERC7984BalanceViewModule)
        returns (euint64 transferred)
    {
        return ERC7984BalanceViewModule._update(from, to, amount);
    }

    /* ============ Module Validation Overrides ============ */

    function _validateMint(address to) internal virtual override {
        if (!_canMintBurnByModule(to)) {
            revert ERC7943CannotReceive(to);
        }
    }

    function _validateBurn(address from) internal virtual override {
        if (!_canMintBurnByModule(from)) {
            revert ERC7943CannotSend(from);
        }
    }

    function _validateForcedTransfer(
        address from,
        address to
    ) internal virtual override {
        if (to == address(0)) {
            revert CMTAT_Enforcement_ZeroAddressNotAllowed();
        }
        if (!isFrozen(from)) {
            revert CMTAT_AddressNotFrozen(from);
        }
    }

    function _validateForcedBurn(address from) internal virtual override {
        if (!isFrozen(from)) {
            revert CMTAT_AddressNotFrozen(from);
        }
    }

    /* ============ Transfer View ============ */

    /**
     * @notice Returns whether a transfer from `from` to `to` is currently permitted.
     * @dev Delegates to `_canTransferGenericByModule(address(0), from, to)`, which is the
     * central transfer gate shared by all 8 transfer overrides below. It checks, in order:
     *   - for standard transfers: freeze status of sender, receiver and spender; pause state
     *   - for mint: deactivation and freeze status of the recipient
     *   - for burn: deactivation and freeze status of the sender
     * Deployment variants override this function to add their own policy layer on top
     * (allowlist check in CMTATConfidentialWhitelist; rule engine in CMTATConfidentialRuleEngine).
     *
     * The `amount` parameter is intentionally ignored. Transfer amounts are encrypted and
     * cannot be evaluated in a public view function, so amount-based rules are never enforced here.
     *
     * **Asymmetry with `canSend`/`canReceive`:** `canSend(from) && canReceive(to)` is NOT
     * equivalent to `canTransfer(from, to, 0)`. `canSend`/`canReceive` only check freeze
     * (and allowlist in the whitelist variant) — they do not reflect pause state. When the
     * contract is paused, those functions may return `true` while `canTransfer` returns `false`.
     * Use `canTransfer` for the authoritative pre-flight check.
     * @param from Token sender.
     * @param to Token recipient.
     * @return True if the transfer is currently permitted.
     */
    function canTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) public view virtual returns (bool) {
        return _canTransferGenericByModule(address(0), from, to);
    }

    /* ============ Transfer Overrides ============ */
    /**
     * @dev All transfer overrides below pass `0` as the `amount` argument to
     * `ERC7943CannotTransfer`. The actual transfer amount is encrypted and
     * unavailable at the point of the pre-flight check, so the value is
     * structurally fixed to zero. Integrators must not assume amount-based
     * rules (e.g. minimum transfer size, balance caps) are enforced by this
     * error — only permissioned restrictions on sender and receiver are checked.
     */

    /// @inheritdoc ERC7984
    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(address(0), from, to);
        return ERC7984.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ERC7984
    function confidentialTransfer(
        address to,
        euint64 amount
    ) public virtual override returns (euint64) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(address(0), from, to);
        return ERC7984.confidentialTransfer(to, amount);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        if (!_canTransferGenericByModule(spender, from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(spender, from, to);
        return ERC7984.confidentialTransferFrom(from, to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ERC7984
    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        if (!_canTransferGenericByModule(spender, from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(spender, from, to);
        return ERC7984.confidentialTransferFrom(from, to, amount);
    }

    /**
     * @inheritdoc ERC7984
     * @dev **Silent refund failure warning.** The receiver is credited before its
     * `onConfidentialTransferReceived` callback fires. If the callback returns `false`,
     * a compensating reverse transfer is attempted via `FHE.select(success, 0, sent)`.
     * A malicious or re-entrant receiver can drain its encrypted balance inside the
     * callback before returning `false`, causing `FHESafeMath.tryDecrease` to silently
     * saturate to 0 — the sender permanently loses the tokens with no revert. This is a
     * structural limitation of FHE arithmetic (underflow conditions are encrypted and
     * cannot trigger an EVM revert) and an intentional design choice in the upstream
     * ERC-7984 library.
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
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(address(0), from, to);
        return ERC7984.confidentialTransferAndCall(to, encryptedAmount, inputProof, data);
    }

    /**
     * @inheritdoc ERC7984
     * @dev **Silent refund failure warning.** See the `externalEuint64` overload above for
     * a full description of the silent refund failure risk. The same limitation applies here.
     * **Only call this function with trusted, audited receiver contracts.**
     */
    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(address(0), from, to);
        return ERC7984.confidentialTransferAndCall(to, amount, data);
    }

    /**
     * @inheritdoc ERC7984
     * @dev **Silent refund failure warning.** Shares the credited-before-callback /
     * best-effort-refund semantics of `confidentialTransferAndCall` — see the
     * `externalEuint64` overload above for the full description. A malicious or
     * re-entrant receiver can cause the sender to permanently lose the tokens with no
     * revert. This is not an atomic pay-and-call primitive.
     * **Only call this function with trusted, audited receiver contracts.**
     */
    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        if (!_canTransferGenericByModule(spender, from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(spender, from, to);
        return ERC7984.confidentialTransferFromAndCall(from, to, encryptedAmount, inputProof, data);
    }

    /**
     * @inheritdoc ERC7984
     * @dev **Silent refund failure warning.** See the `externalEuint64` overload above for
     * a full description of the silent refund failure risk. The same limitation applies here.
     * **Only call this function with trusted, audited receiver contracts.**
     */
    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        address spender = _msgSender();
        if (!_canTransferGenericByModule(spender, from, to)) {
            revert ERC7943CannotTransfer(from, to, 0);
        }
        _beforeTransfer(spender, from, to);
        return ERC7984.confidentialTransferFromAndCall(from, to, amount, data);
    }

    /**
     * @dev Hook called after all module guards pass but before FHE arithmetic executes.
     * Mirrors CMTAT's pattern where rule engine notification fires before the actual
     * token state change. Empty by default; override to add pre-FHE enforcement
     * (e.g. rule engine transfer notification).
     * @param spender Address initiating the transfer (`address(0)` for direct transfers).
     * @param from Token sender.
     * @param to Token recipient.
     */
    function _beforeTransfer(address spender, address from, address to) internal virtual {}

    /* ============ ERC165 Support ============ */

    /**
     * @notice Returns whether the contract implements the interface `interfaceId`.
     * @dev Resolves the diamond between ERC7984 and AccessControl; true if either supports it.
     * @param interfaceId The ERC-165 interface identifier to query.
     * @return True if `interfaceId` is supported.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC7984, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC7984.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /* ============ Version Override ============ */

    /// @inheritdoc CMTATConfidentialVersionModule
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
