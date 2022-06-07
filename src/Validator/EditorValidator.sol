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
    mapping(address => uint256[]) edits;
    uint256 count;

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    // mapping of editors and edits / blocktimestamps in order of calculate how many edits in X period of time
    function validate(address _user, string calldata _ipfs)
        external
        returns (bool)
    {
        // check if array is full
        if (edits[_user].length < 5) {
            edits[_user].push(uint256(block.timestamp)); // add new element to array
        } else if (edits[_user].length == 5) // check if array is full
        {
            // check if the oldest edit time is older than 1 day, #NOTE: the oldest edit time is the first element in the array
            if (block.timestamp - edits[_user][0] >= 1 days) {
                // shift the first element to the end of the array and reorder the array
                for (uint256 i = 0; i < edits[_user].length - 1; i++) {
                    edits[_user][i] = edits[_user][i + 1];
                }
                edits[_user].pop(); // remove the last element from the array, which is now the oldest edit time
                edits[_user].push(block.timestamp); // add the new edit time to the end of the array
            } else {
                revert ExceededEditLimit();
            }
        }

        // uint256 _index = recentEdits[_user]._editsByIndex[noOfEdits - 1];
        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }
}
