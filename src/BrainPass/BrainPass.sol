// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";


/// @title BRAIN Pass NFT
/// @author Oleanji
/// @notice A pass for IQ Wiki Editors

contract BrainPassCollectibles is ERC721, Ownable {
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
        uint256 _tokenId;
        uint256 _passId;
        uint256 _startTimestamp;
        uint256 _endTimestamp;
    }

    struct PassType {
        uint256 _passId;
        string _passSlug;
        uint256 _pricePerDays;
        string _tokenURI;
        uint256 _maxTokens;
        uint256 _discount;
        uint256 _lastTokenIdMinted;
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
    Counters.Counter private _tokenIds;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------
    constructor(address _IqAddr) ERC721("BRAINY EDITOR PASS", "BEP") {
        IqToken = IERC20(_IqAddr);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function addPassType(
        uint256 _passId,
        uint256 _pricePerDays,
        string memory _tokenURI,
        string memory _passSlug,
        uint256 _maxTokens,
        uint256 _discount
    ) public onlyOwner {
        require(bytes(_tokenURI).length > 0, "Invalid token URI");
        require(_maxTokens > 0, "Invalid max tokens");

        passTypes[_passId] = PassType(
            _passId,
            _passSlug,
            _pricePerDays,
            _tokenURI,
            _maxTokens,
            _discount,
            0
        );

        emit NewPassAdded(_passId, _passSlug, _maxTokens, _pricePerDays);
    }

    function mintNFT(
        uint256 _passIdNum,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public payable {
        require(
            addressToPassId[msg.sender][_passIdNum] != true,
            "Max NFTs per address reached"
        );

        PassType storage passType = passTypes[_passIdNum];

        require(passType._maxTokens != 0, "Pass type not found");

        require(
            passType._lastTokenIdMinted.add(1) <= passType._maxTokens,
            "Max supply reached"
        );

        uint256 price = calculatePrice(
            _passIdNum,
            _startTimestamp,
            _endTimestamp
        );
        require(msg.value >= price, "Not enough payment token");

        uint256 tokenId = passType._lastTokenIdMinted;
        bool success = IqToken.transfer(owner(), price);
        if (!success) revert MintingPaymentFailed();

        setBaseURI(passType._tokenURI);
        _safeMint(msg.sender, tokenId);

        UserPassItem memory purchase = UserPassItem(
            tokenId,
            _passIdNum,
            _startTimestamp,
            _endTimestamp
        );
        addressToPassId[msg.sender][_passIdNum] = true;
        addressToNFTPass[msg.sender][tokenId] = purchase;
        passType._lastTokenIdMinted = tokenId += 1;

        emit BrainPassBought(
            msg.sender,
            tokenId,
            _startTimestamp,
            _endTimestamp
        );
    }

    function calculatePrice(
        uint256 _passIdNum,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) public view returns (uint256) {
        PassType memory passType = passTypes[_passIdNum];
        uint256 duration = _endTimestamp.sub(_startTimestamp);
        uint256 totalPrice = duration.mul(passType._pricePerDays);
        if (passType._discount > 0) {
            uint256 discountAmount = totalPrice.mul(passType._discount).div(
                100
            );
            totalPrice = totalPrice.sub(discountAmount);
        }

        return totalPrice;
    }

    function increasePassTime(
        uint256 tokenId,
        uint256 _passIdNum,
        uint _newStartTime,
        uint256 _newEndTime
    ) public payable {
        require(
            msg.sender == ownerOf(tokenId),
            "You cannot increase the time for an NFT you don't own"
        );

        UserPassItem storage pass = addressToNFTPass[ownerOf(tokenId)][tokenId];
        uint256 price = calculatePrice(_passIdNum, _newStartTime, _newEndTime);
        require(msg.value >= price, "Not enough payment token");

        pass._startTimestamp = _newStartTime;
        pass._endTimestamp = _newEndTime;

        emit TimeIncreased(
            msg.sender,
            tokenId,
            pass._startTimestamp,
            pass._endTimestamp
        );
    }

    function getUserNFTs(
        address _user,
        uint _passIdNum
    ) public view returns (UserPassItem[] memory) {
        uint256 userTokenCount = balanceOf(_user);
        PassType memory passType = passTypes[_passIdNum];
        UserPassItem[] memory userTokens = new UserPassItem[](userTokenCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < passType._maxTokens; i++) {
            if (ownerOf(i) == _user) {
                userTokens[counter] = addressToNFTPass[msg.sender][i];
                counter++;
            }
        }
        return userTokens;
    }

    function getPassType(
        uint256 _passId
    ) public view returns (PassType memory) {
        PassType memory passType = passTypes[_passId];
        return (passType);
    }

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
