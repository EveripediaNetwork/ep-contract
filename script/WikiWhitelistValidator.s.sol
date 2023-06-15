// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";

import {WhitelistValidator} from "../src/Validator/WhitelistValidator.sol";

contract WikiWhitelistValidator is Script {
    address constant owner = address(0xaCa39B187352D9805DECEd6E73A3d72ABf86E7A0);

    function run() external {
        vm.startBroadcast();

        console.log("Deploying WhitelistValidator....");
        WhitelistValidator validator = new WhitelistValidator();
        console.log("WhitelistValidator Deployed", address(validator));

        validator.whitelistEditor(address(0x704E3d9c38E339b15631C1bedd7aCfd476ADB7a6));
        validator.whitelistEditor(address(0x7da121Af2c3Fc2e65eDCD3573a403C352B4538Aa));
        validator.whitelistEditor(address(0x293c952ee0D8ae1cfe92Eaf8f6D020AE5D7d93be));
        validator.whitelistEditor(address(0xF6d9467758C08d05571f1bFa0a03A2286cE1F043));
        validator.whitelistEditor(address(0x2fE6aCD015384E1ee5138eF79fe1a434dA8FA12e));
        validator.whitelistEditor(address(0xb029c0367CCFeEFBc6D00B4cc22fcbFd6A781F5c));
        validator.whitelistEditor(address(0x9fEAB70f3c4a944B97b7565BAc4991dF5B7A69ff));
        validator.whitelistEditor(address(0x14B68b85E1037d1C75726b7794e99C20554f9CC3));
        validator.setOwner(owner);

        vm.stopBroadcast();
    }
}
