// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import "forge-std/console.sol";
import {stdError} from "forge-std/Errors.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract TestEditor is PRBTest, Cheats {
    BrainPassCollectibles internal brainPass;
    address private alice = address(0x2);
    address private doe = address(0x3);
    address private babe = address(0x4);
    MockERC20 private mockERC20;

    struct PassType {
        uint256 passId;
        string name;
        uint256 pricePerMonth;
        string tokenURI;
        uint256 maxTokens;
        uint256 discount;
        uint256 lastTokenIdMinted;
    }

    struct UserPassItem {
        uint256 tokenId;
        uint256 passId;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    function setUp() public {
        mockERC20 = new MockERC20("Mock Token", "MTN", 18);
        brainPass = new BrainPassCollectibles(address(mockERC20));
        brainPass.addPassType(1, 15, "http://example.com/1", "Gold", 20, 0);
    }

    function testAddPassType() public {
        brainPass.getAllPassType(1);
        assertEq(brainPass.getAllPassType(1).tokenURI, "http://example.com/1");
    }

    function testmintNFT() public {
        mockERC20.mint(alice, 10);

        vm.startPrank(alice);

        mockERC20.approve(address(brainPass), 3e18);
        vm.expectRevert(stdError.arithmeticError);
        brainPass.mintNFT(1, 5184000, 18144000);

        mockERC20.mint(alice, 4e18);
        brainPass.mintNFT(1, 5184000, 18144000);
        assertEq(brainPass.balanceOf(alice), 1);
        bool hasMinted = brainPass.addressToPassId(alice, 1);
        assertEq(hasMinted, true);
        vm.stopPrank();
    }

    function testIncreaseTime() public {
        mockERC20.mint(alice, 3e18);

        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 5e18);
        brainPass.mintNFT(1, 5184000, 18144000);

        // brainPass.getUserPassDetails(alice, 1);
        // console.log(brainPass.getUserPassDetails(alice, 1).tokenId);
        // brainPass.increasePassTime(
        //     brainPass.getUserPassDetails(alice, 1).tokenId,
        //     18144000,
        //     20736000
        // );

        // brainPass.addressToNFTPass(
        //     alice,
        //     brainPass.getUserPassDetails(alice, 1).tokenId
        // );
        // uint _satTime = brainPass.getUserPassDetails(alice, 1).startTimestamp;
        // assertEq(_satTime, 30);
    }
}
