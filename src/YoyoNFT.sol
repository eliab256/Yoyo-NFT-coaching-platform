// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title A Yoga NFT collection
 * @author Elia Bordoni
 * @notice This contract is for creating a NFT collection with random features
 * @dev This implements the Chainlink VRF Version 2 and ERC721 standard
 */

contract YoyoNft is ERC721, VRFConsumerBaseV2Plus {
    using VRFV2PlusClient for VRFV2PlusClient.RandomWordsRequest;

    /* Errors */
    error YoyoNft__NotOwner();
    error YoyoNft__ValueCantBeZero();
    error YoyoNft__TokenIdDoesNotExist();
    error YoyoNft__TokenNotMintedYet();
    error YoyoNft__InvalidRequest();
    error YoyoNft__AllNFTsHaveBeenMinted();
    error YoyoNft__NotEnoughPayment();
    error YoyoNft__WithdrawFailed();
    error YoyoNft__ThisContractDoesntAcceptDeposit();
    error YoyoNft__CallValidFunctionToInteractWithContract();
    error YoyoNft__YouAreNotAnNftOwner();
    error YoyoNft__ContractBalanceIsZero();
    error YoyoNft__InvalidReceiver();

    /* Type declarations */

    /* State variables */
    IVRFCoordinatorV2Plus public immutable i_vrfCoordinator;
    uint256 public immutable i_subscriptionId;
    bytes32 public immutable i_keyHash;
    uint32 public immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private s_tokenCounter;
    uint256 public constant MAX_NFT_SUPPLY = 100;
    string private s_baseURI;
    address public immutable i_owner;
    uint256 private s_mintPriceEth = 0.002 ether;

    mapping(uint256 => string) private s_tokenIdToUri;
    mapping(uint256 => address) private s_requestIdToSender;
    mapping(uint256 => bool) private s_tokensMinted;

    /* Events */
    event YoyoNft__NftRequested(
        uint256 indexed requestId,
        address indexed sender
    );
    event YoyoNft__WithdrawCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__DepositCompleted(uint256 amount, uint256 timestamp);
    event YoyoNft__TokenIdAssigned(uint256 indexed tokenId, string tokenUri);

    /* Modifiers */
    modifier yoyoOnlyOwner() {
        if (msg.sender != i_owner) {
            revert YoyoNft__NotOwner();
        }
        _;
    }

    modifier notExceedNFTsMaxSupply() {
        if (s_tokenCounter >= MAX_NFT_SUPPLY) {
            revert YoyoNft__AllNFTsHaveBeenMinted();
        }
        _;
    }

    /* Functions */
    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint256 callbackGasLimit,
        string memory baseURI
    ) ERC721("Yoyo Collection", "YOYO") VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinator);
        i_owner = msg.sender;
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = uint32(callbackGasLimit);
        s_baseURI = baseURI;
        s_tokenCounter = 0;
    }

    receive() external payable {
        revert YoyoNft__ThisContractDoesntAcceptDeposit();
    }

    fallback() external payable {
        revert YoyoNft__CallValidFunctionToInteractWithContract();
    }

    function requestNFT(
        bool _nativePayment
    ) public payable notExceedNFTsMaxSupply {
        if (msg.value < s_mintPriceEth) {
            revert YoyoNft__NotEnoughPayment();
        }
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: _nativePayment})
                )
            })
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit YoyoNft__NftRequested(requestId, msg.sender);
    }

    function changeMintPrice(uint256 newPrice) public yoyoOnlyOwner {
        if (newPrice == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        s_mintPriceEth = newPrice;
    }

    function transferNFT(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert YoyoNft__YouAreNotAnNftOwner();
        }
        if (to == address(0)) {
            revert YoyoNft__InvalidReceiver();
        }
        _safeTransfer(msg.sender, to, tokenId, data);
    }

    function withdraw() public yoyoOnlyOwner {
        if (address(this).balance == 0) {
            revert YoyoNft__ContractBalanceIsZero();
        }
        uint256 contractBalance = address(this).balance;
        bool success = payable(i_owner).send(contractBalance);
        if (success) {
            emit YoyoNft__WithdrawCompleted(contractBalance, block.timestamp);
        } else {
            revert YoyoNft__WithdrawFailed();
        }
    }

    function deposit() public payable yoyoOnlyOwner {
        if (msg.value == 0) {
            revert YoyoNft__ValueCantBeZero();
        }
        emit YoyoNft__DepositCompleted(msg.value, block.timestamp);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        address nftOwner = s_requestIdToSender[_requestId];
        uint256 tokenId;
        uint256 candidateTokenId = (_randomWords[0] % MAX_NFT_SUPPLY);
        if (!s_tokensMinted[candidateTokenId]) {
            tokenId = candidateTokenId;
        } else {
            tokenId = findAvailableTokenId(candidateTokenId);
        }
        s_tokensMinted[tokenId] = true;
        s_tokenCounter++;

        _safeMint(nftOwner, tokenId);

        string memory tokenUri = string(
            abi.encodePacked(s_baseURI, "/", Strings.toString(tokenId), ".json")
        );
        s_tokenIdToUri[tokenId] = tokenUri;
        emit YoyoNft__TokenIdAssigned(tokenId, tokenUri);
    }

    function findAvailableTokenId(
        uint256 _candidateTokenId
    ) internal view returns (uint256) {
        uint256 startTokenId = (_candidateTokenId + 1) % MAX_NFT_SUPPLY;
        uint256 currentTokenId = startTokenId;
        for (uint256 i = 0; i < MAX_NFT_SUPPLY; i++) {
            if (!s_tokensMinted[currentTokenId]) {
                return currentTokenId;
            }
            currentTokenId = ((currentTokenId + 1) % MAX_NFT_SUPPLY);
        }
        revert YoyoNft__AllNFTsHaveBeenMinted();
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (tokenId < 0 || tokenId >= MAX_NFT_SUPPLY) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        if (s_tokensMinted[tokenId] == false) {
            revert YoyoNft__TokenNotMintedYet();
        }
        return s_tokenIdToUri[tokenId];
    }

    function getMyNFT() public view returns (uint256[] memory) {
        uint256 count = 0;
        uint256[] memory temporaryTokenIds = new uint256[](s_tokenCounter);

        for (uint256 tokenId = 0; tokenId <= MAX_NFT_SUPPLY; tokenId++) {
            if (s_tokensMinted[tokenId]) {
                try this.ownerOf(tokenId) returns (address owner) {
                    if (owner == msg.sender) {
                        temporaryTokenIds[count] = tokenId;
                        count++;
                    }
                } catch {
                    continue;
                }
            }
        }

        if (count == 0) {
            revert YoyoNft__YouAreNotAnNftOwner();
        }

        uint256[] memory finalTokenIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalTokenIds[i] = temporaryTokenIds[i];
        }
        return finalTokenIds;
    }

    function getTotalMinted() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintPriceEth() public view returns (uint256) {
        return s_mintPriceEth;
    }

    function getBaseURI() public view returns (string memory) {
        return s_baseURI;
    }

    function getSenderFromRequestId(
        uint256 requestId
    ) public view returns (address) {
        return s_requestIdToSender[requestId];
    }

    function getOwnerFromTokenId(
        uint256 tokenId
    ) public view returns (address) {
        return _ownerOf(tokenId);
    }

    function getAccountBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }
}
