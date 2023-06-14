// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {BrainPassValidiator} from "../src/BrainPass/BrainPassValidator.sol";

contract BrainPassValidiatorDeployer is Script {
    function run() external {
        vm.startBroadcast();
        console.log("Deploying Brainpass Valdiator....");
        BrainPassValidiator brainPassValidator = new BrainPassValidiator(
            0x6e213cE219d7ef282ACCC7734040D67875828be4
        );
        console.log("Brainpass Deployed To", address(brainPassValidator));
        vm.stopBroadcast();
    }
}
