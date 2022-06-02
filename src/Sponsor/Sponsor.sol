// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "solmate/auth/Owned.sol";

/// @title Sponsor
/// @author kesar.eth
/// @notice A contract to sponsor wikis
contract Sponsor is Owned {

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() Owned(msg.sender) {
    }
}
