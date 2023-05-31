// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Counters} from "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import {Wiki} from "../../src/Wiki.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title BRAIN Pass NFT
/// @author Oleanji
/// @notice A pass for IQ Wiki Editors

contract BrainPassCollectibles is ERC721, Pausable, Ownable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error MintingPaymentFailed();
    error IncreseTimePaymentFailed();
    error AlreadyMintedAPass();
    error NotTheOwnerOfThisNft();
    error InvalidMaxTokensForAPass();
    error PassTypeNotFound();
    error PassMaxSupplyReached();
    error NoEtherLeftToWithdraw();
    error TransferFailed();
    error DurationNotInTimeFrame();
    error CannotMintPausedPassType();
    error NoIQLeftToWithdraw();

    /// -----------------------------------------------------------------------
    ///  Inheritances
    /// -----------------------------------------------------------------------
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
        uint256 maxTokens;
        uint256 discount;
        uint256 lastMintedId;
        bool isPaused;
    }

    /// -----------------------------------------------------------------------
    /// Mappings
    /// -----------------------------------------------------------------------

    mapping(uint256 => PassType) public passTypes;
    mapping(address => UserPassItem) public addressToNFTPass;

    /// -----------------------------------------------------------------------
    /// Constant
    /// -----------------------------------------------------------------------

    address public iqToken;

    /// -----------------------------------------------------------------------
    /// Variables
    /// -----------------------------------------------------------------------

    Counters.Counter private passIdTracker;
    Counters.Counter private tokenIdTracker;
    uint256 public MINT_LOWER_LIMIT = 28;
    uint256 public MINT_UPPER_LIMIT = 365;
    string public baseTokenURI;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        address IqAddr,
        string memory _baseTokenURI
    ) ERC721("BAINPASS", "BEP") {
        iqToken = IqAddr;
        passIdTracker.increment();
        tokenIdTracker.increment();
        setBaseURI(_baseTokenURI);
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Change the MintLimit for the Nfts
    /// @param lowerLimit the new lower limit for how short a nft can be subscribed for
    /// @param upperLimit  the new upper limit for how long a nft can be subscribed for
    function configureMintLimit(
        uint256 lowerLimit,
        uint256 upperLimit
    ) external onlyOwner {
        MINT_UPPER_LIMIT = upperLimit;
        MINT_LOWER_LIMIT = lowerLimit;
    }

    /// @notice Add a new Pass Type
    /// @param pricePerDay the price per day of the new pass type
    /// @param name the name of the new pass type to be added
    /// @param maxTokens the total number of tokens in the pass
    /// @param discount the amount in % to be deducted when buying the pass
    function addPassType(
        uint256 pricePerDay,
        string memory name,
        uint256 maxTokens,
        uint256 discount
    ) external onlyOwner whenNotPaused {
        if (maxTokens <= 0) revert InvalidMaxTokensForAPass();
        uint256 passId = passIdTracker.current();
        passTypes[passId] = PassType(
            passId,
            name,
            pricePerDay,
            maxTokens,
            discount,
            0,
            false
        );
        passIdTracker.increment();
        emit NewPassAdded(passId, name, maxTokens, pricePerDay);
    }

    /// @notice Toggles the staus of a pass type (paused or unpaused)
    /// @param passId the Id of the pass
    function togglePassTypeStatus(
        uint256 passId
    ) external onlyOwner whenNotPaused {
        if (passId >= passIdTracker.current()) revert PassTypeNotFound();
        PassType storage passType = passTypes[passId];
        bool newStatus = !passType.isPaused;

        passTypes[passId] = PassType(
            passType.passId,
            passType.name,
            passType.pricePerDay,
            passType.maxTokens,
            passType.discount,
            passType.lastMintedId,
            newStatus
        );

        emit PassTypeStatusToggled(passId, passType.name);
    }

    /// @notice Mint and NFT of a particular passtype
    /// @param passId The id of the passtype to mint
    /// @param startTimestamp The time when the NFT subcription time starts
    /// @param endTimestamp The time when the NFT subcription time ends
    function mintNFT(
        uint256 passId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) external whenNotPaused {
        if (passId >= passIdTracker.current()) revert PassTypeNotFound();
        if (addressToNFTPass[msg.sender].tokenId != 0)
            revert AlreadyMintedAPass();
        PassType storage passType = passTypes[passId];

        if (passType.isPaused) revert CannotMintPausedPassType();
        if (passType.lastMintedId >= passType.maxTokens)
            revert PassMaxSupplyReached();
        if (!validatePassDuration(startTimestamp, endTimestamp))
            revert DurationNotInTimeFrame();

        uint256 price = calculatePrice(passId, startTimestamp, endTimestamp);

        bool success = IERC20(iqToken).transferFrom(msg.sender, owner(), price);
        if (!success) revert MintingPaymentFailed();

        uint256 tokenId = tokenIdTracker.current();
        passType.lastMintedId += 1;
        UserPassItem memory purchase = UserPassItem(
            tokenId,
            passId,
            startTimestamp,
            endTimestamp
        );
        addressToNFTPass[msg.sender] = purchase;

        tokenIdTracker.increment();
        _safeMint(msg.sender, tokenId);

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
    function increaseEndTime(
        uint256 tokenId,
        uint256 newEndTime
    ) external whenNotPaused {
        UserPassItem memory pass = addressToNFTPass[msg.sender];

        PassType storage passType = passTypes[pass.passId];
        if (passType.isPaused) revert CannotMintPausedPassType();

        if (addressToNFTPass[msg.sender].tokenId != tokenId)
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
        bool success = IERC20(iqToken).transferFrom(msg.sender, owner(), price);
        if (!success) revert IncreseTimePaymentFailed();

        UserPassItem memory purchase = UserPassItem(
            pass.tokenId,
            pass.passId,
            pass.startTimestamp,
            newEndTime
        );

        addressToNFTPass[msg.sender] = purchase;

        emit TimeIncreased(
            msg.sender,
            tokenId,
            pass.startTimestamp,
            pass.endTimestamp
        );
    }

    /// @notice Withdraws any amount in the contract
    function withdrawEther() external payable onlyOwner {
        uint256 ethbalance = address(this).balance;
        if (ethbalance <= 0) revert NoEtherLeftToWithdraw();

        (bool success, ) = (msg.sender).call{value: ethbalance}("");
        if (!success) revert TransferFailed();
    }

    function withdrawIQ() external payable onlyOwner {
        uint256 tokenBalance = IERC20(iqToken).balanceOf(address(this));

        if (tokenBalance <= 0) revert NoIQLeftToWithdraw();

        bool tokenSuccess = IERC20(iqToken).transfer(msg.sender, tokenBalance);
        if (!tokenSuccess) revert TransferFailed();
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
        uint256 subscriptionPeriodInSeconds = endTimestamp - startTimestamp;

        uint256 subscriptionPeriodInDays = subscriptionPeriodInSeconds / 1 days;

        // Calculate the total price
        uint256 totalPrice = subscriptionPeriodInDays * passType.pricePerDay;

        if (passType.discount > 0) {
            uint256 discountAmount = (totalPrice * passType.discount) / (100);
            totalPrice = totalPrice - discountAmount;
        }

        return totalPrice;
    }

    /// @notice Validates the Timestamp Duration for minting Nft
    /// @param startTimestamp The start time for checking the validity of a pass
    /// @param endTimestamp The end time for checking the validity of a pass
    function validatePassDuration(
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal view returns (bool) {
        uint256 durationInDays = (endTimestamp - startTimestamp) / 1 days;
        return
            durationInDays >= MINT_LOWER_LIMIT &&
            durationInDays <= MINT_UPPER_LIMIT;
    }

    /// -----------------------------------------------------------------------
    /// Getters
    /// -----------------------------------------------------------------------

    /// @notice Gets all the NFT owned by an address
    /// @param user The address of the user
    function getUserPassDetails(
        address user
    ) public view returns (UserPassItem memory) {
        UserPassItem memory userToken = addressToNFTPass[user];
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

    event PassTypeStatusToggled(uint256 indexed _passId, string _name);
}
