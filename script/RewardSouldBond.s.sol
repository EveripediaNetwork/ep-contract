// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";

import {Reward} from "../src/Reward/Reward.sol";
import {RewardRenderer} from "../src/Reward/RewardRenderer.sol";

contract RewardSoulBond is Script {
    address constant owner = address(0xaCa39B187352D9805DECEd6E73A3d72ABf86E7A0);
    function run() external {
        vm.startBroadcast();

        console.log("Deploying RewardRenderer contract....");
        RewardRenderer renderer = new RewardRenderer();
        console.log("RewardRenderer Deployed", address(renderer));

        console.log("Deploying RewardSouldBond....");
        Reward reward = new Reward("EPREWARD", "EPREWARD", address(renderer));
        console.log("Reward Deployed", address(reward));

        reward.setOwner(owner);

        vm.stopBroadcast();
    }
}
