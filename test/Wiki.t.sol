// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";

import "../src/Wiki.sol";
import "../src/Validator/NoValidator.sol";

contract TestWiki is Test {
    Wiki wiki;
    NoValidator noValidator;
    address editor;

    bytes32 private constant SIGNED_POST_TYPEHASH = 0x2786d465b1ae76a678938e05e206e58472f266dfa9f8534a71c3e35dc91efb45;

    function setUp() public {
        wiki = new Wiki(vm.addr(1));
        noValidator = new NoValidator();
        editor = vm.addr(0xBEEF);
    }

    function testWrongValidatorPost() public {
        vm.expectRevert();
        wiki.post("abcd");
    }

    function testNoValidatorPostWrongIPFS() public {
        wiki.setValidator(noValidator);
        vm.expectRevert(NoValidator.WrongIPFSLength.selector);
        wiki.post("abcd");
    }

    function testNoValidatorPostRightIPFS() public {
        wiki.setValidator(noValidator);
        wiki.post("Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
    }

    function testSetValidatorNotOwner() public {
        vm.prank(editor);
        vm.expectRevert("UNAUTHORIZED");
        wiki.setValidator(noValidator);
    }

    function testPostBySignRight() public {
        uint256 privateKey = 0xBEEF;
        string memory ipfs = "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v";
        uint256 _deadline = block.timestamp;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    wiki.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(SIGNED_POST_TYPEHASH, keccak256(bytes(ipfs)), editor, _deadline))
                )
            )
        );
        wiki.setValidator(noValidator);
        wiki.postBySig(ipfs, editor, _deadline, v, r, s);
    }

    function testPostBySignWrong() public {
        uint256 privateKey = 0xBEEF;
        string memory ipfs = "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v";
        uint256 _deadline = block.timestamp;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    wiki.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(SIGNED_POST_TYPEHASH, keccak256(bytes(ipfs)), vm.addr(0xCAFE), _deadline))
                )
            )
        );
        vm.expectRevert(Wiki.InvalidSignature.selector);
        wiki.postBySig(ipfs, editor, _deadline, v, r, s);
    }

    function testPostBySignExpired() public {
        uint256 privateKey = 0xBEEF;
        string memory ipfs = "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v";
        uint256 _deadline = block.timestamp - 1;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    wiki.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(SIGNED_POST_TYPEHASH, keccak256(bytes(ipfs)), editor, _deadline))
                )
            )
        );

        vm.expectRevert(Wiki.DeadlineExpired.selector);
        wiki.postBySig(ipfs, editor, _deadline, v, r, s);
    }
}
