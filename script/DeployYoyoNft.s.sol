// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig} from "./helperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployYoyoNft is Script {
    //function setUp() public {}

    function run() public returns (YoyoNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //if local, deploy the mocks and get the config
        //if sepolia, get sepolia config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if (config.subscriptionId == 0) {
            // Create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (
                config.subscriptionId,
                config.vrfCoordinatorV2_5
            ) = createSubscription.createSubscription(
                config.vrfCoordinatorV2_5
            );

            // Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5,
                config.subscriptionId,
                config.link
            );
        }

        vm.startBroadcast();
        // Deploy the YoyoNft contract and assign parameters from the config
        YoyoNft yoyoNft = new YoyoNft(
            config.vrfCoordinatorV2_5,
            config.keyHash,
            config.subscriptionId,
            config.callbackGasLimit,
            config.baseURI
        );
        console.log("(deploy script) YoyoNft deployed to: ", address(yoyoNft));
        vm.stopBroadcast();

        // Add the consumer don't need broadcast cause it's already in the contract
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(
            address(yoyoNft),
            config.vrfCoordinatorV2_5,
            config.subscriptionId
        );

        return (yoyoNft, helperConfig);
    }
}
