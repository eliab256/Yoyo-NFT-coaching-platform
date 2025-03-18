// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract YoyoNft is ERC721 {
    uint256 private s_tokenCounter;

    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("Yoyo Collection", "YOYO") {
        s_tokenCounter = 0;
    }
}
