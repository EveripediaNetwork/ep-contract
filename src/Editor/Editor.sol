// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;
// transferable nft user needs this nft to create wikis

import "../LilOwnable.sol";
import "../Strings.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/auth/Owned.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract Editor is ERC721, Owned {
    uint256 public TOTAL_SUPPLY = 9999;
    uint256 public constant PRICE_PER_MINT = 0.08 ether;
    uint256 public currentTokenId;
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI
    ) payable ERC721(name, symbol) Owned(msg.sender) {
        baseURI = _baseURI;
    }

    // function mint(uint16 amount) external payable {
    //     if (currentTokenId + amount >= TOTAL_SUPPLY) revert NoTokensLeft();
    //     if (msg.value < amount * PRICE_PER_MINT) revert NotEnoughETH();

    //     unchecked {
    //         for (uint16 index = 0; index < amount; index++) {
    //             _mint(msg.sender, currentTokenId++);
    //         }
    //     }
    // }

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

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }
}
