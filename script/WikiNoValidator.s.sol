// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";

import "../src/Wiki.sol";
import "../src/Validator/NoValidator.sol";

contract WikiNoValidator is Script {
    address constant owner = address(0xaCa39B187352D9805DECEd6E73A3d72ABf86E7A0);

    function run() external {
        vm.startBroadcast();

        console.log("Deploying WikiNoValidator....");
        NoValidator noValidator = new NoValidator();
        console.log("Novalidator Deployed", address(noValidator));

        console.log("Deploying Wiki contract....");
        Wiki wiki = new Wiki(address(noValidator));
        console.log("Wiki Deployed", address(wiki));

        wiki.setOwner(owner);

        vm.stopBroadcast();
    }
}
