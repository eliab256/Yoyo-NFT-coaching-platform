// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {DeployYoyoNft} from "../script/DeployYoyoNft.s.sol";

contract YoyoNftTest is Test {
    YoyoNft yoyoNft;

    address deployer = vm.envAddress("ANVIL_DEPLOYER_ADDRESS");
    address user1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address user2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;


    address vrfCoordinator = vm.envAddress("VRF_COORDINATOR");
    bytes32 keyHash = vm.envBytes32("KEY_HASH");
    uint256 subscriptionId = vm.envUint("SUBSCRIPTION_ID");
    uint256 callbackGasLimit = vm.envUint("CALLBACK_GAS_LIMIT");
    string baseURI = vm.envString("BASE_URI");

    function setUp() external {
        DeployYoyoNft deployYoyoNft = new DeployYoyoNft();
        yoyoNft = deployYoyoNft.run();
    }

// Test the constructor parameters assignments
    function testConstructorParametersAssignments() public {
        assertEq(yoyoNft.i_owner(), deployer);
        //assertEq(yoyoNft.i_vrfCoordinator(), vrfCoordinator);
        assertEq(yoyoNft.i_keyHash(), keyHash);
        assertEq(yoyoNft.i_subscriptionId(), subscriptionId);
        assertEq(yoyoNft.i_callbackGasLimit(),callbackGasLimit);
        assertEq(yoyoNft.getBaseURI(), baseURI);
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

// Test receive and fallback functions
    function testIfReceiveFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__ThisContractDoesntAcceptDeposit.selector
        );
        address(yoyoNft).call{value: 1 ether}("");
    }

    function testIfFallbackFunctionReverts() public {
        vm.expectRevert(
            YoyoNft.YoyoNft__CallValidFunctionToInteractWithContract.selector
        );
        address(yoyoNft).call{value: 1 ether}("metadata");
    }

    //test modifiers
        function testIfYoyoOnlyOwnerModifierWorks() public {
        vm.startPrank(user1);
        vm.expectRevert(YoyoNft.YoyoNft__NotOwner.selector);
        yoyoNft.changeMintPrice(0.002 ether);
        vm.stopPrank();
    }

    // function testIfNotExceedNFTsMaxSupplyModifierWorks() public {
    //     vm.deal(user1, 1 ether);
    //     uint256 memorySlot = 9;
    //     vm.store(
    //         address(yoyoNft),
    //         bytes32(memorySlot),
    //         bytes32(uint256(yoyoNft.MAX_NFT_SUPPLY())) 
    //     );
        
    //     /*Now TokenCounter is equal to max nft supply, all nft are minted*/ 
    //     /* ExternalUser try to mint a new token but function revert with custom error cause counter is at maximum */
    //     vm.startPrank(user1);
    //     vm.expectRevert(YoyoNft.YoyoNft__AllNFTsHaveBeenMinted.selector);
    //     yoyoNft.requestNFT{value: yoyoNft.getMintPriceEth()}(true);
    //     vm.stopPrank();
    // }

    // function testConsoleLogStorageSlots() public {
    //     for (uint256 i = 0; i < 20; i++) {
    //         bytes32 slot = bytes32(i);
    //         bytes32 value = vm.load(address(yoyoNft), slot);
    //         uint256 intValue = uint256(value);
    //         console.log("Slot", i, ":", intValue);
    //     }
    // }
// Test requeste and minting NFT functions
    function testIfRequestNFTWorksAndEmitsEvent() public {}

    // function testIfRequestNFTRevertsIfValueisLessThanMintPrice() public{
    //     vm.prank(deployer);
    //     uint256 newMintPrice = 0.008 ether;
    //     yoyoNft.changeMintPrice(newMintPrice);
    //     vm.stopPrank();
    //     vm.startPrank(user1);
    //     vm.expectRevert(YoyoNft.YoyoNft__NotEnoughPayment.selector);
    //     yoyoNft.requestNFT{value: 0.001 ether}(true);
    //     vm.stopPrank();
    // }

//bisogno del mock di chainlinkvrf
    // function testIfEnableNativePaymentWorks() public {
    //     vm.deal(user1, 1 ether);
    //     vm.startPrank(user1);
    //     vm.expectRevert();
    //     yoyoNft.requestNFT{value: yoyoNft.getMintPriceEth()}(false);
    //     vm.stopPrank();
    // }



// Test deposit and withdraw function

    function testIfDepositWorksAndEmitsEvent() public {
        uint256 depositAmount = 0.001 ether;
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__DepositCompleted(depositAmount, block.timestamp);
        yoyoNft.deposit{value: depositAmount}();
        assertEq(address(yoyoNft).balance, depositAmount);
    }

    function testIfDepositRevertsIfValueIsZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        yoyoNft.deposit{value: 0}();
    }

    function testIfWithdrawWorksAndEmitsEvent() public {
        uint256 withdrawAmount = 0.001 ether;
        vm.deal(deployer, 1 ether);
        vm.deal(address(yoyoNft), withdrawAmount);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__WithdrawCompleted(withdrawAmount, block.timestamp);
        yoyoNft.withdraw();
        assertEq(address(yoyoNft).balance, 0);
    }

    function testIfWithdrawRevertsIfContractBalanceIsZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ContractBalanceIsZero.selector);
        yoyoNft.withdraw();
    }

    // function testIfEmitEventOfFailedWithdraw() public {
    //     vm.deal(deployer, 1 ether);
    //     vm.deal(address(yoyoNft), 0.001 ether);
    //     vm.prank(deployer);
    //     vm.expectEmit(true, true, true, true);
    //     emit YoyoNft.YoyoNft__WithdrawIsFailed(0.001 ether, block.timestamp);
    //     yoyoNft.withdraw();
    // }

// Test mintPrice functions
    function testIfChangeMintPriceWorks() public {
        vm.prank(deployer);
        uint256 newMintPrice = 0.002 ether;
        yoyoNft.changeMintPrice(newMintPrice);
        vm.stopPrank();
        assertEq(yoyoNft.getMintPriceEth(), newMintPrice);
    }

    function testIfChangeMintPriceRevertIfNewPriceEqualToZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        yoyoNft.changeMintPrice(0);
        vm.prank(deployer);
    }

// Test Getters
    function testTotalMintedGetter() public {
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    function testMintPriceEthGetter() public {
        vm.prank(deployer);
        uint256 newMintPrice = 0.004 ether;
        yoyoNft.changeMintPrice(newMintPrice);
        vm.stopPrank();
        assertEq(yoyoNft.getMintPriceEth(), newMintPrice);
    }

    function testBaseURIGetter() public {
        assertEq(yoyoNft.getBaseURI(), baseURI);
    }


}
