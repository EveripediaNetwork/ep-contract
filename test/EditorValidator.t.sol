// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {EditorValidator} from "../src/Validator/EditorValidator.sol";

// import "forge-std/console.sol";

contract TestEditorValidator is Test {
    EditorValidator editorValidator;
    address editor;

    function setUp() public {
        editorValidator = new EditorValidator();
        editor = vm.addr(0xBEEF);
    }

    function testValidate() public {
        for (uint256 i = 0; i < 5; i++) {
            editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        }
        skip(10 hours);
        vm.expectRevert(EditorValidator.ExceededEditLimit.selector);
        editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        skip(14 hours);
        for (uint256 i = 0; i < 5; i++) {
            editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        }
        vm.expectRevert(EditorValidator.ExceededEditLimit.selector);
        editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
    }

    function testGetRemainEditsCount() public {
        for (uint256 i = 0; i < 3; i++) {
            editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        }
        skip(10 hours);
        assertEq(editorValidator.getEditsCount(editor), 2);
        skip(14 hours);
        assertEq(editorValidator.getEditsCount(editor), 5);
        for (uint256 i = 0; i < 5; i++) {
            editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        }
        assertEq(editorValidator.getEditsCount(editor), 0);
        skip(1 days);
        assertEq(editorValidator.getEditsCount(editor), 5);
    }
}
