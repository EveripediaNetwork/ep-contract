// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BrainPassCollectibles} from "./BrainPass.sol";

/// @title BRAIN Pass Validator
/// @author Oleanji
/// @notice A validation for the Nft
contract BrainPassValidiator {

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
        if (brainPass.balanceOf(user) == 0) return false;
        if (brainPass.getUserPassDetails(user).endTimestamp < block.timestamp) {
            return false;
        }

        return true;
    }
}
