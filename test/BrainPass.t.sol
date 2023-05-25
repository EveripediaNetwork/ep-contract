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
    address private bob = address(0x3);
    address private doe = address(0x4);
    MockERC20 private mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock IQ Token", "MIT", 18); //mocking IQ token
        brainPass = new BrainPassCollectibles(address(mockERC20));
        brainPass.addPassType(15, "http://example.com/1", "Gold", 200, 0);
    }

    function testAddPassType() public {
        brainPass.addPassType(15, "http://example.com/56", "Gold", 200, 0);
        string memory _name = brainPass.getPassType(1).name;
        assertEq(_name, "Gold");
    }

    function testFailMintNFT() public {
        mockERC20.mint(alice, 300e18);
        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 120e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(0, 172800, 518400);
        assertEq(brainPass.balanceOf(alice), 1);
        brainPass.mintNFT(0, 172800, 518400);
        vm.expectRevert("AlreadyMintedThisPass");
    }

    function testmintNFT() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 3e18);
        vm.expectRevert(stdError.arithmeticError);
        brainPass.mintNFT(0, 172800, 5184000);
        mockERC20.approve(address(brainPass), 9000e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(0, 172800, 5184000);
        assertEq(brainPass.balanceOf(alice), 1);
        assertEq(mockERC20.balanceOf(address(this)), 870e18);
        uint256 mintedPass = brainPass.getUserPassDetails(alice, 0).passId;
        assertEq(mintedPass, 0);
        vm.stopPrank();
    }

    function testFailIncreaseTime() public {
        mockERC20.mint(alice, 300e18);
        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 120e18);
        brainPass.mintNFT(0, 172800, 518400);
        uint256 _tokenId = brainPass.getUserPassDetails(alice, 0).tokenId;
        brainPass.increaseEndTime(_tokenId, 864000);
        vm.startPrank(bob);
        brainPass.increaseEndTime(_tokenId, 864000);
        vm.expectRevert("NotTheOwnerOfThisNft");
    }

    function testIncreaseTime() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 12000e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(0, 172800, 5184000);
        assertEq(brainPass.balanceOf(alice), 1);
        uint256 _tokenId = brainPass.getUserPassDetails(alice, 0).tokenId;
        assertEq(_tokenId, 1);
        brainPass.increaseEndTime(_tokenId, 8640000);
        console.log(mockERC20.balanceOf(address(this)));
        assertEq(mockERC20.balanceOf(address(this)), 1470e18);
        brainPass.addressToNFTPass(alice, _tokenId);
        uint _endTine = brainPass.getUserPassDetails(alice, 0).endTimestamp;
        assertEq(_endTine, 8640000);
    }

    function testBaseTokenURI() public {
        assertEq(brainPass.baseTokenURI(), "");
        brainPass.setBaseURI("http://example.org.com/565");
        assertEq(brainPass.baseTokenURI(), "http://example.org.com/565");
    }

    function testGetAllPassType() public {
        assertEq(brainPass.getAllPassType().length, 1);
        brainPass.addPassType(
            400,
            "http://example.com/56",
            "Platinum",
            3000,
            10
        );
        assertEq(brainPass.getPassType(1).name, "Platinum");
        assertEq(brainPass.getAllPassType().length, 2);
    }

    function testFailPassMaxSupplyReached() public {
        brainPass.addPassType(15, "http://example.orgs", "OleanjiPass", 2, 0);
        mockERC20.mint(alice, 20000e18);
        mockERC20.mint(bob, 20000e18);
        mockERC20.mint(doe, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(brainPass), 1700e18);
        assertEq(brainPass.balanceOf(alice), 0);
        brainPass.mintNFT(1, 172800, 5184000);
        assertEq(brainPass.balanceOf(alice), 1);
        vm.stopPrank();
        vm.startPrank(bob);
        mockERC20.approve(address(brainPass), 1700e18);
        brainPass.mintNFT(1, 172800, 5184000);
        assertEq(brainPass.balanceOf(bob), 1);
        vm.stopPrank();
        vm.startPrank(doe);
        mockERC20.approve(address(brainPass), 1700e18);

        brainPass.mintNFT(1, 172800, 5184000);
        vm.expectRevert("PassMaxSupplyReached()");
    }
}
