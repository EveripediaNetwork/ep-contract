// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PRBTest} from "prb-test/PRBTest.sol";
import {Cheats} from "forge-std/Cheats.sol";
import {WhitelistValidator} from "../src/Validator/WhitelistValidator.sol";

contract TestEditorValidator is PRBTest, Cheats {
    WhitelistValidator whitelistValidator;
    address editor;

    function setUp() public {
        whitelistValidator = new WhitelistValidator();
        editor = vm.addr(0xBEEF);
    }

    function testIsEditorWhitelisted() public {
        vm.expectRevert(WhitelistValidator.EditorNotWhitelisted.selector);
        whitelistValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
    }

    function testIsEditorWhitelistedWithoutRevert() public {
        whitelistValidator.whitelistEditor(editor);
        whitelistValidator.validate(editor, "Qmb7Kc2r7oH6ff5VdvV97ynuv9uVNXPVppjiMvkGF98F6v");
        bool isWhitelisted = whitelistValidator.isEditorWhitelisted(editor);
        assertEq(isWhitelisted, true);
    }

    function testUnWhitelistEditor() public {
        whitelistValidator.whitelistEditor(editor);
        bool isWhitelisted = whitelistValidator.isEditorWhitelisted(editor);
        assertEq(isWhitelisted, true);

        //
        whitelistValidator.unWhitelistEditor(editor);
        bool wasDeleted = whitelistValidator.isEditorWhitelisted(editor);
        assertEq(wasDeleted, false);
    }
}
