// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {VRFConsumerBaseV2Plus, VRFV2PlusClient, IVFRCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8";

/**
 * @title A Yoga NFT collection
 * @author Elia Bordoni
 * @notice This contract is for creating a NFT collection with random features
 * @dev This implements the Chainlink VRF Version 2 and ERC271 standard
 */

contract YoyoNft is ERC721, VRFConsumerBaseV2Plus {
    using VRFV2PlusClient for VRFV2PlusClient.RandomWordsRequest;

    /* Errors */
    error YoyoNft__NotOwner();
    error YoyoNft__TokenIdDoesNotExist();

    /* Type declarations */

    /* State variables */
    //uint256 private constant ROLL_IN_PROGRESS = 42;
    IVFRCoordinatorV2Plus private immutable i_vrfCoordinator;
    address private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_tokenCounter;
    uint256 private constant MAX_NFT_SUPPLY = 125;
    uint256 private constant MIN_TOKEN_ID = 1;
    string private s_baseURI;
    address private immutable i_owner;

    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(uint256 => address) private s_rollers;
    mapping(address => uint256) private s_results;

    /* Events */
    event Nftminted(uint256 indexed tokenId, address minter);

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoNft__NotOwner();
        }
        _;
    }

    /* Functions */
    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit,
        string memory _baseURI
    ) ERC721("Yoyo Collection", "YOYO") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_vrfCoordinator = IVFRCoordinatorV2Plus(_vrfCoordinator);
        i_owner = msg.sender;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_baseURI = _baseURI;
        s_tokenCounter = 0;
    }

    function mintNft(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function transferNFT(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        _safeTransfer(to, tokenId, data);
    }

    function getNftUri(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > 125) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        return s_tokenIdToUri[tokenId];
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        //da modificare (copiata dal contratto raffle)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
