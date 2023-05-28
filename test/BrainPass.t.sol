// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {stdError} from "forge-std/Errors.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract TestEditor is PRBTest, Cheats {
    BrainPassCollectibles BrainPass;
    address alice = vm.addr(0x2);
    address bob = vm.addr(0x3);
    address doe = vm.addr(0x4);
    MockERC20 mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock IQ Token", "MIT", 18); //mocking IQ token
        BrainPass = new BrainPassCollectibles(address(mockERC20));
        BrainPass.addPassType(15, "http://example.com/1", "Gold", 200, 0);
    }

    function testAddPassType() public {
        BrainPass.addPassType(15, "http://example.com/56", "Gold", 200, 0);
        string memory _name = BrainPass.getPassType(1).name;
        assertEq(_name, "Gold");
    }

    function testmintNFTWrong() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(0, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        vm.expectRevert(BrainPassCollectibles.AlreadyMintedThisPass.selector);
        BrainPass.mintNFT(0, 172800, 5184000);
        vm.stopPrank();
    }

    function testMintDurationNotInTimeFrame() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        vm.expectRevert(BrainPassCollectibles.DurationNotInTimeFrame.selector);
        BrainPass.mintNFT(0, 172800, 518400);
        vm.stopPrank();
    }

    function testmintNFT() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 3e18);
        vm.expectRevert(stdError.arithmeticError);
        BrainPass.mintNFT(0, 172800, 5184000);
        mockERC20.approve(address(BrainPass), 9000e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(0, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        assertEq(mockERC20.balanceOf(address(this)), 870e18);
        uint256 mintedPass = BrainPass.getUserPassDetails(alice, 0).passId;
        assertEq(mintedPass, 0);
        vm.stopPrank();
    }

    function testIncreaseTimeWrong() public {
        mockERC20.mint(alice, 3000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        BrainPass.mintNFT(0, 172800, 5184000);
        uint256 _tokenId = BrainPass.getUserPassDetails(alice, 0).tokenId;
        BrainPass.increaseEndTime(_tokenId, 8640000);
        vm.stopPrank();
        vm.startPrank(bob);
        vm.expectRevert(BrainPassCollectibles.NotTheOwnerOfThisNft.selector);
        BrainPass.increaseEndTime(_tokenId, 8640000);
    }

    function testIncreaseTime() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 12000e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(0, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        uint256 _tokenId = BrainPass.getUserPassDetails(alice, 0).tokenId;
        assertEq(_tokenId, 1);
        BrainPass.increaseEndTime(_tokenId, 8640000);
        assertEq(mockERC20.balanceOf(address(this)), 1470e18);
        BrainPass.addressToNFTPass(alice, _tokenId);
        uint _endTine = BrainPass.getUserPassDetails(alice, 0).endTimestamp;
        assertEq(_endTine, 8640000);
    }

    function testBaseTokenURI() public {
        assertEq(BrainPass.baseTokenURI(), "");
        BrainPass.setBaseURI("http://example.org.com/565");
        assertEq(BrainPass.baseTokenURI(), "http://example.org.com/565");
    }

    function testGetAllPassType() public {
        assertEq(BrainPass.getAllPassType().length, 1);
        BrainPass.addPassType(
            400,
            "http://example.com/56",
            "Platinum",
            3000,
            10
        );
        assertEq(BrainPass.getPassType(1).name, "Platinum");
        assertEq(BrainPass.getAllPassType().length, 2);
    }

    function testMintNftWrong() public {
        BrainPass.addPassType(15, "http://example.orgs", "OleanjiPass", 2, 0);
        mockERC20.mint(alice, 20000e18);
        mockERC20.mint(bob, 20000e18);
        mockERC20.mint(doe, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 1700e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        vm.stopPrank();
        vm.startPrank(bob);
        mockERC20.approve(address(BrainPass), 1700e18);
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(bob), 1);
        vm.stopPrank();
        vm.startPrank(doe);
        mockERC20.approve(address(BrainPass), 1700e18);
        vm.expectRevert(BrainPassCollectibles.PassMaxSupplyReached.selector);
        BrainPass.mintNFT(1, 172800, 5184000);
    }
}
