// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IValidator} from "./IValidator.sol";

contract EditorValidator is IValidator {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error WrongIPFSLength();
    error ExceededEditLimit();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    uint256 public editLimit = 5;

    struct Editor {
        uint256 _edits;
        uint256 _lastEdit;
    }
    /// @notice The amount of edits
    mapping(address => Editor) public edits;

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    // mapping of editors and edits / blocktimestamps in order of calculate how many edits in X period of time
    function validate(address _user, string calldata _ipfs)
        external
        returns (bool)
    {
        uint256 later = edits[_user]._lastEdit + 1 days;
        if (block.timestamp >= later) {
            edits[_user]._edits = 0;
            edits[_user]._lastEdit = block.timestamp;
        }

        require(edits[_user]._edits < editLimit, "ExceededEditLimit");
        edits[_user]._edits++;
        edits[_user]._lastEdit = block.timestamp;
        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }

        return true;
    }
}
