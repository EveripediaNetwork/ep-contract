// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../lib/forge-std/src/console.sol";

import "../src/Wiki.sol";
import "../src/Validator/NoValidator.sol";

contract WikiNoValidator is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy the Novalidator contract
        console.log("Deploying WikiNoValidator....");
        NoValidator noValidator = new NoValidator();
        console.log("Novalidator Deployed", address(noValidator));

        // Deploy the Wiki contract
        console.log("Deploying Wiki contract....");
        Wiki wiki = new Wiki(address(noValidator));
        console.log("Wiki Deployed", address(wiki));
        vm.stopBroadcast();
    }
}
