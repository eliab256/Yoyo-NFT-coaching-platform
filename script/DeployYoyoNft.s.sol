// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig} from "./helperConfig.s.sol";

contract DeployYoyoNft is Script {
    //function setUp() public {}

    function run() public {   

    }

    function deployContract() public returns(YoyoNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        YoyoNft yoyoNft = new YoyoNft(
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit,
            config.baseURI
        );
        console.log("YoyoNft deployed to: ", address(yoyoNft));
        vm.stopBroadcast();
        return (yoyoNft, helperConfig);
    }
}
