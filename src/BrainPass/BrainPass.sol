// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeMath} from "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @title BRAIN Pass NFT
/// @author Oleanji
/// @notice A pass for IQ Wiki Editors

contract BrainPassCollectibles is ERC721, Owned {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error MintingPaymentFailed();
    error IncreseTimePaymentFailed();
    error UserBalanceNotEnough();

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
        string name;
        uint256 pricePerDay;
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
    address public IqToken;
    uint256 SecondsInADay = 86400;

    /// -----------------------------------------------------------------------
    /// Variables
    /// -----------------------------------------------------------------------
    string public baseTokenURI;
    Counters.Counter private passIds;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(address IqAddr) ERC721("BAINPASS", "BEP") Owned(msg.sender) {
        IqToken = IqAddr;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Add a new Pass Type
    /// @param name and others are the details needed for a passType
    function addPassType(
        uint256 pricePerDay,
        string memory tokenURI,
        string memory name,
        uint256 maxTokens,
        uint256 discount
    ) external onlyOwner {
        require(bytes(tokenURI).length > 0, "Invalid token URI");
        require(maxTokens > 0, "Invalid max tokens");
        uint256 passId = passIds.current();
        passTypes[passId] = PassType(
            passId,
            name,
            pricePerDay,
            tokenURI,
            maxTokens,
            discount,
            0
        );

        passIds.increment();

        emit NewPassAdded(passId, name, maxTokens, pricePerDay);
    }

    /// @notice Mint and NFT of a particular passtype
    /// @param passId The id of the passtype to mint
    function mintNFT(
        uint256 passId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        require(
            addressToPassId[msg.sender][passId] != true,
            "Max NFTs per address reached"
        );

        PassType storage passType = passTypes[passId];

        require(passType.maxTokens != 0, "Pass type not found");

        require(
            passType.lastTokenIdMinted.add(1) <= passType.maxTokens,
            "Max supply reached"
        );

        uint256 price = calculatePrice(passId, startTimestamp, endTimestamp);

        bool success = IERC20(IqToken).transferFrom(msg.sender, owner, price);
        if (!success) revert MintingPaymentFailed();

        uint256 tokenId = passType.lastTokenIdMinted + 1;

        addressToPassId[msg.sender][passId] = true;
        UserPassItem memory purchase = UserPassItem(
            tokenId,
            passId,
            startTimestamp,
            endTimestamp
        );
        addressToNFTPass[msg.sender][tokenId] = purchase;
        passType.lastTokenIdMinted = tokenId;

        _safeMint(msg.sender, tokenId);
        setBaseURI(passType.tokenURI);

        emit BrainPassBought(
            msg.sender,
            tokenId,
            passId,
            startTimestamp,
            endTimestamp
        );
    }

    /// @notice Increase the time to hold a PassNft
    /// @param tokenId The Id of the NFT whose time is to be increased
    function increasePassTime(
        uint256 tokenId,
        uint newStartTime,
        uint256 newEndTime
    ) external {
        require(
            msg.sender == ownerOf(tokenId),
            "You cannot increase the time for an NFT you don't own"
        );

        UserPassItem storage pass = addressToNFTPass[msg.sender][tokenId];
        uint256 price = calculatePrice(pass.passId, newStartTime, newEndTime);

        bool success = IERC20(IqToken).transferFrom(msg.sender, owner, price);
        if (!success) revert IncreseTimePaymentFailed();

        pass.startTimestamp = newStartTime;
        pass.endTimestamp = newEndTime;

        emit TimeIncreased(
            msg.sender,
            tokenId,
            pass.startTimestamp,
            pass.endTimestamp
        );
    }

    /// @notice Withdraws any amount in the contract
    function withdraw() external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /// @notice Calculate the price of an Nft
    /// @param startTimestamp and endTimestamp are used to calc the price to be paid
    function calculatePrice(
        uint256 passId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal view returns (uint256) {
        PassType memory passType = passTypes[passId];
        uint256 duration = endTimestamp.sub(startTimestamp);

        uint256 subscriptionPeriodInDays = duration.div(SecondsInADay);

        // Calculate the total price
        uint256 totalPrice = subscriptionPeriodInDays.mul(passType.pricePerDay);

        if (passType.discount > 0) {
            uint256 discountAmount = totalPrice.mul(passType.discount).div(100);
            totalPrice = totalPrice.sub(discountAmount);
        }

        return totalPrice * 1e18;
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Gets all the NFT owned by an address
    /// @param user The address of the user
    function getUserPassDetails(
        address user,
        uint passId
    ) public view returns (UserPassItem memory) {
        PassType memory passType = passTypes[passId];
        UserPassItem memory userToken;
        for (uint256 i = 1; i < passType.maxTokens; i++) {
            if (ownerOf(i) == user) {
                userToken = addressToNFTPass[msg.sender][i];
                break;
            }
        }
        return userToken;
    }

    /// @notice Gets all the PassType created
    function getAllPassType() external view returns (PassType[] memory) {
        uint256 total = passIds.current();
        PassType[] memory passType = new PassType[](total);
        for (uint256 i = 0; i < total; i++) {
            passType[i] = passTypes[i];
        }
        return passType;
    }

    /// @notice Gets all the details of a passtype
    /// @param passId The id of the passtype
    function getPassType(
        uint256 passId
    ) external view returns (PassType memory) {
        PassType memory passType = passTypes[passId];
        return (passType);
    }

    /// -----------------------------------------------------------------------
    /// Setters
    /// -----------------------------------------------------------------------
    function setBaseURI(string memory tokenURI) internal {
        baseTokenURI = tokenURI;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event BrainPassBought(
        address indexed _owner,
        uint256 _passId,
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
        string _name,
        uint256 _maxtokens,
        uint256 _pricePerDay
    );
}
