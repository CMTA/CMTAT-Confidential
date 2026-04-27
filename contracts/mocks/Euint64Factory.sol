// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";

contract Euint64Factory is ZamaEthereumConfig {
    event HandleCreated(bytes32 indexed handle, address indexed owner);

    function make(uint64 value) external returns (euint64) {
        euint64 handle = FHE.asEuint64(value);
        FHE.allow(handle, msg.sender);
        emit HandleCreated(euint64.unwrap(handle), msg.sender);
        return handle;
    }

    function makeFor(
        address authorized,
        uint64 value
    ) external returns (euint64) {
        euint64 handle = FHE.asEuint64(value);
        FHE.allow(handle, msg.sender);
        FHE.allow(handle, authorized);
        emit HandleCreated(euint64.unwrap(handle), msg.sender);
        return handle;
    }
}
