// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";

contract BrainPassMinter is Script {
    address constant owner = address(0xaCa39B187352D9805DECEd6E73A3d72ABf86E7A0);

    function run() external {
        vm.startBroadcast();


        vm.stopBroadcast();
    }
}
