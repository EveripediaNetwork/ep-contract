// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract TestEditor is PRBTest, Cheats {
    BrainPassCollectibles internal brainPass;
    address private alice = address(0x2);
    address private doe = address(0x3);
    address private babe = address(0x4);
    MockERC20 private mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock Token", "MTN", 18);
        brainPass = new BrainPassCollectibles(address(mockERC20));
    }

    function testAddPassType() public {
        brainPass.addPassType(1, 15, "http://example.com/1", "Gold", 30, 0);
        brainPass.getAllPassType(1);
        assertEq(brainPass.getAllPassType(1).tokenURI, "http://example.com/1");
    }

    function testCalculatePrice() public {
        brainPass.addPassType(1, 2, "http://example.com/1", "Gold", 30, 0);
        brainPass.calculatePrice(1, 10, 20);
        assertEq(brainPass.calculatePrice(1, 10, 20), 20);
    }

    function testFailUserBalanceNotEnough() public {
        brainPass.addPassType(1, 2, "http://example.com/1", "Gold", 20, 0);
        vm.startPrank(alice);
        brainPass.mintNFT(1, 10, 20);
        vm.expectRevert("UserBalanceNotEnough");
        vm.stopPrank();
    }

    function testFailMintingPaymentFailed() public {
        brainPass.addPassType(1, 2, "http://example.com/1", "Gold", 20, 0);
        uint256 mintAmount = 1e18;
        mockERC20.mint(alice, mintAmount);
        vm.startPrank(alice);
        brainPass.mintNFT(1, 10, 20);
        vm.expectRevert("MintingPaymentFailed");
        vm.stopPrank();
    }

    function testmintNFT() public {
        brainPass.addPassType(1, 2, "http://example.com/1", "Gold", 20, 0);
        uint256 mintAmount = 10000e18;
        mockERC20.mint(alice, mintAmount);
        vm.startPrank(alice);
        brainPass.mintNFT(1, 10, 20);
        assertEq(brainPass.balanceOf(alice), 1);
        bool hasMinted = brainPass.addressToPassId(alice, 1);
        assertEq(hasMinted, true);
        vm.stopPrank();
    }

   
}
