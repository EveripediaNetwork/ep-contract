// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./IValidator.sol";
import "../../lib/forge-std/src/console.sol";

contract NoValidator is IValidator {
    error WrongIPFSLength();

    /// @notice Validate Post
    /// @param _user Creator of Post
    /// @param _ipfs The IPFS Hash
    function validate(address _user, string calldata _ipfs) external returns (bool) {
        bytes memory _ipfsBytes = bytes(_ipfs);
        console.log(_ipfsBytes.length);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }
}
