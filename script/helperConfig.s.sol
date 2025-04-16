//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
    
    //VRF Mock Inputs
    uint96 public MOCK_BASE_FEE = 0.25 ether; //base fee
    uint96 public MOCK_GAS_PRICE_LINK = 1e9; // gas price
    int256 public MOCK_WEI_PER_UNIT_LINK = 4e15; // wei per unit link
}    

contract HelperConfig is Script, CodeConstants{
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint256 callbackGasLimit;
        string baseURI;
    }

    NetworkConfig public activeNetworkConfig;
    mapping (uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        // if (block.chainid == 11155111) {
        //     activeNetworkConfig = getSepoliaEthConfig();
        // } else if (block.chainid == 31337) {
        //     activeNetworkConfig = getAnvilConfig();
        // } else {
        //     revert("No active network config found");
        // }
    }

    function getConfigsByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if(chainId == ANVIL_CHAIN_ID) {
            return getAnvilConfig();
        } else  {
            revert HelperConfig__InvalidChainId();
        }
    }


    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0 /*vm.envUint("SUBSCRIPTION_ID")*/,
            callbackGasLimit: 500000,
            baseURI: "baseURI" /*vm.envString("BASE_URI")*/
        });
        

    }

    function getAnvilConfig()  public returns (NetworkConfig memory) {
        if(activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
  
        //VRF Mock deployment
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UNIT_LINK
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinatorMock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: vm.envUint("SUBSCRIPTION_ID"),
            callbackGasLimit: 200,
            baseURI: vm.envString("BASE_URI")
        });
        return anvilConfig;

    }
}