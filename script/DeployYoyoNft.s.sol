// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployYoyoNft is Script {
    //function setUp() public {}
    address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
    bytes32 keyHash = vm.envBytes32("KEY_HASH");
    uint256 subscriptionId = vm.envUint("SUBSCRIPTION_ID");
    uint256 callbackGasLimit = vm.envUint("CALLBACK_GAS_LIMIT");
    string baseURI = vm.envString("BASE_URI");

    function run() external returns (YoyoNft) {
        address deployer = vm.envAddress("ANVIL_DEPLOYER_ADDRESS");

        HelperConfig helperConfig = new HelperConfig();
        (address vrfCoordinator) = helperConfig.activeNetworkConfig.vrfCoordinator();

        vm.startBroadcast(deployer);
        YoyoNft yoyoNft = new YoyoNft(
            vrfCoordinator,
            keyHash,
            subscriptionId,
            callbackGasLimit,
            baseURI
        );
        vm.stopBroadcast();

        return yoyoNft;
    }
}
