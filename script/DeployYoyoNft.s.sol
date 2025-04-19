// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {HelperConfig} from "./helperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployYoyoNft is Script {
    //function setUp() public {}

    function run() public {   
        deployContract();
    }

    function deployContract() public returns(YoyoNft, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        if(config.subscriptionId == 0) {
            // Create a subscription
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator);

            // Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);

        }

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

        // Add the consumer don't need broadcast cause it's already in the contract
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(yoyoNft), config.vrfCoordinator, config.subscriptionId);

        return (yoyoNft, helperConfig);
    }
}
