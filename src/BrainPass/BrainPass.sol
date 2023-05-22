// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeMath} from "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title BRAIN Pass NFT
/// @author Oleanji
/// @notice A pass for IQ Wiki Editors

contract BrainPassCollectibles is ERC721, Owned {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error MintingPaymentFailed();

    /// -----------------------------------------------------------------------
    ///  Inheritances
    /// -----------------------------------------------------------------------
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------
    struct UserPassItem {
        uint256 tokenId;
        uint256 passId;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    struct PassType {
        uint256 passId;
        string passSlug;
        uint256 pricePerDays;
        string tokenURI;
        uint256 maxTokens;
        uint256 discount;
        uint256 lastTokenIdMinted;
    }

    /// -----------------------------------------------------------------------
    /// Mappings
    /// -----------------------------------------------------------------------
    mapping(uint256 => PassType) public passTypes;
    mapping(address => mapping(uint256 => UserPassItem))
        public addressToNFTPass;
    mapping(address => mapping(uint256 => bool)) public addressToPassId;

    /// -----------------------------------------------------------------------
    /// Constant
    /// -----------------------------------------------------------------------
    IERC20 public IqToken;

    /// -----------------------------------------------------------------------
    /// Variables
    /// -----------------------------------------------------------------------
    string public baseTokenURI;
    Counters.Counter private tokenIds;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(
        address IqAddr
    ) ERC721("BRAINY EDITOR PASS", "BEP") Owned(msg.sender) {
        IqToken = IERC20(IqAddr);
    }

    function baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory tokenURI) public onlyOwner {
        baseTokenURI = tokenURI;
    }

    /// @notice Add a new Pass Type
    /// @param passId and others are the details needed for a passType
    function addPassType(
        uint256 passId,
        uint256 pricePerDays,
        string memory tokenURI,
        string memory passSlug,
        uint256 maxTokens,
        uint256 discount
    ) public onlyOwner {
        require(bytes(tokenURI).length > 0, "Invalid token URI");
        require(maxTokens > 0, "Invalid max tokens");

        passTypes[passId] = PassType(
            passId,
            passSlug,
            pricePerDays,
            tokenURI,
            maxTokens,
            discount,
            0
        );

        emit NewPassAdded(passId, passSlug, maxTokens, pricePerDays);
    }

    /// @notice Mint and NFT of a particular passtype
    /// @param passIdNum The id of the passtype to mint
    function mintNFT(
        uint256 passIdNum,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) public payable {
        require(
            addressToPassId[msg.sender][passIdNum] != true,
            "Max NFTs per address reached"
        );

        PassType storage passType = passTypes[passIdNum];

        require(passType.maxTokens != 0, "Pass type not found");

        require(
            passType.lastTokenIdMinted.add(1) <= passType.maxTokens,
            "Max supply reached"
        );

        uint256 price = calculatePrice(passIdNum, startTimestamp, endTimestamp);
        require(msg.value >= price, "Not enough payment token");

        uint256 tokenId = passType.lastTokenIdMinted;
        bool success = IqToken.transfer(owner, price);
        if (!success) revert MintingPaymentFailed();

        setBaseURI(passType.tokenURI);
        _safeMint(msg.sender, tokenId);

        UserPassItem memory purchase = UserPassItem(
            tokenId,
            passIdNum,
            startTimestamp,
            endTimestamp
        );
        addressToPassId[msg.sender][passIdNum] = true;
        addressToNFTPass[msg.sender][tokenId] = purchase;
        passType.lastTokenIdMinted = tokenId += 1;

        emit BrainPassBought(msg.sender, tokenId, startTimestamp, endTimestamp);
    }

    /// @notice Calculate the price of an Nft
    /// @param startTimestamp and endTimestamp are used to calc the price to be paid
    function calculatePrice(
        uint256 passIdNum,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) public view returns (uint256) {
        PassType memory passType = passTypes[passIdNum];
        uint256 duration = endTimestamp.sub(startTimestamp);
        uint256 totalPrice = duration.mul(passType.pricePerDays);
        if (passType.discount > 0) {
            uint256 discountAmount = totalPrice.mul(passType.discount).div(100);
            totalPrice = totalPrice.sub(discountAmount);
        }

        return totalPrice;
    }

    /// @notice Increase the time to hold a PassNft
    /// @param tokenId The Id of the NFT whose time is to be increased
    function increasePassTime(
        uint256 tokenId,
        uint256 passIdNum,
        uint newStartTime,
        uint256 newEndTime
    ) public payable {
        require(
            msg.sender == ownerOf(tokenId),
            "You cannot increase the time for an NFT you don't own"
        );

        UserPassItem storage pass = addressToNFTPass[ownerOf(tokenId)][tokenId];
        uint256 price = calculatePrice(passIdNum, newStartTime, newEndTime);
        require(msg.value >= price, "Not enough payment token");

        pass.startTimestamp = newStartTime;
        pass.endTimestamp = newEndTime;

        emit TimeIncreased(
            msg.sender,
            tokenId,
            pass.startTimestamp,
            pass.endTimestamp
        );
    }

    /// @notice Gets all the NFT owned by an address
    /// @param user The address of the user
    function getUserNFTs(
        address user,
        uint passIdNum
    ) public view returns (UserPassItem[] memory) {
        uint256 userTokenCount = balanceOf(user);
        PassType memory passType = passTypes[passIdNum];
        UserPassItem[] memory userTokens = new UserPassItem[](userTokenCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < passType.maxTokens; i++) {
            if (ownerOf(i) == user) {
                userTokens[counter] = addressToNFTPass[msg.sender][i];
                counter++;
            }
        }
        return userTokens;
    }

    /// @notice Gets all the details of a passtype
    /// @param passId The id of the passtype
    function getAllPassType(
        uint256 passId
    ) public view returns (PassType memory) {
        PassType memory passType = passTypes[passId];
        return (passType);
    }

    /// @notice Withdraws any amount in the contract
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event BrainPassBought(
        address indexed _owner,
        uint256 _tokenId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    );

    event TimeIncreased(
        address indexed _owner,
        uint256 _tokenId,
        uint256 _startTimestamp,
        uint256 _newEndTimestamp
    );

    event NewPassAdded(
        uint256 indexed _passId,
        string _passSlug,
        uint256 _maxtokens,
        uint256 _pricePerDays
    );
}
