// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {EditorValidator} from "../src/Validator/EditorValidator.sol";
import {EditorValidatorV2} from "../src/Validator/EditorValidatorV2.sol";

contract TestEditorValidator is PRBTest, Cheats {
    EditorValidator editorValidator;
    EditorValidatorV2 editorValidatorV2;
    address editor;

    function setUp() public {
        editorValidator = new EditorValidator();
        editorValidatorV2 = new EditorValidatorV2();
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
        assertEq(editorValidator.getRemainEditsCount(editor), 2);
        skip(14 hours);
        assertEq(editorValidator.getRemainEditsCount(editor), 5);
        for (uint256 i = 0; i < 5; i++) {
            editorValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        }
        assertEq(editorValidator.getRemainEditsCount(editor), 0);
        skip(1 days);
        assertEq(editorValidator.getRemainEditsCount(editor), 5);
    }

    function testIsEditorWhitelisted() public {
        vm.expectRevert(EditorValidatorV2.EditorNotWhitelisted.selector);
        editorValidatorV2.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
    }

    function testFailGetRemainEditsCount() public {
        editorValidatorV2.getRemainEditsCount(editor);
    }

    function testIsEditorWhitelistedWithoutRevert() public {
        editorValidatorV2.whitelistEditor(editor);
        editorValidatorV2.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        bool isWhitelisted = editorValidatorV2.isEditorWhitelisted(editor);
        assertEq(isWhitelisted, true);
    }
}
