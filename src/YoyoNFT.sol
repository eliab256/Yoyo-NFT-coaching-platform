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
    error YoyoNft__ValueCantBeZero();
    error YoyoNft__TokenIdDoesNotExist();
    error YoyoNft__InvalidRequest();
    error YoyoNft__AllNFTsHaveBeenMinted();
    error YoyoNft__NotEnoughPayment();
    error YoyoNft__WithdrawFailed();
    error YoyoNft__ThisContractDoesntAcceptDeposit();
    error YoyoNft__CallValidFunctionToInteractWithContract();



    /* Type declarations */


    /* State variables */
    IVFRCoordinatorV2Plus private immutable i_vrfCoordinator;
    address private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_tokenCounter;
    uint256 private constant MAX_NFT_SUPPLY = 100;
    uint256 private constant MIN_TOKEN_ID = 1;
    string private s_baseURI;
    address private immutable i_owner;
    uint256 public mintPriceEth = 0.001;

    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(uint256 => address) private s_requestIdToSender;
    mapping(uint256 => bool) private s_tokensMinted;

    /* Events */
    event NftRequested(uint256 indexed requestId, address indexed sender);
    event Nftminted(uint256 indexed tokenId, address minter);
    event YoyoNft__WithdrawCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__DepositCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__TokenIdAssigned(uint256 tokenId, string tokenUri);

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

    function requestNFT(bool _enableNativepayment) public payable{
        if (s_tokenCounter >= MAX_NFT_SUPPLY) {
            revert YoyoNft__AllNFTsHaveBeenMinted();
        }
        if (msg.value < mintPriceEth) {
            revert YoyoNft__NotEnoughPayment();
        }
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: _enableNativepayment})
                )
            })
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function changeMintPrice(uint256 newPrice) public onlyOwner {
        if(newPrice == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        mintPriceEth = newPrice;
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

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        if(s_requestIdToSender[_requestId] = address(0)){YoyoNft__InvalidRequest();}
        address nftOwner = s_requestIdToSender[_requestId];
        uint256 candidateTokenId = (_randomWords[0] % MAX_NFT_SUPPLY) + MIN_TOKEN_ID;
        uint256 tokenId = findAvailableTokenId(candidateTokenId);
        s_tokensMinted[tokenId] = true;
        s_tokenCounter++;

        _safeMint(nftOwner, tokenId);
        emit Nftminted(tokenId, nftOwner);
    }

    function findAvailableTokenId(uint256 _candidateTokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < MAX_NFT_SUPPLY; i++) {
            if (!s_tokensMinted[_candidateTokenId]) {
                return _candidateTokenId;
            }
            _candidateTokenId = (_candidateTokenId % MAX_NFT_SUPPLY) + MIN_TOKEN_ID;
            if (_candidateTokenId == 0) {
                _candidateTokenId = MIN_TOKEN_ID;
            }    
        }
        revert YoyoNft__AllNFTsHaveBeenMinted();
    }

    function withdraw() public onlyOwner {
        bool success = payable(i_Owner).send(address(this).balance);
        if(success){
        emit YoyoNft__WithdrawCompleted(address(this).balance, block.timestamp);}
        else {
            revert YoyoNft__WithdrawFailed();
        }
    }

    function deposit() public payable onlyOwner{
        if(msg.value == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        emit YoyoNft__DepositCompleted(msg.value, block.timestamp);
    }

    receive() external payable {
        revert YoyoNft__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoNft__CallValidFunctionToInteractWithContract();
    }
}
