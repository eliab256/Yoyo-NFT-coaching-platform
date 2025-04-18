// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {DeployYoyoNft} from "../script/DeployYoyoNft.s.sol";
import {HelperConfig} from "../script/helperConfig.s.sol";

contract YoyoNftTest is Test {
    YoyoNft public yoyoNft;
    HelperConfig public helperConfig;

    // NetworkConfig struct
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint256 callbackGasLimit;
    string baseURI;
    
    // Test partecipants
    address public deployer;
    address public USER_1 = makeAddr("user 1");
    address public USER_2 = makeAddr("user 2");
    address public USER_NO_BALANCE = makeAddr("user no balance");

    uint256 public constant STARING_BALANCE_DEPLOYER = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_1 = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_2 = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_NO_BALANCE = 0 ether;
    

    function setUp() external {
        DeployYoyoNft contractDeployer = new DeployYoyoNft();
        (yoyoNft, helperConfig) = contractDeployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;   
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        baseURI = config.baseURI;

        deployer = msg.sender;

        vm.deal(deployer, STARING_BALANCE_DEPLOYER);
        vm.deal(USER_1, STARING_BALANCE_PLAYER_1);
        vm.deal(USER_2, STARING_BALANCE_PLAYER_2);
        vm.deal(USER_NO_BALANCE, STARING_BALANCE_PLAYER_NO_BALANCE);
    }

// Test the constructor parameters assignments
    function testConstructorParametersAssignments() public  view{
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
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__NotOwner.selector);
        yoyoNft.changeMintPrice(0.002 ether);
        vm.stopPrank();
    }

    function testIfNotExceedNFTsMaxSupplyModifierWorks() public {
        uint256 memorySlot = 9;
        vm.store(
            address(yoyoNft),
            bytes32(memorySlot),
            bytes32(uint256(yoyoNft.MAX_NFT_SUPPLY())) 
        );
        /*Now TokenCounter is equal to max nft supply, all nft are minted*/ 
        assertEq(
            vm.load(address(yoyoNft), bytes32(memorySlot)),
            bytes32(uint256(yoyoNft.MAX_NFT_SUPPLY()))
        );
        /* ExternalUser try to mint a new token but function revert with custom error cause counter is at maximum */
        uint256 mintPayment = yoyoNft.getMintPriceEth();
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__AllNFTsHaveBeenMinted.selector);
        yoyoNft.requestNFT{value: mintPayment}(true);
        vm.stopPrank();
    } 

    // function testConsoleLogStorageSlots() public {
    //     for (uint256 i = 0; i < 20; i++) {
    //         bytes32 slot = bytes32(i);
    //         bytes32 value = vm.load(address(yoyoNft), slot);
    //         uint256 intValue = uint256(value);
    //         console.log("Slot", i, ":", intValue);
    //     }
    // }

// Test requeste and minting NFT functions
    // function testIfRequestNFTWorksAndEmitsEvent() public {
    //     uint256 mintPayment = yoyoNft.getMintPriceEth();
    //     vm.startPrank(USER_1);
    //     vm.expectEmit(true, true, true, true);
    //     emit YoyoNft.NftRequested(0, USER_1);
    //     yoyoNft.requestNFT{value: mintPayment}(true);
    //     vm.stopPrank();

    //     //assertEq(yoyoNft.getSenderFromRequestId(0), USER_1);
    // }

    function testIfRequestNFTRevertsIfValueisLessThanMintPrice() public{
        uint256 mintPayment = yoyoNft.getMintPriceEth()/2;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__NotEnoughPayment.selector);
        yoyoNft.requestNFT{value:mintPayment}(true);
        vm.stopPrank();
    }

    function testIfEnableNativePaymentWorks() public {
        uint256 mintPayment = yoyoNft.getMintPriceEth();
        vm.startPrank(USER_1);
        vm.expectRevert();
        yoyoNft.requestNFT{value: mintPayment}(false);
        vm.stopPrank();
    }



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
        vm.deal(address(yoyoNft), withdrawAmount);
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__WithdrawCompleted(withdrawAmount, block.timestamp);
        yoyoNft.withdraw();
        assertEq(address(yoyoNft).balance, 0);
        assertEq(deployer.balance, STARING_BALANCE_DEPLOYER + withdrawAmount);
    }

    function testIfWithdrawRevertsIfContractBalanceIsZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ContractBalanceIsZero.selector);
        yoyoNft.withdraw();
    }

    function testIfEmitEventOfFailedWithdraw() public {
      
    }

// Test mintPrice functions
    function testIfChangeMintPriceWorks() public {
        vm.startPrank(deployer);
        uint256 newMintPrice = yoyoNft.getMintPriceEth() + 0.001 ether;
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

    function testTokenURIGetterRevertDueToInvalidTokenId() public {
        uint256 invalidTokenId = yoyoNft.MAX_NFT_SUPPLY() + 1;
        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__TokenIdDoesNotExist.selector);
        yoyoNft.tokenURI(invalidTokenId);
    }

    function testTokenURIGetterRevertDueToTokenNotMintedId() public {
        uint256 tokenId = yoyoNft.MAX_NFT_SUPPLY() -1;
        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__TokenNotMintedYet.selector);
        yoyoNft.tokenURI(tokenId);
    }

    

    function testTotalMintedGetter() public view{
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    function testMintPriceEthGetter() public {
        vm.prank(deployer);
        uint256 newMintPrice = 0.004 ether;
        yoyoNft.changeMintPrice(newMintPrice);
        vm.stopPrank();
        assertEq(yoyoNft.getMintPriceEth(), newMintPrice);
    }

    function testBaseURIGetter() public view{
        assertEq(yoyoNft.getBaseURI(), baseURI);
    }


}
