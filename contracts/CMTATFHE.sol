// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* ==== CMTAT Modules === */
import {CMTATBaseGeneric} from "../CMTAT/contracts/modules/0_CMTATBaseGeneric.sol";
import {PauseModule} from "../CMTAT/contracts/modules/wrapper/core/PauseModule.sol";
import {ICMTATConstructor} from "../CMTAT/contracts/interfaces/technical/ICMTATConstructor.sol";

/* ==== OpenZeppelin === */
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/* ==== OpenZeppelin Confidential Contracts === */
import {ERC7984} from "../openzeppelin-confidential-contracts/contracts/token/ERC7984/ERC7984.sol";
import {FHE, externalEuint64, ebool, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

/* ==== FHE Modules === */
import {ERC7984MintModule} from "./modules/ERC7984MintModule.sol";
import {ERC7984BurnModule} from "./modules/ERC7984BurnModule.sol";
import {ERC7984EnforcementModule} from "./modules/ERC7984EnforcementModule.sol";

/**
 * @title CMTATFHE
 * @dev Implementation of CMTAT token standard with FHE confidential balances using ERC7984.
 *
 * This contract combines:
 * - ERC7984: Confidential fungible token with encrypted balances
 * - CMTATBaseGeneric: CMTAT modules for pause, freeze, access control, document engine, etc.
 * - ERC7984MintModule: Modular mint functionality with flexible access control
 * - ERC7984BurnModule: Modular burn functionality with flexible access control
 * - ERC7984EnforcementModule: Modular forced transfer functionality
 *
 * Features:
 * - Confidential balances using FHE encryption
 * - Pause/unpause token transfers
 * - Freeze/unfreeze specific addresses
 * - Role-based access control for mint, burn, pause, freeze operations
 * - Forced transfer capability for enforcement
 * - Document engine integration
 * - Extra information attributes (tokenId, terms, information)
 *
 * Access Control Architecture:
 * - Each module defines a modifier (e.g., onlyMinter) that calls a virtual function
 * - The virtual function (e.g., _authorizeMint) is overridden here to apply access control
 * - This allows flexible access control without tight coupling to a specific implementation
 */
contract CMTATFHE is
    ERC7984,
    CMTATBaseGeneric,
    ZamaEthereumConfig,
    ERC7984MintModule,
    ERC7984BurnModule,
    ERC7984EnforcementModule
{
    /* ============ Errors ============ */
    error CMTAT_InvalidTransfer(address from, address to, string reason);

    /* ============ Constructor ============ */
    /**
     * @dev Constructor to initialize the CMTATFHE token.
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param contractURI_ Contract metadata URI
     * @param admin Admin address with DEFAULT_ADMIN_ROLE
     * @param extraInformationAttributes_ Extra information (tokenId, terms, information)
     */
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

    /**
     * @dev Initializes the contract. Called by constructor for standalone deployment.
     * @param admin Admin address with DEFAULT_ADMIN_ROLE
     * @param extraInformationAttributes_ Extra information (tokenId, terms, information)
     */
    function initialize(
        address admin,
        ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_
    ) public initializer {
        __CMTAT_init(admin, extraInformationAttributes_);
    }

    /* ============ Module Authorization Overrides ============ */

    /**
     * @dev Authorize mint operations - requires MINTER_ROLE.
     * Called by the onlyMinter modifier in ERC7984MintModule.
     */
    function _authorizeMint() internal virtual override onlyRole(MINTER_ROLE) {}

    /**
     * @dev Authorize burn operations - requires BURNER_ROLE.
     * Called by the onlyBurner modifier in ERC7984BurnModule.
     */
    function _authorizeBurn() internal virtual override onlyRole(BURNER_ROLE) {}

    /**
     * @dev Authorize forced transfer operations - requires ENFORCER_ROLE.
     * Called by the onlyEnforcer modifier in ERC7984EnforcementModule.
     */
    function _authorizeForcedTransfer() internal virtual override onlyRole(ENFORCER_ROLE) {}

    /**
     * @dev Authorize pause/unpause operations - requires PAUSER_ROLE.
     * Called by the onlyPauser modifier in PauseModule.
     */
    function _authorizePause() internal virtual override onlyRole(PAUSER_ROLE) {}

    /**
     * @dev Authorize contract deactivation - requires DEFAULT_ADMIN_ROLE.
     */
    function _authorizeDeactivate() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @dev Authorize freeze/unfreeze operations - requires ENFORCER_ROLE.
     * Called by the onlyEnforcer modifier in EnforcementModule.
     */
    function _authorizeFreeze() internal virtual override onlyRole(ENFORCER_ROLE) {}

    /* ============ Module Validation Overrides ============ */

    /**
     * @dev Validates mint operation against CMTAT modules (pause, freeze).
     * @param to Recipient address
     */
    function _validateMint(address to) internal virtual override {
        if (!_canMintBurnByModule(to)) {
            revert CMTAT_InvalidTransfer(address(0), to, "Mint blocked");
        }
    }

    /**
     * @dev Validates burn operation against CMTAT modules (pause, freeze).
     * @param from Address to burn from
     */
    function _validateBurn(address from) internal virtual override {
        if (!_canMintBurnByModule(from)) {
            revert CMTAT_InvalidTransfer(from, address(0), "Burn blocked");
        }
    }

    /**
     * @dev Validates forced transfer against deactivation status.
     * Forced transfers bypass freeze checks but respect deactivation.
     * @param from Source address
     * @param to Destination address
     */
    function _validateForcedTransfer(address from, address to) internal virtual override {
        if (PauseModule.deactivated()) {
            revert CMTAT_InvalidTransfer(from, to, "Contract deactivated");
        }
    }

    /* ============ Transfer Overrides ============ */
    /// @inheritdoc ERC7984
    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64) {
        address from = _msgSender();
        if (!_canTransferGenericByModule(address(0), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ERC7984
    function confidentialTransfer(
        address to,
        euint64 amount
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
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
    ) public virtual override(ERC7984, ERC7984MintModule, ERC7984BurnModule, ERC7984EnforcementModule) returns (euint64 transferred) {
        if (!_canTransferGenericByModule(_msgSender(), from, to)) {
            revert CMTAT_InvalidTransfer(from, to, "Transfer blocked");
        }
        return ERC7984.confidentialTransferFromAndCall(from, to, amount, data);
    }

    /* ============ ERC165 Support ============ */
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC7984, AccessControlUpgradeable)
        returns (bool)
    {
        return ERC7984.supportsInterface(interfaceId) || AccessControlUpgradeable.supportsInterface(interfaceId);
    }
}
