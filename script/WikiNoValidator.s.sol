// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Wiki.sol";
import "../src/Validator/NoValidator.sol";

contract WikiNoValidator is Script {
    function run() external {
        vm.startBroadcast();

        // NFT nft = new NFT("NFT_tutorial", "TUT", "baseUri");
        NoValidator noValidator = new NoValidator();

        vm.stopBroadcast();
    }
}
