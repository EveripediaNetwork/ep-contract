// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IValidator} from "./IValidator.sol";
import "../Utils/DateTime.sol";

// set this to wiki as validator and it will check if user has editor NFT and has not more than 5 edits in last 24h . number of edits is settable

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // This holds in all cases
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EditorValidator is IValidator {
    using SafeMath for uint256; // use the library for uint type
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
        if (edits[_user]._lastEdit > block.timestamp.sub(86400)) {
            edits[_user]._edits = 0;
            edits[_user]._lastEdit = block.timestamp;
        }

        // require(
        //     edits[_user]._lastEdit < uint256(block.timestamp).sub(86400),
        //     "time"
        // );

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
