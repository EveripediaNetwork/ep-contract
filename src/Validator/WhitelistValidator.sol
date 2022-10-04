// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IValidator} from "./IValidator.sol";

contract WhitelistValidator is IValidator {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// The ipfs hash provided hash a wrong length
    error WrongIPFSLength();
    /// The address provided does not correspond to any whitelisted editor
    error EditorNotWhitelisted();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    address public owner;
    mapping(address => bool) whitelistedAddresses;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        owner = msg.sender;
    }

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Check if the contract caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner.");
        _;
    }

    /// -----------------------------------------------------------------------
    /// External functions
    /// -----------------------------------------------------------------------

    /// @notice Add a new editor to the whitelist
    /// @param editorAddress the address of the editor
    function whitelistEditor(address editorAddress) external onlyOwner {
        whitelistedAddresses[editorAddress] = true;
    }

    /// @notice Delete a whitelisted editor
    /// @param editorAddress the address of the editor
    function unWhitelistEditor(address editorAddress) external onlyOwner {
        delete whitelistedAddresses[editorAddress];
    }

    /// @notice Set owner to a different address
    /// @param newOwner the address of the new owner
    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    /// @notice Review that an editor can post a wiki based in previous edits
    /// @param _user The user to approve the module for
    /// @param _ipfs The IPFS Hash
    function validate(address _user, string calldata _ipfs) external returns (bool) {
        if (!whitelistedAddresses[_user]) {
            revert EditorNotWhitelisted();
        }

        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Check if the editor is whitelisted
    /// @param editorAddress the address of the editor
    function isEditorWhitelisted(address editorAddress) external view returns (bool) {
        return whitelistedAddresses[editorAddress];
    }
}
