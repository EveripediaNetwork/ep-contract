// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./IValidator.sol";

// set this to wiki as validator and it will check if user has editor NFT and has not more than 5 edits in last 24h . number of edits is settable
contract EditorValidator is IValidator {
    error WrongIPFSLength();

    // mapping of editors and edits / blocktimestamps in order of calculate how many edits in X period of time
    function validate(address _user, string calldata _ipfs) external returns (bool) {
        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true; // TODO: fix
    }
}
