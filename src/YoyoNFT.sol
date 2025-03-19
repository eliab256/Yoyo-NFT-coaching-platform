// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {VRFConsumerBaseV2Plus, VRFV2PlusClient, IVFRCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8";

contract YoyoNft is ERC721, VRFConsumerBaseV2Plus {
    using VRFV2PlusClient for VRFV2PlusClient.RandomWordsRequest;
  //variables
    //uint256 private constant ROLL_IN_PROGRESS = 42;
    IVFRCoordinatorV2Plus private immutable  i_vrfCoordinator;
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

    //events

    //errors
    error YoyoNft__NotOwner();
    error YoyoNft__TokenIdDoesNotExist();

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoNft__NotOwner();
        }
        _;
    }

    //functions
    constructor(address _vrfCoordinator, bytes32 _keyHash, uint256 _subscriptionId, uint32 _callbackGasLimit, string memory _baseURI
    ) ERC721("Yoyo Collection", "YOYO") VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_vrfCoordinator = IVFRCoordinatorV2Plus(_vrfCoordinator);
        i_owner = msg.sender;
        i_keyHash = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_baseURI = _baseURI;
        s_tokenCounter = 0;
    }

    function mintNft() public {}

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenId == 0 || tokenId > 125) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        return s_tokenIdToUri[tokenId];
    }
}
