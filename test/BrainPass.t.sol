// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import "forge-std/console.sol";
import {stdError} from "forge-std/Errors.sol";
import {BrainPassCollectibles} from "../src/BrainPass/BrainPass.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {MockERC20} from "../lib/solmate/src/test/utils/mocks/MockERC20.sol";

contract BrainPassTest is PRBTest, Cheats {
    BrainPassCollectibles BrainPass;
    address alice = vm.addr(0x2);
    address bob = vm.addr(0x3);
    address doe = vm.addr(0x4);
    address sam = vm.addr(0x1);
    MockERC20 mockERC20;

    function setUp() public {
        mockERC20 = new MockERC20("Mock IQ Token", "MIT", 18); //mocking IQ token
        BrainPass = new BrainPassCollectibles(
            address(mockERC20),
            "http://example.com/"
        );
        BrainPass.addPassType(15e18, "Gold", 200, 0);
    }

    function testAddPassType() public {
        BrainPass.addPassType(15e18, "Gold", 200, 0);
        string memory _name = BrainPass.getPassType(1).name;
        assertEq(_name, "Gold");
    }

    function testmintNFTWrong() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        vm.expectRevert(BrainPassCollectibles.AlreadyMintedAPass.selector);
        BrainPass.mintNFT(1, 172800, 5184000);
        vm.stopPrank();
    }

    function testMintDurationNotInTimeFrame() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        vm.expectRevert(BrainPassCollectibles.DurationNotInTimeFrame.selector);
        BrainPass.mintNFT(1, 172800, 518400);
        vm.stopPrank();
    }

    function testInvalidMaxTokensForAPass() public {
        vm.expectRevert(
            BrainPassCollectibles.InvalidMaxTokensForAPass.selector
        );
        BrainPass.addPassType(15e18, "OleanjiPass", 0, 0);
    }

    function testPassTypeNotFound() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        vm.expectRevert(BrainPassCollectibles.PassTypeNotFound.selector);
        BrainPass.mintNFT(4, 172800, 5184000);
    }

    function testCannotMintPausedPass() public {
        BrainPass.togglePassTypeStatus(1);
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        vm.expectRevert(BrainPassCollectibles.PassTypeIsPaused.selector);
        BrainPass.mintNFT(1, 172800, 5184000);
    }

    function testmintNFT() public {
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 3e18);
        vm.expectRevert(stdError.arithmeticError);
        BrainPass.mintNFT(1, 172800, 5184000);
        mockERC20.approve(address(BrainPass), 9000e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        assertEq(mockERC20.balanceOf(address(BrainPass)), 870e18);
        uint256 mintedPass = BrainPass.getUserPassDetails(alice).tokenId;
        assertEq(mintedPass, 1);
        vm.stopPrank();
    }

    function testDifferentPassMint() public {
        BrainPass.addPassType(15e18, "OleanjiPass", 2, 0);
        BrainPass.addPassType(15e18, "KesarPass", 2, 0);
        mockERC20.mint(alice, 20000e18);
        mockERC20.mint(doe, 20000e18);

        mockERC20.mint(bob, 20000e18);

        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 20000e18);
        BrainPass.mintNFT(1, 172800, 5184000);
        uint256 firstId = BrainPass.getUserPassDetails(alice).tokenId;
        assertEq(BrainPass.tokenURI(firstId), "http://example.com/1");
        console.log(BrainPass.tokenURI(firstId), firstId);
        vm.stopPrank();
        vm.startPrank(doe);
        mockERC20.approve(address(BrainPass), 20000e18);
        BrainPass.mintNFT(2, 172800, 5184000);
        uint256 newId = BrainPass.getUserPassDetails(doe).tokenId;
        assertEq(BrainPass.tokenURI(newId), "http://example.com/2");
        console.log(BrainPass.tokenURI(newId), newId);
        vm.stopPrank();
        vm.startPrank(bob);
        mockERC20.approve(address(BrainPass), 20000e18);
        BrainPass.mintNFT(3, 172800, 5184000);
        uint256 newIds = BrainPass.getUserPassDetails(bob).tokenId;
        assertEq(BrainPass.tokenURI(newIds), "http://example.com/3");
        console.log(BrainPass.tokenURI(newIds), newIds);
        uint256 mintedPass = BrainPass.getUserPassDetails(doe).tokenId;
        console.log(BrainPass.balanceOf(alice));
        assertEq(mintedPass, 2);
        vm.stopPrank();
    }

    function testIncreaseTimeWrong() public {
        mockERC20.mint(alice, 3000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 9000e18);
        BrainPass.mintNFT(1, 172800, 5184000);
        uint256 _tokenId = BrainPass.getUserPassDetails(alice).tokenId;
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
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        uint256 _tokenId = BrainPass.getUserPassDetails(alice).tokenId;
        assertEq(_tokenId, 1);
        BrainPass.increaseEndTime(_tokenId, 8640000);
        assertEq(mockERC20.balanceOf(address(BrainPass)), 1470e18);
        BrainPass.getUserPassDetails(alice);
        uint _endTine = BrainPass.getUserPassDetails(alice).endTimestamp;
        assertEq(_endTine, 8640000);
    }

    function testGetAllPassType() public {
        assertEq(BrainPass.getAllPassType().length, 2);
        BrainPass.addPassType(400e18, "Platinum", 3000, 10);
        assertEq(BrainPass.getPassType(2).name, "Platinum");
        assertEq(BrainPass.getAllPassType().length, 3);
    }

    function testMintNftWrong() public {
        BrainPass.addPassType(15e18, "OleanjiPass", 2, 0);
        mockERC20.mint(alice, 20000e18);
        mockERC20.mint(bob, 20000e18);
        mockERC20.mint(doe, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 1700e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(2, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        vm.stopPrank();
        vm.startPrank(bob);
        mockERC20.approve(address(BrainPass), 1700e18);
        BrainPass.mintNFT(2, 172800, 5184000);
        assertEq(BrainPass.balanceOf(bob), 1);
        vm.stopPrank();
        vm.startPrank(doe);
        mockERC20.approve(address(BrainPass), 1700e18);
        vm.expectRevert(BrainPassCollectibles.PassMaxSupplyReached.selector);
        BrainPass.mintNFT(2, 172800, 5184000);
    }

    function testWithdrawTokens() public {
        vm.expectRevert(BrainPassCollectibles.IQNotEnoughToWithdraw.selector);
        BrainPass.withdrawIQ(alice, 200e18);
        assertEq(mockERC20.balanceOf(address(BrainPass)), 0);
        mockERC20.mint(address(BrainPass), 20000e18);
        assertEq(mockERC20.balanceOf(address(BrainPass)), 20000e18);
        vm.expectRevert(
            BrainPassCollectibles.EtherNotEnoughToWithdraw.selector
        );
        BrainPass.withdrawEther(alice, 200e18);
    }

    function testConfigureMintLimit() public {
        assertEq(BrainPass.MINT_LOWER_LIMIT(), 28);
        assertEq(BrainPass.MINT_UPPER_LIMIT(), 365);
        BrainPass.configureMintLimit(50, 730);
        assertEq(BrainPass.MINT_LOWER_LIMIT(), 50);
        assertEq(BrainPass.MINT_UPPER_LIMIT(), 730);
    }

    function testPauseAndUnPauseContract() public {
        BrainPass.pause();
        vm.startPrank(alice);
        vm.expectRevert("Pausable: paused");
        BrainPass.mintNFT(1, 172800, 5184000);
        vm.stopPrank();
        BrainPass.unpause();
        mockERC20.mint(alice, 20000e18);
        vm.startPrank(alice);
        mockERC20.approve(address(BrainPass), 19700e18);
        assertEq(BrainPass.balanceOf(alice), 0);
        BrainPass.mintNFT(1, 172800, 5184000);
        assertEq(BrainPass.balanceOf(alice), 1);
        BrainPass.safeTransferFrom(alice, bob, 1);
        assertEq(BrainPass.balanceOf(bob), 1);
    }
}
