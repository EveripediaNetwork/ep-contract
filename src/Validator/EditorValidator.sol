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

    struct RecentEd {
        uint256 _edits;
        uint256[] _allEdits;
        mapping(uint256 => uint256) _editsByIndex;
    }
    mapping(address => RecentEd) public recentEdits;
    uint256 noOfEdits = 0;
    uint256 currentOldestIndex = 0;

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    // mapping of editors and edits / blocktimestamps in order of calculate how many edits in X period of time
    function validate(address _user, string calldata _ipfs)
        external
        returns (bool)
    {
        uint256 oldestTime = recentEdits[_user]._editsByIndex[
            currentOldestIndex
        ];

        if (noOfEdits < editLimit) {
            recentEdits[_user]._editsByIndex[noOfEdits] = uint256(
                block.timestamp
            );
            noOfEdits++;
        } else if (block.timestamp - oldestTime > 1 days) {
            recentEdits[_user]._editsByIndex[currentOldestIndex] = uint256(
                block.timestamp
            );
            if (currentOldestIndex == editLimit - 1) {
                currentOldestIndex = 0;
            } else {
                currentOldestIndex++;
            }
            noOfEdits = 1;
        } else {
            revert ExceededEditLimit();
        }

        // uint256 _index = recentEdits[_user]._editsByIndex[noOfEdits - 1];
        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }
}
