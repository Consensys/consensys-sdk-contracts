// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// Token URI of contract cannot be empty.
error TokenURIIsEmpty();
/// Quantity has to be greater than one.
error QuantityIsZero();

contract ERC1155Mintable is
    ERC1155,
    ERC2981,
    AccessControl,
    ReentrancyGuard,
    Ownable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(uint256 => uint256) public tokenSupply;

    constructor(string memory uri_) ERC1155(uri_) {
        if (!(bytes(uri_).length > 1)) {
            revert TokenURIIsEmpty();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(
        address to_,
        uint256 id_,
        uint256 quantity_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (quantity_ < 1) {
            revert QuantityIsZero();
        }
        _mint(to_, id_, quantity_, "");
    }

    function mintBatch(
        address to_,
        uint256[] memory ids_,
        uint256[] memory quantities_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        for (uint256 i = 0; i < quantities_.length; i++) {
            if (quantities_[i] < 1) {
                revert QuantityIsZero();
            }
        }
        _mintBatch(to_, ids_, quantities_, "");
    }

    ///#if_succeeds let receiver, _ := royaltyInfo(0, 10000) in receiver == receiver_;
    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    ///#if_succeeds let uri := uri() in uri == newUri;
    function setURI(string memory newUri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri_);
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
