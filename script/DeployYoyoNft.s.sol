// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {YoyoNft} from "../src/YoyoNFT.sol";

contract DeployYoyoNft is Script {
    YoyoNft public yoyoNft;

    function setUp() public {}

    function run() external returns (YoyoNft) {
        vm.startBroadcast();
        yoyoNft = new YoyoNft();
        vm.stopBroadcast();

        return yoyoNft;
    }
}
