//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/helperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        (uint256 subscriptionId, ) = createSubscription(vrfCoordinator);
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinatorV2_5
    ) public returns (uint256, address) {
        console.log("Creating subscription on chain id", block.chainid);
        vm.startBroadcast();
        // Create a subscription
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription ID: ", subscriptionId);
        return (subscriptionId, vrfCoordinatorV2_5);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(
        address vrfCoordinatorV2_5,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Funding subscription on chain id", block.chainid);
        console.log(
            "Funding subscription with vrfCoordinator",
            vrfCoordinatorV2_5
        );

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinatorV2_5,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subscriptionId);
    }

    function addConsumer(
        address consumer,
        address vrfCoordinatorV2_5,
        uint256 subscriptionId
    ) public {
        console.log("Adding consumer contract:", consumer);
        console.log("To vrfCoordinator:", vrfCoordinatorV2_5);
        console.log("on chain id:", block.chainid);

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(
            subscriptionId,
            consumer
        );
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
            "YoyoNft",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentDeployed);
    }
}
