// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";

import "src/Wiki.sol";

contract TestWiki is Test {
    Wiki w;

    function setUp() public {
        w = new Wiki();
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }
}
