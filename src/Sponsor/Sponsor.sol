// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {Owned} from "solmate/auth/Owned.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title Sponsor
/// @author kesar.eth
/// @notice A contract to sponsor wikis
contract Sponsor is Owned {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error WithdrawTransfer();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Sponsored(address indexed _from, string _ipfs, address _token, uint256 _amount);
    event withdraw(address indexed _to, address _token, uint256 _amount);

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() Owned(msg.sender) {
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Sponsor IPFS hash
    /// @param ipfs The IPFS Hash
    function sponsor(string calldata ipfs) payable external {
        emit Sponsored(msg.sender, ipfs, address(0), msg.value);
    }

    /// @notice Sponsor IPFS hash w ERC20
    /// @param ipfs The IPFS Hash
    function sponsorERC20(IERC20 token, uint256 amount, string calldata ipfs) external {
        require(token.transferFrom(msg.sender, address(this), amount));
        emit Sponsored(msg.sender, ipfs, address(token), amount);
    }

    /// @notice Withdraw sponsors
    /// @param payee The account to transfer
    function withdrawETH(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value : balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
        emit withdraw(payee, address(0), balance);
    }

    /// @notice Withdraw ERC20 sponsors
    /// @param payee The account to transfer
    function withdrawERC20(IERC20 token, uint256 amount, address payee) external onlyOwner {
        bool transferTx = token.transferFrom(address(this), payee, amount);
        if (!transferTx) {
            revert WithdrawTransfer();
        }
        emit withdraw(payee, address(token), amount);
    }
}
