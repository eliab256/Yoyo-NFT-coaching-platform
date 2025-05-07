//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/helperConfig.s.sol";
import {VRFCoordinatorV2_5MockWrapper} from "../test/mocks/VRFCoordinatorV2_5MockWrapper.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        (uint256 subscriptionId, ) = createSubscription(
            vrfCoordinator,
            account
        );
        return (subscriptionId, vrfCoordinator);
    }

    function createSubscription(
        address vrfCoordinatorV2_5,
        address account
    ) public returns (uint256, address) {
        console2.log("Creating subscription on chain id", block.chainid);
        vm.startBroadcast(account);
        // Create a subscription
        uint256 subscriptionId = VRFCoordinatorV2_5MockWrapper(
            vrfCoordinatorV2_5
        ).createSubscription();
        vm.stopBroadcast();
        console2.log("Your subscription ID: ", subscriptionId);
        return (subscriptionId, vrfCoordinatorV2_5);
    }

    function run() external returns (uint256, address) {
        createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        addConsumer(
            mostRecentlyDeployed,
            vrfCoordinator,
            subscriptionId,
            account
        );
    }

    function addConsumer(
        address consumer,
        address vrfCoordinatorV2_5,
        uint256 subscriptionId,
        address account
    ) public {
        console2.log(
            "(interactions script)Adding consumer contract:",
            consumer
        );
        console2.log(
            "(interactions script)To vrfCoordinator:",
            vrfCoordinatorV2_5
        );
        console2.log("(interactions script)on chain id:", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5).addConsumer(
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

contract FundSubscription is Script, CodeConstants {
    uint96 public constant FUND_AMOUNT = 10 ether; // 10 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updateSubscriptionId, address updateVRFv2) = createSub
                .run();
            subscriptionId = updateSubscriptionId;
            vrfCoordinator = updateVRFv2;
        }

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(
        address vrfCoordinatorV2_5,
        uint256 subscriptionId,
        address linkToken,
        address account
    ) public {
        console2.log(
            "(interactions script) Funding subscription: ",
            subscriptionId
        );
        console2.log(
            "(interactions script)Funding subscription on chain id",
            block.chainid
        );
        console2.log(
            "(interactions script)Funding subscription with vrfCoordinator ",
            vrfCoordinatorV2_5
        );

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5).fundSubscription(
                subscriptionId,
                FUND_AMOUNT * 100
            );
            console2.log(
                "(interactions script)Funding subscription with",
                FUND_AMOUNT * 100,
                "LINK at:",
                msg.sender
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(
                vrfCoordinatorV2_5,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
        console2.log(
            "(interactions script)Subscription funded with",
            FUND_AMOUNT,
            "LINK at:",
            msg.sender
        );
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}
