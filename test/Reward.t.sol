// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {Reward} from "src/Reward/Reward.sol";
import {RewardRenderer} from "src/Reward/RewardRenderer.sol";

contract TestReward is PRBTest, Cheats {
    Reward internal reward;
    RewardRenderer internal _renderer;

    function setUp() public {
        _renderer = new RewardRenderer();
        reward = new Reward("Reward NFT", "RDT", address(_renderer));
    }

    function testFailMintToZeroAddress() public {
        reward.mint(address(0), "the25thbamm.eth", "12 June 2022", 3);
    }

    function testMint() public {
        bool res = reward.mint(address(1), "the25thbamm.eth", "12 June 2022", 3);
        assertTrue(res);
    }

    function testTokenURI() public {
        reward.mint(address(1), "the25thbamm.eth", "12 June 2022", 3);
        string memory res = reward.tokenURI(1);
    }

    function testFailTrasferNft() public {
        reward.mint(address(1), "the25thbamm.eth", "12 June 2022", 3);
        reward.transferFrom(address(1), address(2), 1);
    }

    function testChangeRenderer() public {
        address _newRenderer = address(1234);
        bool res = reward.changeRenderer(_newRenderer);
        assertTrue(res);
        vm.expectRevert("Reward: Only the admin can change the renderer address");
        vm.startPrank(address(0xd3ad));
        reward.changeRenderer(_newRenderer);
        vm.stopPrank();
    }
}
