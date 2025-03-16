// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";

contract YoyoNftScript is Script {
    YoyoNft public yoyoNft;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        yoyoNft = new YoyoNft();

        vm.stopBroadcast();
    }
}
