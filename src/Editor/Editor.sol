// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Strings} from "../Utils/Strings.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Editor is ERC721, Owned {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error MintPriceNotPaid();
    error MaxSupply();
    error NonExistentTokenURI();
    error WithdrawTransfer();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    uint256 public TOTAL_SUPPLY = 9999;
    uint256 public constant PRICE_PER_MINT = 0.08 ether;
    uint256 public currentTokenId;
    string public baseURI;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) ERC721(name, symbol) Owned(msg.sender) {
        baseURI = _baseURI;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function mintTo(address recipient) public payable returns (uint256) {
        if (msg.value != PRICE_PER_MINT) {
            revert MintPriceNotPaid();
        }
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) {
            revert MaxSupply();
        }
        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    function increaseTotalSupply(uint256 amount) public onlyOwner {
        TOTAL_SUPPLY += amount;
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) revert NonExistentTokenURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
                : "";
    }
}
