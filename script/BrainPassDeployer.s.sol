// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";

import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";


contract BrainPassDeployer is Script {
    address constant owner = address(0xE161eB85f00eC6471E0de06bA1Cfc136C053fFfe);

    function run() external {
        vm.startBroadcast();

        console.log("Deploying Brainpass deployer....");
        BrainPassCollectibles validator = new BrainPassCollectibles(0x5E959c60f86D17fb7D764AB69B654227d464E820);
        console.log("Brainpass Deployed", address(validator));

        vm.stopBroadcast();
    }
}
