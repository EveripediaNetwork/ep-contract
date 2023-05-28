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
    error AlreadyMintedThisPass();
    error NotTheOwnerOfThisNft();
    error InvalidMaxTokensForAPass();
    error PassTypeNotFound();
    error PassMaxSupplyReached();
    error NoEtherLeftToWithdraw();
    error TransferFailed();
    error DurationNotInTimeFrame();

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
    mapping(uint256 => mapping(address => UserPassItem)) internal ownerOfToken;

    /// -----------------------------------------------------------------------
    /// Constant
    /// -----------------------------------------------------------------------

    address public immutable iqToken;
    uint256 immutable SECONDS_IN_A_DAY = 86400;
    uint256 immutable DAYS_MINT_LOWER_LIMIT = 28;
    uint256 immutable DAYS_MINT_UPPER_LIMIT = 365;

    /// -----------------------------------------------------------------------
    /// Variables
    /// -----------------------------------------------------------------------

    string public baseTokenURI;
    Counters.Counter private passIdTracker;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    
    constructor(address IqAddr) ERC721("BAINPASS", "BEP") Owned(msg.sender) {
        iqToken = IqAddr;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Add a new Pass Type
    /// @param pricePerDay the price per day of the new pass type 
    /// @param tokenURI the link that stores the data of all the Nfts in the new pass
    /// @param name the name of the new pass type to be added
    /// @param maxTokens the total number of tokens in the pass
    /// @param discount the amount in % to be deducted when buying the pass
    function addPassType(
        uint256 pricePerDay,
        string memory tokenURI,
        string memory name,
        uint256 maxTokens,
        uint256 discount
    ) external onlyOwner {
        if (maxTokens <= 0) revert InvalidMaxTokensForAPass();
        uint256 passId = passIdTracker.current();
        passTypes[passId] = PassType(
            passId,
            name,
            pricePerDay,
            tokenURI,
            maxTokens,
            discount,
            0
        );
        passIdTracker.increment();
        emit NewPassAdded(passId, name, maxTokens, pricePerDay);
    }

    /// @notice Mint and NFT of a particular passtype
    /// @param passId The id of the passtype to mint
    /// @param startTimestamp The time when the NFT subcription time starts
    /// @param endTimestamp The time when the NFT subcription time ends
    function mintNFT(
        uint256 passId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external {
        if (getUserPassDetails(msg.sender, passId).tokenId != 0)
            revert AlreadyMintedThisPass();

        PassType storage passType = passTypes[passId];

        if (passType.maxTokens == 0) revert PassTypeNotFound();
        if (passType.lastTokenIdMinted >= passType.maxTokens)
            revert PassMaxSupplyReached();

        if (!validatePassDuration(startTimestamp, endTimestamp))
            revert DurationNotInTimeFrame();

        uint256 price = calculatePrice(passId, startTimestamp, endTimestamp);

        bool success = IERC20(iqToken).transferFrom(msg.sender, owner, price);
        if (!success) revert MintingPaymentFailed();

        uint256 tokenId = passType.lastTokenIdMinted + 1;
        UserPassItem memory purchase = UserPassItem(
            tokenId,
            passId,
            startTimestamp,
            endTimestamp
        );
        addressToNFTPass[msg.sender][tokenId] = purchase;
        ownerOfToken[passId][msg.sender] = purchase;
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
    /// @param newEndTime The new subcription endTime for the of the NFT
    function increaseEndTime(uint256 tokenId, uint256 newEndTime) external {
        UserPassItem memory pass = addressToNFTPass[msg.sender][tokenId];
        if (getUserPassDetails(msg.sender, pass.passId).tokenId != tokenId)
            revert NotTheOwnerOfThisNft();
        uint256 newStartTime;
        if (pass.endTimestamp < block.timestamp) {
            newStartTime = block.timestamp;
        } else {
            newStartTime = pass.endTimestamp;
        }

        if (!validatePassDuration(newStartTime, newEndTime))
            revert DurationNotInTimeFrame();

        uint256 price = calculatePrice(pass.passId, newStartTime, newEndTime);
        bool success = IERC20(iqToken).transferFrom(msg.sender, owner, price);
        if (!success) revert IncreseTimePaymentFailed();

        UserPassItem memory purchase = UserPassItem(
            pass.tokenId,
            pass.passId,
            pass.startTimestamp,
            newEndTime
        );

        addressToNFTPass[msg.sender][tokenId] = purchase;
        ownerOfToken[pass.passId][msg.sender] = purchase;

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
        if (balance <= 0) revert NoEtherLeftToWithdraw();
        (bool success, ) = (msg.sender).call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /// @notice Calculate the price of an Nft
    /// @param startTimestamp The start time to calculate the price of the Nft
    /// @param endTimestamp The end time to calculate the price of the Nft
    function calculatePrice(
        uint256 passId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal view returns (uint256) {
        PassType memory passType = passTypes[passId];
        uint256 subscriptionPeriodInSeconds = endTimestamp.sub(startTimestamp);

        uint256 subscriptionPeriodInDays = subscriptionPeriodInSeconds.div(
            SECONDS_IN_A_DAY
        );

        // Calculate the total price
        uint256 totalPrice = subscriptionPeriodInDays.mul(passType.pricePerDay);

        if (passType.discount > 0) {
            uint256 discountAmount = totalPrice.mul(passType.discount).div(100);
            totalPrice = totalPrice.sub(discountAmount);
        }

        return totalPrice * 1e18;
    }

    /// @notice Validates the Timestamp Duration for minting Nft
    /// @param startTimestamp The start time for checking the validity of a pass
    /// @param endTimestamp The end time for checking the validity of a pass
    function validatePassDuration(
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal pure returns (bool) {
        uint256 durationInDays = (endTimestamp.sub(startTimestamp)) /
            SECONDS_IN_A_DAY;
        return
            durationInDays >= DAYS_MINT_LOWER_LIMIT &&
            durationInDays <= DAYS_MINT_UPPER_LIMIT;
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice Gets all the NFT owned by an address
    /// @param user The address of the user
    /// @param passId The Id of the pass to get the user's info on
    function getUserPassDetails(
        address user,
        uint passId
    ) public view returns (UserPassItem memory) {
        UserPassItem memory userToken = ownerOfToken[passId][user];
        return userToken;
    }

    /// @notice Gets all the PassType created
    function getAllPassType() external view returns (PassType[] memory) {
        uint256 total = passIdTracker.current();
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

    /// @notice Sets the tokenURI where the NFT data is gotten
    /// @param tokenURI The tokenURI to be set
    function setBaseURI(string memory tokenURI) public {
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
