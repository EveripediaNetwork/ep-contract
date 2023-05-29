// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import "forge-std/console.sol";
import {stdError} from "forge-std/Errors.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";
import {BrainPassValidiator} from "../src/BrainPass/BrainPassValidator.sol";

contract BrainPassValidatorTest is PRBTest, Cheats {
    BrainPassCollectibles BrainPass;
    BrainPassValidiator brainPassValidator;
    address alice = vm.addr(0x2);
    address bob = vm.addr(0x3);
    MockERC20 mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock IQ Token", "MIT", 18); //mocking IQ token
        BrainPass = new BrainPassCollectibles(address(mockERC20));
        brainPassValidator = new BrainPassValidiator(address(BrainPass));
        BrainPass.addPassType(15e18, "http://example.com", "Gold", 200, 0);
    }

    function testPostWiki() public {
        vm.expectRevert(BrainPassValidiator.UserDoesNotHaveAPass.selector);
        brainPassValidator.validate(alice);
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 1700e18);
        BrainPass.mintNFT(1, 1685638993, 1693587793); // june 1st - sept 1st (3 months)
        vm.stopPrank();
        assertEq(brainPassValidator.validate(alice), true);
        skip(1685638993 + 7948800); //skipped from the start date till the end of the 3 months
        console.log(block.timestamp);
        vm.expectRevert(BrainPassValidiator.UserPassExpired.selector);
        brainPassValidator.validate(alice);
    }
}
