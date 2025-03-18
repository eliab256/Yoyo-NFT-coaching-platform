// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {VRFConsumerBaseV2Plus, VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev";

contract YoyoNft is ERC721, VRFConsumerBaseV2Plus {
    //variables
    uint256 private s_tokenCounter;
    uint256 private constant maxNftSupply = 125;
    uint256 private constant minTokenId = 1;

    mapping(uint256 => string) private s_tokenIdToUri;

    //events

    //errors
    error YoyoNft__NotOwner();
    error YoyoNft__TokenIdDoesNotExist();

    //modifiers
    modifier onlyOwner() {
        if(msg.sender != owner){
            revert YoyoNft__NotOwner();
        }  _;
    }


    //functions
    constructor() ERC721("Yoyo Collection", "YOYO") {
        s_tokenCounter = 0;
    }

    function mintNft() public {}

    function tokenURI(uint256 tokenId) public view override returns (string memory){
         if (tokenId == 0 || tokenId > 125) {
            revert YoyoNft__TokenIdDoesNotExist();
        }
        return s_tokenIdToUri[tokenId];
    }
}
