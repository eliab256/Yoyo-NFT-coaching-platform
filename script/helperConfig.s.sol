//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5MockWrapper} from "../test/mocks/VRFCoordinatorV2_5MockWrapper.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;

    //VRF Mock Inputs
    uint96 public MOCK_BASE_FEE_LINK = 0.25 ether; //base fee
    uint96 public MOCK_GAS_PRICE_LINK = 20e9; // gas price
    int256 public MOCK_WEI_PER_UNIT_LINK = 2e16; // wei per unit link
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    //Network Config Struct give different parameters to the contract due to different networks
    struct NetworkConfig {
        address vrfCoordinatorV2_5;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint256 callbackGasLimit;
        string baseURI;
        address link;
        address account;
    }

    NetworkConfig public activeNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        uint256 subscriptionIdFromEnv = getEnvSubscriptionId();
        string memory baseURIFromEnv = getEnvBaseURI();
        address accountFromEnv = getAccountFromEnv();
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig(
            subscriptionIdFromEnv,
            baseURIFromEnv,
            accountFromEnv
        );
    }

    function getConfigsByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinatorV2_5 != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == ANVIL_CHAIN_ID) {
            return getAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    //Start deploying the contracts on run function of deploy Script based on the chainId (DeployYoyoNft.s.sol, line 16)
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigsByChainId(block.chainid);
    }

    function getEnvSubscriptionId() public view returns (uint256) {
        return vm.envUint("SUBSCRIPTION_ID");
    }

    function getEnvBaseURI() public view returns (string memory) {
        return vm.envString("BASE_URI");
    }

    function getAccountFromEnv() public view returns (address) {
        return vm.envAddress("SEPOLIA_ACCOUNT");
    }

    function getSepoliaEthConfig(
        uint256 _subscriptionId,
        string memory _baseURI,
        address _account
    ) public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: _subscriptionId /*"SUBSCRIPTION_ID" from .env*/,
                callbackGasLimit: 300000,
                baseURI: _baseURI /*"BASE_URI" from .env*/,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                account: _account /*vm.envAddress("SEPOLIA_ACCOUNT")*/
            });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorV2_5 != address(0)) {
            return activeNetworkConfig;
        }

        //VRF Mock deployment
        vm.startBroadcast();
        //ChainlinkVRF Mock deployment
        VRFCoordinatorV2_5MockWrapper vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5MockWrapper(
                MOCK_BASE_FEE_LINK,
                MOCK_GAS_PRICE_LINK,
                MOCK_WEI_PER_UNIT_LINK
            );
        //Link Token Mock deployment
        LinkToken linkToken = new LinkToken();

        //Fund the subscription
        uint256 mockSubscriptionId = vrfCoordinatorV2_5Mock
            .createSubscription();
        vm.stopBroadcast();
        console.log(
            "(helper config) Mock VrfCoordinator deployed to: ",
            address(vrfCoordinatorV2_5Mock)
        );

        activeNetworkConfig = NetworkConfig({
            vrfCoordinatorV2_5: address(vrfCoordinatorV2_5Mock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: mockSubscriptionId,
            callbackGasLimit: 300000,
            baseURI: vm.envString("BASE_URI"),
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });

        return activeNetworkConfig;
    }
}
