
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ==== OpenZeppelin === */
import "../CMTAT/contracts/modules/0_CMTATBaseGeneric.sol";
import {ConfidentialFungibleToken} from "../openzeppelin-confidential-contracts/contracts/token/ConfidentialFungibleToken.sol";
import {FHE, externalEuint64, ebool, euint64} from "@fhevm/solidity/lib/FHE.sol";
/**
 * @dev This is an example contract implementation of NFToken.
 */
contract CMTATFHE is ConfidentialFungibleToken, CMTATBaseGeneric {
    error CMTAT_InvalidTransferExternal(address from, address to,  externalEuint64 encryptedAmount);
    error CMTAT_InvalidTransfer(address from, address to, euint64 encryptedAmount);

    constructor(string memory name_, string memory symbol_, string memory tokenURI_,  address admin, 
    ICMTATConstructor.ExtraInformationAttributes memory extraInformationAttributes_,IERC1643 documentEngine) ConfidentialFungibleToken(name_, symbol_, tokenURI_) {
         __CMTAT_init(admin, extraInformationAttributes_, documentEngine);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransfer(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override returns (euint64) {
          address from = _msgSender();
        require(_canTransferGenericByModule(address(0), from, to), CMTAT_InvalidTransferExternal(from, to, encryptedAmount));
        return ConfidentialFungibleToken.confidentialTransfer(to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransfer(address to, euint64 amount) public virtual override  returns (euint64) {
        address from = _msgSender();
        require(_canTransferGenericByModule(address(0), from, to), CMTAT_InvalidTransfer(from, to, amount));
        return ConfidentialFungibleToken.confidentialTransfer(to, amount);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferFrom(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) public virtual override  returns (euint64 transferred) {
       require(_canTransferGenericByModule(_msgSender(), from, to), CMTAT_InvalidTransferExternal(from, to, encryptedAmount));
       return ConfidentialFungibleToken.confidentialTransferFrom(from, to, encryptedAmount, inputProof);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferFrom(
        address from,
        address to,
        euint64 amount
    ) public virtual override  returns (euint64 transferred) {
       require(_canTransferGenericByModule(_msgSender(), from, to), CMTAT_InvalidTransfer(from, to, amount));
       return ConfidentialFungibleToken.confidentialTransferFrom(from, to, amount);
    }
    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferAndCall(
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override  returns (euint64 transferred) {
        address from = _msgSender();
        require(_canTransferGenericByModule(address(0), from, to), CMTAT_InvalidTransferExternal(from, to,  encryptedAmount));
       return ConfidentialFungibleToken.confidentialTransferAndCall(to, encryptedAmount, inputProof, data);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferAndCall(
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override  returns (euint64 transferred) {
        address from = _msgSender();
        require(_canTransferGenericByModule(address(0), from, to), CMTAT_InvalidTransfer(from, to, amount));
       return ConfidentialFungibleToken.confidentialTransferAndCall(to, amount, data);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferFromAndCall(
        address from,
        address to,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof,
        bytes calldata data
    ) public virtual override  returns (euint64 transferred) {

       require(_canTransferGenericByModule(_msgSender(), from, to), CMTAT_InvalidTransferExternal(from, to, encryptedAmount));
       return ConfidentialFungibleToken.confidentialTransferFromAndCall(from, to, encryptedAmount, inputProof, data);
    }

    /// @inheritdoc ConfidentialFungibleToken
    function confidentialTransferFromAndCall(
        address from,
        address to,
        euint64 amount,
        bytes calldata data
    ) public virtual override returns (euint64 transferred) {
        require(_canTransferGenericByModule(_msgSender(), from, to), CMTAT_InvalidTransfer(from, to, amount));
       return ConfidentialFungibleToken.confidentialTransferFromAndCall(from, to, amount, data);
    }

    function mint(address to, euint64 amount) public returns (euint64 transferred) {
         return ConfidentialFungibleToken._mint(to, amount);
    }

    function burn(address from, euint64 amount) public returns (euint64 transferred) {
         return ConfidentialFungibleToken._burn(from, amount);
    }

    function forcedTransfer(address from,address to, euint64 amount) internal returns (euint64 transferred) {
         ConfidentialFungibleToken._transfer(from, to, amount);
    }

}
