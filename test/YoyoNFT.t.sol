// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {DeployYoyoNft} from "../script/DeployYoyoNft.s.sol";

contract YoyoNftTest is Test {
    YoyoNft yoyoNft;

    function setUp() external {
        DeployYoyoNft deployYoyoNft = new DeployYoyoNft();
        yoyoNft = deployYoyoNft.run();
    }

    function testConstructorParametersAssignments() public {
        assertEq(yoyoNft.i_owner(), vm.envAddress("ANVIL_DEPLOYER_ADDRESS"));
        //assertEq(yoyoNft.i_vrfCoordinator(), vm.envAddress("VRF_COORDINATOR"));
        assertEq(yoyoNft.i_keyHash(), vm.envBytes32("KEY_HASH"));
        assertEq(yoyoNft.i_subscriptionId(), vm.envUint("SUBSCRIPTION_ID"));
        assertEq(
            yoyoNft.i_callbackGasLimit(),
            vm.envUint("CALLBACK_GAS_LIMIT")
        );
        assertEq(yoyoNft.getBaseURI(), vm.envString("BASE_URI"));
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    function testIfReceiveFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__ThisContractDoesntAcceptDeposit.selector
        );
        (bool success, ) = address(yoyoNft).call{value: 1 ether}("");
        assertTrue(!success);
    }

    function testIfFallbackFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__CallValidFunctionToInteractWithContract.selector
        );
        (bool success, ) = address(yoyoNft).call{value: 1 ether}("metadata");
        assertTrue(!success);
    }
}
