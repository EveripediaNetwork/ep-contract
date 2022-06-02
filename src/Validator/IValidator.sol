// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

interface IValidator {
    function validate(address _user, string calldata _ipfs) external returns (bool);
}
