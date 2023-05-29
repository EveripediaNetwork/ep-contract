// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BrainPassCollectibles} from "./BrainPass.sol";

/// @title BRAIN Pass Validator
/// @author Oleanji
/// @notice A validation for the Nft
contract BrainPassValidiator {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------
    error UserDoesNotHaveAPass();
    error UserPassExpired();

    /// -----------------------------------------------------------------------
    /// variables
    /// -----------------------------------------------------------------------
    BrainPassCollectibles brainPass;

    constructor(address brainPassAddr) {
        brainPass = BrainPassCollectibles(brainPassAddr);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Validate Post
    /// @param user The user to validiate
    function validate(address user) external view returns (bool) {
        if (brainPass.balanceOf(user) <= 0) revert UserDoesNotHaveAPass();
        if (brainPass.getUserPassDetails(user).endTimestamp < block.timestamp) {
            revert UserPassExpired();
        }
        return true;
    }
}
