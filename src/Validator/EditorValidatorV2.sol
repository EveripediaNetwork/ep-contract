// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {IValidator} from "./IValidator.sol";

contract EditorValidatorV2 is IValidator {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error WrongIPFSLength();
    error ExceededEditLimit();
    error EditorNotWhitelisted();

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @dev fix before year 2106
    mapping(address => uint32[5]) edits;
    address owner;
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

    /// @notice Check if the editor is whitelisted
    /// @param editorAddress the address of the editor
    function isEditorWhitelisted(address editorAddress) external view returns (bool) {
        return whitelistedAddresses[editorAddress]; 
    }

    /// @notice Review that an editor can post a wiki based in previous edits
    /// @param _user The user to approve the module for
    /// @param _ipfs The IPFS Hash
    function validate(address _user, string calldata _ipfs) external returns (bool) {
        if(!whitelistedAddresses[_user]) {
            revert EditorNotWhitelisted();
        }

        uint32[5] memory userEdits = edits[_user];

        if (userEdits[4] == 0) {
            for (uint256 i = 0; i < userEdits.length;) {
                if (userEdits[i] == 0) {
                    userEdits[i] = uint32(block.timestamp);
                    break;
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            if (block.timestamp - userEdits[0] >= 1 days) {
                for (uint256 i = 0; i < userEdits.length - 1;) {
                    userEdits[i] = userEdits[i + 1];

                    unchecked {
                        ++i;
                    }
                }
                userEdits[4] = uint32(block.timestamp);
            } else {
                revert ExceededEditLimit();
            }
        }

        edits[_user] = userEdits;

        bytes memory _ipfsBytes = bytes(_ipfs);
        if (_ipfsBytes.length != 46) {
            revert WrongIPFSLength();
        }
        return true;
    }

    function getRemainEditsCount(address _user) external view returns (uint256) {
        uint32[5] memory userEdits = edits[_user];
        uint256 count = 0;
        for (uint256 i = 0; i < userEdits.length; ++i) {
            if (userEdits[i] == 0 || block.timestamp - userEdits[i] >= 1 days) {
                ++count;
            }
        }
        return count;
    }
}
