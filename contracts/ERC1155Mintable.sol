// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// Base URI of tokens to be minted cannot be empty.
error BaseURIIsEmpty();
/// Contract URI cannot be empty.
error ContractURIIsEmpty();

contract ERC1155Mintable is ERC1155, ERC2981, AccessControl, Ownable {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseURI;
    string private _contractURI;
    mapping(uint256 => bool) private _validIds;

    constructor(
        string memory uri_,
        string memory contractURI_,
        uint256[] memory ids_
    ) ERC1155(uri_) {
        if (!(bytes(uri_).length > 1)) {
            revert BaseURIIsEmpty();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _baseURI = uri_;
        _contractURI = contractURI_;
        addIds(ids_);
    }

    ///#if_succeeds old(balanceOf(to_, id_)) + quantity_ == balanceOf(to_, id_);
    function mint(
        address to_,
        uint256 id_,
        uint256 quantity_
    ) public onlyRole(MINTER_ROLE) {
        _mint(to_, id_, quantity_, "");
    }

    ///#if_succeeds old(balanceOf(to_, ids_[0])) + quantities_[0] == balanceOf(to_, ids_[0]);
    function mintBatch(
        address to_,
        uint256[] memory ids_,
        uint256[] memory quantities_
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to_, ids_, quantities_, "");
    }

    function addIds(uint256[] memory ids_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = ids_.length;
        for (uint256 i = 0; i < length; i++) {
            _validIds[ids_[i]] = true;
        }
    }

    ///#if_succeeds (keccak256(abi.encodePacked((_baseURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_baseURI))) == keccak256(abi.encodePacked((newUri_))));
    function setURI(string memory newUri_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!(bytes(newUri_).length > 1)) {
            revert BaseURIIsEmpty();
        }
        _baseURI = newUri_;
    }

    ///#if_succeeds (keccak256(abi.encodePacked((_contractURI))) != keccak256(abi.encodePacked((""))));
    ///#if_succeeds (keccak256(abi.encodePacked((_contractURI))) == keccak256(abi.encodePacked((contractURI_))));
    function setContractURI(string memory contractURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (!(bytes(contractURI_).length > 1)) {
            revert ContractURIIsEmpty();
        }
        _contractURI = contractURI_;
    }

    ///#if_succeeds let receiver, _ := royaltyInfo(0, 10000) in receiver == receiver_;
    function setRoyalties(address receiver_, uint96 feeNumerator_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function uri(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_validIds[tokenId_], "URI requested for invalid Token ID");
        return
            bytes(_baseURI).length > 0
                ? string(
                    abi.encodePacked(_baseURI, tokenId_.toString(), ".json")
                )
                : _baseURI;
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
