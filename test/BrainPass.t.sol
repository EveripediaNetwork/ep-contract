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
    MockERC20 private mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock IQ Token", "MIT", 18); //mocking IQ token
        brainPass = new BrainPassCollectibles(address(mockERC20));
        brainPass.addPassType( 15, "http://example.com/1", "Gold", 200, 0);
    }

    function testAddPassType() public {
        brainPass.addPassType(15, "http://example.com/56", "Gold", 200, 0);
        string memory _name = brainPass.getPassType(1).name;
        assertEq(_name, "Gold");
    }

    function testmintNFT() public {
        mockERC20.mint(alice, 100e18);

        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 3e18);

        vm.expectRevert(stdError.arithmeticError);
        brainPass.mintNFT(1, 172800, 518400); 

  
        mockERC20.approve(address(brainPass), 60e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(1, 172800, 518400);
        assertEq(brainPass.balanceOf(alice), 1);
        bool hasMinted = brainPass.addressToPassId(alice, 1);
        assertEq(hasMinted, true);
        vm.stopPrank();
    }

    function testIncreaseTime() public {
        mockERC20.mint(alice, 200e18);

        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 120e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(1, 172800, 518400);
        assertEq(brainPass.balanceOf(alice), 1);
        
        uint256 _tokenId = brainPass.getUserPassDetails(alice, 1).tokenId;
        assertEq(_tokenId, 1);
        brainPass.increasePassTime(_tokenId, 518400, 864000);

        brainPass.addressToNFTPass(alice, _tokenId);
        uint _startTime = brainPass.getUserPassDetails(alice, 1).startTimestamp;
        assertEq(_startTime, 518400);
    }

    //todo : upgrade /downgrade after subscription has ended, Errors
}
