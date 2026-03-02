// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FHE, ebool, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import {IERC7984Receiver} from "../../openzeppelin-confidential-contracts/contracts/interfaces/IERC7984Receiver.sol";

contract ConfidentialReceiverMock is IERC7984Receiver, ZamaEthereumConfig {
    bool private _accept;

    constructor(bool accept_) {
        _accept = accept_;
    }

    function setAccept(bool accept_) external {
        _accept = accept_;
    }

    function onConfidentialTransferReceived(
        address,
        address,
        euint64,
        bytes calldata
    ) external override returns (ebool) {
        ebool result = FHE.asEbool(_accept);
        FHE.allow(result, msg.sender);
        return result;
    }
}
