//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/moks/LinkToken.sol";

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
        address link;
    }

    NetworkConfig public activeNetworkConfig;
    mapping (uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        uint256 subscriptionIdFromEnv = getEnvSubscriptionId();
        string memory baseURIFromEnv = getEnvBaseURI();
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig(subscriptionIdFromEnv, baseURIFromEnv);

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

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigsByChainId(block.chainid);
    }


    function getEnvSubscriptionId() public view returns (uint256) {
        return vm.envUint("SUBSCRIPTION_ID");
    }
    function getEnvBaseURI() public view returns (string memory) {
        return vm.envString("BASE_URI");
    }

    function getSepoliaEthConfig(uint256 _subscriptionId, string memory _baseURI) public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: _subscriptionId, /*"SUBSCRIPTION_ID" from .env*/
            callbackGasLimit: 500000,
            baseURI: _baseURI, /*"BASE_URI" from*/
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
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
        //Link Token deployment
        LinkToken linkToken = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorMock.createSubscription();
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinatorMock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: subscriptionId,
            callbackGasLimit: 500000,
            baseURI: vm.envString("BASE_URI"),
            link: address(linkToken)
        });
        return anvilConfig;

    }
}