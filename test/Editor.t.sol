// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {stdStorage, StdStorage} from "forge-std/Storage.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {Editor, ERC721TokenReceiver} from "src/Editor/Editor.sol";

contract TestEditor is PRBTest, Cheats {
    using stdStorage for StdStorage;

    StdStorage private stdstore;
    Editor internal editor;

    function setUp() public {
        editor = new Editor("Editor NFT", "EDT", "http://example.com/");
    }

    function testFailNoMintPricePaid() public {
        editor.mintTo(address(1));
    }

    function testMintPricePaid() public {
        editor.mintTo{value: 0.08 ether}(address(1));
    }

    function testTokenURI() public {
        editor.mintTo{value: 0.08 ether}(address(1));

        assertEq(editor.tokenURI(1), "http://example.com/1");
        editor.mintTo{value: 0.08 ether}(address(1));

        assertEq(editor.tokenURI(2), "http://example.com/2");
    }

    function testFailMaxSupplyReached() public {
        uint256 slot =
            stdstore.target(address(editor)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(10000));
        vm.store(address(editor), loc, mockedCurrentTokenId);
        editor.mintTo{value: 0.08 ether}(address(1));
    }

    function testFailMintToZeroAddress() public {
        editor.mintTo{value: 0.08 ether}(address(0));
    }

    function testNewMintOwnerRegistered() public {
        editor.mintTo{value: 0.08 ether}(address(1));
        uint256 slotOfNewOwner = stdstore.target(address(editor)).sig(
            editor.ownerOf.selector
        ).with_key(1).find();

        uint160 ownerOfTokenIdOne = uint160(
            uint256((vm.load(address(editor), bytes32(abi.encode(slotOfNewOwner)))))
        );
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        editor.mintTo{value: 0.08 ether}(address(1));
        uint256 slotBalance = stdstore.target(address(editor)).sig(
            editor.balanceOf.selector
        ).with_key(address(1)).find();

        uint256 balanceFirstMint =
            uint256(vm.load(address(editor), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        editor.mintTo{value: 0.08 ether}(address(1));
        uint256 balanceSecondMint =
            uint256(vm.load(address(editor), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testIncreaseTotalSupply(uint256 amount) public {
        if (amount > editor.TOTAL_SUPPLY()) return;
        uint256 prevSupply = editor.TOTAL_SUPPLY();
        editor.increaseTotalSupply(amount);
        assertEq(editor.TOTAL_SUPPLY(), prevSupply + amount);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        editor.mintTo{value: 0.08 ether}(address(receiver));
        uint256 slotBalance = stdstore.target(address(editor)).sig(
            editor.balanceOf.selector
        ).with_key(address(receiver)).find();

        uint256 balance =
            uint256(vm.load(address(editor), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    function testFailUnSafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        editor.mintTo{value: 0.08 ether}(address(1));
    }

    function testWithdrawalWorksAsOwner() public {
        // Mint an NFT, sending eth to the contract
        Receiver receiver = new Receiver();
        address payable payee = payable(address(0x1337));
        uint256 priorPayeeBalance = payee.balance;
        editor.mintTo{value: editor.PRICE_PER_MINT()}(address(receiver));
        // Check that the balance of the contract is correct
        assertEq(address(editor).balance, editor.PRICE_PER_MINT());
        uint256 nftBalance = address(editor).balance;
        // Withdraw the balance and assert it was transferred
        editor.withdrawPayments(payee);
        assertEq(payee.balance, priorPayeeBalance + nftBalance);
    }

    function testWithdrawalFailsAsNotOwner() public {
        // Mint an NFT, sending eth to the contract
        Receiver receiver = new Receiver();
        editor.mintTo{value: editor.PRICE_PER_MINT()}(address(receiver));
        // Check that the balance of the contract is correct
        assertEq(address(editor).balance, editor.PRICE_PER_MINT());
        // Confirm that a non-owner cannot withdraw
        vm.expectRevert("UNAUTHORIZED");
        vm.startPrank(address(0xd3ad));
        editor.withdrawPayments(payable(address(0xd3ad)));
        vm.stopPrank();
    }
}

contract Receiver is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
