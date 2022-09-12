// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// Token URI of contract cannot be empty.
error TokenURIIsEmpty();

contract ERC1155Mintable is
    ERC1155,
    ERC2981,
    AccessControl,
    Ownable
{
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseURI;
    mapping (uint256 => bool) private _validIds;

    constructor(string memory uri_, uint256[] memory ids_) ERC1155(uri_) {
        if (bytes(uri_).length < 1) {
            revert TokenURIIsEmpty();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _baseURI = uri_;
        addIds(ids_);
    }

    function mint(
        address to_,
        uint256 id_,
        uint256 quantity_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to_, id_, quantity_, "");
    }

    function mintBatch(
        address to_,
        uint256[] memory ids_,
        uint256[] memory quantities_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintBatch(to_, ids_, quantities_, "");
    }

    function addIds(uint256[] memory ids_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ids_.length; i++) {
            _validIds[ids_[i]] = true;
        }
    }
 
    ///#if_succeeds let uri := uri() in uri == newUri_;
    function setURI(string memory newUri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bytes(newUri_).length < 1) {
            revert TokenURIIsEmpty();
        }
        _setURI(newUri_);
    }

    ///#if_succeeds let receiver, _ := royaltyInfo(0, 10000) in receiver == receiver_;
    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function uri(uint256 tokenId_)
        public
        view                
        override
        returns (string memory)
    {
        require(
            _validIds[tokenId_],
            "URI requested for invalid Token ID"
        );
        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId_.toString(), ".json"))
                : _baseURI;
    }

    // Overrides

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
