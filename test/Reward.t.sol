// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";

import "src/Reward/Reward.sol";
import "src/Reward/RewardRenderer.sol";

import "../lib/forge-std/src/console.sol";

contract TestReward is Test {
    using stdStorage for StdStorage;
    Vm internal constant hevm = Vm(HEVM_ADDRESS);

    Reward internal reward;
    RewardRenderer internal _renderer;

    function setUp() public {
        _renderer = new RewardRenderer();
        reward = new Reward("Reward NFT", "RDT", address(_renderer));
    }

    function testTrue() public {
        assertTrue(true);
    }

    function testMint() public {
        bool res = reward.mint(address(1), "brokeWhale");
        assertTrue(res);
    }

    function testTokenURI() public {
        reward.mint(address(1), "brokeWhale.eth");
        string memory res = reward.tokenURI(1);
        console.log(res);
    }

    function testFailTrasferNft() public {
        reward.mint(address(1), "brokeWhale.eth");
        reward.transferFrom(address(1), address(2), 1);
    }
}
