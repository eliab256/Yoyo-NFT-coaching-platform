//SPDX-License-Identifier: MIT

// Deploy mocks for local anvil chain

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script{
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilConfig();
        } else {
            revert("No active network config found");
        }
    }

    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint256 callbackGasLimit;
        string baseURI;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: vm.envUint("SUBSCRIPTION_ID"),
            callbackGasLimit: 200,
            baseURI: vm.envString("BASE_URI")
        });
        return sepoliaConfig;

    }

    function getAnvilConfig() pure public returns (NetworkConfig memory) {
        NetworkConfig memory anvilConfig = NetworkConfig({
            vrfCoordinator: 0x8103B0A8A00be2DDC778C855A1fD9B2a9B2D4F0e,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: vm.envUint("SUBSCRIPTION_ID"),
            callbackGasLimit: 200,
            baseURI: vm.envString("BASE_URI")
        });
        return config;

        vm.startBroadcast();

        vm.stopBroadcast();

    }
}