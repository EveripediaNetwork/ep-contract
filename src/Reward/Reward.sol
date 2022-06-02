// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;
import {Base64} from "../Utils/Base64.sol";
import {Strings} from "../Utils/Strings.sol";

interface ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract IRewardRenderer {
    function renderReward(
        address _editorAddress,
        string memory _editorUsername,
        string memory _rewardDate,
        uint256 _position
    ) public pure returns (string memory) {}
}

contract Reward is ERC721 {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------
    string public name;
    string public symbol;
    uint256 public totalSupply;
    address private _admin;
    address private _rendererAddress;

    struct Editor {
        address _editorAddress;
        string _editorUsername;
        string _rewardDate;
        uint256 _position;
    }

    mapping(uint256 => address) private _ownership;
    mapping(address => uint256) private _balances;
    mapping(uint256 => Editor) public editors;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        string memory _name,
        string memory _symbol,
        address _renderer
    ) {
        name = _name;
        symbol = _symbol;
        _admin = msg.sender;
        _rendererAddress = _renderer;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    function mint(
        address _to,
        string memory _editorUsername,
        string memory _rewardDate,
        uint256 _position
    ) public returns (bool) {
        require(
            msg.sender == _admin,
            "Reward: Only the admin can mint new tokens"
        );
        require(_to != address(0), "Reward: Cannot mint to the null address");

        Editor memory _editor = Editor(
            _to,
            _editorUsername,
            _rewardDate,
            _position
        );
        totalSupply++;
        _ownership[totalSupply] = _to;
        _balances[_to] = _balances[_to] + 1;
        editors[totalSupply] = _editor;

        emit Transfer(address(0), _to, totalSupply);

        return true;
    }

    function changeRenderer(address _newRenderer) public returns (bool) {
        require(
            msg.sender == _admin,
            "Reward: Only the admin can change the renderer address"
        );
        require(
            _newRenderer != address(0),
            "Reward: Cannot change to the null address"
        );
        _rendererAddress = _newRenderer;
        return true;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _ownership[_tokenId] != address(0x0),
            "Reward: token doesn't exist."
        );

        Editor memory _editor = editors[_tokenId];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "Wiki title:What is a DAO",',
                        '"description": "A non-transferrable badge to show wiki contibutions.",',
                        '"tokenId": ',
                        Strings.toString(_tokenId),
                        ",",
                        '"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_renderSVG(_editor))),
                        '"',
                        "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _ownership[_tokenId];
    }

    // this function is disabled since we don;t want to allow transfers
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable virtual override {
        revert("Reward: Transfer not supported.");
    }

    // this function is disabled since we don;t want to allow transfers
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable virtual override {
        revert("Reward: Transfer not supported.");
    }

    // this function is disabled since we don;t want to allow transfers
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable virtual override {
        revert("Reward: Transfer not supported.");
    }

    // this function is disabled since we don;t want to allow transfers
    function approve(address _to, uint256 _tokenId)
        public
        payable
        virtual
        override
    {
        revert("Reward: Approval not supported.");
    }

    // this function is disabled since we don;t want to allow transfers
    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
    {
        revert("Reward: Approval not supported.");
    }

    // this function is disabled since we don;t want to allow transfers
    function getApproved(uint256 _tokenId)
        public
        pure
        override
        returns (address)
    {
        return address(0x0);
    }

    // this function is disabled since we don;t want to allow transfers
    function isApprovedForAll(address _owner, address _operator)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f;
    }

    function _renderSVG(Editor memory _editor)
        internal
        view
        returns (string memory)
    {
        IRewardRenderer renderer = IRewardRenderer(_rendererAddress);
        return
            renderer.renderReward(
                _editor._editorAddress,
                _editor._editorUsername,
                _editor._rewardDate,
                _editor._position
            );
    }
}
