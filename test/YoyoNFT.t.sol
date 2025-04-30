// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Test.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";
import {DeployYoyoNft} from "../script/DeployYoyoNft.s.sol";
import {HelperConfig} from "../script/helperConfig.s.sol";
import {CodeConstants} from "../script/helperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5MockWrapper} from "../test/mocks/VRFCoordinatorV2_5MockWrapper.sol";

contract YoyoNftTest is Test, CodeConstants {
    YoyoNft public yoyoNft;
    HelperConfig public helperConfig;

    // NetworkConfig struct for constructor parameters
    address vrfCoordinatorV2_5;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint256 callbackGasLimit;
    string baseURI;
    LinkToken link;

    // Test partecipants
    address public deployer;
    address public USER_1 = makeAddr("user 1");
    address public USER_2 = makeAddr("user 2");
    address public USER_NO_BALANCE = makeAddr("user no balance");

    uint256 public constant STARTING_BALANCE_YOYO_CONTRACT = 10 ether;
    uint256 public constant STARTING_BALANCE_VRFCOORDINATOR = 10 ether;
    uint256 public constant STARTING_BALANCE_LINK_CONTRACT = 10 ether;
    uint256 public constant STARING_BALANCE_DEPLOYER = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_1 = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_2 = 10 ether;
    uint256 public constant STARING_BALANCE_PLAYER_NO_BALANCE = 0 ether;
    uint256 public constant STARING_LINK_BALANCE = 100 ether;

    function setUp() external {
        DeployYoyoNft contractDeployer = new DeployYoyoNft();
        (yoyoNft, helperConfig) = contractDeployer.run();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        keyHash = config.keyHash;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        baseURI = config.baseURI;
        link = LinkToken(config.link);

        deployer = msg.sender;

        // Set up ether balances for each address
        vm.deal(address(yoyoNft), STARTING_BALANCE_YOYO_CONTRACT);
        vm.deal(address(vrfCoordinatorV2_5), STARTING_BALANCE_VRFCOORDINATOR);
        vm.deal(address(link), STARTING_BALANCE_LINK_CONTRACT);
        vm.deal(deployer, STARING_BALANCE_DEPLOYER);
        vm.deal(USER_1, STARING_BALANCE_PLAYER_1);
        vm.deal(USER_2, STARING_BALANCE_PLAYER_2);
        vm.deal(USER_NO_BALANCE, STARING_BALANCE_PLAYER_NO_BALANCE);

        vm.startPrank(deployer);
        if (block.chainid == ANVIL_CHAIN_ID) {
            link.mint(deployer, STARING_LINK_BALANCE);
            VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5).fundSubscription(
                subscriptionId,
                STARING_LINK_BALANCE
            );
            link.mint(address(yoyoNft), STARING_LINK_BALANCE);
            link.mint(address(vrfCoordinatorV2_5), STARING_LINK_BALANCE);
            link.mint(address(USER_1), STARING_LINK_BALANCE);
            link.mint(address(USER_2), STARING_LINK_BALANCE);
        }
        link.approve(vrfCoordinatorV2_5, STARING_LINK_BALANCE);
        vm.stopPrank();
        //balances consolelog
        console2.log("Deployer address:", deployer);
        console2.log("yoyoNft address:", address(yoyoNft));
        console2.log("VRFCoordinator address:", vrfCoordinatorV2_5);
        console2.log("Link address:", address(link));
        console2.log(
            "Deployer balance:",
            deployer.balance,
            "Link balance:",
            link.balanceOf(deployer)
        );
        console2.log(
            "VRFCoordinator balance:",
            address(vrfCoordinatorV2_5).balance,
            "Link balance:",
            link.balanceOf(vrfCoordinatorV2_5)
        );
        console2.log(
            "YoyoNft contract balance:",
            address(yoyoNft).balance,
            "Link balance:",
            link.balanceOf(address(yoyoNft))
        );
        console2.log(
            "link contract balance:",
            address(link).balance,
            "linkcontract balance of link:",
            link.balanceOf(address(link))
        );
        console2.log(
            "User 1 balance:",
            USER_1.balance,
            "Link balance:",
            link.balanceOf(USER_1)
        );
        console2.log(
            "get subscription balance",
            VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5)
                .getSubscriptionBalance(subscriptionId)
        );
    }

    /*//////////////////////////////////////////////////////////////
            Test the constructor parameters assignments
//////////////////////////////////////////////////////////////*/
    function testNameAndSymbol() public view {
        assertEq(yoyoNft.name(), "Yoyo Collection");
        assertEq(yoyoNft.symbol(), "YOYO");
    }

    function testVrfCoordinator() public view {
        assertEq(address(yoyoNft.i_vrfCoordinator()), vrfCoordinatorV2_5);
    }

    function testConstructorParametersAssignments() public view {
        assertEq(yoyoNft.i_owner(), deployer);
        assertEq(yoyoNft.i_keyHash(), keyHash);
        assertEq(yoyoNft.i_callbackGasLimit(), callbackGasLimit);
        assertEq(yoyoNft.getBaseURI(), baseURI);
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    /*//////////////////////////////////////////////////////////////
            Test receive and fallback functions
//////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                        Test modifiers
//////////////////////////////////////////////////////////////*/
    function testIfYoyoOnlyOwnerModifierWorks() public {
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__NotOwner.selector);
        yoyoNft.changeMintPrice(0.002 ether);
        vm.stopPrank();
    }

    function testIfNotExceedNFTsMaxSupplyModifierWorks() public {
        uint256 memorySlot = 9;
        bool nativepayment = false;
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
        yoyoNft.requestNFT{value: mintPayment}(nativepayment);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
            Test requeste and minting NFT functions
//////////////////////////////////////////////////////////////*/
    //This modifier can be used to request nft from one to three different users
    modifier multipleRequestNft(
        bool nativePayment,
        address sender,
        address sender2,
        address sender3
    ) {
        uint256 mintPayment = yoyoNft.getMintPriceEth();
        vm.startPrank(sender);
        yoyoNft.requestNFT{value: mintPayment}(nativePayment);
        vm.warp(block.timestamp + 30);
        vm.roll(block.number + 1);
        vm.stopPrank();

        if (sender2 != address(0)) {
            vm.startPrank(sender2);
            yoyoNft.requestNFT{value: mintPayment}(nativePayment);
            vm.warp(block.timestamp + 30);
            vm.roll(block.number + 1);
            vm.stopPrank();
        }

        if (sender3 != address(0)) {
            vm.startPrank(sender3);
            yoyoNft.requestNFT{value: mintPayment}(nativePayment);
            vm.warp(block.timestamp + 30);
            vm.roll(block.number + 1);
            vm.stopPrank();
        }
        _;
    }

    function testIfRequestNFTWorksAndEmitsEvent() public {
        uint256 mintPayment = yoyoNft.getMintPriceEth();
        bool nativePayment = false;
        uint256 contractInitialBalance = address(yoyoNft).balance;

        vm.startPrank(USER_1);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__NftRequested(1, USER_1);
        yoyoNft.requestNFT{value: mintPayment}(nativePayment);
        vm.stopPrank();

        assertEq(
            address(yoyoNft).balance,
            contractInitialBalance + mintPayment
        );
    }

    function testIfRequestPassAllCorrectParameters()
        public
        multipleRequestNft(false, USER_1, address(0), address(0))
    {
        assertEq(yoyoNft.getSenderFromRequestId(1), USER_1);

        VRFCoordinatorV2_5MockWrapper.RequestPublic
            memory request = VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5)
                .getRequest(1);
        assertEq(request.subId, subscriptionId);
        assertEq(request.callbackGasLimit, callbackGasLimit);
        assertEq(
            request.numWords,
            1
        ); /* 1 rapresent the private variable NUM_WORDS*/
    }

    function testIfRequestIdToSenderMappingWorksWithRequestNFT()
        public
        multipleRequestNft(false, USER_1, USER_2, address(0))
    {
        assertEq(yoyoNft.getSenderFromRequestId(1), USER_1);
        assertEq(yoyoNft.getSenderFromRequestId(2), USER_2);
    }

    function testIfRequestNFTRevertsIfValueisLessThanMintPrice() public {
        uint256 mintPayment = yoyoNft.getMintPriceEth() / 2;
        bool nativePayment = false;
        vm.startPrank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__NotEnoughPayment.selector);
        yoyoNft.requestNFT{value: mintPayment}(nativePayment);
        vm.stopPrank();
    }

    function testIfFulfillRandomWordsRevertsIfRequestIdIsInvalid() public {
        uint256 invalidRequestId = 9999;
        vm.startPrank(address(yoyoNft));
        vm.expectRevert();
        VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5).fulfillRandomWords(
            invalidRequestId,
            address(yoyoNft)
        );
        vm.stopPrank();
    }

    function testIfFullfillRandomWordsWorksAndMintsNFT()
        public
        multipleRequestNft(false, USER_1, address(0), address(0))
    {
        VRFCoordinatorV2_5MockWrapper(vrfCoordinatorV2_5).fulfillRandomWords(
            1,
            address(yoyoNft)
        );

        assertEq(yoyoNft.getTotalMinted(), 1);
        assertEq(yoyoNft.getAccountBalance(USER_1), 1);
    }

    /*//////////////////////////////////////////////////////////////
                Test deposit and withdraw functions  
//////////////////////////////////////////////////////////////*/

    function testIfDepositWorksAndEmitsEvent() public {
        uint256 depositAmount = 0.001 ether;
        vm.deal(deployer, 1 ether);

        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__DepositCompleted(depositAmount, block.timestamp);
        yoyoNft.deposit{value: depositAmount}();
        assertEq(
            address(yoyoNft).balance - STARTING_BALANCE_YOYO_CONTRACT,
            depositAmount
        );
    }

    function testIfDepositRevertsIfValueIsZero() public {
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ValueCantBeZero.selector);
        yoyoNft.deposit{value: 0}();
    }

    function testIfWithdrawWorksAndEmitsEvent() public {
        vm.prank(deployer);
        vm.expectEmit(true, true, true, true);
        emit YoyoNft.YoyoNft__WithdrawCompleted(
            STARTING_BALANCE_YOYO_CONTRACT,
            block.timestamp
        );
        yoyoNft.withdraw();
        assertEq(address(yoyoNft).balance, 0);
        assertEq(
            deployer.balance,
            STARING_BALANCE_DEPLOYER + STARTING_BALANCE_YOYO_CONTRACT
        );
    }

    function testIfWithdrawRevertsIfContractBalanceIsZero() public {
        vm.deal(address(yoyoNft), 0);
        vm.prank(deployer);
        vm.expectRevert(YoyoNft.YoyoNft__ContractBalanceIsZero.selector);
        yoyoNft.withdraw();
    }

    /*//////////////////////////////////////////////////////////////
                Test mintPrice functions 
//////////////////////////////////////////////////////////////*/
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

    /*//////////////////////////////////////////////////////////////
                Test getters functions
//////////////////////////////////////////////////////////////*/
    function testTokenURIGetterRevertDueToInvalidTokenId() public {
        uint256 invalidTokenId = yoyoNft.MAX_NFT_SUPPLY() + 1;
        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__TokenIdDoesNotExist.selector);
        yoyoNft.tokenURI(invalidTokenId);
    }

    function testTokenURIGetterRevertDueToTokenNotMintedId() public {
        uint256 tokenId = yoyoNft.MAX_NFT_SUPPLY() - 1;
        vm.prank(USER_1);
        vm.expectRevert(YoyoNft.YoyoNft__TokenNotMintedYet.selector);
        yoyoNft.tokenURI(tokenId);
    }

    function testTotalMintedGetter() public view {
        assertEq(yoyoNft.getTotalMinted(), 0);
    }

    function testMintPriceEthGetter() public {
        vm.prank(deployer);
        uint256 newMintPrice = 0.004 ether;
        yoyoNft.changeMintPrice(newMintPrice);
        vm.stopPrank();
        assertEq(yoyoNft.getMintPriceEth(), newMintPrice);
    }

    function testBaseURIGetter() public view {
        assertEq(yoyoNft.getBaseURI(), baseURI);
    }

    function testAccountBalanceGetter() public view {
        assertEq(yoyoNft.getAccountBalance(USER_1), 0);
    }

    // function testConsoleLogStorageSlots() public {
    //     for (uint256 i = 0; i < 20; i++) {
    //         bytes32 slot = bytes32(i);
    //         bytes32 value = vm.load(address(yoyoNft), slot);
    //         uint256 intValue = uint256(value);
    //         console.log("Slot", i, ":", intValue);
    //     }
    // }
}
